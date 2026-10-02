"""Why a DQ run failed: category, plain-language explanation, next step, and whether a retry can help.

The worker stores the category and the technical detail on the run (dq_runs.error_category /
error_message); the status endpoint turns the category into the title and next step shown in the UI.
"""
from __future__ import annotations

import re
import sqlite3
import zipfile
from dataclasses import dataclass

import requests


@dataclass(frozen=True)
class FailureCategory:
    title: str
    explanation: str
    action: str
    transient: bool  # True: the worker retries automatically (the cause may go away)


CATEGORIES: dict[str, FailureCategory] = {
    "source_file_missing": FailureCategory(
        "Source file not found",
        "The Excel file registered for this dataset is no longer in the uploads folder.",
        "Re-upload the file in Metadata for this project, then start a new DQ run.",
        transient=False,
    ),
    "file_unreadable": FailureCategory(
        "File could not be read",
        "The source file is not a readable Excel workbook or CSV (it may be corrupted, password-protected or unsupported).",
        "Re-upload a valid .xlsx, .xlsm or .csv file in Metadata and run DQ again.",
        transient=False,
    ),
    "empty_data": FailureCategory(
        "No data found",
        "The sheet has no header row or no data rows, so there is nothing to check.",
        "Make sure the first sheet has a header row followed by data rows, re-upload it and run DQ again.",
        transient=False,
    ),
    "ai_model_missing": FailureCategory(
        "AI model not installed",
        "The AI model selected for DQ is not installed on the Ollama server.",
        "Install it (docker exec ag_ollama ollama pull llama3.2:3b) or pick an installed model in Settings > AI Setup, then run DQ again.",
        transient=False,
    ),
    "ai_auth": FailureCategory(
        "AI service refused the request",
        "The AI service rejected the API key.",
        "Check the API key in Settings > AI Setup (cloud mode), then run DQ again.",
        transient=False,
    ),
    "ai_unreachable": FailureCategory(
        "AI service not reachable",
        "The worker could not connect to the Ollama AI service.",
        "Start it (docker compose up -d ollama) or check the base URL in Settings > AI Setup, then run DQ again.",
        transient=True,
    ),
    "ai_timeout": FailureCategory(
        "AI service too slow",
        "The AI model did not answer in time; the computer may be busy.",
        "Close other heavy programs and run DQ again, or raise the timeout in Settings > AI Setup.",
        transient=True,
    ),
    "ai_error": FailureCategory(
        "AI service error",
        "The AI service returned an error while generating the rules.",
        "Run DQ again; if it keeps failing, check the ollama container log.",
        transient=True,
    ),
    "database_busy": FailureCategory(
        "Database busy",
        "The database was busy with another save and the results could not be written.",
        "Run DQ again in a moment.",
        transient=True,
    ),
    "bigquery_error": FailureCategory(
        "BigQuery read failed",
        "The table could not be read from BigQuery.",
        "Check the project, dataset and table names and the service-account access, then run DQ again.",
        transient=False,
    ),
    "unsupported_source": FailureCategory(
        "Unsupported data source",
        "The run was created without a readable data source.",
        "Start a new DQ run from the project's Metadata files.",
        transient=False,
    ),
    "unexpected": FailureCategory(
        "Unexpected error",
        "Something went wrong while running the checks.",
        "Run DQ again; if it keeps failing, send the run ID and the detail below to the tech team.",
        transient=False,
    ),
}


class EmptyDataError(ValueError):
    """The source has no header or no data rows."""


class UnsupportedSourceError(ValueError):
    """The run has no readable data source."""


def classify_failure(exc: BaseException) -> str:
    """Map an exception raised during a DQ run to a key of CATEGORIES."""
    if isinstance(exc, FileNotFoundError):
        return "source_file_missing"
    if isinstance(exc, EmptyDataError):
        return "empty_data"
    if isinstance(exc, UnsupportedSourceError):
        return "unsupported_source"
    if isinstance(exc, requests.HTTPError):
        code = exc.response.status_code if exc.response is not None else None
        if code == 404:
            return "ai_model_missing"
        if code in (401, 403):
            return "ai_auth"
        return "ai_error"
    if isinstance(exc, requests.Timeout):
        return "ai_timeout"
    if isinstance(exc, requests.ConnectionError):
        return "ai_unreachable"
    if isinstance(exc, (zipfile.BadZipFile, KeyError)) or type(exc).__name__ == "InvalidFileException":
        return "file_unreadable"
    message = str(exc).lower()
    if isinstance(exc, sqlite3.OperationalError) or "database is locked" in message:
        return "database_busy"
    if type(exc).__module__.startswith("google."):
        return "bigquery_error"
    return "unexpected"


def failure_detail(exc: BaseException, category: str, model: str | None = None) -> str:
    """Short technical detail stored with the run (shown under the explanation)."""
    filename = getattr(exc, "filename", None)
    if category == "source_file_missing" and filename:
        name = re.sub(r"^[0-9a-f]{32}_", "", str(filename).rsplit("/", 1)[-1])  # drop the upload id prefix
        return f"Missing file: {name}"
    if category == "ai_model_missing":
        return f"Model '{model}' was not found on the Ollama server." if model else "Model not found on the Ollama server."
    return f"{type(exc).__name__}: {exc}"[:500]
