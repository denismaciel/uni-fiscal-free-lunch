from __future__ import annotations

import re
from dataclasses import replace
from pathlib import Path

import numpy as np
import pandas as pd

from fiscal_free_lunch.model import simulate
from fiscal_free_lunch.params import Params


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def _figure3_shocks() -> np.ndarray:
    source = _repo_root() / "code" / "dynare" / "figure-3.mod"
    text = source.read_text()
    match = re.search(r'@#define x = \[(.*?)\]\s*\n\n@#for', text, re.S)
    if match is None:
        raise RuntimeError(f"Could not parse figure-3 shock grid from {source}")
    return np.array([float(value) for value in re.findall(r'"([^"]+)"', match.group(1))])


def write_figure_1a(output_dir: Path, params: Params = Params()) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    periods = 150

    irfs_gov0 = simulate(
        periods=periods,
        eps_con=-params.sig_con,
        eps_gov=0.0,
        params=params,
    )
    irfs_gov1 = simulate(
        periods=periods,
        eps_con=-params.sig_con,
        eps_gov=params.sig_gov,
        params=params,
    )
    irfs_gov2 = simulate(
        periods=periods,
        eps_con=-params.sig_con,
        eps_gov=0.1,
        params=params,
    )

    rows: list[dict[str, float | int | str]] = []
    for column in range(1, 16):
        quarter = column - 1
        rows.extend(
            [
                {
                    "quarter": quarter,
                    "series": "potential_real_rate_taste_shock_only",
                    "value": 400 * irfs_gov0.series("rpotV")[column],
                },
                {
                    "quarter": quarter,
                    "series": "nominal_interest_rate_taste_shock_only",
                    "value": 400 * irfs_gov0.series("iV")[column],
                },
                {
                    "quarter": quarter,
                    "series": "potential_real_rate_1_percent_g_increase",
                    "value": 400 * irfs_gov1.series("rpotV")[column],
                },
                {
                    "quarter": quarter,
                    "series": "potential_real_rate_2_percent_g_increase",
                    "value": 400 * irfs_gov2.series("rpotV")[column],
                },
            ]
        )

    path = output_dir / "figure-1a.csv"
    pd.DataFrame(rows).to_csv(path, index=False)
    return path


def write_figure_1b(output_dir: Path, params: Params = Params()) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    rows: list[dict[str, float]] = []
    for sig_con in np.round(np.arange(0, 50.0 + 0.1, 0.1), 10):
        sim = simulate(
            periods=40,
            eps_con=-float(sig_con),
            eps_gov=params.sig_gov,
            params=replace(params, sig_con=float(sig_con)),
        )
        rows.append(
            {
                "potential_real_interest_rate": 400 * sim.series("rpotV")[1],
                "liquidity_trap_duration": float(np.sum(sim.series("iV") == -params.ibar)),
            }
        )

    path = output_dir / "figure-1b.csv"
    pd.DataFrame(rows).to_csv(path, index=False)
    return path


def _figure_2_id(params: Params) -> str:
    if params.xip == 1:
        return "figure-2-no-inflation-response"
    if params.xip == 0.8 and params.gam_xgap == 0.2 and params.gam_pi == 1.5:
        return "figure-2-5-quarter-new-taylor-rule"
    if params.xip == 0.8:
        return "figure-2-5-quarter-price-contract"
    return f"figure-2-xip-{params.xip:.2f}"


def write_figure_2(output_dir: Path, params: Params = Params()) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    figure_id = _figure_2_id(params)
    periods = 40

    irfs_gov1 = simulate(
        periods=periods,
        eps_con=-params.sig_con,
        eps_gov=params.sig_gov,
        params=params,
    )
    irfs_gov2 = simulate(
        periods=periods,
        eps_con=-params.sig_con,
        eps_gov=0.0,
        params=params,
    )

    rows: list[dict[str, float | int | str]] = []
    specs = [
        ("real_interest_rate", "rV", 400),
        ("output_gap", "xV", 100),
        ("inflation", "piV", 400),
        ("government_debt_to_gdp", "debtg", 25),
    ]
    for column in range(1, 20):
        quarter = column - 1
        for variable, model_variable, scale in specs:
            both = scale * irfs_gov1.series(model_variable)[column]
            taste = scale * irfs_gov2.series(model_variable)[column]
            rows.extend(
                [
                    {
                        "figure_id": figure_id,
                        "xip": params.xip,
                        "quarter": quarter,
                        "variable": variable,
                        "series": "both_shocks",
                        "value": both,
                    },
                    {
                        "figure_id": figure_id,
                        "xip": params.xip,
                        "quarter": quarter,
                        "variable": variable,
                        "series": "taste_shock_only",
                        "value": taste,
                    },
                    {
                        "figure_id": figure_id,
                        "xip": params.xip,
                        "quarter": quarter,
                        "variable": variable,
                        "series": "government_shock_only",
                        "value": both - taste,
                    },
                ]
            )

    path = output_dir / f"{figure_id}.csv"
    pd.DataFrame(rows).to_csv(path, index=False)
    return path


def write_figure_3(output_dir: Path, params: Params) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    shocks = _figure3_shocks()
    sims = [
        simulate(
            periods=40,
            eps_con=-params.sig_con,
            eps_gov=float(shock),
            params=params,
        )
        for shock in shocks
    ]

    i_values = np.array([sim.series("iV") for sim in sims])
    liqduration = np.sum(i_values == -params.ibar, axis=1)

    xip_name = f"{params.xip:.2f}"
    duration_path = output_dir / f"figure-3-liquidity-trap-duration-xip-{xip_name}.csv"
    pd.DataFrame(
        {
            "xip": params.xip,
            "shock": shocks,
            "liquidity_trap_duration": liqduration,
        }
    ).to_csv(duration_path, index=False)

    y = np.array([sim.series("yV")[1] for sim in sims])
    g = np.array([sim.series("govshk")[1] for sim in sims])
    debtgov = np.array([sim.series("debtg")[1] for sim in sims])

    marginal_multiplier = np.diff(y) / np.diff(g) * (1 / params.shrgy)
    government_debt_multiplier = np.diff(debtgov) / np.diff(g)

    liqmul_shock = shocks[:-1].copy()
    liqmul_multiplier = marginal_multiplier.copy()
    liqmul_duration = liqduration[:-1]

    base_index = int(np.flatnonzero(np.abs(liqmul_shock) == np.min(np.abs(liqmul_shock)))[-1])
    average_multiplier = np.full(len(liqmul_shock), np.nan)
    for idx in range(base_index, len(liqmul_shock)):
        denominator = g[idx] - g[base_index]
        if denominator != 0:
            average_multiplier[idx] = (y[idx] - y[base_index]) / denominator * (1 / params.shrgy)

    to_include = liqmul_duration[:-1] == liqduration[1:-1]
    liqmul_shock = liqmul_shock[:-1]
    liqmul_multiplier = liqmul_multiplier[:-1]
    average_multiplier = average_multiplier[:-1]

    liqmul_shock = liqmul_shock[to_include]
    liqmul_multiplier = liqmul_multiplier[to_include]
    average_multiplier = average_multiplier[to_include]

    multiplier_path = output_dir / f"figure-3-multiplier-xip-{xip_name}.csv"
    pd.DataFrame(
        {
            "xip": params.xip,
            "shock": liqmul_shock,
            "marginal_multiplier": liqmul_multiplier,
            "average_multiplier": average_multiplier,
        }
    ).to_csv(multiplier_path, index=False)

    debt_path = output_dir / f"figure-3-government-debt-xip-{xip_name}.csv"
    pd.DataFrame(
        {
            "xip": params.xip,
            "shock": shocks[:-1],
            "government_debt_multiplier": government_debt_multiplier,
        }
    ).to_csv(debt_path, index=False)

    return [duration_path, multiplier_path, debt_path]


def write_all_figures(output_dir: Path) -> list[Path]:
    paths = [
        write_figure_1a(output_dir),
        write_figure_1b(output_dir),
        write_figure_2(output_dir, Params()),
        write_figure_2(output_dir, Params(xip=0.8)),
        write_figure_2(output_dir, Params(xip=0.8, gam_xgap=0.2, gam_pi=1.5)),
    ]
    for xip in [1, 0.9, 0.8, 0.75]:
        paths.extend(write_figure_3(output_dir, Params(xip=xip)))
    return paths
