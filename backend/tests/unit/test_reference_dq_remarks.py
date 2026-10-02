"""Data Type and automated Remarks produced by the reference DQ method (no Ollama needed)."""
import os

os.environ.setdefault("SECRET_KEY", "test-secret")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("DATABASE_URL_SYNC", "sqlite:///:memory:")

import pandas as pd
import pytest

from app.services import reference_dq
from app.services.reference_dq import ReferenceDQConfig, result_rows_from_reference

# Canned model answers per column: a valid regex, an invalid regex, and one without a regex
_REGEX = {
    "code": r"r'^[A-Z]{3}$'",
    "bad": r"r'^(abc$'",          # unbalanced parenthesis -> invalid regex
    "created": r"r'^\d{4}-\d{2}-\d{2}$'",
}


def _fake_ollama(prompt: str, model: str, config: ReferenceDQConfig) -> str:
    column = next(c for c in ("code", "bad", "created", "notes") if f"Column Name: {c}\n" in prompt)
    regex_line = f"- RegEx Pattern: {_REGEX[column]}\n" if column in _REGEX else ""
    return (
        "HERE IS THE FINAL RESULT.\n"
        f"- Column Name: {column}\n- Column Type: object\n"
        "- Business Rules: a. Value must follow the observed format\n"
        f"{regex_line}- Complexity: Low\n- Reasoning: Based on the sample values"
    )


def _run(monkeypatch, df: pd.DataFrame):
    monkeypatch.setattr(reference_dq, "_call_ollama", _fake_ollama)
    config = ReferenceDQConfig(base_url="http://unused", primary_model="primary-model", secondary_model="secondary-model")
    rows, _ = result_rows_from_reference(reference_dq.run_reference_dq_for_dataframe(df, "t", "p", config))
    return {(r["column_name"], r["check_type"]): r for r in rows}


def test_data_type_and_default_remark(monkeypatch):
    rules = _run(monkeypatch, pd.DataFrame({"code": ["ABC", "DEF", "GHI"]}))
    assert rules[("code", "completeness")]["data_type"] == "object"
    assert rules[("code", "consistency")]["data_type"] == "object"
    assert rules[("code", "completeness")]["remarks"] == "-"
    assert rules[("code", "consistency")]["remarks"] == "-"
    # the r'...' wrapper is fully removed on every dimension
    assert rules[("code", "completeness")]["regex_pattern"] == "^[A-Z]{3}$"
    assert rules[("code", "consistency")]["regex_pattern"] == "^[A-Z]{3}$"


def test_dropped_fields_are_not_output(monkeypatch):
    """Model, Category and Raw Text are not part of the DQ output (not used in the real rules index)."""
    rules = _run(monkeypatch, pd.DataFrame({"code": ["ABC", "DEF", "GHI"]}))
    for rule in rules.values():
        assert "ai_model" not in rule
        assert "column_category" not in rule
        assert "raw_text" not in rule["details"]


def test_invalid_model_regex_keeps_the_data_profile_regex(monkeypatch):
    rules = _run(monkeypatch, pd.DataFrame({"bad": ["abc", "abd", "abe"]}))
    consistency = rules[("bad", "consistency")]
    assert consistency["regex_pattern"] == "^[a-z]{3}$"
    assert consistency["score"] == 100.0
    assert "suggested ^(abc$ (0.0%); data-profile regex kept (100.0%)" in consistency["remarks"]
    assert rules[("bad", "completeness")]["remarks"] == "-"


def test_invalid_regex_and_repair_are_noted_without_a_profile(monkeypatch):
    monkeypatch.setattr(reference_dq, "profile_regex", lambda *args: None)  # model-only path
    rules = _run(monkeypatch, pd.DataFrame({"bad": ["abc", "abd", "abe"]}))
    remark = rules[("bad", "consistency")]["remarks"]
    assert "Generated regex is not valid" in remark
    assert "repair pass with secondary-model" in remark
    assert "first regex kept" in remark  # the fake repair answer is invalid too


def test_model_regex_replaces_a_weaker_profile_regex(monkeypatch):
    monkeypatch.setattr(reference_dq, "profile_regex", lambda *args: r"^ABC$")  # matches 1 of 3 values
    rules = _run(monkeypatch, pd.DataFrame({"code": ["ABC", "DEF", "GHI"]}))
    consistency = rules[("code", "consistency")]
    assert consistency["regex_pattern"] == "^[A-Z]{3}$"
    assert "Regex corrected by primary-model (100.0% vs data-profile regex 33.3%)" in consistency["remarks"]


def test_repair_pass_uses_failed_values_and_replaces_a_worse_regex(monkeypatch):
    monkeypatch.setattr(reference_dq, "profile_regex", lambda *args: r"^AB-1$")  # weak first regex
    prompts = []

    def fake(prompt, model, config):
        prompts.append(prompt)
        # first answer only matches 'AB-1'; the repair answer matches every value
        regex = r"r'^[A-Z]{2}-\d+$'" if "Values that do NOT match" in prompt else r"r'^AB-1$'"
        return (
            "HERE IS THE FINAL RESULT.\n- Column Name: code\n- Column Type: object\n"
            f"- Business Rules: a. Two letters; b. A dash; c. Digits\n- RegEx Pattern: {regex}\n"
            "- Complexity: Low\n- Reasoning: ok"
        )

    monkeypatch.setattr(reference_dq, "_call_ollama", fake)
    config = ReferenceDQConfig(base_url="http://unused", primary_model="m", secondary_model="m")
    df = pd.DataFrame({"code": ["AB-1", "CD-22", "EF-333", "GH-4444"]})
    rows, _ = result_rows_from_reference(reference_dq.run_reference_dq_for_dataframe(df, "t", "p", config))
    consistency = next(r for r in rows if r["check_type"] == "consistency")

    repair_prompt = next(p for p in prompts if "Values that do NOT match" in p)
    assert "CD-22" in repair_prompt and "r'^AB-1$'" in repair_prompt
    assert consistency["score"] == 100.0
    assert consistency["regex_pattern"] == r"^[A-Z]{2}-\d+$"
    assert "repaired regex scored 100.0% and replaced it" in consistency["remarks"]


def test_select_samples_covers_every_kind_of_character():
    values = [f"{i:05d}" for i in range(500)] + ["-7", "AB CD", "x.y_z"]
    picked = reference_dq._select_samples(values, 10)
    assert len(picked) == 10
    assert {"-7", "AB CD", "x.y_z"} <= set(picked)  # minus, upper, space, lower, '.', '_' all represented


def test_prompt_contains_samples_profile_regex_and_output_format():
    prompt = (reference_dq.INIT_PROMPT.replace("<COLUMN-DATA>", reference_dq._format_values([1.5, -2.25], "float64"))
              .replace("<PROFILE-REGEX>", r"^-?\d+(\.\d+)?$"))
    assert "[1.5, -2.25]" in prompt
    assert r"Regex derived from the data: r'^-?\d+(\.\d+)?$'" in prompt
    assert "HERE IS THE FINAL RESULT." in prompt and "- RegEx Pattern: r'^<regex>$'" in prompt


@pytest.mark.parametrize("raw, expected", [
    (r"r'^^(KAB\.|KOTA) [A-Z]+$'", r"^(KAB\.|KOTA) [A-Z]+$"),
    (r"r'^\d+$$'", r"^\d+$"),
    (r"r'^\d+\$$'", r"^\d+\$$"),  # escaped dollar followed by the anchor is kept
])
def test_clean_regex_removes_repeated_anchors(raw, expected):
    assert reference_dq._clean_regex(raw) == expected


def test_missing_model_regex_uses_the_profile_regex(monkeypatch):
    rules = _run(monkeypatch, pd.DataFrame({"notes": ["x", "y", "z"]}))
    consistency = rules[("notes", "consistency")]
    assert consistency["regex_pattern"] == "^[a-z]$"
    assert consistency["score"] == 100.0
    assert "no RegEx pattern" not in consistency["remarks"]


def test_missing_regex_is_noted_without_a_profile(monkeypatch):
    monkeypatch.setattr(reference_dq, "profile_regex", lambda *args: None)
    rules = _run(monkeypatch, pd.DataFrame({"notes": ["x", "y", "z"]}))
    assert "output contained no RegEx pattern" in rules[("notes", "consistency")]["remarks"]


@pytest.mark.parametrize("values, dtype, expected", [
    (["BPS_001", "BPS_120", "BPS_345"], "object", r"^BPS_\d{3}$"),
    (["AHM JTG", "AHM DIY", "AST JTM"], "object", "^[A-Z]{3} [A-Z]{3}$"),
    (["JAWA TENGAH", "BENGKULU", "DI YOGYAKARTA", "BALI"], "object", "^[A-Z]+( [A-Z]+)*$"),
    (["KAB. BANYUMAS", "KOTA SEMARANG", "KAB. KLATEN", "KOTA TEGAL"], "object", r"^(KAB\.|KOTA) [A-Z]+( [A-Z]+)*$"),
    ([1.5, 22.125, -3.0], "float64", r"^-?\d+(\.\d+)?$"),
    ([0, 1, 1, 0], "Int64", "^[01]$"),
    ([1, 3, 5], "Int64", "^[135]$"),
    ([0, 1, 2, 3, 4, 5], "Int64", "^[0-5]$"),
    ([-3, 0, 12, 40, 7, 8], "Int64", r"^-?\d+$"),
    (["a@b.com", "c.d@e.co.id", "x_y@z.org"], "object", reference_dq.EMAIL_REGEX),
])
def test_profile_regex_matches_the_hso_style(values, dtype, expected):
    assert reference_dq.profile_regex(values, [1] * len(values), dtype) == expected


@pytest.mark.parametrize("values, weights, expected", [
    # names from the real HSO sample data: no fixed lengths for words longer than a code
    (["NEGARA", "TABANAN", "DENPASAR", "GIANYAR", "KLUNGKUNG"], [1] * 5, "^[A-Z]+( [A-Z]+)*$"),
    (["KALIMANTAN TIMUR", "KALIMANTAN UTARA"], [1, 1], "^[A-Z]+( [A-Z]+)*$"),
    (["KAB. SAMBAS", "KAB. BENGKAYANG", "KAB. LANDAK"], [1] * 3, r"^KAB\. [A-Z]+$"),
    # a short category list with different shapes, each value repeated
    (["AVG", "MAX", "SUM", "-", "Other"], [4] * 5, "^(-|AVG|MAX|Other|SUM)$"),
    # place names are not enumerated even when only a few repeat in one table
    (["KAB. BLORA", "KOTA PEKALONGAN", "KAB. JEPARA", "KAB. KARANGANYAR", "KAB. PEMALANG"], [3] * 5,
     r"^(KAB\.|KOTA) [A-Z]+( [A-Z]+)*$"),
    # free text: each character range once
    (["HSO BKL", "HSO DIY", "HSO Kaltim-BPP", "HSO NTB", "HSO PTK"], [1] * 5, r"^[A-Za-z \-]+$"),
])
def test_profile_regex_on_real_hso_shapes(values, weights, expected):
    assert reference_dq.profile_regex(values, weights, "object") == expected


def test_profile_regex_does_not_enumerate_amounts():
    assert reference_dq.profile_regex([76, 99, 175, 178, 427], [1] * 5, "Int64") == r"^\d+$"


def test_profile_regex_ignores_rare_bad_values():
    good = [f"BPS_{i:03d}" for i in range(1, 60)]
    bad = ["BPS_12", "bps_001"]  # 3% of rows: must be flagged, not absorbed into the pattern
    assert reference_dq.profile_regex(good + bad, [1] * 61, "object") == r"^BPS_\d{3}$"


def test_data_facts_describe_small_integer_sets():
    facts = reference_dq.data_facts([1, 3, 5], [10, 5, 2], "Int64")
    assert "Only these 3 distinct values occur: 1, 3, 5" in facts
    assert "No value is negative" in facts and "whole numbers" in facts


def test_data_facts_describe_code_structure_and_ignore_rare_shapes():
    good = [f"H {1000 + i} {'ABCD'[i % 4]}{'XYZ'[i % 3]}" for i in range(60)]
    facts = reference_dq.data_facts(good + ["h1234ab"], [1] * 61, "object")
    assert "Every value is: 1 upper-case letter, then a space, then 4 digits, then a space, then 2 upper-case letters" in facts
    assert "Length: exactly 9 characters" in facts
    assert "lower-case" not in facts  # the rare bad value does not change the facts


def test_data_facts_describe_capitalisation():
    facts = reference_dq.data_facts(["Auto", "Mortgage", "Personal", "High risk"], [1] * 4, "object")
    assert "Each value starts with one upper-case letter; all other letters are lower-case" in facts
    assert "All letters are upper-case" in reference_dq.data_facts(["JAWA TENGAH", "BALI"], [1, 1], "object")


def test_data_facts_for_decimals_and_negatives():
    facts = reference_dq.data_facts([-1.5, 2.25, 10.125], [1, 1, 1], "float64")
    assert "Some values are negative" in facts
    assert "Values have 1 to 3 decimal places" in facts
    assert "Characters used: digits, a decimal point '.', a leading minus sign '-' for negative values" in facts
    assert "no minus sign" in reference_dq.data_facts([1.5, 2.0], [1, 1], "float64")


def test_prompt_gets_the_data_facts(monkeypatch):
    prompts = []

    def fake(prompt, model, config):
        prompts.append(prompt)
        return _fake_ollama(prompt, model, config)

    monkeypatch.setattr(reference_dq, "_call_ollama", fake)
    config = ReferenceDQConfig(base_url="http://unused")
    reference_dq.run_reference_dq_for_dataframe(pd.DataFrame({"code": ["ABC", "DEF", "GHI"]}), "t", "p", config)
    assert "<DATA-FACTS>" not in prompts[0]
    assert "- Every value is: 3 upper-case letters" in prompts[0]


def test_consistency_failed_count_is_the_non_matching_rows(monkeypatch):
    rules = _run(monkeypatch, pd.DataFrame({"code": ["ABC", "DEF", "GHI", None]}))
    consistency = rules[("code", "consistency")]
    assert consistency["score"] == 75.0  # the empty row counts as non-matching, as in the template
    assert consistency["row_count"] == 4 and consistency["failed_count"] == 1


@pytest.mark.parametrize("value", [None, float("nan"), pd.NaT, "", "   ", "\t", "NULL", "null", "None", "NaN", "N/A", "na", "#N/A", "-", "--", "(blank)", "undefined"])
def test_empty_like_values(value):
    assert reference_dq.is_empty_value(value)


@pytest.mark.parametrize("value", [0, 0.0, False, "0", "No", "NAS", "Nana", "- 1", "BPS_001"])
def test_real_values_are_not_empty(value):
    assert not reference_dq.is_empty_value(value)


def test_empty_attributes_need_every_value_empty():
    data = {
        "all_blank": ["", "  ", None, "NULL", "N/A"],
        "partly": ["", "x", None],
        "zeros": [0, 0, 0],
        "no_rows": [],
    }
    assert reference_dq.empty_attributes(data) == ["all_blank", "no_rows"]


def test_checks_on_blank_attributes_are_no_data_not_failed(monkeypatch):
    rules = _run(monkeypatch, pd.DataFrame({"code": ["ABC", "DEF", "GHI"], "notes": [None, None, None]}))
    rows = list(rules.values())
    reference_dq.mark_blank_attributes(rows, ["notes"])
    notes = [r for r in rows if r["column_name"] == "notes"]
    assert notes and all(r["status"] == "no_data" for r in notes)
    completeness = next(r for r in notes if r["check_type"] == "completeness")
    assert completeness["remarks"].startswith("All 3 values are empty")
    assert len(completeness["findings"]) == 1 and "has no values" in completeness["findings"][0]["description"]
    assert all(not r["findings"] for r in notes if r["check_type"] != "completeness")
    assert all(r["status"] != "no_data" for r in rows if r["column_name"] == "code")


def test_latency_notes_latest_date(monkeypatch):
    rules = _run(monkeypatch, pd.DataFrame({"created": ["2026-01-01", "2026-01-15", "2026-02-01"]}))
    assert rules[("created", "latency")]["remarks"].startswith("Latest date found: 2026-02-01")
