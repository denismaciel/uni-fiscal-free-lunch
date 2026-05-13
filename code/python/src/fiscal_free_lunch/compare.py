from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd


@dataclass(frozen=True)
class FileComparison:
    filename: str
    rows: int
    max_abs_diff: float


def _sort_frame(frame: pd.DataFrame) -> pd.DataFrame:
    sort_columns = list(frame.columns)
    return frame.sort_values(sort_columns, kind="mergesort").reset_index(drop=True)


def _numeric_columns(frame: pd.DataFrame) -> list[str]:
    return [
        column
        for column in frame.columns
        if pd.api.types.is_numeric_dtype(frame[column])
    ]


def compare_csv(
    dynare_path: Path,
    python_path: Path,
    *,
    atol: float = 1e-9,
    rtol: float = 1e-9,
) -> FileComparison:
    dynare = _sort_frame(pd.read_csv(dynare_path))
    python = _sort_frame(pd.read_csv(python_path))

    if list(dynare.columns) != list(python.columns):
        raise AssertionError(
            f"{dynare_path.name}: schema differs\n"
            f"Dynare: {list(dynare.columns)}\n"
            f"Python: {list(python.columns)}"
        )

    if len(dynare) != len(python):
        raise AssertionError(
            f"{dynare_path.name}: row count differs "
            f"(Dynare {len(dynare)}, Python {len(python)})"
        )

    numeric_columns = _numeric_columns(dynare)
    text_columns = [column for column in dynare.columns if column not in numeric_columns]

    for column in text_columns:
        dynare_values = dynare[column].astype("string")
        python_values = python[column].astype("string")
        mismatched = dynare_values != python_values
        if bool(mismatched.any()):
            row = int(np.flatnonzero(mismatched.to_numpy())[0])
            raise AssertionError(
                f"{dynare_path.name}: text mismatch in {column!r} at sorted row {row}: "
                f"{dynare_values.iloc[row]!r} != {python_values.iloc[row]!r}"
            )

    max_abs_diff = 0.0
    for column in numeric_columns:
        dynare_values = dynare[column].to_numpy(dtype=float)
        python_values = python[column].to_numpy(dtype=float)
        diff = np.abs(dynare_values - python_values)
        if len(diff):
            max_abs_diff = max(max_abs_diff, float(np.nanmax(diff)))

        close = np.isclose(dynare_values, python_values, atol=atol, rtol=rtol, equal_nan=True)
        if not bool(close.all()):
            row = int(np.flatnonzero(~close)[0])
            raise AssertionError(
                f"{dynare_path.name}: numeric mismatch in {column!r} at sorted row {row}: "
                f"{dynare_values[row]:.17g} != {python_values[row]:.17g} "
                f"(abs diff {diff[row]:.3g}, atol {atol}, rtol {rtol})"
            )

    return FileComparison(dynare_path.name, len(dynare), max_abs_diff)


def compare_directories(
    dynare_dir: Path,
    python_dir: Path,
    *,
    filenames: list[str] | None = None,
    atol: float = 1e-9,
    rtol: float = 1e-9,
) -> list[FileComparison]:
    if filenames is None:
        filenames = sorted(path.name for path in dynare_dir.glob("*.csv"))

    if not filenames:
        raise AssertionError(f"No CSV files selected in {dynare_dir}")

    results: list[FileComparison] = []
    for filename in filenames:
        dynare_path = dynare_dir / filename
        python_path = python_dir / filename
        if not dynare_path.exists():
            raise AssertionError(f"Missing Dynare CSV: {dynare_path}")
        if not python_path.exists():
            raise AssertionError(f"Missing Python CSV: {python_path}")
        results.append(compare_csv(dynare_path, python_path, atol=atol, rtol=rtol))
    return results
