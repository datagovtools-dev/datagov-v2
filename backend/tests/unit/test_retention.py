"""Uploaded source file retention: end date + 30 days, or + the approved ROPA retention period."""
from datetime import date

import pytest
from dateutil.relativedelta import relativedelta

from app.services.retention import parse_retention_period, source_file_retention

END = date(2027, 3, 31)


@pytest.mark.parametrize("text, expected", [
    ("5 Years from Account Termination", relativedelta(years=5)),
    ("3 Years", relativedelta(years=3)),
    ("2 Months", relativedelta(months=2)),
    ("18 months after contract end", relativedelta(months=18)),
    ("90 days", relativedelta(days=90)),
    ("1 year", relativedelta(years=1)),
    ("Two years", relativedelta(years=2)),
    ("5 tahun", relativedelta(years=5)),
    ("Until consent is withdrawn", None),
    ("", None),
    (None, None),
])
def test_parse_retention_period(text, expected):
    assert parse_retention_period(text) == expected


def test_no_approved_ropa_keeps_files_30_days_after_end_date():
    r = source_file_retention(END, [])
    assert (r.basis, r.expiry_date, r.warning_date) == ("default", date(2027, 4, 30), date(2027, 4, 23))


def test_approved_ropa_sets_retention_and_longest_period_wins():
    r = source_file_retention(END, [("Churn", "2 Months"), ("Billing", "5 Years from Account Termination")])
    assert r.basis == "ropa"
    assert r.expiry_date == date(2032, 3, 31)
    assert (r.ropa_process_name, r.ropa_retention_period) == ("Billing", "5 Years from Account Termination")


def test_unreadable_ropa_period_falls_back_to_default_and_is_reported():
    r = source_file_retention(END, [("Churn", "As required by law")])
    assert r.basis == "default" and r.expiry_date == date(2027, 4, 30)
    assert r.unreadable_ropa_periods == ["As required by law"]


def test_project_without_end_date_has_no_expiry():
    r = source_file_retention(None, [("Churn", "3 Years")])
    assert r.expiry_date is None
