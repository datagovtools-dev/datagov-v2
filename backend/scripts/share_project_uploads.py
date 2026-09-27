"""Copy a project's uploaded source files into backend/shared_uploads so they can be committed.

Only for projects with fictitious test data (never client data). Teammates get the files
back into their uploads volume automatically when the API starts (see
app/services/shared_uploads.py). Files of the project that are no longer registered in
project_source_files are removed from shared_uploads.

Usage (inside the api container):
    docker exec ag_api python scripts/share_project_uploads.py PRJ-2026-022 [PRJ-...]
"""
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main(project_codes: list[str]) -> int:
    from sqlalchemy import select

    import app.models  # noqa: F401
    from app.database import get_sync_session
    from app.models.metadata import ProjectSourceFile
    from app.models.project import Project
    from app.services.shared_uploads import SHARED_ROOT, shared_copy_path

    missing = 0
    with get_sync_session() as db:
        for code in project_codes:
            project = db.scalars(select(Project).where(Project.project_code == code)).first()
            if not project:
                print(f"  ! {code}: project not found")
                missing += 1
                continue
            files = db.scalars(select(ProjectSourceFile).where(ProjectSourceFile.project_id == project.id)).all()
            keep = set()
            for f in files:
                shared = shared_copy_path(f.stored_path)
                if not shared:
                    print(f"  ! {code}: {f.original_filename} is not under the uploads folder, skipped")
                    continue
                if not os.path.isfile(f.stored_path):
                    print(f"  ! {code}: {f.original_filename} is missing from the uploads folder")
                    missing += 1
                    continue
                os.makedirs(os.path.dirname(shared), exist_ok=True)
                shutil.copy2(f.stored_path, shared)
                keep.add(os.path.basename(shared))
                print(f"  + {code}: {f.original_filename}")
            folder = os.path.join(SHARED_ROOT, str(project.id))
            if os.path.isdir(folder):
                for name in os.listdir(folder):
                    if name not in keep:
                        os.remove(os.path.join(folder, name))
                        print(f"  - {code}: removed unregistered {name}")
                if not os.listdir(folder):
                    os.rmdir(folder)
    return 1 if missing else 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1:]))
