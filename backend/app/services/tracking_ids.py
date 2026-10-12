"""Helpers for allocating human-readable yearly tracking IDs."""
import re
from datetime import datetime, timezone
from typing import Type

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


async def next_yearly_tracking_id(
    db: AsyncSession,
    model: Type,
    tracking_column,
    prefix: str,
    year: int | None = None,
) -> str:
    """Return the next ID after the highest valid sequence already stored.

    Counting rows is incorrect when records are deleted or imported with gaps.
    Invalid legacy values are ignored rather than shifting the sequence.
    """
    year = year or datetime.now(timezone.utc).year
    pattern = re.compile(rf"^{re.escape(prefix)}-{year:04d}-(\d+)$")
    values = (
        await db.execute(
            select(tracking_column).where(
                tracking_column.like(f"{prefix}-{year:04d}-%")
            )
        )
    ).scalars()

    highest = 0
    for value in values:
        match = pattern.fullmatch(value or "")
        if match:
            highest = max(highest, int(match.group(1)))
    return f"{prefix}-{year:04d}-{highest + 1:04d}"
