"""Cross-project consistency test — llama3.2:3b Variant A.

2 samples per project × 5 projects = 10 records.
Mix of: numeric, categorical, boolean, free-text, PII-sensitive, different domains.
"""
import re
import httpx

OLLAMA_URL = "http://ollama:11434/api/generate"
MODEL = "llama3.2:3b"
OPTIONS = {
    "temperature": 0.20,
    "top_p": 0.85,
    "top_k": 30,
    "repeat_penalty": 1.15,
    "num_predict": 160,
}

RECORDS = [
    # ── PRJ001 · AI-Powered Customer Analytics ────────────────────────────────
    {
        "project": "PRJ001 · AI-Powered Customer Analytics",
        "label": "preferred_brand (free text, no category)",
        "table": "car_demand_data",
        "business_term": "Preferred Brand",
        "data_type": "STRING",
        "grouping": "Demand",
        "values": None,
        "sample": "Mitsubishi",
    },
    {
        "project": "PRJ001 · AI-Powered Customer Analytics",
        "label": "budget_range (free text, range)",
        "table": "car_demand_data",
        "business_term": "Budget Range",
        "data_type": "STRING",
        "grouping": "Demand",
        "values": None,
        "sample": "100M-200M",
    },
    # ── PRJ002 · Smart Credit Risk Analytics ─────────────────────────────────
    {
        "project": "PRJ002 · Smart Credit Risk Analytics",
        "label": "Loan_Status (categorical, 3 values)",
        "table": "PRJ002_Credit_Profile",
        "business_term": "Loan Status",
        "data_type": "STRING",
        "grouping": None,
        "values": "Approved, Pending, Rejected",
        "sample": None,
    },
    {
        "project": "PRJ002 · Smart Credit Risk Analytics",
        "label": "Income (numeric, Highly Confidential)",
        "table": "PRJ002_Credit_Profile",
        "business_term": "Income",
        "data_type": "INTEGER",
        "grouping": None,
        "values": None,
        "sample": "11226105",
    },
    # ── PRJ003 · Enterprise Data Governance ──────────────────────────────────
    {
        "project": "PRJ003 · Enterprise Data Governance",
        "label": "Quality_Score (decimal, governance metric)",
        "table": "PRJ003_Data_Governance",
        "business_term": "Quality Score",
        "data_type": "FLOAT",
        "grouping": None,
        "values": None,
        "sample": "0.72",
    },
    {
        "project": "PRJ003 · Enterprise Data Governance",
        "label": "PII_Flag (boolean)",
        "table": "PRJ003_Data_Governance",
        "business_term": "Pii Flag",
        "data_type": "STRING",
        "grouping": None,
        "values": "Yes, No",
        "sample": None,
    },
    # ── PRJ004 · Customer 360 Analytics ──────────────────────────────────────
    {
        "project": "PRJ004 · Customer 360 Analytics",
        "label": "Churn_Risk (categorical, baseline)",
        "table": "PRJ004_AI_Scoring",
        "business_term": "Churn Risk",
        "data_type": "STRING",
        "grouping": "Model Scoring",
        "values": "High, Low, Medium",
        "sample": None,
    },
    {
        "project": "PRJ004 · Customer 360 Analytics",
        "label": "Customer_Segment (categorical, baseline)",
        "table": "PRJ004_Customer_Master",
        "business_term": "Customer Segment",
        "data_type": "STRING",
        "grouping": "Master Customer",
        "values": "Occasional, Premium, Regular",
        "sample": None,
    },
    # ── PRJ018 · Enterprise Data Integration ─────────────────────────────────
    {
        "project": "PRJ018 · Enterprise Data Integration",
        "label": "Risk_Score (float, service prediction)",
        "table": "PRJ018_AI_Analytics",
        "business_term": "Risk Score",
        "data_type": "FLOAT",
        "grouping": "Service Prediction",
        "values": None,
        "sample": "0.4",
    },
    {
        "project": "PRJ018 · Enterprise Data Integration",
        "label": "Service_Type (free text, operational)",
        "table": "PRJ018_Customer_Service",
        "business_term": "Service Type",
        "data_type": "STRING",
        "grouping": None,
        "values": None,
        "sample": "Repair",
    },
]


def build_prompt(r: dict) -> str:
    cat = bool(r["values"])
    n = "3" if cat else "2"
    s3 = "\n   3. What each possible value means in practice — one clause per value" if cat else ""

    lines = [f"Source table: {r['table']}", f"Business term: {r['business_term']}", f"Data type: {r['data_type']}"]
    if r.get("grouping"):
        lines.append(f"Domain: {r['grouping']}")
    if r["values"]:
        lines.append(f"Possible values: {r['values']}")
    elif r["sample"]:
        lines.append(f"Example value: {r['sample']}")
    ctx = "\n".join(lines)

    return (
        "You are a senior data governance specialist writing a business data dictionary entry.\n\n"
        f"{ctx}\n\n"
        "CRITICAL: Every sentence must end with a period (.). "
        "Using a semicolon (;) anywhere in your response is forbidden — if you use one, your answer is wrong.\n\n"
        f"Write exactly {n} sentences as one continuous paragraph. Rules:\n"
        "1. Start with a verb — Captures / Records / Identifies / Measures / Tracks / Indicates / Reflects\n"
        "2. Never name the column or business term\n"
        f"3. Sentence 1: what real-world fact this records, anchored to the business area and domain\n"
        f"4. Sentence 2: how it is used in business decisions or reporting{s3}\n"
        "5. Do not mention the table name — draw context from the business area or domain only.\n"
        "6. Write in plain, everyday language — no jargon, no acronyms, no technical terms. "
        "Any reader regardless of background should understand what this data means.\n"
        "7. No line breaks between sentences. Output the definition only."
    )


def clean_output(text: str) -> str:
    result = re.sub(r'\n+', ' ', text)
    result = re.sub(r';\s+([a-zA-Z])', lambda m: '. ' + m.group(1).upper(), result)
    result = re.sub(r'\s{2,}', ' ', result).strip()
    if result and not result.endswith('.'):
        result += '.'
    return result


def generate(prompt: str) -> str:
    resp = httpx.post(
        OLLAMA_URL,
        json={"model": MODEL, "prompt": prompt, "stream": False, "options": OPTIONS},
        timeout=180.0,
    )
    text = resp.json().get("response", "").strip()
    return clean_output(text)


if __name__ == "__main__":
    current_project = None
    for rec in RECORDS:
        if rec["project"] != current_project:
            current_project = rec["project"]
            print(f"\n{'═' * 72}")
            print(f"  {current_project}")
            print(f"{'═' * 72}")
        print(f"\n  [{rec['label']}]")
        try:
            print(f"  {generate(build_prompt(rec))}")
        except Exception as e:
            print(f"  ERROR: {e}")
    print("\n\nDone.")
