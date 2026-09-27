# Dummy Test Project: end-to-end UI test

Created 2026-09-27. All names, IDs, e-mails and numbers are fictitious. Use this project to check Project, Metadata, DSR, AI Checklist (AICK), DPIA and Data Quality in one flow.

Files in this folder:

| File | Rows × columns | Used for |
|---|---|---|
| `TEST01_Customer_Master.xlsx` (sheet `customers`) | 200 × 11 | Metadata (personal data), DQ |
| `TEST02_Transactions.xlsx` (sheet `transactions`) | 600 × 9 | Metadata, DQ, DSR 2 |
| `TEST03_Churn_Features.xlsx` (sheet `features`) | 200 × 10 | Metadata, DQ, DSR 1 (AI use) |
| `TEST04_Header_Only.xlsx` (sheet `empty`) | 0 × 2 | Optional failure test |

---

## Step 1: Create the project (Projects > New Project)

| Field | Value |
|---|---|
| Project ID / Code | assigned by the system (expect the next `PRJ-2026-NNN`) |
| Project / Asset Name | Retail Customer Churn Prediction |
| Customer / Client Name | PT Nusantara Retail Digital (Dummy) |
| Line of Business | Retail & Consumer Analytics |
| Project Category | AI / ML |
| Project Year | 2026 |
| Monetization Status | Internal Governance |
| Start Date | 2026-10-01 |
| End Date | 2027-03-31 |
| Use Case & Governance Description | Predict which retail customers are likely to stop shopping in the next 90 days, so the CRM team can send retention offers. Data: customer master, 6 months of store and online transactions, and engineered churn features. Personal data (name, NIK, e-mail, phone, birth date) is pseudonymised before modelling; only the project team gets access. |

Delivery & Governance Team (pick the existing users):

| Role | User |
|---|---|
| Subject Matter Expert (SME) | Dewi Rahayu |
| Delivery Manager | Ahmad Fauzi |
| Project Manager | Bagas Adi Nugraha |
| Data Governance Officer (DGO) | Anisa Putri |
| Metadata Officer | Diah Ayu Ningrum |
| Data Quality Officer (DQO) | Dani Wahyudi |
| PIC Data Compliance | Budi Santoso |

Accountable Stewardship & Ownership:

| Role | Full Name | Email |
|---|---|---|
| Lead Business Steward | Rizky Pramono | rizky.pramono@nusantararetail.example |
| Data Owner | Sri Handayani | sri.handayani@nusantararetail.example |

Check: the Project ID is assigned automatically in the `PRJ-2026-NNN` format and cannot be typed.

---

## Step 2: Metadata (Metadata > select the project > import files)

1. Import `TEST01_Customer_Master.xlsx`, `TEST02_Transactions.xlsx` and `TEST03_Churn_Features.xlsx` (Excel source).
2. Expect 3 tables: `… - customers` (11 attributes), `… - transactions` (9), `… - features` (10) = 30 attributes.
3. Run **Generate AI Definitions** (llama3.2:3b).

Check:
- Sensitivity: `full_name`, `nik`, `email`, `phone`, `gender`, `birth_date` should be flagged as personal/sensitive (their names match the PII keyword list).
- Every attribute gets a business definition; data type and sample values are filled.
- The project info strip at the top shows the project, Data Steward and Data Owner.

Optional: try importing `TEST04_Header_Only.xlsx`. Metadata may refuse a file without data rows; if it accepts it, keep it for the DQ failure test in Step 6.

---

## Step 3: DSR 1, AI use (DSR > New)

| Field | Value |
|---|---|
| Source Project | Retail Customer Churn Prediction |
| Dataset Name | Churn Features (Pseudonymised) |
| Recipient Organisation | PT Analitika Data Mandiri (Dummy) |
| Purpose & Legal Justification | Share the pseudonymised churn feature table (TEST03) with the external data-science vendor to train and validate the churn prediction model. Legal basis: legitimate interest and customer consent for service improvement in the membership terms. Controls: no direct identifiers, access for the named vendor team only, data deleted when the project ends. |
| Sharing Start Date | 2026-10-05 |
| Sharing End Date | 2027-03-31 |
| "This dataset will be consumed for AI / Machine Learning workflows" | ✅ ticked |

Check: an **AI Checklist (AICK)** is created automatically. Open it from AI Checklist and fill in the items, then submit it for approval.

### DSR 1: Data & Insights Sharing Evaluation Checklist (on the DSR page)

Every item needs a Yes/No answer and a remark. For A and C, "No" is the good answer.

| # | Question | Answer | Remarks |
|---|---|---|---|
| A.i.1 | Loss in revenue due to cannibalization | No | Features are used only to build our own churn model; the vendor may not sell or reuse the data or the model. |
| A.i.2 | Damage to relationship with customers | No | Only pseudonymised features are shared; customers are not contacted by the vendor. Retention offers stay with our CRM team. |
| A.i.3 | Other commercial interest(s) | No | No pricing, margin or supplier terms in the dataset. |
| A.ii.1 | Highly confidential partnerships | No | Dataset holds customer behaviour features only; no partner or contract data. |
| A.ii.2 | Patent information | No | No product design or patent information included. |
| A.ii.3 | M&A deals | No | Not related to any merger or acquisition. |
| A.ii.4 | Other commercial secret(s) | No | Store-level revenue and strategy are not included; spend is per customer and pseudonymised. |
| B.i | Are the data & insights requested sensitive? | No | No religion, health, physical/mental condition, sexual life or bank/credit data. Features: tenure, monthly spend, visits, complaints, churn flag/score. |
| B.ii | Mitigation steps if sensitive data is used? | Yes | customer_id is replaced by a hashed key; name, NIK, e-mail, phone and birth date are removed before sharing; the key table stays with the Data Owner. |
| B.iii | Is it personal data? | Yes | Pseudonymised data is still personal data under UU No. 27/2022 (PDP) because the BU can re-link it with the key table. |
| B.iv | Written consent for sharing obtained? | Yes | Membership terms clause 7.2 allow sharing with appointed processors; the vendor signed a data processing agreement (DPA-2026-014, dummy). |
| B.v | Written consent for research/use case development obtained? | Yes | Membership consent covers analytics for service improvement; customers who withdrew consent are excluded before extraction. |
| B.vi | Processing within the BU analytics environment with limited access? | Yes | Vendor works inside the BU analytics workspace (no download), 4 named vendor accounts, access ends 2027-03-31. |
| C.i.1 | Industry-specific laws violated? | No | Retail sector: no sector-specific restriction on sharing pseudonymised behaviour data with a processor. |
| C.i.2 | Data protection laws violated? | No | UU PDP: legal basis (consent/legitimate interest), processor agreement, pseudonymisation and DPIA in place. |
| C.i.3 | Internal regulations and policies violated? | No | Follows the Group Data Sharing Policy: DSR approval, DPIA, RBAC and extermination (BAPD) at project end. |
| D.i | Is the analysis carried out using AI technology? | Yes | The vendor trains a gradient-boosting churn model on the features; the AI Checklist (AICK) is completed and a fairness review is done before go-live. |

Sign-off:

| Field | Value |
|---|---|
| Approved? | Yes |
| Prepared By (client representative) | Sri Handayani / CRM Department Head: auto-filled from the project's Data Owner and Position (set it under Data Assets Catalog → Edit → Data Owner → Position); signs at the "Client Sign Off" step |
| Acknowledged By (internal project SME) | Dewi Rahayu / Head of Business Analytics: auto-filled from the project SME and her company position; signs at the "SME Sign Off" step |
| Remarks | Approved with conditions: (1) share only the pseudonymised feature table (hashed customer_id, no name, NIK, e-mail, phone or birth date); (2) vendor works only inside the BU analytics workspace, 4 named accounts, no download; (3) access ends 2027-03-31, then the data is deleted and a BAPD extermination record is created; (4) AICK and model fairness review must be completed before go-live. Ref: DPIA for PRJ-2026-022, DPA-2026-014 (dummy). |

### AICK for DSR 1 (AI/ML Checklist > AICK-2026-0007): Gen AI Usage Assessment

Context: the project uses two approved Gen AI tools: the platform's local **llama3.2** (on-premise Ollama) to draft Metadata definitions and DQ rules, and **GitHub Copilot Business** to assist with the churn-model code. The churn model itself is a classic ML model (gradient boosting) trained by the vendor.

| Area | Item | Status | Remarks |
|---|---|---|---|
| Before Use | Complied with legal regulations and internal policies | Yes | Team completed the Group Gen AI policy training (Sep 2026); use case reviewed against UU PDP and the Group AI Guideline; DPIA completed. |
| Before Use | Gen AI platform properly licensed and approved by management | Yes | llama3.2 runs on the company's own Ollama server (open licence, approved by IT, 2026-09-25); GitHub Copilot Business licensed under the Group enterprise agreement. |
| Before Use | History disabled and opted out of model training | Yes | Local llama3.2 keeps no chat history and sends nothing outside the company; Copilot Business: prompt/code retention and training use disabled at organisation level. |
| Input | No personal, sensitive or IP data in prompts | Yes | Prompts contain only column names, data types and masked sample values; no names, NIK, e-mails or phone numbers. |
| Input | Anonymisation, pseudonymisation or dummy data used | Yes | Exploration uses pseudonymised features (hashed customer_id) and the dummy test files TEST01–TEST03. |
| Input | Prompts free of bias/harmful narratives and documented | Yes | Prompt templates are stored in the repository (reference_dq.py, metadata prompt) and reviewed by the DGO; no customer-group labels used. |
| Output | Results verified for accuracy, hallucination and bias | Yes | Every AI-generated definition and DQ rule is reviewed by the Metadata Officer / DQ Officer before approval; the DQ regex is scored against the real data. |
| Output | AI-generated source code validated before use | Yes | Copilot suggestions go through pull-request review by a senior engineer, unit tests and a security scan before merging. |
| Utilization | Outputs used only after review and approval by an authorised user | Yes | Metadata and DQ results pass the approval workflow (DGO / Data Owner) before publication; model results go to the CRM team after the fairness review. |
| Utilization | Inaccurate or inappropriate results corrected before distribution | Yes | Rejected definitions and rules are regenerated or corrected by hand; outputs are labelled "need review" until approved. |

Sign-off (names and positions are auto-filled from the project):

| Field | Value |
|---|---|
| Approved? | Yes |
| Prepared By | Ahmad Fauzi / Delivery Manager: signs at the "DM Sign-off" step |
| Acknowledged By | Dewi Rahayu / Head of Business Analytics: signs at the "SME Sign-off" step |

Approval flow: PIC Data Compliance Approval (Budi Santoso) → DM Sign-off (Ahmad Fauzi) → SME Sign-off (Dewi Rahayu).

Tip for a negative test: set "History disabled and opted out of model training" to **No** with the remark "Copilot organisation policy not yet applied; pending IT ticket", then check how the reviewers see it.

## Step 4: DSR 2, no AI use

| Field | Value |
|---|---|
| Source Project | Retail Customer Churn Prediction |
| Dataset Name | Store Transactions Sep 2026 |
| Recipient Organisation | KAP Audit Sejahtera (Dummy) |
| Purpose & Legal Justification | Provide September 2026 store and online transactions (TEST02) to the external auditor for the quarterly revenue audit. Legal basis: legal obligation (financial audit). Customer IDs only, no names or contact details. |
| Sharing Start Date | 2026-10-10 |
| Sharing End Date | 2026-11-30 |
| AI / ML checkbox | ☐ not ticked |

Check: no AI Checklist is created for this DSR. Walk both DSRs through the approval flow (dual approval).

DSR 2 checklist: section D does not appear (no AI use). Use the DSR 1 answers with these changes:

| # | Answer | Remarks |
|---|---|---|
| B.i | No | Transaction ID, date, amount, payment method, store, channel, status; no sensitive categories. |
| B.ii | Yes | Only customer_id (pseudonymised key) is included; no name, NIK, e-mail or phone. |
| B.iii | Yes | Transactions linked to a customer key are personal data under UU PDP. |
| B.iv | Yes | Sharing with the statutory auditor is required by law (legal obligation); no extra consent needed. |
| B.v | No | Not used for use case development or research, only for the financial audit. |
| B.vi | Yes | Auditor reviews the data in the BU audit room / read-only share, 2 named auditors. |
| C.i.1–3 | No | Audit sharing is required by financial reporting regulation and internal audit policy. |

Sign-off: Approved? Yes; Prepared By Sri Handayani / CRM Department Head and Acknowledged By Dewi Rahayu / Head of Business Analytics (both auto-filled).

Remarks: Approved for the Q3 2026 revenue audit only: transaction data with pseudonymised customer_id, read-only access for 2 named auditors in the BU audit room, access ends 2026-11-30. The data may not be copied or reused for any other purpose; deletion is confirmed by the auditor at the end of the engagement.

---

## Step 5: DPIA (open DPIA-2026-0007 and fill it in)

The DPIA draft was created automatically with DSR 1 (one DPIA per project, status Draft, empty). Do not use DPIA > New; open **DPIA-2026-0007** from the DPIA list, click Edit, fill in the fields below and submit. In the list, "DSR Status" (Submitted) and "DPIA Status" (Draft) are separate columns.

| Field | Value |
|---|---|
| Project Asset | Retail Customer Churn Prediction |
| Process name | Customer churn scoring and retention targeting |
| Data Categories Involved | Full Name; National ID / IC Number; Date of Birth; Gender; Email Address; Phone Number; Transaction History; Online Purchase Behaviour; Customer Relationship (CRM) |
| Risk Description | Customers are profiled with an ML model that combines identity data (NIK, birth date), contact data and purchase history. Risks: re-identification if pseudonymised data leaks, unfair targeting of some customer groups, and use of contact data beyond the consented purpose. |
| Mitigation Measures | Pseudonymise NIK, name, e-mail and phone before modelling; role-based access for the project team only; vendor receives features only (DSR 1); model fairness review before go-live; retention offers only for customers who opted in to marketing; data deleted at project end (BAPD). |
| Residual Risk Level | Medium |
| Governance Activities | Keep the template items; set the status of each (e.g. Access A1–A4 and Data Definition D1–D2 done by Internal, Client items pending) and add a short remark where useful. |

Governance Activities (Status: Yes = in place / planned; No = not applicable, which shows the Responsible as N/A):

| # | Activity | Responsible | Status | Remarks |
|---|---|---|---|---|
| A1 | Data Sharing Request Document | ADI-DI | Yes | DSR-2026-0007 (churn features to the vendor, AI use) submitted in the platform; DSR 2 (transactions to the auditor) follows. |
| A2 | Revoke / Extermination Documentation | ADI-DI | Yes | BAPD extermination request planned at access end (2027-03-31 vendor, 2026-11-30 auditor); proof of deletion kept in the platform. |
| A3 | Data Activity Records Documentation (during project) | ADI-DI | Yes | Every access and change is logged in the platform audit log; monthly access review by the DGO (Anisa Putri). |
| A4 | Role-Based Access Control Document | ADI-DI | Yes | RBAC matrix v1.0 (2026-10-01): 4 named vendor accounts (read-only features), 2 named auditors, project team per role. |
| A5 | Assess and Approve Documentation Above | PT Nusantara Retail Digital | Yes | Reviewed and approved by Sri Handayani (CRM Department Head) on 2026-10-02. |
| A6 | Grant Access to Project Team Only (per RBAC document) | PT Nusantara Retail Digital | Yes | Access granted by the client IT team per RBAC v1.0 on 2026-10-05; access list reviewed monthly. |
| B1 | Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised) | PT Nusantara Retail Digital | Yes | customer_id hashed (SHA-256 with secret salt held by the client); name, NIK, e-mail, phone and birth date removed from the shared files. |
| C1 | Provide Secure Environment or Schema to Enable Data Sharing | PT Nusantara Retail Digital | Yes | Dedicated analytics workspace (schema `churn_prj022`) with no download, MFA login and encryption at rest; separate read-only share for the auditor. |
| D1 | Create Metadata Documentation | ADI-DI | Yes | Metadata for the 3 tables (30 attributes) generated and reviewed in Metadata Management; personal-data columns flagged. |
| D2 | Measure Data Quality Index | ADI-DI | Yes | DQ run on all 3 files; Project DQ Report shared: 2 blank attributes (legacy_fax, analyst_notes) and stale last_visit_date flagged for follow-up. |
| D3 | Assess and Approve Metadata Definition | PT Nusantara Retail Digital | Yes | Metadata definitions reviewed by Rizky Pramono (Lead Business Steward); approval planned for 2026-10-09. |
| D4 | Assess and Approve Data Quality Measurement Approach and Index | PT Nusantara Retail Digital | Yes | DQ method (4 dimensions, llama3.2 rules) and index reviewed with the Data Owner; approval planned for 2026-10-09. |

Negative test (optional): set C1 to **No**: the Responsible shows N/A; add the remark "Client uses vendor environment: not allowed, change requested" and see how reviewers treat it.

Check: the DPIA is saved with its reference number, categories and governance table, and can go through approval.

---

## Step 6: Data Quality (Data Quality > select the project > Run All Data)

1. Data step: the 3 files are selected (a file that is registered but missing on disk would be greyed out; a file that is already queued or running shows "Queued"/"Running now" and cannot be selected). Unselect TEST04 unless you want the "No data found" failure test.
   You can leave the Generate step while it runs: Data Quality > this project shows a banner with the time left and **View progress** (do not start the batch again; Run All becomes View Progress while it runs).
2. Generate step: files run **one after another**. Each shows "x / y columns checked" and a countdown. At about 1 minute per column, expect roughly 11 + 9 + 10 = 30 minutes in total.
3. After all 3 finish, open each run, then **Project Report**.

Expected results (facts from the data; exact regexes and rule text come from the model):

| File | What to look for |
|---|---|
| TEST01 Customer Master | **Blank Attributes 1 / 11** (`legacy_fax`: only NULL / N/A / - / spaces / empty, its checks show "no data"). `segment` Completeness **90%** (Warning). Consistency below 100% for `nik` (3 values with 15 digits), `email` (4 invalid), `phone` (7 without dashes / +62), `gender` (6 "Male"/"Female" instead of M/F). Uniqueness checks for `customer_id`, `nik`, `email`, `phone`, `registered_at` (all values happen to be different). Latency: `birth_date` 0% (a birth date is not a freshness column: a good review point), `registered_at` 70% when run within 7 days of 2026-09-26. |
| TEST02 Transactions | Blank Attributes 0 / 9. `promo_code` Completeness **14.7%** (Failed). Consistency issues: `customer_id` (3 × `CUST0099`), `payment_method` (10 × `qris`, 3 × `Card`), `store_code` (6 × `STR001`). `amount_idr` has 8 negative refunds (regex allows the minus sign). Uniqueness for `transaction_id` and `amount_idr`. Latency `transaction_date` 100% on 2026-09-27, 70% within 7 days, then lower. |
| TEST03 Churn Features | **Blank Attributes 1 / 10** (`analyst_notes`). Small code sets: `complaints_count` (0–5), `churn_flag` (0/1). `model_version` is one constant value. Latency `last_visit_date` **0%** (latest 2026-07-31: stale, real Failed). Uniqueness for `customer_id` and `monthly_spend`. |
| Project Report | Cards combine the 3 files: **Blank Attributes 2 / 30**; Total Metric Checks = sum of the 3 runs; Rules tab has a Table column and a table filter; Export (Excel/PDF) includes the Table column. |

Other things to check:
- Score tab: N/A slots for metrics that were not run, "No data" bars for `legacy_fax` and `analyst_notes`.
- Findings: one "has no values" finding per blank attribute, not one per check.
- Rules tab Export → Excel and PDF.
- Re-run Check on one file: the Version goes to 2.
- Optional failure test: if TEST04 was imported, run DQ on it. Expected: failed with **"No data found"** and what to do.

---

## Step 7: Source file retention and ROPA (ROPA > New)

1. Before any ROPA: open the project in **Data Assets Catalog**. "Uploaded Source Files Kept Until" shows **30 Apr 2027**, "End date + 30 days (no approved ROPA yet)".
2. Create a ROPA for the project:

| Field | Value |
|---|---|
| Project | Retail Customer Churn Prediction (PRJ-2026-022) |
| Process Name | Customer churn scoring and retention targeting |
| Purpose | Predict churn risk to send retention offers to customers who opted in to marketing |
| Data Category | Identity (name, NIK, birth date, gender), contact (e-mail, phone), purchase history, churn features |
| Data Subject | Retail customers of PT Nusantara Retail Digital |
| Legal Basis | Consent (marketing opt-in) and contract |
| Retention Period | 2 Years after project end |
| Recipients | Model vendor (features only, DSR 1); external auditor (transactions, DSR 2) |

3. Submit it, then Under Review: the project page still shows **30 Apr 2027** (only an approved ROPA counts).
4. Approve it: the project page now shows **31 Mar 2029**, "End date + approved ROPA retention period "2 Years after project end" (Customer churn scoring …)". The project PDF shows the same line.
5. Optional negative test: a second ROPA with Retention Period "As required by law", approved: the date stays 31 Mar 2029 and an amber warning says the text is not readable as a duration.

---

## Step 8: Share with the team (done by Claude at commit time)

- The database is exported **with** PRJ-2026-022, and `docker exec ag_api python scripts/share_project_uploads.py PRJ-2026-022` copies TEST01–03 into `backend/shared_uploads/<project_id>/` for the commit.
- A teammate pulls, runs `docker volume rm datagov-v2_sqlite_data` once (to load the new database) and starts the stack; the files are restored automatically, so the DQ Data step shows them as available (not "File missing").
