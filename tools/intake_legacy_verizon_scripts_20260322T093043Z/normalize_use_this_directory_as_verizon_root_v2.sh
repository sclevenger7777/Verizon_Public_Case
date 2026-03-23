#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="/storage/emulated/0"
VERIZON_ROOT="$ROOT/USE_THIS_DIRECTORY"
QUAR="$ROOT/Quarantine_Unrelated_From_USE_THIS_DIRECTORY"
LOGDIR="$ROOT/Verizon_Consolidation_Logs"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
AUDIT="$LOGDIR/use_this_directory_audit_v2_$TS.txt"
MOVED="$LOGDIR/use_this_directory_moved_v2_$TS.txt"
SKIPPED="$LOGDIR/use_this_directory_skipped_v2_$TS.txt"

mkdir -p "$VERIZON_ROOT" "$QUAR" "$LOGDIR"
mkdir -p \
  "$VERIZON_ROOT/evidence" \
  "$VERIZON_ROOT/scripts" \
  "$VERIZON_ROOT/manifests" \
  "$VERIZON_ROOT/legal" \
  "$VERIZON_ROOT/analysis" \
  "$VERIZON_ROOT/exports" \
  "$VERIZON_ROOT/misc_review"

: > "$AUDIT"
: > "$MOVED"
: > "$SKIPPED"

echo "=== USE_THIS_DIRECTORY normalization audit v2 ===" >> "$AUDIT"
echo "UTC: $(date -u)" >> "$AUDIT"
echo >> "$AUDIT"

safe_mv() {
  local src="$1"
  local dest="$2"
  local final="$dest"

  if [ ! -e "$src" ]; then
    printf 'MISSING: %s\n' "$src" >> "$SKIPPED"
    return 0
  fi

  mkdir -p "$(dirname "$final")"

  if [ -e "$final" ]; then
    local base ext stem
    base="$(basename "$final")"
    if [[ "$base" == *.* ]]; then
      ext=".${base##*.}"
      stem="${base%.*}"
      final="$(dirname "$final")/${stem}_$TS${ext}"
    else
      final="$(dirname "$final")/${base}_$TS"
    fi
  fi

  if mv -n "$src" "$final"; then
    printf '%s -> %s\n' "$src" "$final" >> "$MOVED"
  else
    printf 'FAILED: %s -> %s\n' "$src" "$final" >> "$SKIPPED"
  fi
}

safe_cp() {
  local src="$1"
  local dest="$2"
  local final="$dest"

  if [ ! -e "$src" ]; then
    printf 'MISSING COPY SOURCE: %s\n' "$src" >> "$SKIPPED"
    return 0
  fi

  mkdir -p "$(dirname "$final")"

  if [ -e "$final" ]; then
    local base ext stem
    base="$(basename "$final")"
    if [[ "$base" == *.* ]]; then
      ext=".${base##*.}"
      stem="${base%.*}"
      final="$(dirname "$final")/${stem}_$TS${ext}"
    else
      final="$(dirname "$final")/${base}_$TS"
    fi
  fi

  if cp -n "$src" "$final"; then
    printf 'COPIED %s -> %s\n' "$src" "$final" >> "$MOVED"
  else
    printf 'FAILED COPY: %s -> %s\n' "$src" "$final" >> "$SKIPPED"
  fi
}

echo "[Initial tree: $VERIZON_ROOT]" >> "$AUDIT"
find "$VERIZON_ROOT" -maxdepth 5 | sort >> "$AUDIT" 2>/dev/null || true
echo >> "$AUDIT"

# Move obviously unrelated material.
# Important: sort deepest paths first to avoid stale child paths after parent move.
find "$VERIZON_ROOT" -mindepth 1 -maxdepth 8 \
  \( -iname "*happy*" -o -iname "*happymod*" -o -iname "*modded*" -o -iname "*xapk*" -o -iname "*.apk" \) \
  ! -iname "*verizon*" \
  ! -iname "*vzw*" \
  ! -iname "*ims*" \
  ! -iname "*telephony*" \
  ! -iname "*radio*" \
  ! -iname "*epdg*" \
  ! -iname "*carrier*" \
  -print 2>/dev/null | awk '{ print length($0), $0 }' | sort -rn | cut -d" " -f2- |
while IFS= read -r p; do
  [ -z "$p" ] && continue
  safe_mv "$p" "$QUAR/$(basename "$p")"
done

# Collect Verizon-related scripts into scripts/
find "$HOME" "$ROOT/Download" "$ROOT/Downloads" "$ROOT/Verizon_Public_Case" "$ROOT" \
  -maxdepth 4 -type f \
  \( -iname "*.sh" -o -iname "*.bash" -o -iname "*.zsh" -o -iname "*.py" \) \
  \( -iname "*verizon*" -o -iname "*vzw*" -o -iname "*ims*" -o -iname "*telephony*" -o -iname "*epdg*" -o -iname "*provision*" -o -iname "*carrier*" \) \
  -print 2>/dev/null |
while IFS= read -r s; do
  [ -z "$s" ] && continue
  safe_cp "$s" "$VERIZON_ROOT/scripts/$(basename "$s")"
done

# Rehome strongly-identifiable file classes already inside Verizon root.
find "$VERIZON_ROOT" -maxdepth 3 -type f \
  \( -iname "*sha256*" -o -iname "*manifest*" -o -iname "*.tsv" \) \
  -print 2>/dev/null |
while IFS= read -r f; do
  [ -z "$f" ] && continue
  safe_mv "$f" "$VERIZON_ROOT/manifests/$(basename "$f")"
done

find "$VERIZON_ROOT" -maxdepth 3 -type f \
  \( -iname "*fcc*rebuttal*.pdf" -o -iname "*ims*timeline*.pdf" -o -iname "*epdg*summary*.pdf" -o -iname "*technical*appendix*.pdf" -o -iname "*integrity*sha*.pdf" \) \
  -print 2>/dev/null |
while IFS= read -r f; do
  [ -z "$f" ] && continue
  safe_mv "$f" "$VERIZON_ROOT/legal/$(basename "$f")"
done

find "$VERIZON_ROOT" -maxdepth 3 -type f \
  \( -iname "*.md" -o -iname "*.txt" \) \
  \( -iname "*analysis*" -o -iname "*timeline*" -o -iname "*ims*" -o -iname "*epdg*" -o -iname "*provision*" -o -iname "*telephony*" -o -iname "*session*" \) \
  -print 2>/dev/null |
while IFS= read -r f; do
  [ -z "$f" ] && continue
  safe_mv "$f" "$VERIZON_ROOT/analysis/$(basename "$f")"
done

find "$VERIZON_ROOT" -maxdepth 4 -type f \
  \( -iname "*radio*" -o -iname "*telephony*" -o -iname "*connectivity*" -o -iname "*netpolicy*" -o -iname "*ip_addr*" -o -iname "*ip_route*" -o -iname "*dumpsys*" -o -iname "*telereg*" \) \
  -print 2>/dev/null |
while IFS= read -r f; do
  [ -z "$f" ] && continue
  safe_mv "$f" "$VERIZON_ROOT/evidence/$(basename "$f")"
done

echo >> "$AUDIT"
echo "[Final tree: $VERIZON_ROOT]" >> "$AUDIT"
find "$VERIZON_ROOT" -maxdepth 5 | sort >> "$AUDIT" 2>/dev/null || true
echo >> "$AUDIT"

echo "[Quarantine tree: $QUAR]" >> "$AUDIT"
find "$QUAR" -maxdepth 5 | sort >> "$AUDIT" 2>/dev/null || true
echo >> "$AUDIT"

echo "Done."
echo "Audit log:   $AUDIT"
echo "Moved log:   $MOVED"
echo "Skipped log: $SKIPPED"
echo
echo "Review:"
echo "  $VERIZON_ROOT"
echo "  $QUAR"
