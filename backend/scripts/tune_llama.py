"""Hyperparameter tuning for llama3.2:3b.

Tests 3 parameter variants side by side on all 4 records:

  Current   — baseline from Round 5 (temp=0.35, top_p=0.90)
  Variant A — tighter temperature + top_k to narrow word selection pool
  Variant B — Mirostat 2 algorithm (controls perplexity directly, overrides top_p/top_k)
               better suited for short, coherent professional text

Key parameters explained
─────────────────────────
temperature     Randomness. Lower = more rule-following and focused.
top_p           Nucleus sampling — considers only the top-P probability mass. Lower = narrower.
top_k           Only considers the top-K tokens per step. Lower = more disciplined vocabulary.
repeat_penalty  >1.0 penalises repeating the same phrase (helps prevent echoing column names).
num_predict     Hard token cap — forces brevity.
mirostat        Sampling algorithm that targets a fixed perplexity instead of temperature/top_p.
                2 = Mirostat v2 (more stable). Overrides top_p and top_k when enabled.
mirostat_tau    Target perplexity. Lower (e.g. 3.0) = more focused, coherent text.
                Higher (e.g. 6.0) = more varied but less predictable.
mirostat_eta    Learning rate for mirostat (default 0.1 — leave as-is).
"""
import httpx

OLLAMA_URL = "http://ollama:11434/api/generate"
MODEL = "llama3.2:3b"

VARIANTS = {
    "Current  (temp=0.35, top_p=0.90, rep=1.10)": {
        "temperature": 0.35,
        "top_p": 0.90,
        "repeat_penalty": 1.1,
        "num_predict": 150,
    },
    "Variant A (temp=0.20, top_p=0.85, top_k=30, rep=1.15)": {
        "temperature": 0.20,
        "top_p": 0.85,
        "top_k": 30,
        "repeat_penalty": 1.15,
        "num_predict": 160,
    },
    "Variant B (mirostat=2, tau=3.0, rep=1.15)": {
        "temperature": 0.3,
        "mirostat": 2,
        "mirostat_tau": 3.0,
        "mirostat_eta": 0.1,
        "repeat_penalty": 1.15,
        "num_predict": 160,
    },
}

RECORDS = [
    {
        "label": "Score (numeric)",
        "table": "PRJ004_AI_Scoring",
        "business_term": "Score",
        "data_type": "FLOAT",
        "grouping": "Model Scoring",
        "values": None,
        "sample": "0.24",
    },
    {
        "label": "Churn_Risk (categorical)",
        "table": "PRJ004_AI_Scoring",
        "business_term": "Churn Risk",
        "data_type": "STRING",
        "grouping": "Model Scoring",
        "values": "High, Low, Medium",
        "sample": None,
    },
    {
        "label": "Email (PK, Highly Confidential)",
        "table": "PRJ004_Customer_Master",
        "business_term": "Email",
        "data_type": "STRING",
        "grouping": "Master Customer",
        "values": None,
        "sample": "cust0@mail.com",
    },
    {
        "label": "Customer_Segment (categorical)",
        "table": "PRJ004_Customer_Master",
        "business_term": "Customer Segment",
        "data_type": "STRING",
        "grouping": "Master Customer",
        "values": "Occasional, Premium, Regular",
        "sample": None,
    },
]


def build_prompt(r: dict) -> str:
    cat = bool(r["values"])
    n = "3" if cat else "2"
    s3 = "\n   3. What each possible value means in practice — one clause per value" if cat else ""

    ctx_lines = [
        f"Source table: {r['table']}",
        f"Business term: {r['business_term']}",
        f"Data type: {r['data_type']}",
        f"Domain: {r['grouping']}",
    ]
    if r["values"]:
        ctx_lines.append(f"Possible values: {r['values']}")
    elif r["sample"]:
        ctx_lines.append(f"Example value: {r['sample']}")
    ctx = "\n".join(ctx_lines)

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


def generate(options: dict, prompt: str) -> str:
    resp = httpx.post(
        OLLAMA_URL,
        json={"model": MODEL, "prompt": prompt, "stream": False, "options": options},
        timeout=180.0,
    )
    return resp.json().get("response", "").strip()


if __name__ == "__main__":
    for rec in RECORDS:
        prompt = build_prompt(rec)
        print(f"\n{'=' * 72}")
        print(f"  {rec['label']}")
        print(f"{'=' * 72}")
        for variant_name, options in VARIANTS.items():
            print(f"\n  [{variant_name}]")
            try:
                print(f"  {generate(options, prompt)}")
            except Exception as e:
                print(f"  ERROR: {e}")
    print("\n\nDone.")
