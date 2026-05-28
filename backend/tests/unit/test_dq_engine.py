"""Unit tests for Data Quality engine helper functions."""
import sys
from types import SimpleNamespace

import pytest

from app.worker.tasks import dq
from app.worker.tasks.dq import (
    DQAIConfig,
    _apply_regex_score,
    _call_ollama,
    _compute_ai_consistency,
    _compute_completeness,
    _compute_uniqueness,
    _detect_format_regex,
    _get_ai_config,
)


class DummyResponse:
    def __init__(self, payload: dict):
        self.payload = payload

    def raise_for_status(self):
        return None

    def json(self):
        return self.payload


class TestCompleteness:
    def test_all_present(self):
        assert _compute_completeness("col", ["a", "b", "c"])["score"] == pytest.approx(100.0)

    def test_half_null(self):
        assert _compute_completeness("col", [None, "a", None, "b"])["score"] == pytest.approx(50.0)

    def test_all_null(self):
        assert _compute_completeness("col", [None, None])["score"] == pytest.approx(0.0)

    def test_empty(self):
        assert _compute_completeness("col", [])["score"] == pytest.approx(0.0)


class TestUniqueness:
    def test_all_unique(self):
        result = _compute_uniqueness("id", [1, 2, 3, 4])
        assert result is not None
        assert result["score"] == pytest.approx(100.0)

    def test_duplicates_do_not_create_uniqueness_check(self):
        assert _compute_uniqueness("id", [1, 1, 1, 1]) is None

    def test_empty(self):
        assert _compute_uniqueness("id", []) is None


class TestDetectFormat:
    def test_email_format(self):
        assert _detect_format_regex(["test@example.com", "user@domain.org"]) == r"^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$"

    def test_date_iso_format(self):
        assert _detect_format_regex(["2024-01-01", "2023-12-31"]) == r"^\d{4}-\d{2}-\d{2}$"

    def test_integer_format(self):
        assert _detect_format_regex(["123", "456", "789"]) == r"^\d+$"

    def test_uuid_format(self):
        assert _detect_format_regex(["550e8400-e29b-41d4-a716-446655440000"]) == r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"

    def test_mixed_no_format(self):
        assert _detect_format_regex(["hello", "123", "2024-01-01"]) is None


class TestAISetupWiring:
    def test_get_ai_config_reads_saved_setup_and_decrypts_key(self, monkeypatch):
        class FakeCursor:
            def execute(self, query):
                self.query = query

            def fetchone(self):
                return ("gpt-oss:120b", "https://ollama.com/", 60, "encrypted-value")

            def close(self):
                return None

        class FakeConnection:
            def cursor(self):
                return FakeCursor()

            def close(self):
                return None

        monkeypatch.setitem(
            sys.modules,
            "psycopg2",
            SimpleNamespace(connect=lambda _: FakeConnection()),
        )
        monkeypatch.setattr(dq, "decrypt_secret", lambda value: "plain-key" if value == "encrypted-value" else None)

        config = _get_ai_config("postgresql://example")

        assert config == DQAIConfig(
            model_name="gpt-oss:120b",
            base_url="https://ollama.com",
            timeout_seconds=60,
            api_key="plain-key",
        )

    def test_call_ollama_sends_saved_api_key_as_bearer_token(self, monkeypatch):
        calls = {}

        def fake_post(url, json, headers, timeout):
            calls.update({"url": url, "json": json, "headers": headers, "timeout": timeout})
            return DummyResponse({"response": "ok"})

        monkeypatch.setattr(dq.requests, "post", fake_post)

        assert _call_ollama("prompt", "gpt-oss:120b", "https://ollama.com", 60, "secret-key") == "ok"
        assert calls["url"] == "https://ollama.com/api/generate"
        assert calls["json"]["model"] == "gpt-oss:120b"
        assert calls["headers"] == {"Authorization": "Bearer secret-key"}
        assert calls["timeout"] == 60

    def test_call_ollama_omits_auth_header_without_api_key(self, monkeypatch):
        calls = {}

        def fake_post(url, json, headers, timeout):
            calls["headers"] = headers
            return DummyResponse({"response": "ok"})

        monkeypatch.setattr(dq.requests, "post", fake_post)

        _call_ollama("prompt", "local-model", "http://ollama:11434", 120)
        assert calls["headers"] is None


class TestConsistency:
    def test_ai_success_uses_configured_model_and_generated_rules(self, monkeypatch):
        raw = (
            "HERE IS THE FINAL RESULT\n"
            "- Column Name: Email\n"
            "- Column Type: object\n"
            "- Business Rules: a. Must be an email address\n"
            "- RegEx Pattern: r'^[\\w._%+\\-]+@[\\w.\\-]+\\.[a-zA-Z]{2,}$'\n"
            "- Complexity: Low\n"
            "- Reasoning: Samples are email addresses"
        )
        monkeypatch.setattr(dq, "_call_ollama", lambda *args, **kwargs: raw)

        result = _compute_ai_consistency(
            "Email",
            "object",
            ["a@b.com", "c@d.org"],
            DQAIConfig("gpt-oss:120b", "https://ollama.com", 60, "secret-key"),
        )

        assert result["ai_model"] == "gpt-oss:120b"
        assert "Must be an email address" in result["business_rules"]
        assert result["score"] == pytest.approx(100.0)

    def test_missing_ai_setup_falls_back_to_rule_based_consistency(self):
        result = _compute_ai_consistency("Email", "object", ["a@b.com", "c@d.org"], None)
        assert result["ai_model"] == "rule-based"
        assert result["regex_pattern"] == r"^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$"
        assert result["score"] == pytest.approx(100.0)

    def test_regex_score_matches_non_null_values(self):
        matched, total, score = _apply_regex_score(["a@b.com", "bad", None], r"^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$")
        assert (matched, total, score) == (1, 2, 50.0)
