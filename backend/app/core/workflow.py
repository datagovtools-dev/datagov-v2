"""
Shared workflow state machine for all governance records.
Transitions: draft -> submitted -> under_review -> approved | rejected -> archived | executed
"""
from __future__ import annotations

from typing import Literal

RecordStatus = Literal[
    "draft", "submitted", "under_review", "approved",
    "rejected", "executed", "archived",
]

# Allowed forward transitions per module
_TRANSITIONS: dict[str, dict[str, list[str]]] = {
    "dsr": {
        "draft":        ["submitted"],
        "submitted":    ["under_review", "rejected"],
        "under_review": ["approved", "rejected"],
        "approved":     ["executed", "archived"],
        "executed":     ["archived"],
        "rejected":     ["archived"],
    },
    "dpia": {
        "draft":        ["submitted"],
        "submitted":    ["under_review", "rejected"],
        "under_review": ["approved", "rejected"],
        "approved":     ["archived"],
        "rejected":     ["archived"],
    },
    "ropa": {
        "draft":        ["submitted"],
        "submitted":    ["under_review", "rejected"],
        "under_review": ["approved", "rejected"],
        "approved":     ["archived"],
        "rejected":     ["draft"],
    },
    "bapd": {
        "draft":        ["submitted"],
        "submitted":    ["under_review", "rejected"],
        "under_review": ["approved", "rejected"],
        "approved":     ["executed"],
        "executed":     ["archived"],
        "rejected":     ["archived"],
    },
}


class WorkflowError(ValueError):
    pass


def validate_transition(module: str, current: str, target: str) -> None:
    """Raise WorkflowError if the transition is not allowed."""
    allowed = _TRANSITIONS.get(module, {}).get(current, [])
    if target not in allowed:
        raise WorkflowError(
            f"[{module}] Cannot transition '{current}' -> '{target}'. "
            f"Allowed: {allowed or 'none'}"
        )


def get_allowed_transitions(module: str, current: str) -> list[str]:
    return _TRANSITIONS.get(module, {}).get(current, [])


def is_terminal(module: str, status: str) -> bool:
    return get_allowed_transitions(module, status) == []
