"""Provider-independent parsing for AI-generated DQ output.

The model can vary its labels and markdown wrappers, but the application consumes
one canonical shape. Contract versions are source-controlled and selected through
AI Setup so parser changes remain auditable and reversible.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any

NO_MATCH = "No match found."


@dataclass(frozen=True)
class OutputContract:
    version: str
    final_markers: tuple[str, ...]
    field_aliases: dict[str, tuple[str, ...]]
    complexity_values: tuple[str, ...] = ("High", "Medium", "Low")


CONTRACTS: dict[str, OutputContract] = {
    "legacy_v1": OutputContract(
        version="legacy_v1",
        final_markers=("HERE IS THE FINAL RESULT",),
        field_aliases={
            "business_rules": ("Business Rules", "Validation Rules", "Rules"),
            "regex_pattern": ("RegEx Pattern", "Regex Pattern", "Regular Expression"),
            "complexity": ("Complexity", "Complexity Level"),
            "reasoning": ("Reasoning", "Rationale", "Explanation"),
        },
    ),
}


def get_output_contract(version: str = "legacy_v1") -> OutputContract:
    try:
        return CONTRACTS[version]
    except KeyError as exc:
        raise ValueError(f"Unknown AI output contract: {version}") from exc


def _strip_markdown(text: str) -> str:
    text = re.sub(r"```(?:text|markdown)?\s*", "", text, flags=re.IGNORECASE)
    text = text.replace("```", "")
    text = text.replace("**", "")
    return text.strip()


def _remove_final_marker(text: str, contract: OutputContract) -> str:
    marker_pattern = "|".join(re.escape(marker) for marker in contract.final_markers)
    return re.sub(rf".*?(?:{marker_pattern})\.?\s*", "", text, count=1, flags=re.IGNORECASE | re.DOTALL)


def _label_pattern(labels: tuple[str, ...]) -> str:
    return "|".join(re.escape(label) for label in sorted(labels, key=len, reverse=True))


def _find_field(text: str, aliases: tuple[str, ...], all_aliases: tuple[str, ...]) -> str | None:
    labels = _label_pattern(aliases)
    next_labels = _label_pattern(all_aliases)
    pattern = rf"(?:^|\n)\s*[-*]?\s*(?:{labels})\s*:\s*(.*?)(?=\n\s*[-*]?\s*(?:{next_labels})\s*:|\Z)"
    match = re.search(pattern, text, flags=re.IGNORECASE | re.DOTALL)
    if not match:
        # Accept inline fields if a model omitted line breaks.
        pattern = rf"(?:{labels})\s*:\s*(.*?)(?=\s+(?:{next_labels})\s*:|\Z)"
        match = re.search(pattern, text, flags=re.IGNORECASE | re.DOTALL)
    return match.group(1).strip() if match else None


def _extract_regex(value: str | None) -> str:
    if not value:
        return NO_MATCH
    cleaned = value.strip().strip("` ")
    # Prefer an explicitly quoted Python raw string, then backticks/quotes, then
    # an unwrapped anchored expression.
    match = re.search(r"r\s*(['\"])(\^.*?\$)\1", cleaned, flags=re.DOTALL)
    if not match:
        match = re.search(r"(['\"`])(\^.*?\$)\1", cleaned, flags=re.DOTALL)
    if not match:
        match = re.search(r"(\^.*?\$)", cleaned, flags=re.DOTALL)
    if not match:
        return NO_MATCH
    pattern = match.group(2) if match.lastindex and match.lastindex >= 2 else match.group(1)
    return f"r'{pattern.strip()}'"


def _extract_complexity(value: str | None, contract: OutputContract) -> str:
    if not value:
        return NO_MATCH
    for candidate in contract.complexity_values:
        if re.search(rf"\b{re.escape(candidate)}\b", value, flags=re.IGNORECASE):
            return candidate
    return NO_MATCH


def parse_dq_output(raw_text: str, contract_version: str = "legacy_v1") -> dict[str, Any]:
    contract = get_output_contract(contract_version)
    text = _remove_final_marker(_strip_markdown(str(raw_text or "")), contract)
    aliases = tuple(alias for names in contract.field_aliases.values() for alias in names)

    business_rules = _find_field(text, contract.field_aliases["business_rules"], aliases)
    regex_raw = _find_field(text, contract.field_aliases["regex_pattern"], aliases)
    complexity_raw = _find_field(text, contract.field_aliases["complexity"], aliases)
    reasoning = _find_field(text, contract.field_aliases["reasoning"], aliases)

    regex_pattern = _extract_regex(regex_raw)
    warnings: list[str] = []
    if business_rules is None:
        warnings.append("business_rules_missing")
    if regex_pattern == NO_MATCH:
        warnings.append("regex_pattern_missing_or_invalid")
    if complexity_raw is None:
        warnings.append("complexity_missing")
    if reasoning is None:
        warnings.append("reasoning_missing")

    return {
        "business_rules": business_rules if business_rules is not None else NO_MATCH,
        "regex_pattern": regex_pattern,
        "complexity": _extract_complexity(complexity_raw, contract),
        "reasoning": reasoning if reasoning is not None else NO_MATCH,
        "parser_warnings": warnings,
        "parser_contract_version": contract.version,
    }


def normalize_regex_pattern(value: str | None) -> str:
    """Return the regex body while preserving escaped anchors and backslashes."""
    parsed = _extract_regex(value)
    if parsed == NO_MATCH:
        return ""
    return parsed[2:-1]
