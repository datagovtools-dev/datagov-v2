"""Uploaded source files shared through the repository.

Uploaded Excel/CSV files live on the ``uploads_data`` volume (``/app/uploads``), which
is not part of Git. For projects the team agrees to share (test projects with
fictitious data only, never client data), ``scripts/share_project_uploads.py`` copies
the files to ``backend/shared_uploads/`` (``/app/shared_uploads`` in the containers)
so they can be committed. On startup, every registered file that is missing from the
uploads volume is restored from that folder.

Retention still applies: a file is restored only while its ``project_source_files``
row exists, and the expiry job removes the shared copy together with the upload.
"""
from __future__ import annotations

import logging
import os
import shutil

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)

UPLOADS_ROOT = "/app/uploads"
SHARED_ROOT = "/app/shared_uploads"


def shared_copy_path(stored_path: str | None, uploads_root: str = UPLOADS_ROOT,
                     shared_root: str = SHARED_ROOT) -> str | None:
    """Repository path of an uploaded file, or None when it is not under the uploads folder."""
    if not stored_path:
        return None
    rel = os.path.relpath(stored_path, uploads_root)
    if rel.startswith("..") or os.path.isabs(rel):
        return None
    return os.path.join(shared_root, rel)


def restore_missing_files(stored_paths: list[str], uploads_root: str = UPLOADS_ROOT,
                          shared_root: str = SHARED_ROOT) -> int:
    """Copy shared files back into the uploads folder where they are missing."""
    restored = 0
    for stored_path in stored_paths:
        shared = shared_copy_path(stored_path, uploads_root, shared_root)
        if not shared or os.path.exists(stored_path) or not os.path.isfile(shared):
            continue
        try:
            os.makedirs(os.path.dirname(stored_path), exist_ok=True)
            shutil.copy2(shared, stored_path)
            restored += 1
        except OSError as exc:
            logger.warning("Could not restore %s: %s", stored_path, exc)
    return restored


def remove_shared_copy(stored_path: str | None, uploads_root: str = UPLOADS_ROOT,
                       shared_root: str = SHARED_ROOT) -> bool:
    """Delete the repository copy of an uploaded file (used when retention expires)."""
    shared = shared_copy_path(stored_path, uploads_root, shared_root)
    if not shared or not os.path.isfile(shared):
        return False
    try:
        os.remove(shared)
        folder = os.path.dirname(shared)
        if not os.listdir(folder):
            os.rmdir(folder)
    except OSError as exc:
        logger.warning("Could not delete shared copy %s: %s", shared, exc)
        return False
    return True


async def restore_shared_uploads(session: AsyncSession) -> int:
    """Startup step: restore registered files from ``shared_uploads`` into the uploads volume."""
    from app.models.metadata import ProjectSourceFile

    if not os.path.isdir(SHARED_ROOT):
        return 0
    stored_paths = [p for p in (await session.scalars(select(ProjectSourceFile.stored_path))).all() if p]
    restored = restore_missing_files(stored_paths)
    if restored:
        logger.info("Restored %d uploaded file(s) from shared_uploads", restored)
    return restored
