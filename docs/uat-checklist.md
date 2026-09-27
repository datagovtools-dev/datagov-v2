# UAT Checklist — P6-012
# AI Governance Tools Platform — MVP Functional Requirements

**Environment:** Staging  
**Tester:** Data Governance Team  
**Target:** All 82 checks pass (75 Functional Requirements + 7 Non-Functional Requirements)

---

## Module 1: RBAC & Project Management

| FR | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| FR-ACC-001 | Super Admin can create, edit, delete roles | ☐ | ☐ | |
| FR-ACC-002 | Data Owner can view/modify access to owned datasets | ☐ | ☐ | |
| FR-ACC-003 | Data Steward has domain-scoped view/edit only | ☐ | ☐ | |
| FR-ACC-004 | Regular User receives access-denied for restricted areas | ☐ | ☐ | |
| FR-ACC-005 | Auditor has read-only audit trail access | ☐ | ☐ | |
| FR-PRJ-001 | Super Admin can create project; form has 13 fields (4 required: Name, Customer, Year, Category) | ☐ | ☐ | |
| FR-PRJ-002 | Cascading Year→Customer→Project filter works | ☐ | ☐ | |
| FR-DPIA-AUTO-001 | Creating a project's first DSR creates one DPIA draft for the project (empty content, status Draft); the DPIA overview shows DSR Status and DPIA Status separately; the DPIA is submitted only by filling it in and submitting it | ☐ | ☐ | |
| FR-AICK-STATUS-001 | After submit, DSR and AICK show "Submitted" until PIC Data Compliance approves step 1, then "Under Review"; the AI Checklist overview shows the AICK's own status (an AICK not yet submitted stays "In Progress" even if its DSR was submitted) and the status filter has Submitted / Under Review / Ready for Sign-Off / Completed & Signed / Rejected / In Progress | ☐ | ☐ | |
| FR-AICK-SIGN-001 | A submitted AICK with no approvals stays "Submitted" (DSR status "Submitted") in the DSR and AICK overviews; it becomes "Completed & Signed" only after both sign-off signatures or the final (SME) approval step; a rejection removes the signed state | ☐ | ☐ | |
| FR-DSR-SIGN-001 | DSR checklist sign-off (edit mode): Prepared By = project Data Owner name + Position (read-only; position editable with a hint only if the owner has none), Acknowledged By = project SME name + company position from the user account (e.g. "Head of Business Analytics", not "Subject Matter Expert (SME)"); every user has a position | ☐ | ☐ | |
| FR-PRJ-004 | New/Edit Project: Data Owner has a Position field (e.g. "CRM Department Head"); it is saved, shown under the owner's name in the Data Assets Catalog project detail cards and project PDF, and used for the DSR sign-off; the Metadata and DQ headers and exports show Data Steward and Data Owner with name and email only | ☐ | ☐ | |
| FR-PRJ-003 | All workspace sections inactive until project selected | ☐ | ☐ | |

## Module 2: Data Sharing Request (DSR)

| FR | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| FR-DSR-001 | DSR created with auto-generated tracking ID (DSR-YYYY-NNNN) | ☐ | ☐ | |
| FR-DSR-002 | Multi-level approval workflow functions correctly | ☐ | ☐ | |
| FR-DSR-003 | Notifications sent at each workflow transition | ☐ | ☐ | |
| FR-DSR-004 | DSA linkage blocks approval when no DSA attached | ☐ | ☐ | |
| FR-DSR-005 | Access auto-revoked on expiry | ☐ | ☐ | |
| FR-DSR-006 | PDF/XLSX/CSV export with status history | ☐ | ☐ | |
| FR-DSR-007 | Immutable audit log for all DSR actions | ☐ | ☐ | |
| FR-DSR-008 | AI compliance checklist triggers when is_ai_use=true | ☐ | ☐ | |

## Module 3: DPIA

| FR | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| FR-DPIA-001 | DPIA created with 5×5 risk matrix | ☐ | ☐ | |
| FR-DPIA-002 | Risk score auto-computed (likelihood × impact) | ☐ | ☐ | |
| FR-DPIA-003 | DPO approval workflow (Draft→Review→Approved) | ☐ | ☐ | |
| FR-DPIA-004 | Bidirectional ROPA linkage | ☐ | ☐ | |
| FR-DPIA-005 | ROPA deletion triggers DPIA validation warning | ☐ | ☐ | |
| FR-DPIA-006 | PDF/XLSX reports with risk level filter | ☐ | ☐ | |

## Module 4: ROPA

| FR | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| FR-ROPA-001 | ROPA record created with 7 mandatory fields | ☐ | ☐ | |
| FR-ROPA-002 | Version history with timestamps and author | ☐ | ☐ | |
| FR-ROPA-003 | Link ROPA to GCP tables or systems | ☐ | ☐ | |
| FR-ROPA-004 | Auto-update on linked asset deletion/modification | ☐ | ☐ | |
| FR-ROPA-005 | CSV/XLSX/PDF reports with filters | ☐ | ☐ | |
| FR-ROPA-RET-001 | Data Assets Catalog project page shows "Uploaded Source Files Kept Until" = End Date + 30 days while the project's ROPA is draft/submitted/under review/rejected; after the ROPA is approved it shows End Date + the ROPA Retention Period (e.g. "5 Years" → +5 years) and names the ROPA; with two approved ROPAs the longer period is shown; a period without a duration (e.g. "As required by law") keeps +30 days and shows a warning | ☐ | ☐ | |
| FR-ROPA-RET-002 | Shared test files: after `scripts/share_project_uploads.py <PRJ>` and a fresh clone (`docker volume rm datagov-v2_sqlite_data datagov-v2_uploads_data`, start the stack), the project's files are available at the DQ Data step (not "File missing") | ☐ | ☐ | |

## Module 5: BAPD (Data Extermination)

| FR | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| FR-BAPD-001 | BAPD created for retention-expired datasets only | ☐ | ☐ | |
| FR-BAPD-002 | Dual approval required (Data Owner AND Compliance Officer) | ☐ | ☐ | |
| FR-BAPD-003 | Proof of Deletion PDF generated and stored in GCS | ☐ | ☐ | |
| FR-BAPD-004 | Daily retention eligibility scan identifies expired datasets | ☐ | ☐ | |
| FR-BAPD-005 | PDF/XLSX reports include full approval chain | ☐ | ☐ | |
| FR-BAPD-006 | Immutable audit log for all BAPD actions | ☐ | ☐ | |

## Module 6: Data Quality

| FR | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| FR-DQ-001 | GCP BigQuery source connection validates successfully | ☐ | ☐ | |
| FR-DQ-002 | GCP connection error displays meaningful message | ☐ | ☐ | |
| FR-DQ-003 | Excel upload shows 10-row preview with type badges | ☐ | ☐ | |
| FR-DQ-004 | Async DQ generation computes all 4 dimensions per column: Completeness, Consistency (AI regex via Ollama), Uniqueness, Latency | ☐ | ☐ | |
| FR-DQ-005 | Governance review with approve/reject/revision | ☐ | ☐ | |
| FR-DQ-006 | Approved run archived to BigQuery + GCS | ☐ | ☐ | |
| FR-DQ-007 | Email notifications sent on run complete/review/result | ☐ | ☐ | |
| FR-DQ-008 | Re-run creates new version with delta comparison | ☐ | ☐ | |
| FR-DQ-009 | Consistency dimension uses the AI Setup model (`llama3.2:3b`) with the data-profile regex and data facts to generate business rules, regex, complexity and reasoning per column; falls back to rule-based pattern detection (noted in Remarks) if Ollama is unavailable or times out | ☐ | ☐ | |
| FR-DQ-010 | Uniqueness dimension only created for fully-unique columns (Total Rows == Total Unique non-null values); index = 100 for qualifying columns | ☐ | ☐ | |
| FR-DQ-011 | Latency dimension only created for datetime columns; score: 100 (≤0 days), 70 (1–7 days), 50 (8–14 days), 30 (15–30 days), 0 (>30 days old) | ☐ | ☐ | |
| FR-DQ-012 | Each dq_results row stores: data_type, business_rules, regex_pattern, regex_version, remarks (`-` when no automated note), and the run stores its version — enabling the DQ Template output format. Model, Category and Raw Text are not stored | ☐ | ☐ | |
| FR-DQ-013 | DQ detail page Score tab shows the 4 dimension slots per column; dimensions not run for a column show a blank dashed bar marked N/A (reason on hover), never 0%; Rules tab shows dimension filter chips + Data Type, Business Rules, Regex Pattern, Version, Regex Version, Complexity, Reasoning, Remarks columns with expandable text (no Model column) | ☐ | ☐ | |
| FR-DQ-022 | Data Quality page > Project Report opens the project DQ report: KPI cards combine the latest run with results of every table (checks add up to the sum of the tables), the Score tab shows each table's attribute scores with "Open run", Rules/Findings list all tables with table filter, Export includes a Table column; a table whose newest run failed uses its previous results with a note; Back returns to the same project | ☐ | ☐ | |
| FR-DQ-023 | Start Run All Data, leave the Generate step (e.g. open Metadata), return to Data Quality > the project: a banner "DQ running for this project · N files · ≈ m:ss left" is shown; View progress opens /dq/progress/<project> with the same file rows, countdown and total Time left | ☐ | ☐ | |
| FR-DQ-024 | While files are queued/running, Run All Data / Run All show View Progress; the New DQ Run Data step marks those files "Queued"/"Running now" and does not select them; a direct API call to start or re-run the same file returns 409 "already queued/running (version N)" | ☐ | ☐ | |
| FR-DQ-025 | Re-run Check on a completed run: the progress page opens; the Data Quality table keeps the previous score with its version (e.g. "91.5% v1") and a "v2 queued/running" badge until v2 finishes, then shows the v2 score; a refused re-run shows the reason as a message | ☐ | ☐ | |
| FR-DQ-020 | DQ run page, Rules tab: Export > Excel downloads a .xlsx and Export > PDF opens a printable A3 report; both contain run info, project info, the 10 KPI cards with explanations and the rules shown (all or the selected dimension) with all 14 Rules columns | ☐ | ☐ | |
| FR-DQ-018 | New DQ Run, Generate step: each file shows status, columns checked and a countdown (≈ m:ss left) plus a total time left; a failed file shows the reason, what to do and the detail; the header and final message say how many runs failed (no "completed" message when runs failed) | ☐ | ☐ | |
| FR-DQ-019 | Data step marks files missing from the uploads folder ("File missing — re-upload in Metadata") and they cannot be selected | ☐ | ☐ | |
| FR-DQ-017 | DQ run page row 1: Total Metric Checks (= passed + warning + failed + checks on blank attributes), Passed Checks (≥ 95%), Warning Checks (70–95%), Failed Checks (< 70% on real values) and Blank Attributes (columns with only blank/null/space/'NULL'/'N/A' values, as "blank / all columns", naming them); row 2: Overall Score and one card per metric (Completeness, Consistency, Uniqueness, Latency Score) showing the average score, or N/A with the reason when the metric was not run; every card has a short explanation | ☐ | ☐ | |
| FR-DQ-021 | For an attribute whose values are all blank, spaces, 'NULL', 'N/A' or empty cells, every check has status "no data" (not counted in Failed Checks; the column is counted in Blank Attributes), its Completeness rule shows the Remark "All N values are empty …", there is one finding "has no values", and the Score tab shows "No data" bars | ☐ | ☐ | |
| FR-DQ-015 | Consistency business rules match the data (allowed values, characters, length or number range); Remarks show when the model's regex was used or the data-profile regex was kept; Failed = rows not matching the regex | ☐ | ☐ | |
| FR-DQ-016 | Re-run Check on a run whose source file is missing from the uploads folder shows "re-upload it in Metadata, then start a new DQ run" and creates no run | ☐ | ☐ | |
| FR-DQ-014 | DQ new-run wizard offers "From Project Files" source type; step 2 lists files already imported via the Metadata module for the selected project; selected file is read directly from stored_path (no re-upload); `dq_runs.source_file_id` FK records the linkage | ☐ | ☐ | |

## Module 7: Metadata Management + AI

| FR | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| FR-META-001 | Source table discovery shows documented/undocumented status | ☐ | ☐ | |
| FR-META-002 to 010 | Core attribute auto-population (seq_no, table, project, steward, owner, attribute) | ☐ | ☐ | |
| FR-META-011 | PII keyword detection → Highly Confidential | ☐ | ☐ | |
| FR-META-012 | Bulk grouping applies to all columns in table | ☐ | ☐ | |
| FR-META-013 | Business term auto-expansion from abbreviation map; abbreviations (Indonesian/English) in UPPERCASE: `nik` → NIK, `amount_idr` → Amount IDR, `no_ktp` → Number KTP | ☐ | ☐ | |
| FR-META-029 | Generate AI Definitions on a project with 30+ attributes (local llama3.2) runs through all batches without "HTTP 504" | ☐ | ☐ | |
| FR-META-031 | Metadata attributes grid: a long Business Definition, Standard Format or Sample shows "… more" and expands/collapses on click (as Business Rules/Reasoning on the DQ Rules tab); long table names wrap over several lines instead of "…" | ☐ | ☐ | |
| FR-META-030 | While Generate AI Definitions runs, a panel shows "x / y definitions generated", elapsed time, a progress bar and "Time left ≈ m:ss" counting down; the estimate is corrected after the first batch; the panel disappears when all are done (also with a single table selected) | ☐ | ☐ | |
| FR-META-014 | Ollama AI generates business definitions per row | ☐ | ☐ | |
| FR-META-015 | is_primary_key derived from sample data (all non-null values are unique → PK candidate) | ☐ | ☐ | |
| FR-META-016 | is_nullable derived from sample data (any null or blank value present → nullable) | ☐ | ☐ | |
| FR-META-017 | sample_data shows first non-null value or "(All Blank)" | ☐ | ☐ | |
| FR-META-018 | data_type correctly inferred from schema or sample values | ☐ | ☐ | |
| FR-META-019 | updated_date and updated_by stamped per row on save | ☐ | ☐ | |
| FR-META-020 | data_level defaults to Raw, overridable | ☐ | ☐ | |
| FR-META-021 | Batch save persists all pending edits atomically | ☐ | ☐ | |
| FR-META-022 | Data Owner & Steward management (5 role types) | ☐ | ☐ | |
| FR-META-023 | Standard Format combobox shows grouped options (Boolean / Categorical / Date & Time / Contact / Numeric / Identifier / Text) with free-text fallback | ☐ | ☐ | |
| FR-META-024 | Selecting Category from combobox auto-fills with stored distinct values for that attribute | ☐ | ☐ | |
| FR-META-025 | Editing Table Type, Data Year, Grouping, or Level on one row propagates the same value to all other attributes in the same table | ☐ | ☐ | |
| FR-META-026 | distinct_values stored for all Category/Boolean columns and for any column with ≤ 25 unique non-null values | ☐ | ☐ | |
| FR-META-027 | Saving standard_format as Category auto-derives distinct_values from the format string; Boolean derives sorted values; other formats preserve existing distinct_values | ☐ | ☐ | |
| FR-META-028 | Boolean standard_format label is specific to data (Yes / No, True / False, 1 / 0, Y / N, T / F) not generic | ☐ | ☐ | |

## Cross-Cutting Requirements

| NFR | Description | Pass | Fail | Notes |
|-----|-------------|------|------|-------|
| NFR-001 | Page load < 3 seconds (desktop, good connection) | ☐ | ☐ | |
| NFR-004 | HTTPS enforced, rate limiting on login (5 attempts/10min/IP) | ☐ | ☐ | |
| NFR-005 | 403 returned for insufficient permissions | ☐ | ☐ | |
| NFR-006 | Audit log rows cannot be modified or deleted | ☐ | ☐ | |
| NFR-008 | PDF export < 30s for up to 10,000 rows | ☐ | ☐ | |
| NFR-010 | Email notifications delivered within 5 minutes | ☐ | ☐ | |
| NFR-012 | Responsive layout on tablet and mobile | ☐ | ☐ | |
| NFR-013 | After `docker compose restart api` (or recreating api/frontend), without restarting nginx: Metadata Excel upload of TEST01–03 via http://localhost works once the API is healthy | ☐ | ☐ | |
| NFR-014 | While the API is stopped, an upload or login shows "HTTP 502 · Server not reachable … try again" (not "Unexpected token '<'" or "verify credentials"); a file above 25 MB shows "HTTP 413 · File too large …"; every HTTP error shown has the code, a short cause and what to do | ☐ | ☐ | |

---

**Sign-off:**  
DGO Lead: _________________ Date: _________  
Compliance Officer: _________________ Date: _________  
Tech Lead: _________________ Date: _________
