from __future__ import annotations

import argparse
from pathlib import Path

from fiscal_free_lunch.compare import compare_directories
from fiscal_free_lunch.experiments import (
    write_all_figures,
    write_figure_1a,
    write_figure_1b,
    write_figure_2,
    write_figure_3,
)
from fiscal_free_lunch.params import Params


def _compare(args: argparse.Namespace) -> int:
    results = compare_directories(
        args.dynare,
        args.python,
        filenames=args.file,
        atol=args.atol,
        rtol=args.rtol,
    )
    for result in results:
        print(
            f"OK {result.filename}: {result.rows} rows, "
            f"max abs diff {result.max_abs_diff:.3g}"
        )
    return 0


def _run(args: argparse.Namespace) -> int:
    if args.experiment == "all-figures":
        paths = write_all_figures(args.output)
    elif args.experiment == "figure-1a":
        paths = [write_figure_1a(args.output)]
    elif args.experiment == "figure-1b":
        paths = [write_figure_1b(args.output)]
    elif args.experiment == "figure-2":
        paths = [
            write_figure_2(
                args.output,
                Params(xip=args.xip, gam_xgap=args.gam_xgap, gam_pi=args.gam_pi),
            )
        ]
    elif args.experiment == "figure-3":
        paths = write_figure_3(args.output, Params(xip=args.xip))
    else:
        raise SystemExit(f"Unknown experiment: {args.experiment}")
    for path in paths:
        print(f"Wrote {path}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="fiscal-free-lunch")
    subparsers = parser.add_subparsers(dest="command", required=True)

    compare = subparsers.add_parser("compare")
    compare.add_argument("--dynare", type=Path, default=Path("../../artifacts/data"))
    compare.add_argument("--python", type=Path, default=Path("../../artifacts/python-data"))
    compare.add_argument("--file", action="append")
    compare.add_argument("--atol", type=float, default=1e-9)
    compare.add_argument("--rtol", type=float, default=1e-9)
    compare.set_defaults(func=_compare)

    run = subparsers.add_parser("run")
    run.add_argument("experiment", choices=["all-figures", "figure-1a", "figure-1b", "figure-2", "figure-3"])
    run.add_argument("--output", type=Path, default=Path("../../artifacts/python-data"))
    run.add_argument("--xip", type=float, default=1.0)
    run.add_argument("--gam-xgap", type=float, default=66.15)
    run.add_argument("--gam-pi", type=float, default=66.15)
    run.set_defaults(func=_run)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)
