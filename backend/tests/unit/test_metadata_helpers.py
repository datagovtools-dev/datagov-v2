"""Unit tests for metadata Celery task helper functions."""
import pytest
from app.worker.tasks.metadata import (
    _classify_sensitivity,
    _expand_business_term,
    _detect_data_type,
    _get_sample_data,
    _is_primary_key_candidate,
    _is_nullable,
)


class TestClassifySensitivity:
    def test_pii_name_returns_highly_confidential(self):
        assert _classify_sensitivity("nama_pelanggan") == "Highly Confidential"

    def test_pii_email_returns_highly_confidential(self):
        assert _classify_sensitivity("email_address") == "Highly Confidential"

    def test_pii_nik_returns_highly_confidential(self):
        assert _classify_sensitivity("nik") == "Highly Confidential"

    def test_non_pii_returns_confidential(self):
        assert _classify_sensitivity("transaction_amount") == "Confidential"

    def test_non_pii_code_returns_confidential(self):
        assert _classify_sensitivity("product_cd") == "Confidential"

    def test_pii_salary_english(self):
        assert _classify_sensitivity("salary_amount") == "Highly Confidential"


class TestExpandBusinessTerm:
    def test_expands_id_suffix(self):
        result = _expand_business_term("customer_id")
        assert "Identifier" in result

    def test_expands_dt_suffix(self):
        result = _expand_business_term("created_dt")
        assert "Date" in result

    def test_strips_table_prefix(self):
        result = _expand_business_term("tbl_customer_nm")
        assert "tbl" not in result.lower()
        assert "Name" in result

    def test_unknown_part_is_capitalized(self):
        result = _expand_business_term("invoice_num")
        assert "Invoice" in result
        assert "Number" in result


class TestDetectDataType:
    def test_integer_detection(self):
        assert _detect_data_type(["1", "2", "3", "4", "5"]) == "INTEGER"

    def test_date_detection(self):
        assert _detect_data_type(["2024-01-01", "2024-02-15", "2023-12-31"]) == "DATE"

    def test_empty_returns_string(self):
        assert _detect_data_type([]) == "STRING"

    def test_mixed_returns_string(self):
        assert _detect_data_type(["hello", "world", "foo"]) == "STRING"

    def test_boolean_detection(self):
        assert _detect_data_type(["true", "false", "true", "true", "false"]) == "BOOLEAN"


class TestGetSampleData:
    def test_returns_first_non_null(self):
        assert _get_sample_data([None, None, "hello"]) == "hello"

    def test_all_none_returns_all_blank(self):
        assert _get_sample_data([None, None]) == "(All Blank)"

    def test_truncates_long_values(self):
        assert len(_get_sample_data(["x" * 500])) <= 200


class TestPrimaryKeyCandidate:
    def test_unique_values_is_pk(self):
        assert _is_primary_key_candidate([1, 2, 3, 4, 5]) is True

    def test_duplicate_values_not_pk(self):
        assert _is_primary_key_candidate([1, 1, 2, 3]) is False

    def test_empty_not_pk(self):
        assert _is_primary_key_candidate([]) is False


class TestIsNullable:
    def test_has_none_is_nullable(self):
        assert _is_nullable([1, None, 3]) is True

    def test_no_none_not_nullable(self):
        assert _is_nullable([1, 2, 3]) is False

    def test_empty_string_is_nullable(self):
        assert _is_nullable([1, "", 3]) is True
