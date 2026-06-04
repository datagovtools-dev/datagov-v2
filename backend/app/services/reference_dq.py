"""Reference Data Quality method from the Existing Data Quality scripts.

Telegram and BigQuery upload/notification concerns are intentionally omitted.
The rule prompt, model sequence, sampling, regex scoring, uniqueness, latency,
and index calculations mirror the provided DQ scripts.
"""
from __future__ import annotations

import math
import os
import time
from dataclasses import dataclass
from datetime import datetime
from typing import Any

import numpy as np
import pandas as pd
import regex as re
import requests


INIT_PROMPT = """Offer broad validation rules and a RegEx pattern based on the dataset's characteristics (Column Name, Type, and Value). Aim to capture the essence of what makes data reliable and uniform in the larger dataset. Consider the data snapshot thoroughly and assume the provided information is accurate but may not fully encompass all data. Prioritize creating the output from the data snapshot based on Sample Values, followed by Column Name, and then Column Type. Assess the complexity of the data snapshot in terms of its ability to represent and generalize well to larger datasets, categorizing it as High, Medium, or Low. Provide reasoning for the assigned complexity level.

Requirements:
1. Validation Rules:
- Propose validation rules that encompass all the sample data provided.
- Clearly differentiate between mandatory and optional segments in the sample values.
- Identify edge cases that might arise (e.g., absence of titles, parentheses, or middle initials).

2. Generalized Regex Pattern:
- Create a generalized RegEx pattern (only in UTF-8) based on the rules that will ensure these conditions are met for all sample data.
- For column type float64, ensure the regex pattern could handle floating-point numbers, including values with optional decimal places (e.g., 100., 99.0, 100.5, 25.99).
- Do not overcomplicate the pattern, use the general pattern if the value is too complex and varied.
- The regex pattern should be compatible with the "import re" library in Python.
- To ensure the pattern matches the entire string, use ^ at the beginning to anchor the pattern to the start of the string, and $ at the end to anchor it to the end of the string.

3. Checking for each sample data using regex pattern generated:
- Count "0" as a single digit; for example, `FUR-BO-10001798` should be represented as `r'\\w{3}-\\w{2}-\\d{8}'`.
- The regex must be tested against each sample value.
- Iterate and modify the regex until all values match. If it takes more than 2 minutes, just stop and get the latest regex.
- Below are the sample code for checking the regex generated for each sample code:

import re

# Compiling the regex pattern
pattern = r'^<INSERT-YOUR-REGEX-HERE>$'
compiled_pattern = re.compile(pattern)

# Sample data for validation
sample_data = [
    "Braund, Mr. Owen Harris",
    "Cumings, Mrs. John Bradley (Florence Briggs Thayer)",
    # Add more sample values here
]

# Test validation
for data in sample_data:
    if compiled_pattern.fullmatch(data):
        print(f"'{data}' matches the pattern.")
    else:
        print(f"'{data}' does NOT match the pattern.")

4. The sample values are presented as an array in Python, formatted as ["first_value", "second_value", "etc."]. Each value is enclosed in double quotes and separated by a comma. This format represents the data as a list of strings in Python, where each string is an individual data point. Here are the data snapshot:
Column Name: <COLUMN-NAME>
Column Type: <COLUMN-TYPE>
Sample Values: <COLUMN-DATA>

5. Generate this as final output:
- Column Name: <INSERT_SOMETHING>

- Column Type: <INSERT_SOMETHING>

- Business Rules: a. <INSERT_SOMETHING>; b. <INSERT_SOMETHING>; c. <INSERT_SOMETHING>

- RegEx Pattern: r'^<INSERT-YOUR-REGEX-HERE>$' (Always use ^ at the beginning of the pattern and $ at the end of the pattern)

- Complexity: <High, Medium, Low> (Choose one only)

- Reasoning: <The reasoning>

Indicate your final output by typing: "HERE IS THE FINAL RESULT". Followed up by format as mentioned in number 5.
Don't add anything apart from template number 5 after "HERE IS THE FINAL RESULT".
Don't add anything before "HERE IS THE FINAL RESULT"
No need to show anything except result from template number 5.
"""


@dataclass(frozen=True)
class ReferenceDQConfig:
    base_url: str
    timeout_seconds: int = 120
    api_key: str | None = None
    primary_model: str = "qwen2.5-coder:32b"
    secondary_model: str = "llama3.1:70b"


def check_sample_size(total_data: int) -> int:
    if total_data < 200:
        return total_data
    elif total_data < 500:
        return math.ceil(0.5 * total_data)
    elif (total_data >= 500) or (total_data <= 5000):
        return math.ceil(0.3 * total_data)
    elif total_data > 5000:
        return math.ceil(0.1 * total_data)
    return total_data


def detect_scientific_notation_strings(df: pd.DataFrame) -> list[str]:
    return [
        column for column in df.columns
        if (df[column].dtype == "object" or df[column].dtype == "float64") and (df[column].apply(
            lambda x: bool(re.match(r"^-?\d+(\.\d+)?e[+-]\d+$", str(x)))).any())
    ]


def identify_and_convert_datetime(df: pd.DataFrame, cnt_unique: pd.DataFrame, threshold: float = 0.2) -> list[str]:
    df = df.astype(str)
    datetime_columns = []

    for col in df.columns:
        if df[col].dtype == "object":
            try:
                converted_col = pd.to_datetime(df[col], errors="coerce")
                converted_col = pd.concat([converted_col, cnt_unique], axis=1)
                total_values = converted_col.iloc[:, 1].sum()
                non_null_weighted_sum = converted_col.loc[converted_col.iloc[:, 0].notnull(), "count"].sum()
                non_null_proportion = non_null_weighted_sum / total_values
                if non_null_proportion >= (1 - threshold):
                    datetime_columns.append(col)
            except Exception as exc:
                print(f"Failed to convert column {col}: {exc}")

    return datetime_columns


def extract_from_output(raw_text: str) -> dict[str, str]:
    result = {}
    raw_text = re.sub(r".*HERE IS THE FINAL RESULT\.", "", raw_text, flags=re.DOTALL)
    raw_text = re.sub(r"\*\*", "", raw_text, flags=re.DOTALL)

    business_rules_clean = re.sub(r"\*|\s{2,}", "", raw_text, flags=re.DOTALL)
    business_rules_match = re.search(r"Business Rules:\s*(.*?)\s*RegEx Pattern:", business_rules_clean, re.DOTALL)
    result["business_rules"] = business_rules_match.group(1).strip() if business_rules_match else "No match found."

    regex_pattern_match = re.search(r"r'\^.*?\$'", raw_text, re.DOTALL)
    result["regex_pattern"] = regex_pattern_match.group(0).strip() if regex_pattern_match else "No match found."

    complexity_match = re.search(r"(Complexity.*(High|Low|Medium))", raw_text, re.DOTALL)
    result["complexity"] = complexity_match.group(2) if complexity_match else "No match found."

    reasoning_match = re.search(r"Reasoning:\s*(.*?)\s*$", raw_text, re.DOTALL)
    result["reasoning"] = reasoning_match.group(1).strip() if reasoning_match else "No match found."
    return result


def compile_final_metrics(
    df_final: pd.DataFrame,
    df_consistency: pd.DataFrame,
    df_unique: pd.DataFrame,
    df_latency: pd.DataFrame,
) -> pd.DataFrame:
    return pd.concat([df_final, df_consistency, df_unique, df_latency], ignore_index=True)


def filter_unique_rows(df: pd.DataFrame) -> pd.DataFrame:
    df_unique = df[(df["Total Rows"] == df["Total Unique"]) & (df["Total Rows"] != 0) & (df["Total Unique"] != 0)].copy()
    df_unique["DQ Dimension"] = "Uniqueness"
    df_unique["Index"] = 100
    df_unique["Business Rules"] = df_unique["Column Name"].apply(
        lambda col: f"There should be no duplicated field for {col} in this table"
    )
    return df_unique


def calculate_update_and_merge_consistency(
    regex_df: pd.DataFrame,
    values_df: pd.DataFrame,
    cnt_unique: pd.DataFrame,
    table_name: str,
    credentials_source: str | None,
    threshold: int = 70,
    column_name_col: str = "Column Name",
    regex_pattern_col: str = "RegEx Pattern",
    new_regex_pattern: str = r"^-?\d+(\.\d+)?e[+-]\d+$",
    ingesttime_pattern: str = r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d{6})?\+\d{2}:\d{2}$",
    columns_with_sci_notation: list[str] | None = None,
) -> pd.DataFrame:
    if credentials_source is None:
        print("no sql")
        table_name = table_name
    else:
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = credentials_source

    if columns_with_sci_notation is None:
        columns_with_sci_notation = []

    match_results = []
    for _, row in regex_df.iterrows():
        column_name = row[column_name_col]
        regex_pattern = row[regex_pattern_col]
        column_data = values_df[column_name]
        total_rows = len(column_data)

        regex_pattern = re.sub(r"^r", "", regex_pattern)
        regex_pattern = re.sub(r"^'|'$", "", regex_pattern)

        if total_rows > 500000:
            print(f"Processing '{column_name}' with SQL or optimized logic (rows: {total_rows})")
            match_count = 0
            total_count = 0
            match_percentage = 0
        else:
            print(f"Processing '{column_name}' with Python (rows: {total_rows})")
            if column_data.dtype == "Int64" or column_data.dtype == "int64":
                try:
                    matches = column_data.apply(
                        lambda x: bool(re.match(re.compile(regex_pattern, re.DOTALL), str(int(x)))) if pd.notnull(x) else False
                    )
                    match_df = pd.concat([pd.DataFrame(matches), cnt_unique], axis=1)
                    match_df["cnt_match"] = match_df.iloc[:, 0] * match_df.iloc[:, 1]
                    match_count = match_df["cnt_match"].sum()
                except re.error:
                    match_count = 0
                    match_df = pd.concat([pd.DataFrame(False, index=column_data.index, columns=[column_name]), cnt_unique], axis=1)
            else:
                try:
                    matches = column_data.apply(
                        lambda x: bool(re.match(re.compile(regex_pattern, re.DOTALL), str(x))) if pd.notnull(x) else False
                    )
                    match_df = pd.concat([pd.DataFrame(matches), cnt_unique], axis=1)
                    match_df["cnt_match"] = match_df.iloc[:, 0] * match_df.iloc[:, 1]
                    match_count = match_df["cnt_match"].sum()
                except re.error:
                    match_count = 0
                    match_df = pd.concat([pd.DataFrame(False, index=column_data.index, columns=[column_name]), cnt_unique], axis=1)
            total_count = match_df.iloc[:, 1].sum()
            match_percentage = (match_count / total_count) * 100 if total_count > 0 else 0

        if column_name in columns_with_sci_notation and match_percentage < threshold:
            regex_pattern = new_regex_pattern
            regex_df[regex_pattern_col][regex_df[column_name_col] == column_name] = regex_pattern

        if column_data.dtypes == "datetime64[us, UTC]" and match_percentage < threshold:
            regex_pattern = ingesttime_pattern
            regex_df[regex_pattern_col][regex_df[column_name_col] == column_name] = regex_pattern

        match_results.append({
            "Column Name": column_name,
            "RegEx Pattern": regex_pattern,
            "Total Entries (Including None as Non-Match)": total_count,
            "Matches": match_count,
            "DQ Dimension": "Consistency",
            "Index": match_percentage,
        })
        print(f"Consistency for {column_name} in {table_name} is: {match_count}, {match_percentage}%")

    df_match = pd.DataFrame(match_results)
    df_temp = regex_df.iloc[:, :-2].drop(columns=["RegEx Pattern"])
    df_consistency = pd.merge(
        df_temp,
        df_match[["Column Name", "RegEx Pattern", "DQ Dimension", "Index"]],
        on=["Column Name"],
        how="inner",
    )
    return df_consistency[
        [
            "Column Name", "Column Type", "Total Rows",
            "Total Unique", "Total Null", "Raw Text", "Business Rules",
            "RegEx Pattern", "Model", "Complexity", "Reasoning",
            "DQ Dimension", "Index",
        ]
    ]


def calculate_percentage(days_diff: int) -> int:
    if days_diff > 0:
        return 100
    elif -1 >= days_diff >= -7:
        return 70
    elif -8 >= days_diff >= -14:
        return 50
    elif -15 >= days_diff >= -30:
        return 30
    else:
        return 0


def calculate_latency_index(df: pd.DataFrame, cnt_unique: pd.DataFrame, threshold: float = 0.2) -> pd.DataFrame:
    datetime_columns = identify_and_convert_datetime(df, cnt_unique, threshold)
    print("datetime columns:", datetime_columns)
    latency_index, latency_rules = [], []
    today = datetime.now().date()

    for col in datetime_columns:
        max_date = pd.to_datetime(df[col], errors="coerce").max()
        days_diff = (today - max_date.date()).days if pd.notnull(max_date) else 0
        latency_index.append(calculate_percentage(14 - days_diff))
        latency_rules.append(f"Latest date in {col} should not be more than 14 days ago")

    return pd.DataFrame({"Column Name": datetime_columns, "Business Rules": latency_rules, "DQ Dimension": "Latency", "Index": latency_index})


def _call_ollama(prompt: str, model: str, config: ReferenceDQConfig) -> str:
    headers = {"Authorization": f"Bearer {config.api_key}"} if config.api_key else None
    response = requests.post(
        f"{config.base_url.rstrip('/')}/api/generate",
        json={"model": model, "prompt": prompt, "stream": False, "options": {"temperature": 0}},
        headers=headers,
        timeout=config.timeout_seconds,
    )
    response.raise_for_status()
    return response.json().get("response", "")


def process_columns(df: pd.DataFrame, df_completeness: pd.DataFrame, init_prompt: str, config: ReferenceDQConfig, model: str | None = None) -> tuple[list[str], pd.DataFrame]:
    col_name, col_type, total_row, total_unique, total_null = [], [], [], [], []
    rawtext, business_rules, completeness_rules, regex_rules, complexity_rules, reason_rule, model_name = [], [], [], [], [], [], []
    start_time = time.time()
    column_count = len(df.columns)

    for idx, column in enumerate(df.columns, start=1):
        col_name.append(column)
        col_type.append(str(df[column].dtypes))

        np.random.seed(42)
        prompt = init_prompt.replace("<COLUMN-NAME>", column)
        prompt = prompt.replace("<COLUMN-TYPE>", str(df[column].dtypes))

        size_data = check_sample_size(len(df.drop_duplicates(subset=[column])))
        unique_values = df[column].dropna().unique()
        sample_values = (
            np.random.choice(unique_values, size=size_data, replace=False) if len(unique_values) >= size_data
            else unique_values
        )
        sample_values = np.sort(sample_values)
        if df[column].dtype == "float64":
            sample_values = [float(val) for val in sample_values]
            prompt = prompt.replace("<COLUMN-DATA>", str(sample_values))
        else:
            prompt = prompt.replace("<COLUMN-DATA>", np.array2string(sample_values, separator=", "))

        selected_model = model or config.primary_model
        raw_text = _call_ollama(prompt, selected_model, config)
        extracted_data = extract_from_output(raw_text)

        rawtext.append(raw_text)
        business_rules.append(extracted_data["business_rules"])
        completeness_rules.append(f"There should be no empty field for {column} in this table")
        regex_rules.append(extracted_data["regex_pattern"])
        complexity_rules.append(extracted_data["complexity"])
        reason_rule.append(extracted_data["reasoning"])
        model_name.append(selected_model)

        total_row.append(df_completeness["total_rows"].values[0])
        total_unique.append(df_completeness["total_unique_values"].values[0])
        total_null.append(df_completeness["total_null_values"].values[0])
        index = df_completeness["completeness_pct"].values[0]

        elapsed_time = time.time() - start_time
        avg_time_per_column = elapsed_time / idx
        remaining_columns = column_count - idx
        eta = avg_time_per_column * remaining_columns
        print(f"Processed column {idx}/{column_count}. ETA: {time.strftime('%H:%M:%S', time.gmtime(eta))}")

    print(f"Total All Columns Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - start_time))}")
    data = {
        "Column Name": col_name,
        "Column Type": col_type,
        "Total Rows": total_row,
        "Total Unique": total_unique,
        "Total Null": total_null,
        "Raw Text": rawtext,
        "Business Rules": business_rules,
        "RegEx Pattern": regex_rules,
        "Complexity": complexity_rules,
        "Reasoning": reason_rule,
        "Model": model_name,
        "DQ Dimension": "Completeness",
        "Index": index,
    }
    return completeness_rules, pd.DataFrame(data)


def load_column_profile_from_dataframe(df_raw: pd.DataFrame, column_name: str) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    if column_name not in df_raw.columns:
        raise ValueError(f"Column '{column_name}' not found.")

    df_column_counts = df_raw[column_name].value_counts(dropna=False).reset_index()
    df_column_counts.columns = [column_name, "count"]

    total_rows = len(df_raw)
    total_unique_values = df_raw[column_name].nunique(dropna=True)
    total_null_values = df_raw[column_name].isnull().sum()
    completeness_pct = 100.0 * df_raw[column_name].notnull().sum() / total_rows if total_rows > 0 else 0
    df_completeness = pd.DataFrame({
        "total_rows": [total_rows],
        "total_unique_values": [total_unique_values],
        "total_null_values": [total_null_values],
        "completeness_pct": [completeness_pct],
    })
    return df_column_counts.iloc[:, [0]], df_completeness, df_column_counts.iloc[:, [1]]


def run_data_quality_checks2(
    df: pd.DataFrame,
    df_completeness: pd.DataFrame,
    cnt_unique: pd.DataFrame,
    table_name: str,
    column_name: str,
    project_name: str,
    config: ReferenceDQConfig,
) -> pd.DataFrame:
    start_time = time.time()
    print("run_data_quality_checks2, latest_versions", 0)

    completeness_rules, df_final = process_columns(df, df_completeness, INIT_PROMPT, config, model=config.primary_model)
    columns_with_sci_notation = detect_scientific_notation_strings(df)
    print("columns_with_sci_notation", columns_with_sci_notation)
    print(f"Completeness Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - start_time))}")

    threshold = 70
    try:
        dim_time = time.time()
        df_consistency = calculate_update_and_merge_consistency(df_final, df, cnt_unique, table_name, credentials_source=None, columns_with_sci_notation=columns_with_sci_notation)
        df_consistency = calculate_update_and_merge_consistency(df_consistency, df, cnt_unique, table_name, credentials_source=None, columns_with_sci_notation=columns_with_sci_notation)
        print("qwen")
    except Exception as exc:
        print(f"Error Calculating Consistency Index: {exc}")
        df_consistency = pd.DataFrame()
        dim_time = time.time()

    try:
        columns_below_threshold = df_consistency[df_consistency["Index"] < threshold]
        columns_not_meeting_threshold = columns_below_threshold["Column Name"].tolist()
        if columns_not_meeting_threshold:
            print("Columns_not_meeting_threshold", columns_not_meeting_threshold)
            print("Start reprocessing columns which do not meet the threshold")
            completeness_rules2, df_final2 = process_columns(df[columns_not_meeting_threshold], df_completeness, INIT_PROMPT, config, model=config.secondary_model)
            df_consistency2 = calculate_update_and_merge_consistency(df_final2, df, cnt_unique, table_name, credentials_source=None, columns_with_sci_notation=columns_with_sci_notation)
            df_consistency2 = calculate_update_and_merge_consistency(df_consistency2, df, cnt_unique, table_name, credentials_source=None, columns_with_sci_notation=columns_with_sci_notation)
            for column in columns_not_meeting_threshold:
                row_final = df_consistency[df_consistency["Column Name"] == column].index
                row_final2 = df_consistency2[df_consistency2["Column Name"] == column]
                if not row_final2.empty and not row_final.empty:
                    index_final = df_consistency.loc[row_final, "Index"].values[0]
                    index_final2 = row_final2["Index"].values[0]
                    if index_final2 > index_final:
                        df_consistency.loc[row_final, df_consistency.columns] = row_final2[df_consistency.columns].values[0]
                        print("llama")
                        df_final.loc[df_final["Column Name"] == column, "Raw Text"] = row_final2["Raw Text"].values[0]
                        df_final.loc[df_final["Column Name"] == column, "Business Rules"] = row_final2["Business Rules"].values[0]
                        df_final.loc[df_final["Column Name"] == column, "RegEx Pattern"] = row_final2["RegEx Pattern"].values[0]
                        df_final.loc[df_final["Column Name"] == column, "Complexity"] = row_final2["Complexity"].values[0]
                        df_final.loc[df_final["Column Name"] == column, "Reasoning"] = row_final2["Reasoning"].values[0]
                        df_final.loc[df_final["Column Name"] == column, "Model"] = row_final2["Model"].values[0]
    except Exception as exc:
        print(f"Error Recaculating Columns Below Threshold: {exc}")

    print(f"Consistency Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - dim_time))}")
    dim_time = time.time()
    df_unique = filter_unique_rows(df_final)
    print(f"Uniqueness Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - dim_time))}")

    dim_time = time.time()
    df_latency = calculate_latency_index(df, cnt_unique)
    df_temp = df_final.iloc[:, :-2].drop(columns=["Business Rules"])
    df_latency = pd.merge(df_temp, df_latency, on="Column Name", how="inner")
    del df_temp
    print(f"Latency Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - dim_time))}")

    df_final["Business Rules"] = completeness_rules
    merged_df = compile_final_metrics(df_final, df_consistency, df_unique, df_latency)
    merged_df = merged_df.sort_values(by=["Column Name", "DQ Dimension"]).reset_index(drop=True)
    final_df = merged_df.copy()
    final_df["Regex Version"] = "New Version"
    print(f"Total Program Runtime: {time.strftime('%H:%M:%S', time.gmtime(time.time() - start_time))}")
    return final_df


def run_reference_dq_for_dataframe(df_raw: pd.DataFrame, table_name: str, project_name: str, config: ReferenceDQConfig) -> pd.DataFrame:
    df_combined = pd.DataFrame()
    for column_name in df_raw.columns.tolist():
        print("column", column_name)
        df, df_completeness, cnt_unique = load_column_profile_from_dataframe(df_raw, column_name)
        dq_check = run_data_quality_checks2(df, df_completeness, cnt_unique, table_name, column_name, project_name, config)
        df_combined = pd.concat([df_combined, dq_check], ignore_index=True)
    return df_combined


def status_from_index(index: float) -> str:
    return "pass" if index >= 95 else "warning" if index >= 70 else "fail"


def result_rows_from_reference(df_result: pd.DataFrame) -> tuple[list[dict[str, Any]], float]:
    rows: list[dict[str, Any]] = []
    scores: list[float] = []
    for _, row in df_result.iterrows():
        index = float(row.get("Index") or 0)
        scores.append(index)
        dimension = str(row.get("DQ Dimension") or "").lower()
        total_rows = int(row.get("Total Rows") or 0)
        total_null = int(row.get("Total Null") or 0)
        failed_count = total_null if dimension == "completeness" else 0 if index >= 70 else 1
        rows.append({
            "check_name": f"{row.get('Column Name')}__{dimension}",
            "check_type": dimension,
            "column_name": row.get("Column Name"),
            "score": round(index, 2),
            "row_count": total_rows,
            "failed_count": failed_count,
            "status": status_from_index(index),
            "business_rules": row.get("Business Rules"),
            "regex_pattern": re.sub(r"^r", "", re.sub(r"^'|'$", "", str(row.get("RegEx Pattern") or ""))) or None,
            "ai_model": row.get("Model"),
            "regex_version": row.get("Regex Version"),
            "column_category": row.get("Category"),
            "details": {
                "reference_method": "Existing Data Quality",
                "index": round(index, 2),
                "raw_text": row.get("Raw Text"),
                "complexity": row.get("Complexity"),
                "reasoning": row.get("Reasoning"),
                "total_unique": int(row.get("Total Unique") or 0),
                "total_null": total_null,
            },
            "findings": [] if index >= 70 else [{
                "severity": "critical" if index < 50 else "warning",
                "description": f"{row.get('Column Name')} {row.get('DQ Dimension')} index is {index:.1f}%.",
                "recommendation": row.get("Business Rules") or "Review and remediate this data quality rule.",
            }],
        })
    overall = round(sum(scores) / len(scores), 2) if scores else 0.0
    return rows, overall
