"""Gemma3:4b test — same rules and prompt structure as llama3.2:3b Variant A (final).

Gemma3 known behaviour vs llama3.2:3b:
  + Better strict instruction-following at low temperature
  + Cleaner sentence boundaries (periods vs semicolons)
  - Adds preamble ("Here is...", "Sure!") — suppressed via rule 8
  - More verbose at default settings — compensated with lower temp + top_k + num_predict

Hyperparameter rationale vs llama Variant A:
  temperature  0.15  (lower than llama 0.20 — Gemma drifts more at higher temps)
  top_p        0.85  (same — good nucleus sampling range)
  top_k        25    (tighter than llama 30 — keeps vocabulary more professional)
  repeat_penalty 1.1 (lighter than llama 1.15 — Gemma already has low repetition)
  num_predict  150   (same cap — Gemma is more verbose so same guard needed)

Test project: PRJ002 · Smart Credit Risk Analytics
Samples: 5 records covering numeric, categorical, PII, boolean, free-text
"""
import httpx

OLLAMA_URL = "http://ollama:11434/api/generate"
MODEL = "gemma3:4b"
OPTIONS = {
    "temperature": 0.15,
    "top_p": 0.85,
    "top_k": 25,
    "repeat_penalty": 1.1,
    "num_predict": 150,
}

RECORDS = [
    {
        "label": "Score (numeric, decimal)",
        "table": "PRJ002_Credit_Profile",
        "business_term": "Score",
        "data_type": "FLOAT",
        "grouping": None,
        "values": None,
        "sample": "0.76",
    },
    {
        "label": "Loan_Status (categorical, 3 values)",
        "table": "PRJ002_Credit_Profile",
        "business_term": "Loan Status",
        "data_type": "STRING",
        "grouping": None,
        "values": "Approved, Pending, Rejected",
        "sample": None,
    },
    {
        "label": "Income (numeric, Highly Confidential)",
        "table": "PRJ002_Credit_Profile",
        "business_term": "Income",
        "data_type": "INTEGER",
        "grouping": None,
        "values": None,
        "sample": "11226105",
    },
    {
        "label": "Risk_Level (categorical, 3 values)",
        "table": "PRJ002_Credit_Profile",
        "business_term": "Risk Level",
        "data_type": "STRING",
        "grouping": None,
        "values": "High, Low, Medium",
        "sample": None,
    },
    {
        "label": "Notes (categorical, 4 values)",
        "table": "PRJ002_Credit_Profile",
        "business_term": "Notes",
        "data_type": "STRING",
        "grouping": None,
        "values": "Good profile, High risk, Incomplete docs, Verified",
        "sample": None,
    },
]


def build_prompt(r: dict) -> str:
    cat = bool(r["values"])
    n = "3" if cat else "2"
    s3 = "\n   • Sentence 3: explain what each possible value means in plain terms" if cat else ""

    lines = [
        f"Business term: {r['business_term']}",
        f"Data type: {r['data_type']}",
    ]
    if r.get("grouping"):
        lines.append(f"Domain: {r['grouping']}")
    if r["values"]:
        lines.append(f"Possible values: {r['values']}")
    elif r["sample"]:
        lines.append(f"Example value: {r['sample']}")
    ctx = "\n".join(lines)

    return (
        "You are a senior data governance specialist writing a business data dictionary.\n\n"
        f"Write a definition for the data attribute below.\n\n"
        f"{ctx}\n\n"
        f"CRITICAL: Your very first word must be one of these verbs exactly as written: "
        "Captures, Records, Identifies, Measures, Tracks, Indicates, Reflects, Stores. "
        "Do NOT start with 'This', 'The', 'A', or any noun. "
        "If your first word is not one of those verbs, your answer is wrong.\n\n"
        f"Rules:\n"
        f"1. Write exactly {n} sentences in one continuous paragraph — no line breaks.\n"
        "2. End every sentence with a period. Never use semicolons.\n"
        "3. Never mention the column name, business term, or any table name.\n"
        f"4. Sentence 1: what real-world fact this data records.\n"
        f"5. Sentence 2: how it is used in business decisions or operations.{s3}\n"
        "6. Write in plain, everyday language any reader can understand — no jargon, no acronyms.\n"
        "7. Output only the definition — no labels, no 'Here is', no 'Sure', no extra commentary."
    )


def generate(prompt: str) -> str:
    resp = httpx.post(
        OLLAMA_URL,
        json={"model": MODEL, "prompt": prompt, "stream": False, "options": OPTIONS},
        timeout=180.0,
    )
    return resp.json().get("response", "").strip()


if __name__ == "__main__":
    print(f"\nModel : {MODEL}")
    print(f"Params: temp={OPTIONS['temperature']}, top_p={OPTIONS['top_p']}, "
          f"top_k={OPTIONS['top_k']}, repeat_penalty={OPTIONS['repeat_penalty']}, "
          f"num_predict={OPTIONS['num_predict']}")
    print(f"Project: PRJ002 · Smart Credit Risk Analytics\n")

    for rec in RECORDS:
        print(f"{'─' * 70}")
        print(f"  [{rec['label']}]")
        try:
            result = generate(build_prompt(rec))
            print(f"  {result}")
        except Exception as e:
            print(f"  ERROR: {e}")

    print(f"\n{'─' * 70}")
    print("Done.")
