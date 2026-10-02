"""Read tabular files used by Metadata and Data Quality workflows."""
from __future__ import annotations

import csv
import io
import os
from typing import Any


def _decode_csv(raw: bytes) -> str:
    try:
        return raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        return raw.decode("latin-1", errors="replace")


def _unique_headers(raw_headers: list[Any]) -> list[str]:
    seen: dict[str, int] = {}
    headers: list[str] = []
    for index, raw in enumerate(raw_headers):
        header = str(raw).strip() if raw is not None else ""
        header = header or f"col_{index}"
        seen[header] = seen.get(header, 0) + 1
        headers.append(header if seen[header] == 1 else f"{header}_{seen[header]}")
    return headers


def read_csv_columns(file_path: str) -> dict[str, list[Any]]:
    """Read a CSV into the column-oriented structure used by DQ analysis."""
    with open(file_path, "rb") as handle:
        text = _decode_csv(handle.read())

    rows = list(csv.reader(io.StringIO(text, newline="")))
    if not rows:
        return {}

    headers = _unique_headers(rows[0])
    data: dict[str, list[Any]] = {header: [] for header in headers}
    for row in rows[1:]:
        for index, header in enumerate(headers):
            value = row[index] if index < len(row) else None
            data[header].append(value if value is not None and value.strip() else None)
    return data


def read_excel_columns(file_path: str, sheet_name: str | None = None) -> dict[str, list[Any]]:
    """Read an Excel workbook into the column-oriented structure used by DQ analysis."""
    import openpyxl

    wb = openpyxl.load_workbook(file_path, read_only=True, data_only=True)
    try:
        ws = wb[sheet_name] if sheet_name and sheet_name in wb.sheetnames else wb.active
        if ws is None:
            return {}
        rows = list(ws.iter_rows(values_only=True))
        if not rows:
            return {}
        headers = _unique_headers(list(rows[0]))
        data: dict[str, list[Any]] = {header: [] for header in headers}
        for row in rows[1:]:
            for index, header in enumerate(headers):
                data[header].append(row[index] if index < len(row) else None)
        return data
    finally:
        wb.close()


def read_tabular_columns(file_path: str, sheet_name: str | None = None) -> dict[str, list[Any]]:
    """Read CSV or Excel based on the file extension."""
    if os.path.splitext(file_path)[1].lower() == ".csv":
        return read_csv_columns(file_path)
    return read_excel_columns(file_path, sheet_name)


def count_tabular_columns(file_path: str) -> int | None:
    """Count non-empty headers without loading an entire dataset when possible."""
    if os.path.splitext(file_path)[1].lower() == ".csv":
        with open(file_path, "rb") as handle:
            text = _decode_csv(handle.read())
        first_row = next(csv.reader(io.StringIO(text, newline="")), [])
        return len([header for header in first_row if str(header).strip()]) or None

    import openpyxl

    wb = openpyxl.load_workbook(file_path, read_only=True, data_only=True)
    try:
        ws = wb.active
        if ws is None:
            return None
        header = next(ws.iter_rows(min_row=1, max_row=1, values_only=True), ())
        return sum(1 for value in header if value not in (None, "")) or None
    finally:
        wb.close()


def preview_tabular_file(
    file_path: str,
    sheet_name: str | None = None,
    limit: int = 10,
) -> tuple[str, int, list[str], list[dict[str, Any]]]:
    """Return sheet/table name, row count, headers, and a bounded preview."""
    if os.path.splitext(file_path)[1].lower() == ".csv":
        with open(file_path, "rb") as handle:
            text = _decode_csv(handle.read())
        rows = list(csv.reader(io.StringIO(text, newline="")))
        if not rows:
            return (os.path.splitext(os.path.basename(file_path))[0], 0, [], [])
        headers = _unique_headers(rows[0])
        preview = [
            {
                header: (row[index] if index < len(row) and row[index].strip() else None)
                for index, header in enumerate(headers)
            }
            for row in rows[1 : limit + 1]
        ]
        return (os.path.splitext(os.path.basename(file_path))[0], max(0, len(rows) - 1), headers, preview)

    import openpyxl

    wb = openpyxl.load_workbook(file_path, read_only=True, data_only=True)
    try:
        ws = wb[sheet_name] if sheet_name and sheet_name in wb.sheetnames else wb.active
        if ws is None:
            return ("Sheet1", 0, [], [])
        rows = list(ws.iter_rows(values_only=True))
        if not rows:
            return (ws.title or "Sheet1", 0, [], [])
        headers = _unique_headers(list(rows[0]))
        preview = [
            {
                header: (str(row[index]) if row[index] is not None else None)
                for index, header in enumerate(headers)
            }
            for row in rows[1 : limit + 1]
        ]
        return (ws.title or "Sheet1", max(0, len(rows) - 1), headers, preview)
    finally:
        wb.close()
