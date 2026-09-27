# Data Quality Reference Method Handoff

Last updated: 2026-09-27

## Purpose

The Data Quality module is now project-based. Users should run DQ from data that has already been imported, uploaded, or connected through the Metadata module. This avoids duplicate uploads and keeps DQ aligned with the project governance workflow.

The backend integrates the provided Existing Data Quality reference method through `backend/app/services/reference_dq.py`. The integration preserves the reference rule generation, regex generation, consistency index, uniqueness rule, latency scoring, sampling approach, and model sequence. Telegram, hard-coded notification tokens, and external upload concerns from the reference folder are intentionally ignored.

## User Flow

1. User opens Data Quality.
2. User selects a project.
3. The page shows Metadata source tables/files for that project.
4. User starts `New Project DQ Run` or `Run All Project Data`.
5. New DQ Run follows this wizard:
   - Project
   - Data
   - Preview
   - Generate
   - Results
   - Archive
6. All project files are selected by default after project selection.
7. Each selected file creates a separate `dq_runs` record.

## Active Code Paths

| Area | Path |
|------|------|
| Reference method service | `backend/app/services/reference_dq.py` |
| Celery worker integration | `backend/app/worker/tasks/dq.py` |
| DQ overview page | `frontend/src/app/(dashboard)/dq/page.tsx` |
| New DQ Run wizard | `frontend/src/app/(dashboard)/dq/new/page.tsx` |
| DQ run detail page | `frontend/src/app/(dashboard)/dq/[id]/page.tsx` |
| Project DQ report page | `frontend/src/app/(dashboard)/dq/project/[projectId]/page.tsx` (API `GET /dq/project/{id}/report`) |
| Shared report parts (cards, bars, rules table) | `frontend/src/components/dq/DQReportParts.tsx`, export in `frontend/src/lib/dqExport.ts` |
| Project source file tracking | `project_source_files` table |
| DQ run storage | `dq_runs`, `dq_results`, `dq_findings` tables |

## Model Requirements

Since 2026-09-27 DQ uses the same local model as Metadata: `llama3.2:3b` (about 2 GB). The template's `qwen2.5-coder:32b` + `llama3.1:70b` sequence is too heavy for local CPU computation and is no longer required.

| Use | Default model | Override |
|-----|---------------|----------|
| Primary generation | Settings > AI Setup model (`llama3.2:3b`) | `DQ_PRIMARY_MODEL` |
| Repair pass (index below 70) | same as primary | `DQ_SECONDARY_MODEL` |

The endpoint is resolved in this order:

| Setting | Resolution order |
|---------|------------------|
| Base URL | `DQ_OLLAMA_BASE_URL`, then Settings > AI Setup `base_url`, then `http://ollama:11434` |
| Timeout | `DQ_OLLAMA_TIMEOUT_SECONDS`, then Settings > AI Setup `timeout_seconds` (minimum 300 s for DQ), then `300` |
| API key | Settings > AI Setup encrypted API key, then `DQ_OLLAMA_API_KEY`, then no key |

Local install commands:

```bash
docker compose -f docker-compose.yml up -d ollama
docker compose -f docker-compose.yml exec -T ollama ollama pull llama3.2:3b
docker compose -f docker-compose.yml exec -T ollama ollama list
```

A stronger model (for example on a GPU server or an Ollama-compatible cloud endpoint) can be used by setting `DQ_PRIMARY_MODEL` / `DQ_SECONDARY_MODEL`; the method below works with any model.

If the model is missing, the Generate step can create file runs but mark them failed after Ollama returns a `/api/generate` 404. If Ollama is unreachable, the worker falls back to rule-based format regexes and says so in Remarks.

## Hybrid Rule Generation (llama3.2:3b)

A 3B model writes good business-rule text but is unreliable at regex syntax (with the template prompt it produced accept-all alternations and invented rules, about 4 minutes per column). The generation therefore splits the work:

1. **Data-profile regex (deterministic).** `profile_regex()` in `reference_dq.py` turns every value into a shape (digits, upper/lower letters, literal separators) and builds the regex from the shapes covering at least 95% of rows, in the same style as the qwen answers in the HSO Splash rules index: fixed prefixes (`^BPS_\d{3}$`), fixed lengths (`^[A-Z]{3} [A-Z]{3}$`), word lists (`^[A-Z]+( [A-Z]+)*$`), enumerations (`^(KAB\.|KOTA) [A-Z]+( [A-Z]+)*$`), small integer sets (`^[01]$`), unlimited decimals (`^-?\d+(\.\d+)?$`) and e-mail. Rare shapes are flagged by the regex instead of being absorbed into it.
2. **Data facts.** `data_facts()` describes the same dominant rows in plain words: structure (`1 to 2 upper-case letters, then a space, then 3 to 4 digits, ...`), the distinct values when there are 10 or fewer, number range, negatives, decimal places, capitalisation, length and characters used. A 3B model misreads regex syntax when asked to explain it (for example `^[135]$` as "three digits"), so the rules are written from these facts.
3. **Model prompt.** The model gets the column name, type, up to 20 samples (shortest, longest and every character class represented), the data facts and the profile regex. It writes Business Rules (a. structure or allowed values, b. allowed characters, c. length, range or decimals) from the facts only, Complexity and Reasoning, and may correct the regex. Ollama options: `temperature 0`, `num_ctx 4096`, `num_predict 400`.
4. **Best regex kept.** The model regex and the profile regex are scored on the weighted index; the better one is stored. Remarks record the decision (`Regex corrected by …` or `… suggested …; data-profile regex kept`).
5. **Repair pass.** When the index is still below 70, the model is called again with its regex, the non-matching values and matching examples. The repaired regex replaces the first one only if it scores higher; Remarks record both scores.

Trade-off: values with a rare shape (under 5% of rows, e.g. 1-2 digit plate numbers) score as non-matching. This is intended: DQ should flag them for review.

Speed on CPU (no GPU): about 35-150 s per column (average about 65 s), about 60 s extra on the first call while the model loads.

### Benchmark against the qwen rules index (2026-09-27)

18 test columns: 15 columns named after the HSO Splash rules index (qwen2.5-coder:32b output) with generated test values that fit them, plus e-mail, phone number and plate number. The HSO Excel holds qwen's rules and regexes, not the source data, so the values were generated. Index = weighted regex match on the column; rejection = share of deliberately wrong values (lower case, missing parts, wrong separators, `N/A`) that the regex rejects.

| | llama3.2:3b hybrid | qwen2.5-coder:32b (HSO Splash) |
|---|---|---|
| Mean consistency index | 99.9 (all 18) / 100.0 (15 HSO columns) | 88.9 (15 HSO columns) |
| Wrong values rejected | 100% | 100% |
| Columns at 100 | 17 of 18 | 13 of 15 |
| Weak columns | `plat_nomor` 98.3 (rare 1-2 digit plates flagged, intended) | `market_share_region_mtd` 0, `pertumbuhan_ekonomi_pct` 33.3 |
| Total time | 19.7 min for 18 columns | not measured locally |

### Validation on real HSO sample data (2026-09-27)

`20260908_HSO_SalesPlanningTools_Phase4_SampleData.xlsx` (local only, in `DQ Template (Local Only)/`) holds up to 5 real sample values for each of the 1,734 columns in the HSO Splash rules index (22 tables). 1,685 columns have at least 2 samples. The data-profile regex was checked against them without a model call:

| Type (columns) | Result |
|---|---|
| FLOAT64 (1,348) | The profile regex has no digit/decimal cap, so it accepts every real value. qwen's regex rejects real samples in 87 columns because it caps decimals (`\.\d{1,2}`) while BigQuery floats look like `51973.00000000004`; qwen's full-data index on FLOAT64 is 78.9 |
| INT64 (239) | 190 regexes identical to qwen (`^[01]$`, `^[135]$`, `^\d+$`); the rest differ only because 5 samples show fewer distinct values than the full column |
| STRING (77) | Leave-one-out (regex from 4 samples must accept the 5th) 92.9%; misses come from 5-sample limits (a `KOTA` row seen once) |
| TIMESTAMP / DATETIME (21) | The profile regex follows the real rendering; qwen's DATETIME regex expects `T...` and scores 0 on the full data |

Changes made from this check: words longer than 4 letters get `+` instead of a fixed length (`^[A-Z]+( [A-Z]+)*$` for names such as `KALIMANTAN TIMUR`), short lists of one-word categories with different shapes are enumerated like qwen (`^(-|AVG|MAX|Other|SUM)$`; place names such as `KAB. BLORA` keep a shape), free-text character classes list each range once, and integers are enumerated only when they are small codes (never amounts such as `76, 99, 175`).

Full llama3.2 pipeline on 10 real HSO columns (kota_kab, registration, main_dealer, Aggregation_region, provinsi, group_model, gen_x, cat_padi, hari_penting, period): index 100 on all 10, about 40-120 s per column, 6 regexes identical or equivalent to qwen. llama3.2's rules state measured facts; several qwen rules for the same columns were not supported by the data (`gen_x` "sales figures in dollars, should not exceed 400,000"; `kota_kab` "name without spaces"; `period` "time must be 00:00:00").

Business-rule text was reviewed by hand against the true values. Without data facts the model misread regexes (`^[135]$` as "three digits", invented "starts with A or B" for plates); with data facts all 18 rule sets matched the data. A data steward should still review the rules on real project data.

## Generate Step: Progress, Time Estimate and Failure Reasons

The worker runs one DQ file at a time (`--concurrency=1`), so a batch is a queue, not parallel work.

| Item | How it works |
|------|--------------|
| Progress | `run_reference_dq_for_dataframe(..., on_column_done)` reports each finished column; the worker stores `dq_runs.columns_done` / `columns_total` (the total is read from the Excel header when the run is created) |
| Time estimate | `GET /dq/{id}/status` returns `eta_seconds`: for a running file, all columns x the speed so far minus the time already spent, where the speed so far is blended with the usual 65 s per column (weight of 2 columns) so the slow first column, which includes loading the model, does not swing the estimate; before the first column finishes it is columns x 65 s + 60 s model load; for a queued file, the time left of every file queued ahead in the last 24 h plus its own columns x 65 s. The page counts down every second between polls |
| Failure reason | The worker maps the exception to a category (`backend/app/services/dq_failures.py`) and stores `error_category` + `error_message`. The status endpoint adds the title, explanation and next step |
| Retry | Only temporary problems are retried (2 retries, 60 s apart; the run shows "retrying automatically" meanwhile): AI service not reachable, too slow, or returning an error, and database busy. Everything else fails at once |
| Missing files | `/dq/project/{id}/sources` returns `file_available`; the Data step disables missing files, and `POST /dq` refuses them with a 400 |

| Category | Shown as | Typical cause | What the user is told to do |
|----------|----------|---------------|-----------------------------|
| `source_file_missing` | Source file not found | Uploaded file no longer in the uploads folder (never uploaded on this machine, or deleted when the retention period ended: project end date + 30 days, or + the approved ROPA retention period) | Re-upload the file in Metadata, then start a new DQ run. Files of shared test projects come back automatically from `backend/shared_uploads/` on API start |
| `file_unreadable` | File could not be read | Corrupted, password-protected or not `.xlsx` | Save it again as `.xlsx` without a password and re-upload |
| `empty_data` | No data found | No header or no data rows | Put a header row and data on the first sheet |
| `ai_model_missing` | AI model not installed | Ollama returns 404 for the model | `ollama pull llama3.2:3b` or pick an installed model in AI Setup |
| `ai_auth` | AI service refused the request | 401/403 from a cloud endpoint | Check the API key in AI Setup |
| `ai_unreachable` | AI service not reachable | `ollama` container stopped or wrong base URL | Start Ollama or fix the base URL (retried) |
| `ai_timeout` | AI service too slow | Model busy / computer overloaded | Close heavy programs or raise the timeout (retried) |
| `ai_error` | AI service error | Other HTTP error from Ollama | Run again; check the Ollama log (retried) |
| `database_busy` | Database busy | SQLite locked by another save | Run again in a moment (retried) |
| `bigquery_error` | BigQuery read failed | Wrong table name or no access | Check names and service-account access |
| `unsupported_source` | Unsupported data source | Run created without a readable source | Start a new run from Metadata files |
| `unexpected` | Unexpected error | Anything else | Run again; send the run ID and detail to the tech team |

Runs that failed before 2026-09-27 have no stored category: the status endpoint reports "Source file not found" when their file is missing, otherwise "Unexpected error — reason not recorded".

## Python Dependencies

These backend packages are required by the reference DQ service and are declared in `backend/requirements.txt`:

| Package | Version |
|---------|---------|
| `pandas` | `2.2.2` |
| `numpy` | `1.26.4` |
| `regex` | `2024.5.15` |

Host installation is not required for Docker development. Rebuild `api` and `worker` after dependency changes:

```bash
docker compose -f docker-compose.yml build api worker
docker compose -f docker-compose.yml up -d --force-recreate api worker
```

## DQ Dimensions

| Dimension | Method |
|-----------|--------|
| Completeness | Calculates non-null percentage and uses the rule `There should be no empty field for <column> in this table`. |
| Consistency | Generates business rules and a Python-compatible anchored regex, applies it to value counts, and stores the weighted match percentage as the index. |
| Uniqueness | Created only when total rows equals total unique values and both are non-zero; index is `100`. |
| Latency | Created for date-like columns; scores latest date as 100, 70, 50, 30, or 0 based on recency. |

The repair pass (secondary model) runs only for columns where the first consistency index is below `70`. The better consistency result is kept.

## Result Mapping

The reference output is mapped into the existing DQ schema:

| Reference output | Application field |
|------------------|-------------------|
| `DQ Dimension` | `dq_results.check_type` |
| `Index` | `dq_results.actual_value` |
| `Business Rules` | `dq_results.business_rules` |
| `RegEx Pattern` | `dq_results.regex_pattern` |
| `Column Type` | `dq_results.data_type` |
| `Regex Version` | `dq_results.regex_version` |
| Run number per project dataset | `dq_runs.version` |
| Notes collected during generation | `dq_results.remarks` (`-` when none) |
| `Total Rows` | `dq_results.row_count` |
| Failed rows | `dq_results.failed_count`: Completeness = empty rows; Consistency = rows not matching the regex (`rows x (100 - index) / 100`, empty rows included as in the template); Uniqueness / Latency = `1` when the index is below 70, else `0` |
| `Complexity` | `dq_results.details.complexity` |
| `Reasoning` | `dq_results.details.reasoning` |

`Model`, `Category` and the raw model response (`Raw Text`) are not stored: they are not used in the real rules index (removed 2026-09-25).

Findings are created when a reference index is below `70`.

## Database Notes

No schema change is required for this integration. The existing `dq_results` AI fields and the JSON `details` column can store the reference method output.

Do not export the bundled SQLite database (`export-sqlite.ps1`) from a local database containing failed model-availability test runs unless the team intentionally wants those failed records in the baseline dataset.

## Validation Status

Completed locally:

- API and worker Docker images built successfully after dependency changes.
- `reference_dq.py` and `dq.py` compiled successfully with `python -m py_compile`.
- Frontend Docker build completed successfully after DQ UI changes.
- DQ overview and New DQ Run pages returned HTTP 200 through `http://localhost`.

- 2026-09-27, `llama3.2:3b`: real end-to-end run through the API and Celery worker on `PRJ002_Credit_Profile.xlsx` (40 rows, 11 columns, 4 empty rows): status completed, Version 2 then 3 on re-run, 23 rules (11 Completeness, 11 Consistency, 1 Latency), every Rules tab field filled (Data Type, Business Rules, Regex Pattern, Version, Regex Version, Complexity, Reasoning, Remarks, Rows, Failed). About 1 minute per column. The test runs were removed afterwards (database restored from a snapshot).
- Backend tests: 147 passed; the 3 failures are the known `test_ai_generation.py` items (open item 11).

Known limits:

- Consistency counts empty rows as non-matching (template behaviour), so a column with 10% empty rows scores at most 90 on Consistency as well as Completeness.
- The 3B model sometimes simplifies a rule despite the facts (seen once: "only upper-case letters" for `Auto`, `Mortgage`, `Personal`). Scores and regexes are not affected; a data steward should review the rule text.

## Developer Rules

- Do not add Telegram logic to the application integration.
- Do not make the DQ wizard source-type-first again unless the project governance workflow changes.
- Do not replace the reference DQ method with a simplified fallback without explicit team approval.
- Keep README, `development.config.yml`, and this file updated when model names, prompt behavior, sampling, scoring, or result mapping changes.
