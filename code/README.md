# Code

This directory keeps the imported code and the reproducible working copy separate.

- `original/`: untouched import from `denismaciel/uni-fiscalfreelunch`.
- `dynare/model/base.mod`: shared Dynare model definition.
- `dynare/experiments/`: figure-specific simulation scripts.
- `dynare/model.mod`: compatibility wrapper for the default Figure 2 run.
- `R/`: R helper scripts from the original import.

Run the current Dynare baseline with Docker:

```sh
./scripts/run-dynare-docker.sh figure-2
```

The runner creates `artifacts/dynare-run/experiment.mod` from CLI options, includes
the shared model, and then includes the selected experiment. This has been
validated with `dynare/dynare:latest` (Dynare 6.5 + Octave).

Example with explicit calibration:

```sh
./scripts/run-dynare-docker.sh figure-2 --xip 1 --gam-xgap 66.15 --gam-pi 66.15
```

Known validated Figure 2 output:

```text
liqduration = 8  8
mul1 = 0.5840
x = 0.4335
ypot = 0.1505
mul = 0.5840
debtgov = 0.012692
```

The original Figure 2 file had a stale plotting line,
`plot(25*debtg(1:40));`, which fails because `debtg` is not a standalone
workspace variable. The cleaned copy removes that line; `code/original/` is left
unchanged.
