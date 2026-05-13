#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

./scripts/run-dynare-docker.sh all-figures
nix shell .#r --command Rscript --vanilla code/R/plot-figures.R
./scripts/build-figure-comparison.sh
nix run .#paper
