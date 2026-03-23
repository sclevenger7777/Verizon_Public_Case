#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SRC_ROOT="/storage/emulated/0"
DEST_ROOT="/storage/emulated/0/USE_THIS_DIRECTORY"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
WORKDIR="$DEST_ROOT/_move_logs_$TS"
MANIFEST="$WORKDIR/matched_files.txt"
MOVED="$WORKDIR/moved_files.txt"
SKIPPED="$WORKDIR/skipped_files.txt"
ERRORS="$WORKDIR/errors.txt"

mkdir -p "$DEST_ROOT" "$WORKDIR"
: > "$MANIFEST"
: > "$MOVED"
: > "$SKIPPED"
: > "$ERRORS"

export LC_ALL=C

find "$SRC_ROOT" -type f \
  ! -path "$DEST_ROOT/*" \
  \( \
    -iname 'dumpsys*' -o \
    -iname '*ims*' -o \
    -iname '*telephony*' -o \
    -iname '*secims*' -o \
    -iname '*epdg*' -o \
    -iname '*imsbase*' -o \
    -iname '*carrier_config*' -o \
    -iname '*vzwims*' -o \
    -iname '*radio*' \
  \) | sort -u > "$MANIFEST"

while IFS= read -r src; do
  [ -n "$src" ] || continue

  rel="${src#"$SRC_ROOT"/}"
  dest="$DEST_ROOT/$rel"
  dest_dir="$(dirname "$dest")"

  if [ "$src" = "$dest" ]; then
    printf '%s\n' "$src" >> "$SKIPPED"
    continue
  fi

  mkdir -p "$dest_dir"

  if mv -n -- "$src" "$dest" 2>>"$ERRORS"; then
    printf '%s -> %s\n' "$src" "$dest" >> "$MOVED"
  else
    printf '%s\n' "$src" >> "$SKIPPED"
  fi
done < "$MANIFEST"

{
  echo "Timestamp UTC: $TS"
  echo "Source root: $SRC_ROOT"
  echo "Destination root: $DEST_ROOT"
  echo
  echo "Matched count: $(wc -l < "$MANIFEST")"
  echo "Moved count:   $(wc -l < "$MOVED")"
  echo "Skipped count: $(wc -l < "$SKIPPED")"
  echo "Error lines:   $(wc -l < "$ERRORS")"
} | tee "$WORKDIR/summary.txt"

echo
echo "Created:"
echo "  $WORKDIR"
echo "  $WORKDIR/summary.txt"
echo "  $WORKDIR/matched_files.txt"
echo "  $WORKDIR/moved_files.txt"
echo "  $WORKDIR/skipped_files.txt"
echo "  $WORKDIR/errors.txt"
