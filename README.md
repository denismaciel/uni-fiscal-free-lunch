# Fiscal Free Lunch

This repository contains the LaTeX source, Dynare code, modernized
simulation pipeline, generated figure inputs, and reproducible build environment
for the fiscal free lunch seminar paper.

## Provenance Note

The paper and code were originally written as a university seminar project.
Original paper figures are kept under `paper/figures/` for visual comparison.

In May 2026, the repository was revisited and modernized with Codex. The goal of
that work is engineering reproducibility: split the simulation code into named
entrypoints, export tabular data from Dynare, render figures from that data with
R/ggplot, build the paper with Nix, and add a Python port that can be compared
against Dynare outputs.

The modernization is not intended to change the paper's economics. Behavioral
changes should be explicit, reviewable, and traceable through Git history.

## Build

```sh
nix develop
./scripts/build-all.sh
```

`./scripts/build-all.sh` regenerates Dynare CSVs, renders figures with R, builds
the figure comparison HTML, and builds the paper PDF.

To build only the paper:

```sh
nix run .#paper
```

The paper entrypoint is `paper/main.tex`. LaTeX build products are written to
`compilation/`, and the built PDF is copied to
`artifacts/fiscal-free-lunch-paper.pdf`.

## PDF Snapshot

- `artifacts/fiscal-free-lunch-paper.pdf` is the generated paper PDF from the
  current TeX source, generated figures, and bibliography.

## Code Pipeline

Run Dynare through Docker and export CSV data:

```sh
./scripts/run-dynare-docker.sh all-figures
```

Render figures from exported data:

```sh
nix shell .#r --command Rscript --vanilla code/R/plot-figures.R
```

Build the side-by-side figure comparison page:

```sh
./scripts/build-figure-comparison.sh
```

Open `artifacts/figure-comparison.html` to compare original paper figures with
the newly generated R figures.

## Python Port

The Python implementation is a port of the Dynare simulations. Its current job
is to reproduce Dynare's tabular outputs closely enough to serve as a cleaner
future simulation backend.

```sh
cd code/python
uv run pytest
uv run fiscal-free-lunch run all-figures --output ../../artifacts/python-data
uv run fiscal-free-lunch compare --dynare ../../artifacts/data --python ../../artifacts/python-data
cd ../..
```

Render figures from Python-generated CSVs from the repository root:

```sh
nix shell .#r --command Rscript --vanilla code/R/plot-figures.R --impl python
```

The repository uses `uv`; do not assume a global `python`.

## Current Status

- Dynare runs are available through Docker.
- Dynare graphing has been removed from the working pipeline; Dynare exports
  CSV data instead.
- R/ggplot renders the paper figures from generated CSV data.
- Original figures remain committed as references.
- Python reproduces the generated Dynare CSVs and has tests under
  `code/python/tests/`.
- Generated artifacts stay under `artifacts/` and are ignored by Git.

## Layout

```text
paper/
  main.tex
  preamble.tex
  frontmatter/
  chapters/
  backmatter/
  bibliography/
  figures/
code/
  dynare/
  R/
  python/
docs/
scripts/
artifacts/
```
