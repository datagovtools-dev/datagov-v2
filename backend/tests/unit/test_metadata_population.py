"""Tests for synchronous metadata population helpers."""

import os

os.environ.setdefault("SECRET_KEY", "test-secret")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("DATABASE_URL_SYNC", "sqlite:///:memory:")
os.environ.setdefault("DATABASE_NULL_POOL", "true")

from app.services.metadata_population import (
    build_tables_from_uploaded_payload,
    parse_csv_upload_content,
)


def test_parse_csv_upload_content_returns_sheet_and_sample_payload():
    content = (
        "vehicle_id,brand,model_year,email\n"
        "CAR-001,Toyota,2024,owner@example.com\n"
        "CAR-002,Honda,2025,\n"
    ).encode()

    sheets, tables = parse_csv_upload_content(content, "Automobile.csv")

    assert sheets == [{"sheet_name": "Automobile", "column_count": 4, "row_count": 2}]
    assert tables[0]["table_name"] == "Automobile"
    assert tables[0]["columns"] == ["vehicle_id", "brand", "model_year", "email"]
    assert tables[0]["sample_rows"] == [
        ["CAR-001", "Toyota", "2024", "owner@example.com"],
        ["CAR-002", "Honda", "2025", None],
    ]


def test_build_tables_from_uploaded_payload_filters_selected_tables():
    tables_data, row_counts = build_tables_from_uploaded_payload(
        [
            {
                "table_name": "Automobile",
                "columns": ["vehicle_id", "brand"],
                "sample_rows": [["CAR-001", "Toyota"], ["CAR-002", "Honda"]],
                "row_count": 398,
            },
            {
                "table_name": "Other",
                "columns": ["id"],
                "sample_rows": [["1"]],
                "row_count": 1,
            },
        ],
        ["Automobile"],
    )

    assert list(tables_data) == ["Automobile"]
    assert tables_data["Automobile"] == {
        "vehicle_id": ["CAR-001", "CAR-002"],
        "brand": ["Toyota", "Honda"],
    }
    assert row_counts["Automobile"] == 398
