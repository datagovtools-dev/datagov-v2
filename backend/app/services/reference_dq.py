"""Reference Data Quality method from the Existing Data Quality scripts.

Telegram and BigQuery upload/notification concerns are intentionally omitted.
The rule prompt, model sequence, sampling, regex scoring, uniqueness, latency,
and index calculations mirror the provided DQ scripts.
"""
from __future__ import annotations

import math
import os
import time
from dataclasses import dataclass
from datetime import datetime
from collections.abc import Callable
from typing import Any

import numpy as np
import pandas as pd
import regex as re
import requests

from app.services.ai_generation import ollama_endpoint
from app.services.ai_output_parser import NO_MATCH, parse_dq_output


# Rule-generation prompt tuned for a small local model (llama3.2:3b). It replaces the long
# qwen2.5-coder prompt of the template: short explicit instructions, per-type regex guidance
# (avoids the template's weak spots: capped digit/decimal counts, missing minus sign) and one
# worked example. The output format is unchanged, so extract_from_output() still applies.
_OUTPUT_FORMAT = """Answer in exactly this format and nothing else:
HERE IS THE FINAL RESULT.
- Column Name: <column name>
- Column Type: <column type>
- Business Rules: a. <rule>; b. <rule>; c. <rule>
- RegEx Pattern: r'^<regex>$'
- Complexity: <High, Medium or Low>
- Reasoning: <one sentence on how well the sample values represent the whole column>"""

_REGEX_GUIDE = """How to build the regex:
1. Base it on the sample values first, then the column name, then the column type.
2. EVERY sample value must fully match. Start the regex with ^ and end it with $.
3. Keep it general: describe the kinds of characters and separators you see, not the exact values.
   - Text: allow the letters, spaces and punctuation that appear, e.g. ^[A-Z][A-Z .]*$ for upper-case names.
   - Codes with a fixed shape: keep literal prefixes and fixed digit counts, e.g. BPS_001 -> ^BPS_\\d{3}$.
   - Whole numbers: ^\\d+$, and ^-?\\d+$ if any value is negative. Only list values like ^[135]$ when there are 5 or fewer distinct values.
   - Decimal numbers (float64): ^-?\\d+(\\.\\d+)?$ style. Never limit how many digits or decimals a number has. Use -? only if a negative value appears.
   - Dates and times: copy the exact layout shown, e.g. ^\\d{4}-\\d{2}-\\d{2}$.
4. Escape dots as \\. and do not use lookaheads or backreferences."""

# The model receives facts measured on the data (data_facts) and the data-profile regex (profile_regex)
# and writes the business rules, complexity and reasoning; it may correct the regex, and its version is
# kept only if it scores better.
INIT_PROMPT = f"""You are a data quality analyst. Write the validation rules for one data column.

Column Name: <COLUMN-NAME>
Column Type: <COLUMN-TYPE>
Sample Values: <COLUMN-DATA>
Facts measured on all values:
<DATA-FACTS>
Regex derived from the data: r'<PROFILE-REGEX>'

Tasks:
1. Business Rules: three short rules (a, b, c) in plain words, taken from the facts above: a. the structure or allowed values, b. the allowed characters, listing every item of the "Characters used" fact, c. the length, number range or decimal places. Use only the facts; do not add rules they do not state (such as leading zeros).
2. RegEx Pattern: repeat the regex above exactly. Only if a sample value does not match it, write a corrected regex that matches all samples (start with ^, end with $).
3. Complexity: Low if the values share one simple shape, Medium if there are a few shapes, High if they vary a lot.
4. Reasoning: one sentence on how well the samples represent the whole column.

{_OUTPUT_FORMAT}

Example:
Column Name: dealer_code
Column Type: object
Sample Values: ['DLR-0012', 'DLR-0450', 'DLR-1203']
Facts measured on all values:
- Every value is: the fixed text 'DLR', then '-', then 4 digits
- Length: exactly 8 characters
- Characters used: upper-case letters, digits, '-'
Regex derived from the data: r'^DLR-\\d{{4}}$'
HERE IS THE FINAL RESULT.
- Column Name: dealer_code
- Column Type: object
- Business Rules: a. The value is the fixed text 'DLR', a dash, then exactly 4 digits; b. Only upper-case letters, digits and '-' are used; c. The value is exactly 8 characters long.
- RegEx Pattern: r'^DLR-\\d{{4}}$'
- Complexity: Low
- Reasoning: All samples share one fixed structure, so the pattern represents the whole column well.
"""

# Second pass for columns whose Consistency index is below the threshold: show the model the
# regex it produced and the real values that failed it, and ask for a corrected, more general one.
REPAIR_PROMPT = f"""You are a data quality analyst. A regular expression was written for this column, but some real values do NOT match it. Write a corrected, more general regex that fully matches ALL values below, plus three validation rules.

Column Name: <COLUMN-NAME>
Column Type: <COLUMN-TYPE>
Current regex: <PREVIOUS-REGEX>
Values that do NOT match: <FAILED-VALUES>
Values that already match: <MATCHED-VALUES>

{_REGEX_GUIDE}

{_OUTPUT_FORMAT}
"""


@dataclass(frozen=True)
class ReferenceDQConfig:
    base_url: str
    timeout_seconds: int = 120
    api_key: str | None = None
    primary_model: str = "llama3.2:3b"
    secondary_model: str = "llama3.2:3b"  # second pass uses REPAIR_PROMPT (see run_data_quality_checks2)
    max_samples: int = 20  # values shown to the model per column; keeps a 3B model fast on CPU
    parser_contract_version: str = "legacy_v1"
    dq_policy: str = "guarded_legacy"
    model_override_enabled: bool = True
    repair_enabled: bool = True
    minimum_score_delta: float = 0.0
    fallback_enabled: bool = True


# Automated remarks per rule, keyed by (column name, DQ dimension); stored in dq_results.remarks
RemarkNotes = dict[tuple[str, str], list[str]]


def _note(notes: RemarkNotes | None, column: str, dimension: str, text: str) -> None:
    """Record an automated remark for one rule, once."""
    if notes is None:
        return
    entries = notes.setdefault((str(column), dimension), [])
    if text not in entries:
        entries.append(text)


def check_sample_size(total_data: int) -> int:
    if total_data < 200:
        return total_data
    elif total_data < 500:
        return math.ceil(0.5 * total_data)
    elif (total_data >= 500) or (total_data <= 5000):
        return math.ceil(0.3 * total_data)
    elif total_data > 5000:
        return math.ceil(0.1 * total_data)
    return total_data


def detect_scientific_notation_strings(df: pd.DataFrame) -> list[str]:
    return [
        column for column in df.columns
        if (df[column].dtype == "object" or df[column].dtype == "float64") and (df[column].apply(
            lambda x: bool(re.match(r"^-?\d+(\.\d+)?e[+-]\d+$", str(x)))).any())
    ]


def identify_and_convert_datetime(df: pd.DataFrame, cnt_unique: pd.DataFrame, threshold: float = 0.2) -> list[str]:
    df = df.astype(str)
    datetime_columns = []

    for col in df.columns:
        if df[col].dtype == "object":
            try:
                converted_col = pd.to_datetime(df[col], errors="coerce")
                converted_col = pd.concat([converted_col, cnt_unique], axis=1)
                total_values = converted_col.iloc[:, 1].sum()
                non_null_weighted_sum = converted_col.loc[converted_col.iloc[:, 0].notnull(), "count"].sum()
                non_null_proportion = non_null_weighted_sum / total_values
                if non_null_proportion >= (1 - threshold):
                    datetime_columns.append(col)
            except Exception as exc:
                print(f"Failed to convert column {col}: {exc}")

    return datetime_columns


def extract_from_output(raw_text: str, contract_version: str = "legacy_v1") -> dict[str, str]:
    """Backward-compatible facade for the centralized provider-independent parser."""
    return parse_dq_output(raw_text, contract_version=contract_version)


def compile_final_metrics(
    df_final: pd.DataFrame,
    df_consistency: pd.DataFrame,
    df_unique: pd.DataFrame,
    df_latency: pd.DataFrame,
) -> pd.DataFrame:
    return pd.concat([df_final, df_consistency, df_unique, df_latency], ignore_index=True)


def filter_unique_rows(df: pd.DataFrame) -> pd.DataFrame:
    df_unique = df[(df["Total Rows"] == df["Total Unique"]) & (df["Total Rows"] != 0) & (df["Total Unique"] != 0)].copy()
    df_unique["DQ Dimension"] = "Uniqueness"
    df_unique["Index"] = 100
    df_unique["Business Rules"] = df_unique["Column Name"].apply(
        lambda col: f"There should be no duplicated field for {col} in this table"
    )
    return df_unique


def calculate_update_and_merge_consistency(
    regex_df: pd.DataFrame,
    values_df: pd.DataFrame,
    cnt_unique: pd.DataFrame,
    table_name: str,
    credentials_source: str | None,
    threshold: int = 70,
    column_name_col: str = "Column Name",
    regex_pattern_col: str = "RegEx Pattern",
    new_regex_pattern: str = r"^-?\d+(\.\d+)?e[+-]\d+$",
    ingesttime_pattern: str = r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d{6})?\+\d{2}:\d{2}$",
    columns_with_sci_notation: list[str] | None = None,
    notes: RemarkNotes | None = None,
) -> pd.DataFrame:
    if credentials_source is None:
        print("no sql")
        table_name = table_name
    else:
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = credentials_source

    if columns_with_sci_notation is None:
        columns_with_sci_notation = []

    match_results = []
    for _, row in regex_df.iterrows():
        column_name = row[column_name_col]
        regex_pattern = row[regex_pattern_col]
        column_data = values_df[column_name]
        total_rows = len(column_data)

        regex_pattern = re.sub(r"^r", "", regex_pattern)
        regex_pattern = re.sub(r"^'|'$", "", regex_pattern)

        if total_rows > 500000:
            print(f"Processing '{column_name}' with SQL or optimized logic (rows: {total_rows})")
            match_count = 0
            total_count = 0
            match_percentage = 0
            _note(notes, column_name, "Consistency",
                  f"More than 500,000 distinct values ({total_rows:,}); regex check skipped, index set to 0")
        else:
            print(f"Processing '{column_name}' with Python (rows: {total_rows})")
            if column_data.dtype == "Int64" or column_data.dtype == "int64":
                try:
                    matches = column_data.apply(
                        lambda x: bool(re.match(re.compile(regex_pattern, re.DOTALL), str(int(x)))) if pd.notnull(x) else False
                    )
                    match_df = pd.concat([pd.DataFrame(matches), cnt_unique], axis=1)
                    match_df["cnt_match"] = match_df.iloc[:, 0] * match_df.iloc[:, 1]
                    match_count = match_df["cnt_match"].sum()
                except re.error:
                    match_count = 0
                    match_df = pd.concat([pd.DataFrame(False, index=column_data.index, columns=[column_name]), cnt_unique], axis=1)
                    _note(notes, column_name, "Consistency", "Generated regex is not valid; consistency index set to 0")
            else:
                try:
                    matches = column_data.apply(
                        lambda x: bool(re.match(re.compile(regex_pattern, re.DOTALL), str(x))) if pd.notnull(x) else False
                    )
                    match_df = pd.concat([pd.DataFrame(matches), cnt_unique], axis=1)
                    match_df["cnt_match"] = match_df.iloc[:, 0] * match_df.iloc[:, 1]
                    match_count = match_df["cnt_match"].sum()
                except re.error:
                    match_count = 0
                    match_df = pd.concat([pd.DataFrame(False, index=column_data.index, columns=[column_name]), cnt_unique], axis=1)
                    _note(notes, column_name, "Consistency", "Generated regex is not valid; consistency index set to 0")
            total_count = match_df.iloc[:, 1].sum()
            match_percentage = (match_count / total_count) * 100 if total_count > 0 else 0

        if column_name in columns_with_sci_notation and match_percentage < threshold:
            regex_pattern = new_regex_pattern
            regex_df[regex_pattern_col][regex_df[column_name_col] == column_name] = regex_pattern
            _note(notes, column_name, "Consistency",
                  f"Values in scientific notation matched {match_percentage:.1f}%; regex replaced with the standard scientific-notation pattern")

        if column_data.dtypes == "datetime64[us, UTC]" and match_percentage < threshold:
            regex_pattern = ingesttime_pattern
            regex_df[regex_pattern_col][regex_df[column_name_col] == column_name] = regex_pattern
            _note(notes, column_name, "Consistency",
                  f"Timestamp values matched {match_percentage:.1f}%; regex replaced with the standard ingest-time pattern")

        match_results.append({
            "Column Name": column_name,
            "RegEx Pattern": regex_pattern,
            "Total Entries (Including None as Non-Match)": total_count,
            "Matches": match_count,
            "DQ Dimension": "Consistency",
            "Index": match_percentage,
        })
        print(f"Consistency for {column_name} in {table_name} is: {match_count}, {match_percentage}%")

    df_match = pd.DataFrame(match_results)
    df_temp = regex_df.iloc[:, :-2].drop(columns=["RegEx Pattern"])
    df_consistency = pd.merge(
        df_temp,
        df_match[["Column Name", "RegEx Pattern", "DQ Dimension", "Index"]],
        on=["Column Name"],
        how="inner",
    )
    return df_consistency[
        [
            "Column Name", "Column Type", "Total Rows",
            "Total Unique", "Total Null", "Business Rules",
            "RegEx Pattern", "Complexity", "Reasoning",
            "DQ Dimension", "Index",
        ]
    ]


def calculate_percentage(days_diff: int) -> int:
    if days_diff > 0:
        return 100
    elif -1 >= days_diff >= -7:
        return 70
    elif -8 >= days_diff >= -14:
        return 50
    elif -15 >= days_diff >= -30:
        return 30
    else:
        return 0


def calculate_latency_index(
    df: pd.DataFrame, cnt_unique: pd.DataFrame, threshold: float = 0.2, notes: RemarkNotes | None = None,
) -> pd.DataFrame:
    datetime_columns = identify_and_convert_datetime(df, cnt_unique, threshold)
    print("datetime columns:", datetime_columns)
    latency_index, latency_rules = [], []
    today = datetime.now().date()

    for col in datetime_columns:
        max_date = pd.to_datetime(df[col], errors="coerce").max()
        days_diff = (today - max_date.date()).days if pd.notnull(max_date) else 0
        latency_index.append(calculate_percentage(14 - days_diff))
        latency_rules.append(f"Latest date in {col} should not be more than 14 days ago")
        if pd.notnull(max_date):
            _note(notes, col, "Latency", f"Latest date found: {max_date.date():%Y-%m-%d} ({days_diff} days before the check)")

    return pd.DataFrame({"Column Name": datetime_columns, "Business Rules": latency_rules, "DQ Dimension": "Latency", "Index": latency_index})


def _call_ollama(prompt: str, model: str, config: ReferenceDQConfig) -> str:
    headers = {"Authorization": f"Bearer {config.api_key}"} if config.api_key else None
    response = requests.post(
        ollama_endpoint(config.base_url, "generate"),
        # num_ctx: prompt + samples must not be truncated; num_predict: the answer is ~150-250 tokens
        json={"model": model, "prompt": prompt, "stream": False,
              "options": {"temperature": 0, "num_ctx": 4096, "num_predict": 400}},
        headers=headers,
        timeout=config.timeout_seconds,
    )
    response.raise_for_status()
    return response.json().get("response", "")


# ── Data-profile regex ─────────────────────────────────────────────────────────
# A small local model (llama3.2:3b) writes good rules but unreliable regex syntax, so the regex
# candidate is derived from the column's DOMINANT value shapes (>= PROFILE_COVERAGE of rows), the
# way the qwen2.5-coder answers in the HSO Splash rules index generalize values. Rare shapes are
# left out on purpose: they are exactly the inconsistent values the Consistency index must flag.
PROFILE_COVERAGE = 0.95
EMAIL_REGEX = r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"
_TOKEN = re.compile(r"[A-Z]+|[a-z]+|\d+|[^A-Za-z\d]")


def _as_text(value: Any) -> str:
    return str(int(value)) if isinstance(value, (int, np.integer)) else str(value)


def _token_kind(tok: str) -> str:
    if tok.isdigit():
        return "D"
    if tok.isalpha():
        return "U" if tok.isupper() else "L" if tok.islower() else "A"
    return tok  # separator / punctuation, kept literally


def _tokens(text: str) -> list[str]:
    # merge letter runs of mixed case (e.g. "Jawa") into one token
    raw = _TOKEN.findall(text)
    merged: list[str] = []
    for tok in raw:
        if merged and tok.isalpha() and merged[-1].isalpha():
            merged[-1] += tok
        else:
            merged.append(tok)
    return merged


def _lit(text: str) -> str:
    """Literal text for use outside a character class (spaces and dashes need no escaping there)."""
    return re.escape(text).replace("\\ ", " ").replace("\\-", "-")


def _length(lengths: list[tuple[int, float]]) -> str:
    """Quantifier for a token from the lengths of the dominant rows (rare outlier lengths are ignored)."""
    weight: dict[int, float] = {}
    for n, w in lengths:
        weight[n] = weight.get(n, 0) + w
    kept = _dominant({n: n for n in weight}, weight, sum(weight.values()))
    lo, hi = min(kept), max(kept)
    if lo == hi:
        return "" if lo == 1 else f"{{{lo}}}"
    return f"{{{lo},{hi}}}" if hi - lo <= 3 else "+"


_CLASS = {"D": r"\d", "U": "[A-Z]", "L": "[a-z]", "A": "[A-Za-z]"}
# Letter runs up to this length are codes with a fixed size (AHM JTG, plate letters); longer runs are
# names or words whose length varies in real data (KALIMANTAN, BENGKAYANG), so they get '+'.
_CODE_LETTERS = 4


def _quantifier(kind: str, toks: list[tuple[str, float]]) -> str:
    if kind != "D" and max(len(t) for t, _ in toks) > _CODE_LETTERS:
        return "+"
    return _length([(len(t), w) for t, w in toks])


def _is_word_signature(members: list[tuple[list[str], float]]) -> bool:
    """Only letters and single spaces, with at least one word longer than a code (names, not codes)."""
    toks = members[0][0]
    kinds = {_token_kind(t) for t in toks}
    return kinds <= {"U", "L", "A", " "} and bool(kinds & {"U", "L", "A"}) and any(
        len(t) > _CODE_LETTERS for m, _ in members for t in m if t.isalpha())


def _signature_regex(members: list[tuple[list[str], float]]) -> str:
    """Regex for values sharing one token signature: classes with length ranges, multi-letter constants literal."""
    parts = []
    distinct = len(members)
    for pos in range(len(members[0][0])):
        toks = [(m[pos], w) for m, w in members]
        first = toks[0][0]
        kind = _token_kind(first)
        if kind not in _CLASS:
            parts.append(_lit(first))
        elif kind != "D" and len({t for t, _ in toks}) == 1 and len(first) >= 2 and distinct >= 3:
            parts.append(_lit(first))  # constant prefix/word such as BPS
        else:
            parts.append(_CLASS[kind] + _quantifier(kind, toks))
    return "".join(parts)


def _word_class(kinds: set[str]) -> str:
    letters = kinds & {"U", "L", "A"}
    return _CLASS[next(iter(letters))] if len(letters) == 1 else _CLASS["A"]


def _dominant(groups: dict, weight: dict, total: float) -> list:
    keys = sorted(groups, key=lambda k: -weight[k])
    chosen, covered = [], 0.0
    for k in keys:
        chosen.append(k)
        covered += weight[k]
        if covered >= PROFILE_COVERAGE * total:
            break
    return chosen


def profile_regex(values: list[Any], weights: list[float], dtype: Any) -> str | None:
    """Regex describing the dominant shape of a column (see module note above)."""
    pairs = [(v, w) for v, w in zip(values, weights) if not pd.isna(v)]
    if not pairs:
        return None
    kind = str(dtype).lower()
    total = sum(w for _, w in pairs)

    if kind.startswith("float"):
        numbers = [_as_text(v) for v, _ in pairs]
        neg = "-?" if any(t.startswith("-") for t in numbers) else ""
        sci = r"(e[+\-]?\d+)?" if any("e" in t for t in numbers) else ""
        return rf"^{neg}\d+(\.\d+)?{sci}$"

    if kind.startswith("int"):
        nums = sorted({int(v) for v, _ in pairs})
        if len(nums) <= 10 and all(0 <= n <= 9 for n in nums):
            contiguous = nums == list(range(nums[0], nums[-1] + 1))
            return f"^[{nums[0]}-{nums[-1]}]$" if contiguous and len(nums) > 2 else "^[" + "".join(map(str, nums)) + "]$"
        if len(nums) <= 5 and all(abs(n) < 100 for n in nums):  # small codes only, never amounts
            return "^(" + "|".join(str(n) for n in nums) + ")$"
        return r"^-?\d+$" if nums[0] < 0 else r"^\d+$"

    texts: list[tuple[str, float]] = [(_as_text(v), w) for v, w in pairs]
    if sum(w for t, w in texts if "@" in t and "." in t.split("@")[-1]) >= 0.9 * total:
        return EMAIL_REGEX

    sig_groups: dict[tuple, list] = {}
    sig_weight: dict[tuple, float] = {}
    for text, w in texts:
        toks = _tokens(text)
        sig = tuple(_token_kind(t) for t in toks)
        sig_groups.setdefault(sig, []).append((toks, w))
        sig_weight[sig] = sig_weight.get(sig, 0) + w

    dominant = _dominant(sig_groups, sig_weight, total)
    # the rows that define the pattern; everything else is treated as potentially inconsistent
    texts = [("".join(toks), w) for sig in dominant for toks, w in sig_groups[sig]]

    # 1. one shape covers the column: BPS_001, AHM JTG, 0812-1234-567, H 1234 AB, timestamps;
    #    names (letters and spaces, words longer than codes) become a word list: KALIMANTAN TIMUR
    if len(dominant) == 1:
        members = sig_groups[dominant[0]]
        if _is_word_signature(members):
            word = _word_class({_token_kind(t) for t in members[0][0]})
            return f"^{word}+( {word}+)*$"
        return "^" + _signature_regex(members) + "$"

    word_kinds = {k for sig in dominant for k in sig if k in _CLASS}
    separators = {k for sig in dominant for k in sig if k not in _CLASS}
    letter_kinds = word_kinds - {"D"}
    word = _word_class(letter_kinds)
    distinct = sorted({t for t, _ in texts})

    # 2. a short list of one-word categories with different shapes, each repeated: AVG, MAX, SUM, Other, -
    #    (names with spaces such as KAB. BLORA keep a shape: the full list is rarely seen in one table)
    if len(distinct) <= 6 and not any(ch.isdigit() or ch == " " for t in distinct for ch in t) and \
            sum(w for _, w in texts) >= 2 * len(distinct) and all(0 < len(t) <= 20 for t in distinct):
        return "^(" + "|".join(_lit(t) for t in distinct) + ")$"

    # 3. words separated by single spaces: JAWA TENGAH, DI YOGYAKARTA, BENGKULU
    if letter_kinds and "D" not in word_kinds and separators <= {" "}:
        return f"^{word}+( {word}+)*$"

    # 4. a few fixed first words followed by words: KAB. BANYUMAS, KOTA SEMARANG
    firsts = {t.split(" ", 1)[0] for t, _ in texts if " " in t}
    if all(" " in t for t, _ in texts) and len(firsts) <= 5 and len(distinct) >= 2 * len(firsts):
        rest_kinds = {_token_kind(tok) for t, _ in texts for tok in _tokens(t.split(" ", 1)[1])}
        if rest_kinds <= {"U", "L", "A", " "}:
            rest_word = _word_class(rest_kinds)
            heads = sorted(firsts)
            head = _lit(heads[0]) if len(heads) == 1 else "(" + "|".join(_lit(f) for f in heads) + ")"
            return f"^{head} {rest_word}+( {rest_word}+)*$"

    # 5. two shapes (each with several values): alternation
    if len(dominant) == 2 and all(len(sig_groups[s]) >= 2 for s in dominant):
        alts = [_signature_regex(sig_groups[s]) for s in dominant]
        return "^(" + "|".join(alts) + ")$"

    # 6. free text: the characters used by the dominant shapes, each range once (A-Za-z covers A-Z, a-z)
    kinds: set[str] = set()
    punct: set[str] = set()
    for sig in dominant:
        for toks, _ in sig_groups[sig]:
            for tok in toks:
                k = _token_kind(tok)
                (kinds if k in _CLASS else punct).add(k)
    if "A" in kinds or {"U", "L"} <= kinds:
        kinds = (kinds - {"U", "L"}) | {"A"}
    ranges = {"A": "A-Za-z", "U": "A-Z", "L": "a-z", "D": r"\d"}
    body = "".join(ranges[k] for k in ("A", "U", "L", "D") if k in kinds)
    body += "".join(" " if p == " " else re.escape(p) for p in sorted(punct))
    return f"^[{body}]+$"


# ── Data facts for the prompt ──────────────────────────────────────────────────
# A 3B model misreads regex syntax when asked to explain it (e.g. ^[135]$ as "three digits"), so the
# business rules are written from plain-language facts measured on the same dominant rows.
_KIND_WORDS = {"D": ("digit", "digits"), "U": ("upper-case letter", "upper-case letters"),
               "L": ("lower-case letter", "lower-case letters"), "A": ("letter", "letters")}
_CHAR_WORDS = {"digit": "digits", "upper": "upper-case letters", "lower": "lower-case letters",
               "space": "spaces", "neg": "a leading minus sign"}


def _quantity(quantifier: str, kind: str) -> str:
    one, many = _KIND_WORDS[kind]
    if quantifier == "":
        return f"1 {one}"
    if quantifier == "+":
        return f"one or more {many}"
    lo, _, hi = quantifier.strip("{}").partition(",")
    return f"{lo} {many}" if not hi else f"{lo} to {hi} {many}"


def _describe_signature(members: list[tuple[list[str], float]]) -> str:
    """Plain-language version of _signature_regex (same tokens, same length rules)."""
    parts = []
    distinct = len(members)
    for pos in range(len(members[0][0])):
        toks = [(m[pos], w) for m, w in members]
        first = toks[0][0]
        kind = _token_kind(first)
        if kind not in _CLASS:
            parts.append("a space" if first == " " else f"'{first}'")
        elif kind != "D" and len({t for t, _ in toks}) == 1 and len(first) >= 2 and distinct >= 3:
            parts.append(f"the fixed text '{first}'")
        else:
            parts.append(_quantity(_quantifier(kind, toks), kind))
    return ", then ".join(parts)


def data_facts(values: list[Any], weights: list[float], dtype: Any) -> str:
    """Facts about the column's dominant values, one '- ' line each, for the business-rules prompt."""
    pairs = [(v, w) for v, w in zip(values, weights) if not pd.isna(v)]
    if not pairs:
        return "- The column has no values"
    kind = str(dtype).lower()
    total = sum(w for _, w in pairs)
    numeric = kind.startswith(("float", "int"))
    distinct = sorted({v for v, _ in pairs}) if numeric else sorted({_as_text(v) for v, _ in pairs}, key=lambda t: (len(t), t))
    facts = []
    if len(distinct) <= 10:
        facts.append(f"Only these {len(distinct)} distinct values occur: " + ", ".join(_as_text(v) for v in distinct))

    if numeric:
        nums = [float(v) for v, _ in pairs]
        facts.append(f"Numbers from {_as_text(min(nums)) if kind.startswith('float') else int(min(nums))} "
                     f"to {_as_text(max(nums)) if kind.startswith('float') else int(max(nums))}")
        negative = min(nums) < 0
        facts.append("Some values are negative" if negative else "No value is negative")
        chars = ["digits"]
        if kind.startswith("float"):
            decimals = [len(_as_text(v).split(".")[1]) if "." in _as_text(v) else 0 for v, _ in pairs]
            lo, hi = min(decimals), max(decimals)
            facts.append("Values have no decimal part" if not hi
                         else f"Values have exactly {hi} decimal places" if lo == hi
                         else f"Values have {lo} to {hi} decimal places")
            if hi:
                chars.append("a decimal point '.'")
        else:
            facts.append("Values are whole numbers")
        chars.append("a leading minus sign '-' for negative values" if negative else "no minus sign")
        facts.append("Characters used: " + ", ".join(chars))
        return "\n".join(f"- {f}" for f in facts)

    sig_groups: dict[tuple, list] = {}
    sig_weight: dict[tuple, float] = {}
    for v, w in pairs:
        toks = _tokens(_as_text(v))
        sig = tuple(_token_kind(t) for t in toks)
        sig_groups.setdefault(sig, []).append((toks, w))
        sig_weight[sig] = sig_weight.get(sig, 0) + w
    dominant = _dominant(sig_groups, sig_weight, total)
    rows = [("".join(toks), w) for sig in dominant for toks, w in sig_groups[sig]]

    if sum(w for t, w in rows if "@" in t and "." in t.split("@")[-1]) >= 0.9 * total:
        facts.append("Every value is an e-mail address: a name part, then '@', then a domain containing a dot")
    elif len(dominant) == 1 and not _is_word_signature(sig_groups[dominant[0]]):
        facts.append("Every value is: " + _describe_signature(sig_groups[dominant[0]]))
    else:
        firsts = sorted({t.split(" ", 1)[0] for t, _ in rows if " " in t})
        if all(" " in t for t, _ in rows) and len(firsts) <= 5:
            facts.append("The first word is one of: " + ", ".join(f"'{f}'" for f in firsts))
        words = [len(t.split(" ")) for t, _ in rows]
        if min(words) != max(words):
            facts.append(f"Values have {min(words)} to {max(words)} words separated by single spaces")
        elif words[0] > 1:
            facts.append(f"Every value has {words[0]} words separated by single spaces")
    lengths = [len(t) for t, _ in rows]
    facts.append(f"Length: exactly {lengths[0]} characters" if min(lengths) == max(lengths)
                 else f"Length: {min(lengths)} to {max(lengths)} characters")
    classes = set().union(*(_char_classes(t) for t, _ in rows))
    letters = ["".join(ch for ch in t if ch.isalpha()) for t, _ in rows]
    if {"upper", "lower"} <= classes and all(s and s[0].isupper() and s[1:].islower() for s in letters):
        facts.append("Each value starts with one upper-case letter; all other letters are lower-case")
    elif "upper" in classes and "lower" not in classes:
        facts.append("All letters are upper-case")
    names = [_CHAR_WORDS[c] for c in ("upper", "lower", "digit", "space", "neg") if c in classes]
    names += [f"'{c}'" for c in sorted(classes - set(_CHAR_WORDS))]
    facts.append("Characters used: " + ", ".join(names))
    return "\n".join(f"- {f}" for f in facts)


def _char_classes(text: str) -> set[str]:
    """Kinds of characters in a value (digit, upper, lower, space, each punctuation mark, leading minus)."""
    classes = {"neg"} if text.startswith("-") else set()
    for ch in text:
        classes.add("digit" if ch.isdigit() else "upper" if ch.isupper() else "lower" if ch.islower()
                    else "space" if ch.isspace() else ch)
    return classes


def _select_samples(values: Any, k: int) -> list[Any]:
    """Pick up to k distinct values: the shortest and longest, every kind of character at least once, then random."""
    vals = list(values)
    if len(vals) > k:
        rng = np.random.default_rng(42)
        text = [str(v) for v in vals]
        by_len = sorted(range(len(vals)), key=lambda i: len(text[i]))
        chosen = [by_len[0], by_len[-1]] if by_len[0] != by_len[-1] else [by_len[0]]
        seen = set().union(*(_char_classes(text[i]) for i in chosen))
        for i in rng.permutation(len(vals)):
            if len(chosen) >= k:
                break
            classes = _char_classes(text[i])
            if not classes <= seen:
                chosen.append(int(i))
                seen |= classes
        for i in rng.permutation(len(vals)):
            if len(chosen) >= k:
                break
            if int(i) not in chosen:
                chosen.append(int(i))
        vals = [vals[i] for i in chosen]
    try:
        return sorted(vals)
    except TypeError:
        return sorted(vals, key=str)


def _format_values(values: list[Any], dtype: Any) -> str:
    """Sample values as a Python list: numbers unquoted, everything else as the strings that get scored."""
    kind = str(dtype).lower()
    if kind.startswith("float"):
        return str([float(v) for v in values])
    if kind.startswith("int"):
        return str([int(v) for v in values])
    return str([str(v) for v in values])


def _clean_regex(regex_pattern: str) -> str:
    cleaned = re.sub(r"^'|'$", "", re.sub(r"^r", "", str(regex_pattern).strip()))
    # small models sometimes repeat the anchors when echoing the given regex (^^...$$)
    return re.sub(r"(?<!\\)\$\$+$", "$", re.sub(r"^\^\^+", "^", cleaned))


def _split_by_regex(values: Any, regex_pattern: str, limit_failed: int = 15, limit_matched: int = 10) -> tuple[str, list[str], list[str]]:
    """(cleaned regex, values that do not fully match, values that match) for the repair prompt."""
    regex_clean = _clean_regex(regex_pattern)
    try:
        compiled = re.compile(regex_clean)
    except re.error:
        compiled = None
    failed: list[str] = []
    matched: list[str] = []
    for v in values:
        text = str(int(v)) if isinstance(v, (int, np.integer)) else str(v)
        (matched if compiled is not None and compiled.match(text) else failed).append(text)
    return regex_clean, failed[:limit_failed], matched[:limit_matched]


def _weighted_index(regex: str | None, values: Any, weights: Any) -> float:
    """Share of rows (weighted by value counts) whose value fully matches the regex, as in the index."""
    try:
        compiled = re.compile(regex) if regex else None
    except re.error:
        compiled = None
    total = matched = 0.0
    for v, w in zip(values, weights):
        total += w
        if compiled is not None and not pd.isna(v) and compiled.fullmatch(_as_text(v)):
            matched += w
    return 100.0 * matched / total if total else 0.0


def process_columns(
    df: pd.DataFrame, df_completeness: pd.DataFrame, init_prompt: str, config: ReferenceDQConfig,
    model: str | None = None, notes: RemarkNotes | None = None,
    repair: dict[str, tuple[str, list[str], list[str]]] | None = None,
    counts: pd.DataFrame | None = None,
) -> tuple[list[str], pd.DataFrame]:
    """Ask the model for rules + regex per column; with `repair`, use REPAIR_PROMPT for those columns.

    `df` holds the column's distinct values and `counts` their row counts (same order). The first
    pass gives the model the data-profile regex and keeps whichever regex scores better on the rows.
    """
    col_name, col_type, total_row, total_unique, total_null = [], [], [], [], []
    business_rules, completeness_rules, regex_rules, complexity_rules, reason_rule = [], [], [], [], []
    start_time = time.time()
    column_count = len(df.columns)

    for idx, column in enumerate(df.columns, start=1):
        col_name.append(column)
        col_type.append(str(df[column].dtypes))

        values = df[column].tolist()
        weights = counts.iloc[:, 0].tolist() if counts is not None else [1] * len(values)
        profile = None
        if repair and column in repair:
            previous_regex, failed_values, matched_values = repair[column]
            prompt = (
                REPAIR_PROMPT.replace("<COLUMN-NAME>", column)
                .replace("<COLUMN-TYPE>", str(df[column].dtypes))
                .replace("<PREVIOUS-REGEX>", f"r'{previous_regex}'")
                .replace("<FAILED-VALUES>", str(failed_values))
                .replace("<MATCHED-VALUES>", str(matched_values))
            )
        else:
            profile = profile_regex(values, weights, df[column].dtype)
            prompt = init_prompt.replace("<COLUMN-NAME>", column)
            prompt = prompt.replace("<COLUMN-TYPE>", str(df[column].dtypes))
            prompt = prompt.replace("<PROFILE-REGEX>", profile or "^.*$")
            prompt = prompt.replace("<DATA-FACTS>", data_facts(values, weights, df[column].dtype))
            unique_values = df[column].dropna().unique()
            size_data = min(check_sample_size(len(unique_values)), config.max_samples)
            sample_values = _select_samples(unique_values, size_data)
            prompt = prompt.replace("<COLUMN-DATA>", _format_values(sample_values, df[column].dtype))

        selected_model = model or config.primary_model
        try:
            raw_text = _call_ollama(prompt, selected_model, config)
            extracted_data = extract_from_output(raw_text, contract_version=config.parser_contract_version)
        except Exception as exc:
            if not config.fallback_enabled:
                raise
            extracted_data = {
                "business_rules": NO_MATCH,
                "regex_pattern": NO_MATCH,
                "complexity": NO_MATCH,
                "reasoning": NO_MATCH,
                "parser_warnings": ["ai_request_failed"],
            }
            _note(notes, column, "Consistency", f"AI request failed ({exc}); data-profile regex used")
        if extracted_data["regex_pattern"] == NO_MATCH and not profile:
            _note(notes, column, "Consistency", f"{selected_model} output contained no RegEx pattern")
        if extracted_data["business_rules"] == NO_MATCH:
            _note(notes, column, "Consistency", f"{selected_model} output contained no business rules")

        regex_out = extracted_data["regex_pattern"]
        if profile:
            model_regex = None if regex_out == NO_MATCH else _clean_regex(regex_out)
            profile_idx = _weighted_index(profile, values, weights)
            if model_regex and model_regex != profile:
                model_idx = _weighted_index(model_regex, values, weights)
                allow_override = (
                    config.model_override_enabled
                    and config.dq_policy != "profile_canonical"
                    and model_idx >= profile_idx + config.minimum_score_delta
                )
                if allow_override and model_idx > profile_idx:
                    _note(notes, column, "Consistency",
                          f"Regex corrected by {selected_model} ({model_idx:.1f}% vs data-profile regex {profile_idx:.1f}%)")
                else:
                    regex_out = f"r'{profile}'"
                    _note(notes, column, "Consistency",
                          f"{selected_model} suggested {model_regex} ({model_idx:.1f}%); data-profile regex kept ({profile_idx:.1f}%)")
            else:
                regex_out = f"r'{profile}'"

        business_rules.append(extracted_data["business_rules"])
        completeness_rules.append(f"There should be no empty field for {column} in this table")
        regex_rules.append(regex_out)
        complexity_rules.append(extracted_data["complexity"])
        reason_rule.append(extracted_data["reasoning"])

        total_row.append(df_completeness["total_rows"].values[0])
        total_unique.append(df_completeness["total_unique_values"].values[0])
        total_null.append(df_completeness["total_null_values"].values[0])
        index = df_completeness["completeness_pct"].values[0]

        elapsed_time = time.time() - start_time
        avg_time_per_column = elapsed_time / idx
        remaining_columns = column_count - idx
        eta = avg_time_per_column * remaining_columns
        print(f"Processed column {idx}/{column_count}. ETA: {time.strftime('%H:%M:%S', time.gmtime(eta))}")

    print(f"Total All Columns Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - start_time))}")
    data = {
        "Column Name": col_name,
        "Column Type": col_type,
        "Total Rows": total_row,
        "Total Unique": total_unique,
        "Total Null": total_null,
        "Business Rules": business_rules,
        "RegEx Pattern": regex_rules,
        "Complexity": complexity_rules,
        "Reasoning": reason_rule,
        "DQ Dimension": "Completeness",
        "Index": index,
    }
    return completeness_rules, pd.DataFrame(data)


def load_column_profile_from_dataframe(df_raw: pd.DataFrame, column_name: str) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    if column_name not in df_raw.columns:
        raise ValueError(f"Column '{column_name}' not found.")

    df_column_counts = df_raw[column_name].value_counts(dropna=False).reset_index()
    df_column_counts.columns = [column_name, "count"]

    total_rows = len(df_raw)
    total_unique_values = df_raw[column_name].nunique(dropna=True)
    total_null_values = df_raw[column_name].isnull().sum()
    completeness_pct = 100.0 * df_raw[column_name].notnull().sum() / total_rows if total_rows > 0 else 0
    df_completeness = pd.DataFrame({
        "total_rows": [total_rows],
        "total_unique_values": [total_unique_values],
        "total_null_values": [total_null_values],
        "completeness_pct": [completeness_pct],
    })
    return df_column_counts.iloc[:, [0]], df_completeness, df_column_counts.iloc[:, [1]]


def run_data_quality_checks2(
    df: pd.DataFrame,
    df_completeness: pd.DataFrame,
    cnt_unique: pd.DataFrame,
    table_name: str,
    column_name: str,
    project_name: str,
    config: ReferenceDQConfig,
) -> pd.DataFrame:
    start_time = time.time()
    print("run_data_quality_checks2, latest_versions", 0)
    notes: RemarkNotes = {}

    completeness_rules, df_final = process_columns(df, df_completeness, INIT_PROMPT, config, model=config.primary_model, notes=notes, counts=cnt_unique)
    columns_with_sci_notation = detect_scientific_notation_strings(df)
    print("columns_with_sci_notation", columns_with_sci_notation)
    print(f"Completeness Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - start_time))}")

    threshold = 70
    try:
        dim_time = time.time()
        df_consistency = calculate_update_and_merge_consistency(df_final, df, cnt_unique, table_name, credentials_source=None, columns_with_sci_notation=columns_with_sci_notation, notes=notes)
        df_consistency = calculate_update_and_merge_consistency(df_consistency, df, cnt_unique, table_name, credentials_source=None, columns_with_sci_notation=columns_with_sci_notation, notes=notes)
        print(f"consistency calculated with {config.primary_model}")
    except Exception as exc:
        print(f"Error Calculating Consistency Index: {exc}")
        df_consistency = pd.DataFrame()
        dim_time = time.time()
        _note(notes, column_name, "Completeness", f"Consistency could not be calculated ({exc}); no consistency rule created")

    columns_not_meeting_threshold: list[str] = []
    try:
        columns_below_threshold = df_consistency[df_consistency["Index"] < threshold]
        columns_not_meeting_threshold = columns_below_threshold["Column Name"].tolist()
        if columns_not_meeting_threshold and config.repair_enabled and config.dq_policy != "profile_canonical":
            print("Columns_not_meeting_threshold", columns_not_meeting_threshold)
            print("Start reprocessing columns which do not meet the threshold")
            # Repair pass: give the model its regex and the values that failed it
            repair = {
                column: _split_by_regex(
                    df[column].dropna().unique(),
                    df_consistency.loc[df_consistency["Column Name"] == column, "RegEx Pattern"].values[0],
                )
                for column in columns_not_meeting_threshold
            }
            repair_notes: RemarkNotes = {}
            completeness_rules2, df_final2 = process_columns(df[columns_not_meeting_threshold], df_completeness, INIT_PROMPT, config, model=config.secondary_model, notes=repair_notes, repair=repair, counts=cnt_unique)
            df_consistency2 = calculate_update_and_merge_consistency(df_final2, df, cnt_unique, table_name, credentials_source=None, columns_with_sci_notation=columns_with_sci_notation, notes=repair_notes)
            df_consistency2 = calculate_update_and_merge_consistency(df_consistency2, df, cnt_unique, table_name, credentials_source=None, columns_with_sci_notation=columns_with_sci_notation, notes=repair_notes)
            for column in columns_not_meeting_threshold:
                row_final = df_consistency[df_consistency["Column Name"] == column].index
                row_final2 = df_consistency2[df_consistency2["Column Name"] == column]
                if not row_final2.empty and not row_final.empty:
                    index_final = df_consistency.loc[row_final, "Index"].values[0]
                    index_final2 = row_final2["Index"].values[0]
                    outcome = (
                        f"repaired regex scored {index_final2:.1f}% and replaced it"
                        if index_final2 > index_final
                        else f"first regex kept, repaired regex scored {index_final2:.1f}%"
                    )
                    _note(notes, column, "Consistency",
                          f"First regex scored {index_final:.1f}% (below {threshold}%); repair pass with "
                          f"{config.secondary_model} using the non-matching values: {outcome}")
                    if index_final2 > index_final:
                        # the repaired rule is used, so its own generation notes apply too
                        for text in repair_notes.get((str(column), "Consistency"), []):
                            _note(notes, column, "Consistency", f"Repair pass: {text}")
                        df_consistency.loc[row_final, df_consistency.columns] = row_final2[df_consistency.columns].values[0]
                        print(f"{column}: repaired regex used ({config.secondary_model})")
                        df_final.loc[df_final["Column Name"] == column, "Business Rules"] = row_final2["Business Rules"].values[0]
                        df_final.loc[df_final["Column Name"] == column, "RegEx Pattern"] = row_final2["RegEx Pattern"].values[0]
                        df_final.loc[df_final["Column Name"] == column, "Complexity"] = row_final2["Complexity"].values[0]
                        df_final.loc[df_final["Column Name"] == column, "Reasoning"] = row_final2["Reasoning"].values[0]
    except Exception as exc:
        print(f"Error Recaculating Columns Below Threshold: {exc}")
        for column in columns_not_meeting_threshold:
            _note(notes, column, "Consistency",
                  f"Index below {threshold}%; repair pass with {config.secondary_model} failed ({exc}), first result kept")

    print(f"Consistency Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - dim_time))}")
    dim_time = time.time()
    df_unique = filter_unique_rows(df_final)
    print(f"Uniqueness Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - dim_time))}")

    dim_time = time.time()
    df_latency = calculate_latency_index(df, cnt_unique, notes=notes)
    df_temp = df_final.iloc[:, :-2].drop(columns=["Business Rules"])
    df_latency = pd.merge(df_temp, df_latency, on="Column Name", how="inner")
    del df_temp
    print(f"Latency Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - dim_time))}")

    df_final["Business Rules"] = completeness_rules
    merged_df = compile_final_metrics(df_final, df_consistency, df_unique, df_latency)
    merged_df = merged_df.sort_values(by=["Column Name", "DQ Dimension"]).reset_index(drop=True)
    final_df = merged_df.copy()
    final_df["Regex Version"] = "New Version"
    final_df["Remarks"] = [
        "; ".join(notes.get((str(col), dim), [])) or "-"
        for col, dim in zip(final_df["Column Name"], final_df["DQ Dimension"])
    ]
    print(f"Total Program Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - start_time))}")
    return final_df


def run_reference_dq_for_dataframe(
    df_raw: pd.DataFrame, table_name: str, project_name: str, config: ReferenceDQConfig,
    on_column_done: Callable[[int, int], None] | None = None,
) -> pd.DataFrame:
    """Run the reference checks column by column; `on_column_done(done, total)` reports progress."""
    df_combined = pd.DataFrame()
    columns = df_raw.columns.tolist()
    for done, column_name in enumerate(columns, start=1):
        print("column", column_name)
        df, df_completeness, cnt_unique = load_column_profile_from_dataframe(df_raw, column_name)
        dq_check = run_data_quality_checks2(df, df_completeness, cnt_unique, table_name, column_name, project_name, config)
        df_combined = pd.concat([df_combined, dq_check], ignore_index=True)
        if on_column_done:
            on_column_done(done, len(columns))
    return df_combined


# Values that mean "no value": blank/whitespace and common placeholder texts (compared case-insensitively)
EMPTY_TOKENS = {"", "null", "none", "nan", "nat", "n/a", "na", "#n/a", "-", "--", "(blank)", "undefined"}


def is_empty_value(value: Any) -> bool:
    """True for null/NaN/NaT, blank or whitespace-only text, and placeholder texts such as 'NULL' or 'N/A'."""
    if value is None:
        return True
    try:
        if pd.isna(value):
            return True
    except (TypeError, ValueError):
        pass
    return isinstance(value, str) and value.strip().lower() in EMPTY_TOKENS


def empty_attributes(columns_data: dict[str, list[Any]]) -> list[str]:
    """Attributes (columns) in which every value is empty (see is_empty_value)."""
    return [str(col) for col, values in columns_data.items() if all(is_empty_value(v) for v in values)]


NO_DATA = "no_data"  # check status for an attribute that has no values at all (not a failed check)


def mark_blank_attributes(check_results: list[dict[str, Any]], blank_columns: list[str]) -> None:
    """Checks on attributes with no values get status 'no_data' instead of pass/warning/fail.

    Their scores (0%) stay in the Overall Score, as in the template, but they are counted apart from
    Failed; the per-check findings are replaced by one finding per attribute (on its Completeness rule).
    """
    blank = set(blank_columns)
    for r in check_results:
        if r["column_name"] not in blank:
            continue
        r["status"] = NO_DATA
        r["findings"] = []
        if r["check_type"] == "completeness":
            note = (f"All {r['row_count']} values are empty (blank, null, spaces or placeholder text "
                    f"such as 'NULL' or 'N/A')")
            r["remarks"] = note if (r.get("remarks") or "-") == "-" else f"{r['remarks']}; {note}"
            r["findings"] = [{
                "severity": "warning",
                "description": f"Attribute '{r['column_name']}' has no values: all {r['row_count']} rows are empty.",
                "recommendation": "Check the source extraction for this attribute, or remove it if it is not used.",
            }]


def status_from_index(index: float) -> str:
    return "pass" if index >= 95 else "warning" if index >= 70 else "fail"


def _text_or_none(value: Any) -> str | None:
    """Row value as text; None for missing/NaN (e.g. columns absent from one dimension's frame)."""
    if value is None or (isinstance(value, float) and math.isnan(value)):
        return None
    text = str(value).strip()
    return text or None


def result_rows_from_reference(df_result: pd.DataFrame) -> tuple[list[dict[str, Any]], float]:
    rows: list[dict[str, Any]] = []
    scores: list[float] = []
    for _, row in df_result.iterrows():
        index = float(row.get("Index") or 0)
        scores.append(index)
        dimension = str(row.get("DQ Dimension") or "").lower()
        total_rows = int(row.get("Total Rows") or 0)
        total_null = int(row.get("Total Null") or 0)
        if dimension == "completeness":
            failed_count = total_null
        elif dimension == "consistency":
            # rows not matching the regex (empty values count as non-matching, as in the template)
            failed_count = round(total_rows * (100 - index) / 100)
        else:
            failed_count = 0 if index >= 70 else 1
        rows.append({
            "check_name": f"{row.get('Column Name')}__{dimension}",
            "check_type": dimension,
            "column_name": row.get("Column Name"),
            "data_type": _text_or_none(row.get("Column Type")),
            "remarks": _text_or_none(row.get("Remarks")) or "-",
            "score": round(index, 2),
            "row_count": total_rows,
            "failed_count": failed_count,
            "status": status_from_index(index),
            "business_rules": row.get("Business Rules"),
            "regex_pattern": _clean_regex(row.get("RegEx Pattern") or "") or None,
            "regex_version": row.get("Regex Version"),
            "details": {
                "reference_method": "Existing Data Quality",
                "index": round(index, 2),
                "complexity": row.get("Complexity"),
                "reasoning": row.get("Reasoning"),
                "total_unique": int(row.get("Total Unique") or 0),
                "total_null": total_null,
            },
            "findings": [] if index >= 70 else [{
                "severity": "critical" if index < 50 else "warning",
                "description": f"{row.get('Column Name')} {row.get('DQ Dimension')} index is {index:.1f}%.",
                "recommendation": row.get("Business Rules") or "Review and remediate this data quality rule.",
            }],
        })
    overall = round(sum(scores) / len(scores), 2) if scores else 0.0
    return rows, overall
