# Code

This directory keeps the working simulation and figure-generation code.

- `dynare/model/base.mod`: shared Dynare model definition.
- `dynare/experiments/`: figure-specific simulation scripts.
- `dynare/model.mod`: compatibility wrapper for the default Figure 2 run.
- `R/`: R/ggplot figure-generation scripts.

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

Generated figures are copied to `artifacts/figures/`. The paper reads generated
figures from there; the committed figures under `paper/figures/` are retained as
reference imports.

To regenerate code outputs and build the paper:

```sh
./scripts/build-all.sh
```

Python port:

```sh
cd code/python
uv run fiscal-free-lunch run all-figures --output ../../artifacts/python-data
uv run fiscal-free-lunch compare --dynare ../../artifacts/data --python ../../artifacts/python-data
cd ../..
nix shell .#r --command Rscript --vanilla code/R/plot-figures.R --impl python
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

The imported Figure 2 source had a stale plotting line,
`plot(25*debtg(1:40));`, which fails because `debtg` is not a standalone
workspace variable. The cleaned working copy removes that line.
