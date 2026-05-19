"""Unit tests for the shared workflow state machine."""
import pytest
from app.core.workflow import validate_transition, WorkflowError

VALID_TRANSITIONS = [
    ("draft",        "submitted"),
    ("submitted",    "under_review"),
    ("under_review", "approved"),
    ("under_review", "rejected"),
    ("approved",     "archived"),
    ("rejected",     "archived"),
    ("approved",     "executed"),
]

INVALID_TRANSITIONS = [
    ("draft",     "approved"),
    ("draft",     "archived"),
    ("approved",  "submitted"),
    ("executed",  "draft"),
    ("archived",  "submitted"),
]


@pytest.mark.parametrize("from_s,to_s", VALID_TRANSITIONS)
def test_valid_transitions(from_s, to_s):
    validate_transition(from_s, to_s)  # Must not raise


@pytest.mark.parametrize("from_s,to_s", INVALID_TRANSITIONS)
def test_invalid_transitions_raise(from_s, to_s):
    with pytest.raises((WorkflowError, ValueError)):
        validate_transition(from_s, to_s)
