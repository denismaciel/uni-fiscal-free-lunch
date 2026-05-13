from pathlib import Path

import pandas as pd
import pytest

from fiscal_free_lunch.compare import compare_csv


def test_compare_csv_accepts_matching_files(tmp_path: Path) -> None:
    left = tmp_path / "left.csv"
    right = tmp_path / "right.csv"
    frame = pd.DataFrame(
        {
            "quarter": [1, 0],
            "series": ["b", "a"],
            "value": [2.0, 1.0],
        }
    )
    frame.to_csv(left, index=False)
    frame.iloc[::-1].to_csv(right, index=False)

    result = compare_csv(left, right)

    assert result.rows == 2
    assert result.max_abs_diff == 0.0


def test_compare_csv_reports_numeric_difference(tmp_path: Path) -> None:
    left = tmp_path / "left.csv"
    right = tmp_path / "right.csv"
    pd.DataFrame({"series": ["a"], "value": [1.0]}).to_csv(left, index=False)
    pd.DataFrame({"series": ["a"], "value": [1.1]}).to_csv(right, index=False)

    with pytest.raises(AssertionError, match="numeric mismatch"):
        compare_csv(left, right, atol=1e-12, rtol=1e-12)
