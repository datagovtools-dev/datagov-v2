"""DQ run failure categories: every exception maps to an explained category."""
import os
import sqlite3
import zipfile

os.environ.setdefault("SECRET_KEY", "test-secret")

import pytest
import requests

from app.services.dq_failures import (
    CATEGORIES,
    EmptyDataError,
    UnsupportedSourceError,
    classify_failure,
    failure_detail,
)


def _http_error(code: int) -> requests.HTTPError:
    response = requests.Response()
    response.status_code = code
    return requests.HTTPError(response=response)


@pytest.mark.parametrize("exc, category", [
    (FileNotFoundError(2, "No such file or directory", "/app/uploads/x/abc.xlsx"), "source_file_missing"),
    (zipfile.BadZipFile("File is not a zip file"), "file_unreadable"),
    (EmptyDataError("no rows"), "empty_data"),
    (UnsupportedSourceError("bad source"), "unsupported_source"),
    (_http_error(404), "ai_model_missing"),
    (_http_error(401), "ai_auth"),
    (_http_error(500), "ai_error"),
    (requests.ConnectionError("refused"), "ai_unreachable"),
    (requests.ReadTimeout("slow"), "ai_timeout"),
    (sqlite3.OperationalError("database is locked"), "database_busy"),
    (RuntimeError("boom"), "unexpected"),
])
def test_classify_failure(exc, category):
    assert classify_failure(exc) == category


def test_every_category_explains_what_to_do():
    for key, cat in CATEGORIES.items():
        assert cat.title and cat.explanation and cat.action, key


def test_only_temporary_problems_are_retried():
    retried = {k for k, c in CATEGORIES.items() if c.transient}
    assert retried == {"ai_unreachable", "ai_timeout", "ai_error", "database_busy"}


def test_missing_file_detail_shows_the_original_file_name():
    exc = FileNotFoundError(2, "No such file", "/app/uploads/p/10365909a0e84ec28b28ac185d8352b0_PRJ003_Data_Governance.xlsx")
    assert failure_detail(exc, "source_file_missing") == "Missing file: PRJ003_Data_Governance.xlsx"


def test_missing_model_detail_names_the_model():
    assert "llama3.2:3b" in failure_detail(_http_error(404), "ai_model_missing", model="llama3.2:3b")
