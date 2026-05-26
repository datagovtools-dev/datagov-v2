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
| FR-DQ-009 | Consistency dimension calls Ollama to generate a regex pattern and business rules per column; falls back to rule-based pattern detection if Ollama unavailable or times out | ☐ | ☐ | |
| FR-DQ-010 | Uniqueness dimension only created for fully-unique columns (Total Rows == Total Unique non-null values); index = 100 for qualifying columns | ☐ | ☐ | |
| FR-DQ-011 | Latency dimension only created for datetime columns; score: 100 (≤0 days), 70 (1–7 days), 50 (8–14 days), 30 (15–30 days), 0 (>30 days old) | ☐ | ☐ | |
| FR-DQ-012 | Each dq_results row stores: business_rules, regex_pattern, ai_model, regex_version — enabling the DQ Template output format; column_category is reserved (NULL) for future automated category classification | ☐ | ☐ | |
| FR-DQ-013 | DQ detail page Score tab shows dynamic dimension bars per column (1–4 bars); Rules tab shows dimension filter chips + Business Rules, Regex Pattern, AI Model columns with expandable text | ☐ | ☐ | |
| FR-DQ-014 | DQ new-run wizard offers "From Project Files" source type; step 2 lists files already imported via the Metadata module for the selected project; selected file is read directly from stored_path (no re-upload); `dq_runs.source_file_id` FK records the linkage | ☐ | ☐ | |

## Module 7: Metadata Management + AI

| FR | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| FR-META-001 | Source table discovery shows documented/undocumented status | ☐ | ☐ | |
| FR-META-002 to 010 | Core attribute auto-population (seq_no, table, project, steward, owner, attribute) | ☐ | ☐ | |
| FR-META-011 | PII keyword detection → Highly Confidential | ☐ | ☐ | |
| FR-META-012 | Bulk grouping applies to all columns in table | ☐ | ☐ | |
| FR-META-013 | Business term auto-expansion from abbreviation map | ☐ | ☐ | |
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

---

**Sign-off:**  
DGO Lead: _________________ Date: _________  
Compliance Officer: _________________ Date: _________  
Tech Lead: _________________ Date: _________
