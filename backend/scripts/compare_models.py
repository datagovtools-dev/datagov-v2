"""One-off script: compare phi3.5 / llama3.2:3b / qwen2.5:3b — Round 5.

Focus: short, clean, 2-3 sentence definitions only.
Changes from Round 4:
- Stripped context to essentials only (no sensitivity/PK/nullable — those caused extra sentences)
- Removed all conditional rule blocks
- Hard num_predict cap reduced to enforce brevity
- Prompts simplified to single clear instruction set
"""
import httpx

OLLAMA_URL = "http://ollama:11434/api/generate"

MODEL_OPTIONS = {
    "phi3.5": {
        "temperature": 0.3,
        "top_p": 0.85,
        "repeat_penalty": 1.1,
        "num_predict": 130,
    },
    "llama3.2:3b": {
        "temperature": 0.35,
        "top_p": 0.90,
        "repeat_penalty": 1.1,
        "num_predict": 150,
    },
    "qwen2.5:3b": {
        "temperature": 0.2,
        "top_p": 0.80,
        "repeat_penalty": 1.2,
        "num_predict": 130,
    },
}

RECORDS = [
    {
        "label": "Score (numeric, continuous)",
        "table": "PRJ004_AI_Scoring",
        "attribute": "Score",
        "business_term": "Score",
        "data_type": "FLOAT",
        "grouping": "Model Scoring",
        "standard_format": "Decimal number",
        "sample_data": "0.24",
        "distinct_values": None,
    },
    {
        "label": "Churn_Risk (categorical, 3 values)",
        "table": "PRJ004_AI_Scoring",
        "attribute": "Churn_Risk",
        "business_term": "Churn Risk",
        "data_type": "STRING",
        "grouping": "Model Scoring",
        "standard_format": "Category: High, Low, Medium",
        "sample_data": "Medium",
        "distinct_values": None,
    },
    {
        "label": "Email (Highly Confidential, PK)",
        "table": "PRJ004_Customer_Master",
        "attribute": "Email",
        "business_term": "Email",
        "data_type": "STRING",
        "grouping": "Master Customer",
        "standard_format": "Email (name@domain.com)",
        "sample_data": "cust0@mail.com",
        "distinct_values": None,
    },
    {
        "label": "Customer_Segment (categorical, business domain)",
        "table": "PRJ004_Customer_Master",
        "attribute": "Customer_Segment",
        "business_term": "Customer Segment",
        "data_type": "STRING",
        "grouping": "Master Customer",
        "standard_format": "Category: Occasional, Premium, Regular",
        "sample_data": "Regular",
        "distinct_values": None,
    },
]


def _clean_table(table: str) -> str:
    for ext in (".xlsx", ".xls", ".csv"):
        idx = table.lower().find(ext)
        if idx > 0:
            table = table[:idx]
            break
    for sep in (" - ", " – ", "_"):
        parts = table.rsplit(sep, 1)
        if len(parts) == 2 and parts[1].lower().startswith("sheet"):
            table = parts[0]
    return table.strip(" -_")


def build_context(r: dict) -> str:
    """Lean context — essentials only. No sensitivity/PK/nullable (those inflate output)."""
    table = _clean_table(r["table"])
    lines = [
        f"Source table: {table}",
        f"Business term: {r['business_term']}",
        f"Data type: {r['data_type']}",
    ]
    if r.get("grouping"):
        lines.append(f"Domain: {r['grouping']}")
    if r.get("distinct_values"):
        lines.append(f"Possible values: {r['distinct_values']}")
    elif r.get("standard_format", "").startswith("Category:") or r.get("standard_format", "").startswith("Boolean"):
        lines.append(f"Possible values: {r['standard_format'].replace('Category: ', '')}")
    elif r.get("sample_data"):
        lines.append(f"Example value: {r['sample_data']}")
    return "\n".join(lines)


def is_categorical(r: dict) -> bool:
    sf = r.get("standard_format") or ""
    return bool(r.get("distinct_values")) or sf.startswith("Category:") or sf.startswith("Boolean")


# ── per-model prompts ─────────────────────────────────────────────────────────

def prompt_phi35(r: dict) -> str:
    """phi3.5: prose instructions only, no numbered rules (triggers list output)."""
    ctx = build_context(r)
    cat = is_categorical(r)
    n = "3" if cat else "2"
    s3 = " Third sentence: what each possible value means in practice." if cat else ""
    return (
        "You are a data governance specialist writing a business data dictionary.\n\n"
        f"{ctx}\n\n"
        f"Write exactly {n} sentences. "
        "Start with a verb: Captures / Records / Identifies / Measures / Tracks / Indicates. "
        "Never name the column or business term. "
        "Sentence one: what real-world fact this data records. "
        f"Sentence two: how it drives business decisions or operations.{s3} "
        "Be concise and specific. Output only the definition."
    )


def prompt_llama32(r: dict) -> str:
    """llama3.2:3b: numbered rules it follows well + single-paragraph enforcement."""
    ctx = build_context(r)
    cat = is_categorical(r)
    n = "3" if cat else "2"
    s3 = "\n   3. What each possible value means in practice — one clause per value" if cat else ""
    return (
        "You are a senior data governance specialist writing a business data dictionary entry.\n\n"
        f"{ctx}\n\n"
        f"Write exactly {n} sentences as one continuous paragraph. Rules:\n"
        "1. Start with a verb — Captures / Records / Identifies / Measures / Tracks / Indicates / Reflects\n"
        "2. Never name the column or business term\n"
        f"3. Sentence 1: what real-world fact this records, anchored to the table and domain\n"
        f"4. Sentence 2: how it is used in business decisions or reporting{s3}\n"
        "5. No line breaks between sentences. Output the definition only."
    )


def prompt_qwen25(r: dict) -> str:
    """qwen2.5:3b: strict verb-first + exact sentence count at the top and bottom."""
    ctx = build_context(r)
    cat = is_categorical(r)
    n = "3" if cat else "2"
    s3 = "\n• Sentence 3: what each possible value means in practice" if cat else ""
    return (
        "Write a business dictionary definition.\n\n"
        f"{ctx}\n\n"
        f"Exactly {n} sentences. One paragraph.\n"
        "First word must be a verb: Captures / Records / Identifies / Measures / Tracks / Indicates / Reflects / Stores.\n"
        "Never use the column name or business term.\n"
        "No labels. No preamble. Output only the definition.\n\n"
        "Structure:\n"
        f"• Sentence 1: what this data records in the real world\n"
        f"• Sentence 2: how it supports business decisions{s3}"
    )


# ── generation + main ─────────────────────────────────────────────────────────

MODELS = {
    "phi3.5": prompt_phi35,
    "llama3.2:3b": prompt_llama32,
    "qwen2.5:3b": prompt_qwen25,
}


def generate(model: str, prompt: str) -> str:
    resp = httpx.post(
        OLLAMA_URL,
        json={"model": model, "prompt": prompt, "stream": False, "options": MODEL_OPTIONS[model]},
        timeout=180.0,
    )
    return resp.json().get("response", "").strip()


if __name__ == "__main__":
    for rec in RECORDS:
        print(f"\n{'=' * 72}")
        print(f"  {rec['label']}")
        print(f"{'=' * 72}")
        for model, fn in MODELS.items():
            print(f"\n  [{model}]")
            try:
                print(f"  {generate(model, fn(rec))}")
            except Exception as e:
                print(f"  ERROR: {e}")
    print("\n\nDone.")
