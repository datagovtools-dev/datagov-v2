"""Uploaded files shared through the repository: restore on startup, removal on retention expiry."""
import os

from app.services.shared_uploads import remove_shared_copy, restore_missing_files, shared_copy_path


def _paths(tmp_path):
    uploads, shared = tmp_path / "uploads", tmp_path / "shared"
    stored = uploads / "proj-1" / "abc_TEST01.xlsx"
    copy = shared / "proj-1" / "abc_TEST01.xlsx"
    copy.parent.mkdir(parents=True)
    copy.write_bytes(b"excel")
    return str(uploads), str(shared), str(stored), copy


def test_shared_copy_path_maps_only_files_under_uploads(tmp_path):
    uploads, shared, stored, copy = _paths(tmp_path)
    assert shared_copy_path(stored, uploads, shared) == str(copy)
    assert shared_copy_path("/elsewhere/x.xlsx", uploads, shared) is None
    assert shared_copy_path(None, uploads, shared) is None


def test_missing_upload_is_restored_and_existing_one_kept(tmp_path):
    uploads, shared, stored, _ = _paths(tmp_path)
    assert restore_missing_files([stored], uploads, shared) == 1
    assert open(stored, "rb").read() == b"excel"

    open(stored, "wb").write(b"newer upload")
    assert restore_missing_files([stored], uploads, shared) == 0  # never overwrites
    assert open(stored, "rb").read() == b"newer upload"


def test_expired_file_is_not_restored_after_shared_copy_removed(tmp_path):
    uploads, shared, stored, copy = _paths(tmp_path)
    assert remove_shared_copy(stored, uploads, shared) is True
    assert not copy.exists() and not copy.parent.exists()
    assert restore_missing_files([stored], uploads, shared) == 0
    assert not os.path.exists(stored)
