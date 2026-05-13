#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/run-dynare-docker.sh all-figures
  ./scripts/run-dynare-docker.sh figure-1a|figure-1b|figure-2|figure-3 [--xip VALUE] [--gam-xgap VALUE] [--gam-pi VALUE] [--sig-con VALUE] [--sig-gov VALUE]
  ./scripts/run-dynare-docker.sh path/to/model.mod

Examples:
  ./scripts/run-dynare-docker.sh all-figures
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

write_wrapper() {
  local target="$1"
  local body="$2"
  cat > "$run_dir/$target" <<EOF
@#define XIP = $xip
@#define GAM_XGAP = $gam_xgap
@#define GAM_PI = $gam_pi
@#define SIG_CON = $sig_con
@#define SIG_GOV = $sig_gov

@#include "model/base.mod"
@#include "$body"
EOF
}

run_dynare_model() {
  local model="$1"
  docker run --rm \
    --entrypoint bash \
    --user root \
    -v "$run_dir:/work" \
    -w /work \
    dynare/dynare:latest \
    -lc "octave --no-gui --eval 'addpath(\"/home/matlab/dynare/matlab\"); dynare $model'"
}

case "$experiment" in
  all-figures)
    write_wrapper "figure_1a_run.mod" "figure-1a.mod"
    write_wrapper "figure_1b_run.mod" "figure-1b.mod"
    cat > "$run_dir/figure_2_run.mod" <<EOF
@#define XIP = $xip
@#define GAM_XGAP = $gam_xgap
@#define GAM_PI = $gam_pi
@#define SIG_CON = $sig_con
@#define SIG_GOV = $sig_gov

@#include "model/base.mod"
@#include "experiments/figure-2.mod"
EOF
    cat > "$run_dir/figure_2_xip_0_8_run.mod" <<EOF
@#define XIP = 0.8
@#define GAM_XGAP = $gam_xgap
@#define GAM_PI = $gam_pi
@#define SIG_CON = $sig_con
@#define SIG_GOV = $sig_gov

@#include "model/base.mod"
@#include "experiments/figure-2.mod"
EOF
    cat > "$run_dir/figure_2_xip_0_8_taylor_run.mod" <<EOF
@#define XIP = 0.8
@#define GAM_XGAP = 0.2
@#define GAM_PI = 1.5
@#define SIG_CON = $sig_con
@#define SIG_GOV = $sig_gov

@#include "model/base.mod"
@#include "experiments/figure-2.mod"
EOF
    models=("figure_1a_run.mod" "figure_1b_run.mod" "figure_2_run.mod" "figure_2_xip_0_8_run.mod" "figure_2_xip_0_8_taylor_run.mod")
    ;;
  figure-1a)
    write_wrapper "experiment.mod" "figure-1a.mod"
    models=("experiment.mod")
    ;;
  figure-1b)
    write_wrapper "experiment.mod" "figure-1b.mod"
    models=("experiment.mod")
    ;;
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
    models=("experiment.mod")
    ;;
  figure-3)
    models=()
    ;;
  *.mod)
    models=("$experiment")
    ;;
  *)
    echo "Unknown experiment: $experiment" >&2
    usage >&2
    exit 2
    ;;
esac

if [[ "$experiment" == "figure-3" || "$experiment" == "all-figures" ]]; then
  for figure_3_xip in 1 0.9 0.8 0.75; do
    xip="$figure_3_xip"
    wrapper_xip="$(printf '%s' "$figure_3_xip" | tr '.' '_')"
    write_wrapper "figure_3_xip_${wrapper_xip}.mod" "figure-3.mod"
    run_dynare_model "figure_3_xip_${wrapper_xip}.mod"
  done
fi

for model in "${models[@]}"; do
  run_dynare_model "$model"
done

if [[ -d "$run_dir/output/data" ]]; then
  mkdir -p "$repo_root/artifacts/data"
  cp -R "$run_dir/output/data"/. "$repo_root/artifacts/data"/
fi

docker run --rm \
  --entrypoint bash \
  --user root \
  -v "$run_dir:/work" \
  -w /work \
  dynare/dynare:latest \
  -lc "rm -rf +* model *.log *.m *.mat"
