#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/run-dynare-docker.sh figure-2 [--xip VALUE] [--gam-xgap VALUE] [--gam-pi VALUE] [--sig-con VALUE] [--sig-gov VALUE]
  ./scripts/run-dynare-docker.sh path/to/model.mod

Examples:
  ./scripts/run-dynare-docker.sh figure-2
  ./scripts/run-dynare-docker.sh figure-2 --xip 0.8 --gam-xgap 66.15
USAGE
}

experiment="${1:-figure-2}"
if [[ "$experiment" == "-h" || "$experiment" == "--help" ]]; then
  usage
  exit 0
fi
shift || true

xip="1"
gam_xgap="66.15"
gam_pi="66.15"
sig_con="29.2"
sig_gov="0.05"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --xip)
      xip="$2"
      shift 2
      ;;
    --gam-xgap)
      gam_xgap="$2"
      shift 2
      ;;
    --gam-pi)
      gam_pi="$2"
      shift 2
      ;;
    --sig-con)
      sig_con="$2"
      shift 2
      ;;
    --sig-gov)
      sig_gov="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

repo_root="$(git rev-parse --show-toplevel)"
src_dir="$repo_root/code/dynare"
run_dir="$repo_root/artifacts/dynare-run"

if [[ -d "$run_dir" ]]; then
  docker run --rm \
    --entrypoint bash \
    --user root \
    -v "$run_dir:/work" \
    -w /work \
    dynare/dynare:latest \
    -lc "rm -rf ./* ./.??*"
fi
rm -rf "$run_dir"
mkdir -p "$run_dir"
cp -R "$src_dir"/. "$run_dir"/

case "$experiment" in
  figure-2)
    cat > "$run_dir/experiment.mod" <<EOF
@#define XIP = $xip
@#define GAM_XGAP = $gam_xgap
@#define GAM_PI = $gam_pi
@#define SIG_CON = $sig_con
@#define SIG_GOV = $sig_gov

@#include "model/base.mod"
@#include "experiments/figure-2.mod"
EOF
    model="experiment.mod"
    ;;
  *.mod)
    model="$experiment"
    ;;
  *)
    echo "Unknown experiment: $experiment" >&2
    usage >&2
    exit 2
    ;;
esac

docker run --rm \
  --entrypoint bash \
  --user root \
  -v "$run_dir:/work" \
  -w /work \
  dynare/dynare:latest \
  -lc "octave --no-gui --eval 'addpath(\"/home/matlab/dynare/matlab\"); dynare $model'"

docker run --rm \
  --entrypoint bash \
  --user root \
  -v "$run_dir:/work" \
  -w /work \
  dynare/dynare:latest \
  -lc "rm -rf +* model *.log *.m *.mat"
