#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

./scripts/run-dynare-docker.sh all-figures
./scripts/build-figure-comparison.sh
nix run .#paper
