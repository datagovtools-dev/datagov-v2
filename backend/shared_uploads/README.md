# Shared uploads

Uploaded Excel/CSV source files of projects the team shares through Git, laid out like the
`uploads_data` volume: `<project_id>/<hex>_<original filename>`.

- **Only fictitious test data.** Never put client or personal data here.
- The readable originals and the test guide are in `Dummy Data Source/<project code>/` at the repo root; this folder
  holds the same files under their upload names so the committed database finds them.
- Add or refresh a project's files: `docker exec ag_api python scripts/share_project_uploads.py PRJ-2026-022`
- On startup the API copies every file that is registered in `project_source_files` but missing
  from `/app/uploads` back from this folder, so a teammate who pulls the repo database gets the files too.
- Retention still applies: on project end date + 30 days the expiry job deletes the upload, its
  `project_source_files` row and the copy in this folder. Commit that deletion.
