#!/usr/bin/env bash
#
# optimize-site.sh   — Brown Derbies static-site image + HTML optimiser
#
#  • Requires:  bash ≥4, GNU find, GNU sed, cwebp (brew install webp)
#  • Usage:    ./optimize-site.sh
#
set -euo pipefail

echo "=== 1. Converting images to WebP ====================================="

# convert every .jpg|.jpeg|.png under images/ to .webp (quality 85)
find images -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
  ! -iname '*.webp' \
  -print0 |
while IFS= read -r -d '' img; do
  webp="${img%.*}.webp"
  if [[ -e "$webp" ]]; then
    echo "• WebP exists, skipping  $img"
  else
    echo "• cwebp $img → $webp"
    cwebp -quiet -q 85 "$img" -o "$webp"
  fi
done

echo
echo "=== 2. Rewriting <img> tags in HTML ==================================="

# Regex: capture opening <img …>  (we need GNU sed for \K)
IMG_RE='\<img\([^>]*\)\bsrc="\([^"]*\.\(jpg\|jpeg\|png\)\)"\([^>]*\)\>'
# Patterns we *don’t* want to touch
IGNORE='Derbies_Logo\|Derby_Logo_White\|favicon'

export IMG_RE IGNORE

find images -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
  ! -iname '*.webp' -print0 |
while IFS= read -r -d '' img; do
  webp="${img%.*}.webp"

  if [[ -e "$webp" ]]; then
    echo "• WebP exists, skipping  $(basename "$img")"
    continue
  fi

  if cwebp -quiet -q 85 "$img" -o "$webp"; then
    echo "• cwebp $(basename "$img") → $(basename "$webp")"
  else
    echo "⚠️  cwebp FAILED for $img — leaving original intact" | tee -a convert_errors.log
    rm -f "$webp"
  fi
done

echo
echo "✓ All done!  Original HTML kept as *.bak for safety."