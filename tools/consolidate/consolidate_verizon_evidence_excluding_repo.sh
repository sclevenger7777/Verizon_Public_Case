#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SRC="/storage/emulated/0"
DEST="/storage/emulated/0/USE_THIS_DIRECTORY/evidence"
MANIFEST_DIR="/storage/emulated/0/USE_THIS_DIRECTORY/manifests"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT="$MANIFEST_DIR/evidence_consolidation_excluding_repo_$TS.log"
CANDIDATES="$MANIFEST_DIR/evidence_consolidation_candidates_$TS.txt"

# SET THIS TO THE EXACT REPO PATH
REPO_ROOT="/storage/emulated/0/Verizon_Public_Case"

mkdir -p "$DEST" "$MANIFEST_DIR"
: > "$REPORT"
: > "$CANDIDATES"

find "$SRC" \
  \( \
    -path "$SRC/Android/data" -o -path "$SRC/Android/data/*" -o \
    -path "$SRC/Android/obb"  -o -path "$SRC/Android/obb/*"  -o \
    -path "$REPO_ROOT"        -o -path "$REPO_ROOT/*" \
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
  -print 2>/dev/null | LC_ALL=C sort -u > "$CANDIDATES"

while IFS= read -r f; do
  [ -n "$f" ] || continue

  case "$f" in
    *"/USE_THIS_DIRECTORY/"*)
      printf 'SKIP already centralized: %s\n' "$f" >> "$REPORT"
      continue
      ;;
  esac

  base="$(basename "$f")"
  dest="$DEST/$base"

  if [ -e "$dest" ]; then
    stem="${base%.*}"
    ext="${base##*.}"
    if [ "$stem" = "$base" ]; then
      dest="$DEST/${base}_$TS"
    else
      dest="$DEST/${stem}_$TS.$ext"
    fi
  fi

  mv -- "$f" "$dest"
  printf 'MOVED: %s -> %s\n' "$f" "$dest" >> "$REPORT"
done < "$CANDIDATES"

{
  echo "Done."
  echo "Repo excluded: $REPO_ROOT"
  echo "Candidates: $CANDIDATES"
  echo "Report: $REPORT"
  echo "Candidate count: $(wc -l < "$CANDIDATES")"
  echo "Moved count: $(grep -c '^MOVED:' "$REPORT" 2>/dev/null || true)"
} | tee -a "$REPORT"
