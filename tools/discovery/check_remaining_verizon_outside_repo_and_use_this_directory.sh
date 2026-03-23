#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SRC="/storage/emulated/0"
REPO_ROOT="/storage/emulated/0/Verizon_Public_Case"
OUT="/storage/emulated/0/USE_THIS_DIRECTORY/manifests"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT="$OUT/remaining_verizon_outside_repo_and_use_this_directory_$TS.txt"

mkdir -p "$OUT"

find "$SRC" \
  \( \
    -path "$SRC/Android/data" -o -path "$SRC/Android/data/*" -o \
    -path "$SRC/Android/obb"  -o -path "$SRC/Android/obb/*"  -o \
    -path "$REPO_ROOT"        -o -path "$REPO_ROOT/*"        -o \
    -path "$SRC/USE_THIS_DIRECTORY" -o -path "$SRC/USE_THIS_DIRECTORY/*" \
  \) -prune -o \
  -type f \
  \( \
    -iname '*telephony*' -o \
    -iname '*ims*' -o \
    -iname '*secims*' -o \
    -iname '*radio*' -o \
    -iname '*carrier_config*' -o \
    -iname '*connectivity*' -o \
    -iname '*vzw*' -o \
    -iname '*verizon*' \
  \) \
  -print 2>/dev/null | LC_ALL=C sort -u > "$REPORT"

echo "Report: $REPORT"
echo "Remaining count: $(wc -l < "$REPORT")"
