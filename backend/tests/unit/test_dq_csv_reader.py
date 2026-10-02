from pathlib import Path

from app.services.tabular_reader import count_tabular_columns, preview_tabular_file
from app.worker.tasks.dq import _read_excel


def test_dq_reader_accepts_csv_project_source_file(tmp_path: Path):
    csv_path = tmp_path / "customers.csv"
    csv_path.write_text(
        "customer_id,email,active\n"
        "C001,alice@example.com,Yes\n"
        "C002,,No\n",
        encoding="utf-8",
    )

    assert _read_excel(str(csv_path)) == {
        "customer_id": ["C001", "C002"],
        "email": ["alice@example.com", None],
        "active": ["Yes", "No"],
    }


def test_dq_csv_count_and_preview_use_the_same_headers(tmp_path: Path):
    csv_path = tmp_path / "customers.csv"
    csv_path.write_text(
        "customer_id,email,active\n"
        "C001,alice@example.com,Yes\n"
        "C002,,No\n",
        encoding="utf-8",
    )

    assert count_tabular_columns(str(csv_path)) == 3
    assert preview_tabular_file(str(csv_path)) == (
        "customers",
        2,
        ["customer_id", "email", "active"],
        [
            {"customer_id": "C001", "email": "alice@example.com", "active": "Yes"},
            {"customer_id": "C002", "email": None, "active": "No"},
        ],
    )
