#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
generated_dir="$repo_root/artifacts/figures"
out_dir="$repo_root/artifacts/comparison"
generated_png_dir="$out_dir/generated"
original_png_dir="$out_dir/original"
html="$repo_root/artifacts/figure-comparison.html"

mkdir -p "$generated_png_dir" "$original_png_dir"

slugify() {
  basename "$1" | sed -E 's/\.[^.]+$//' | tr '[:upper:]' '[:lower:]'
}

convert_to_png() {
  local src="$1"
  local dst="$2"
  local ext="${src##*.}"
  ext="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

  case "$ext" in
    pdf)
      local tmp_prefix
      tmp_prefix="$(mktemp -u)"
      pdftoppm -png -singlefile -r 180 "$src" "$tmp_prefix"
      magick "${tmp_prefix}.png" -trim -bordercolor white -border 24 "$dst"
      rm -f "${tmp_prefix}.png"
      ;;
    eps|ps)
      magick -density 180 "$src" -trim -bordercolor white -border 24 "$dst"
      ;;
    png|jpg|jpeg)
      magick "$src" -trim -bordercolor white -border 24 "$dst"
      ;;
    *)
      return 1
      ;;
  esac
}

find_original_for() {
  local stem="$1"
  local candidate
  local aliases=("$stem")

  case "$stem" in
    figure-2-no-inflation-response)
      aliases+=("figure-2-no-ir")
      ;;
  esac

  for alias in "${aliases[@]}"; do
    for candidate in \
      "$repo_root/paper/figures/original/${alias}.png" \
      "$repo_root/paper/figures/${alias}.eps" \
      "$repo_root/paper/figures/${alias}.pdf"; do
      if [[ -f "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done
  done

  return 1
}

find_generated_for() {
  local stem="$1"
  local candidate
  local aliases=("$stem")

  case "$stem" in
    figure-1a-presentation)
      aliases+=("figure-1a")
      ;;
    figure-1b-presentation)
      aliases+=("figure-1b")
      ;;
    figure-2-no-ir)
      aliases+=("figure-2-no-inflation-response")
      ;;
    figure-3-10-quarter-price-contract-multiplier)
      aliases+=("figure-3-runs/multiplier-xip-0.90")
      ;;
    figure-3-5-quarter-price-contract-multiplier)
      aliases+=("figure-3-runs/multiplier-xip-0.80")
      ;;
    figure-3-4-quarter-price-contract-multiplier)
      aliases+=("figure-3-runs/multiplier-xip-0.75")
      ;;
    figure-3-alternative-contract-durations-government-debt-presentation)
      aliases+=("figure-3-alternative-contract-durations-government-debt")
      ;;
    figure-3-no-inflation-response-government-debt-presentation)
      aliases+=("figure-3-no-inflation-response-government-debt")
      ;;
    figure-3-no-inflation-response-multiplier|figure-3-no-inflation-response-multiplier-presentation)
      aliases+=("figure-3-runs/multiplier-xip-1.00")
      ;;
  esac

  for alias in "${aliases[@]}"; do
    for candidate in \
      "$generated_dir/${alias}.pdf" \
      "$generated_dir/${alias}.eps" \
      "$generated_dir/${alias}.png" \
      "$generated_dir/${alias}.jpg" \
      "$generated_dir/${alias}.jpeg"; do
      if [[ -f "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done
  done

  return 1
}

mapfile -t generated_files < <(
  find "$generated_dir" -maxdepth 3 -type f \
    \( -iname '*.pdf' -o -iname '*.eps' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
    | sort
)

mapfile -t original_files < <(
  find "$repo_root/paper/figures/original" -maxdepth 1 -type f \
    \( -iname '*.pdf' -o -iname '*.eps' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
    | sort
)

{
  cat <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Figure Comparison</title>
  <style>
    body {
      margin: 24px;
      font-family: system-ui, sans-serif;
      background: #f6f6f3;
      color: #1f2528;
    }

    h1 {
      margin: 0 0 8px;
      font-size: 24px;
      font-weight: 650;
    }

    .summary {
      margin: 0 0 24px;
      color: #596168;
    }

    .pair {
      margin: 0 0 28px;
      padding-top: 20px;
      border-top: 1px solid #d8d8d2;
    }

    h2 {
      margin: 0 0 14px;
      font-size: 18px;
      font-weight: 650;
    }

    .comparison {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 20px;
      align-items: start;
    }

    figure {
      margin: 0;
      padding: 16px;
      background: white;
      border: 1px solid #d8d8d2;
    }

    figcaption {
      margin-bottom: 8px;
      font-weight: 650;
    }

    .meta {
      margin: 0 0 12px;
      color: #596168;
      font-size: 13px;
      overflow-wrap: anywhere;
    }

    img {
      display: block;
      width: 100%;
      height: auto;
      max-height: 760px;
      border: 1px solid #ecece7;
      background: white;
      object-fit: contain;
    }

    .missing {
      display: grid;
      min-height: 220px;
      place-items: center;
      border: 1px dashed #b9b9b0;
      color: #596168;
      background: #fbfbf8;
    }

    @media (max-width: 900px) {
      .comparison {
        grid-template-columns: 1fr;
      }

      img {
        max-height: 520px;
      }
    }
  </style>
</head>
<body>
  <h1>Figure Comparison</h1>
HTML

  printf '  <p class="summary">%d original figure(s), %d generated figure(s).</p>\n' "${#original_files[@]}" "${#generated_files[@]}"

  if [[ "${#original_files[@]}" -eq 0 ]]; then
    printf '  <p>No original figures found in <code>paper/figures/original</code>.</p>\n'
  elif [[ "${#generated_files[@]}" -eq 0 ]]; then
    printf '  <p>No generated figures found. Run <code>./scripts/run-dynare-docker.sh figure-2</code> first.</p>\n'
  fi

  for original in "${original_files[@]}"; do
    stem="$(slugify "$original")"
    original_png="$original_png_dir/${stem}.png"
    original_rel="comparison/original/${stem}.png"
    convert_to_png "$original" "$original_png"

    generated=""
    generated_png=""
    generated_rel=""
    if generated="$(find_generated_for "$stem")"; then
      generated_stem="$(slugify "$generated")"
      generated_png="$generated_png_dir/${generated_stem}.png"
      generated_rel="comparison/generated/${generated_stem}.png"
      convert_to_png "$generated" "$generated_png"
    fi

    printf '  <section class="pair">\n'
    printf '    <h2>%s</h2>\n' "$stem"
    printf '    <main class="comparison">\n'

    printf '      <figure>\n'
    printf '        <figcaption>Original committed figure</figcaption>\n'
    printf '        <p class="meta"><code>%s</code></p>\n' "${original#"$repo_root/"}"
    printf '        <img src="%s" alt="Original %s">\n' "$original_rel" "$stem"
    printf '      </figure>\n'

    printf '      <figure>\n'
    printf '        <figcaption>Generated figure</figcaption>\n'
    if [[ -n "$generated" ]]; then
      printf '        <p class="meta"><code>%s</code></p>\n' "${generated#"$repo_root/"}"
      printf '        <img src="%s" alt="Generated %s">\n' "$generated_rel" "$stem"
    else
      printf '        <div class="missing">No generated figure found</div>\n'
    fi
    printf '      </figure>\n'

    printf '    </main>\n'
    printf '  </section>\n'
  done

  cat <<'HTML'
</body>
</html>
HTML
} > "$html"

printf 'Wrote %s\n' "${html#"$repo_root/"}"
