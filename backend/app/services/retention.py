"""How long uploaded source files of a project are kept.

- No approved ROPA for the project: project end date + 30 days (default).
- Approved ROPA: project end date + the ROPA retention period (e.g. "5 Years from Account
  Termination" -> 5 years). With several approved ROPAs the longest period applies.
- A retention period that cannot be read (no number + day/week/month/year) is ignored, so
  the default applies; the retention info says so, so the ROPA text can be corrected.
"""
from __future__ import annotations

import re
import uuid
from dataclasses import dataclass
from datetime import date, timedelta

from dateutil.relativedelta import relativedelta  # type: ignore[import-untyped]
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session

DEFAULT_RETENTION_DAYS = 30
WARNING_DAYS = 7

_NUMBER_WORDS = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
                 "eight": 8, "nine": 9, "ten": 10, "satu": 1, "dua": 2, "tiga": 3, "empat": 4,
                 "lima": 5, "enam": 6, "tujuh": 7, "delapan": 8, "sembilan": 9, "sepuluh": 10}
_UNITS = {"day": "days", "days": "days", "hari": "days",
          "week": "weeks", "weeks": "weeks", "minggu": "weeks",
          "month": "months", "months": "months", "bulan": "months",
          "year": "years", "years": "years", "yr": "years", "yrs": "years", "tahun": "years"}
_PERIOD = re.compile(r"(\d+|" + "|".join(_NUMBER_WORDS) + r")\s*(" + "|".join(_UNITS) + r")\b", re.IGNORECASE)


def parse_retention_period(text: str | None) -> relativedelta | None:
    """First "<number> <unit>" in a ROPA retention period, e.g. "5 Years from ..." -> 5 years."""
    match = _PERIOD.search(text or "")
    if not match:
        return None
    raw, unit = match.group(1).lower(), _UNITS[match.group(2).lower()]
    amount = int(raw) if raw.isdigit() else _NUMBER_WORDS[raw]
    return relativedelta(**{unit: amount}) if amount > 0 else None


@dataclass
class SourceFileRetention:
    end_date: date | None
    expiry_date: date | None          # files are deleted on this day (None: project has no end date)
    warning_date: date | None
    basis: str                        # "default" | "ropa"
    ropa_retention_period: str | None  # text of the approved ROPA that sets the date
    ropa_process_name: str | None
    unreadable_ropa_periods: list[str]

    def as_dict(self) -> dict:
        return {
            "end_date": self.end_date, "expiry_date": self.expiry_date, "warning_date": self.warning_date,
            "basis": self.basis, "default_days": DEFAULT_RETENTION_DAYS,
            "ropa_retention_period": self.ropa_retention_period, "ropa_process_name": self.ropa_process_name,
            "unreadable_ropa_periods": self.unreadable_ropa_periods,
        }


def source_file_retention(end_date: date | None, approved_ropas: list[tuple[str, str]]) -> SourceFileRetention:
    """Retention of a project's uploaded files; ``approved_ropas`` is [(process_name, retention_period)]."""
    unreadable: list[str] = []
    if end_date is None:
        return SourceFileRetention(None, None, None, "default", None, None, unreadable)
    expiry = end_date + timedelta(days=DEFAULT_RETENTION_DAYS)
    basis, period_text, process = "default", None, None
    best: date | None = None
    for name, text in approved_ropas:
        period = parse_retention_period(text)
        if period is None:
            unreadable.append(text)
            continue
        candidate = end_date + period
        if best is None or candidate > best:
            best, period_text, process = candidate, text, name
    if best is not None:
        expiry, basis = best, "ropa"
    return SourceFileRetention(end_date, expiry, expiry - timedelta(days=WARNING_DAYS), basis,
                               period_text, process, unreadable)


def _approved_ropas_query(project_id: uuid.UUID):
    from app.models.ropa import ROPARecord

    return select(ROPARecord.process_name, ROPARecord.retention_period).where(
        ROPARecord.project_id == project_id, ROPARecord.status == "approved")


def project_retention_sync(db: Session, project) -> SourceFileRetention:
    rows = [(r.process_name, r.retention_period) for r in db.execute(_approved_ropas_query(project.id)).all()]
    return source_file_retention(project.end_date, rows)


async def project_retention(db: AsyncSession, project) -> SourceFileRetention:
    rows = [(r.process_name, r.retention_period) for r in (await db.execute(_approved_ropas_query(project.id))).all()]
    return source_file_retention(project.end_date, rows)
