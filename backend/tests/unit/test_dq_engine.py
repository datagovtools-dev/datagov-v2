"""Unit tests for Data Quality engine helper functions."""
import pytest
from app.worker.tasks.dq import (
    _compute_completeness,
    _compute_uniqueness,
    _compute_consistency,
    _detect_format,
)


class TestCompleteness:
    def test_all_present(self):
        assert _compute_completeness(["a", "b", "c"]) == pytest.approx(1.0)

    def test_half_null(self):
        assert _compute_completeness([None, "a", None, "b"]) == pytest.approx(0.5)

    def test_all_null(self):
        assert _compute_completeness([None, None]) == pytest.approx(0.0)

    def test_empty(self):
        assert _compute_completeness([]) == pytest.approx(1.0)


class TestUniqueness:
    def test_all_unique(self):
        assert _compute_uniqueness([1, 2, 3, 4]) == pytest.approx(1.0)

    def test_all_duplicates(self):
        assert _compute_uniqueness([1, 1, 1, 1]) == pytest.approx(0.25)

    def test_empty(self):
        assert _compute_uniqueness([]) == pytest.approx(1.0)


class TestDetectFormat:
    def test_email_format(self):
        assert _detect_format(["test@example.com", "user@domain.org"]) == "email"

    def test_date_iso_format(self):
        assert _detect_format(["2024-01-01", "2023-12-31"]) == "date_iso"

    def test_integer_format(self):
        assert _detect_format(["123", "456", "789"]) == "integer"

    def test_uuid_format(self):
        assert _detect_format(["550e8400-e29b-41d4-a716-446655440000"]) == "uuid"

    def test_mixed_no_format(self):
        assert _detect_format(["hello", "123", "2024-01-01"]) is None


class TestConsistency:
    def test_consistent_emails(self):
        values = ["a@b.com", "c@d.org", "e@f.net"]
        score = _compute_consistency(values)
        assert score == pytest.approx(1.0)

    def test_no_dominant_format(self):
        values = ["hello", "world", "foo", "bar"]
        score = _compute_consistency(values)
        # No format detected — returns 1.0 (no violations)
        assert score == pytest.approx(1.0)
