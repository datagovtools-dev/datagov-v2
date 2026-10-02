import os

os.environ.setdefault("SECRET_KEY", "test-secret")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("DATABASE_URL_SYNC", "sqlite:///:memory:")

from app.schemas.settings import AISettingsUpdate
from app.services.ai_generation import AIGenerationError, validate_metadata_definition
from app.services.ai_output_parser import parse_dq_output
from app.services import reference_dq
import pandas as pd


def test_parser_accepts_cloud_model_aliases_and_markdown_wrappers():
    raw = """Here is the final result.
- Column Name: customer_code
- Column Type: object
- Validation Rules: a. Three uppercase letters; b. Digits are not allowed
- Regex Pattern: `^[A-Z]{3}$`
- Complexity Level: Low
- Rationale: All observed values share one shape.
"""

    parsed = parse_dq_output(raw, contract_version="legacy_v1")

    assert parsed["business_rules"].startswith("a. Three uppercase letters")
    assert parsed["regex_pattern"] == "r'^[A-Z]{3}$'"
    assert parsed["complexity"] == "Low"
    assert parsed["reasoning"] == "All observed values share one shape."
    assert parsed["parser_warnings"] == []


def test_parser_reports_invalid_or_missing_fields_without_crashing():
    parsed = parse_dq_output(
        "- Business Rules: values are valid\n- Regex Pattern: not-a-regex",
        contract_version="legacy_v1",
    )

    assert parsed["business_rules"] == "values are valid"
    assert parsed["regex_pattern"] == "No match found."
    assert parsed["complexity"] == "No match found."
    assert "regex_pattern_missing_or_invalid" in parsed["parser_warnings"]


def test_ai_settings_exposes_provider_independent_policy_controls():
    settings = AISettingsUpdate(
        parser_contract_version="legacy_v1",
        metadata_contract_version="metadata_v1",
        dq_policy="guarded_legacy",
        model_override_enabled=True,
        repair_enabled=True,
        minimum_score_delta=2.0,
        metadata_validation="strict",
        fallback_enabled=True,
    )

    assert settings.parser_contract_version == "legacy_v1"
    assert settings.dq_policy == "guarded_legacy"
    assert settings.minimum_score_delta == 2.0
    assert settings.fallback_enabled is True


def test_metadata_contract_rejects_invalid_free_form_output():
    try:
        validate_metadata_definition("this is invalid; it has a semicolon", expected_sentences=2)
    except AIGenerationError as exc:
        assert "metadata output" in str(exc).lower()
    else:
        raise AssertionError("invalid metadata output should be rejected")


def test_profile_canonical_policy_keeps_profile_regex(monkeypatch):
    monkeypatch.setattr(reference_dq, "profile_regex", lambda *args: r"^ABC$")

    def fake(prompt, model, config):
        return (
            "HERE IS THE FINAL RESULT.\n- Column Name: code\n- Column Type: object\n"
            "- Business Rules: a. Any value\n- RegEx Pattern: r'^[A-Z]{3}$'\n"
            "- Complexity: Low\n- Reasoning: stable"
        )

    monkeypatch.setattr(reference_dq, "_call_ollama", fake)
    config = reference_dq.ReferenceDQConfig(base_url="http://unused", dq_policy="profile_canonical")
    rows, _ = reference_dq.result_rows_from_reference(
        reference_dq.run_reference_dq_for_dataframe(pd.DataFrame({"code": ["ABC", "DEF", "GHI"]}), "t", "p", config)
    )
    consistency = next(row for row in rows if row["check_type"] == "consistency")
    assert consistency["regex_pattern"] == "^ABC$"
    assert consistency["score"] == 33.33


def test_dq_fallback_uses_profile_when_model_call_fails(monkeypatch):
    monkeypatch.setattr(reference_dq, "_call_ollama", lambda *args: (_ for _ in ()).throw(RuntimeError("cloud down")))
    config = reference_dq.ReferenceDQConfig(base_url="http://unused", fallback_enabled=True)
    rows, _ = reference_dq.result_rows_from_reference(
        reference_dq.run_reference_dq_for_dataframe(pd.DataFrame({"code": ["ABC", "DEF"]}), "t", "p", config)
    )
    consistency = next(row for row in rows if row["check_type"] == "consistency")
    assert consistency["score"] == 100.0
    assert "AI request failed" in consistency["remarks"]
