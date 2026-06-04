# Data Quality Reference Method Handoff

Last updated: 2026-06-04

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
| Project source file tracking | `project_source_files` table |
| DQ run storage | `dq_runs`, `dq_results`, `dq_findings` tables |

## Model Requirements

The reference method does not use the Metadata default model. It uses this DQ-specific sequence:

| Use | Default model | Override |
|-----|---------------|----------|
| Primary generation | `qwen2.5-coder:32b` | `DQ_PRIMARY_MODEL` |
| Secondary recheck | `llama3.1:70b` | `DQ_SECONDARY_MODEL` |

The endpoint is resolved in this order:

| Setting | Resolution order |
|---------|------------------|
| Base URL | `DQ_OLLAMA_BASE_URL`, then Settings > AI Setup `base_url`, then `http://ollama:11434` |
| Timeout | `DQ_OLLAMA_TIMEOUT_SECONDS`, then Settings > AI Setup `timeout_seconds`, then `120` |
| API key | Settings > AI Setup encrypted API key, then `DQ_OLLAMA_API_KEY`, then no key |

Local install commands:

```bash
docker compose -f docker-compose.yml up -d ollama
docker compose -f docker-compose.yml exec -T ollama ollama pull qwen2.5-coder:32b
docker compose -f docker-compose.yml exec -T ollama ollama pull llama3.1:70b
docker compose -f docker-compose.yml exec -T ollama ollama list
```

These models are large. If local storage, memory, or GPU capacity is not enough, configure an Ollama-compatible cloud endpoint and set the DQ override variables if the cloud model names differ.

If a required model is missing, the Generate step can create file runs but mark them failed after Ollama returns a `/api/generate` 404.

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

The secondary model is used only for columns where the first consistency index is below `70`. The better consistency result is kept.

## Result Mapping

The reference output is mapped into the existing DQ schema:

| Reference output | Application field |
|------------------|-------------------|
| `DQ Dimension` | `dq_results.check_type` |
| `Index` | `dq_results.actual_value` |
| `Business Rules` | `dq_results.business_rules` |
| `RegEx Pattern` | `dq_results.regex_pattern` |
| `Model` | `dq_results.ai_model` |
| `Regex Version` | `dq_results.regex_version` |
| `Complexity` | `dq_results.details.complexity` |
| `Reasoning` | `dq_results.details.reasoning` |
| Raw model response | `dq_results.details.raw_text` |

Findings are created when a reference index is below `70`.

## Database Notes

No new migration is required for this integration. The existing `dq_results` AI fields and JSONB `details` column can store the reference method output.

Do not refresh `database/ag_db_dump.sql` from a local database containing failed model-availability test runs unless the team intentionally wants those failed records in the baseline dump.

## Validation Status

Completed locally:

- API and worker Docker images built successfully after dependency changes.
- `reference_dq.py` and `dq.py` compiled successfully with `python -m py_compile`.
- Frontend Docker build completed successfully after DQ UI changes.
- DQ overview and New DQ Run pages returned HTTP 200 through `http://localhost`.

Blocked locally:

- Full PRJ-001 success could not be validated because `qwen2.5-coder:32b` and `llama3.1:70b` are not installed locally and local storage may be insufficient.
- Observed failure mode: all selected project files can fail during Generate when Ollama returns 404 for missing models.

## Developer Rules

- Do not add Telegram logic to the application integration.
- Do not make the DQ wizard source-type-first again unless the project governance workflow changes.
- Do not replace the reference DQ method with a simplified fallback without explicit team approval.
- Keep README, `development.config.yml`, and this file updated when model names, prompt behavior, sampling, scoring, or result mapping changes.
