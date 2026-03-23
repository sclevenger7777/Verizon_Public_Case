#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="/storage/emulated/0"
VERIZON_ROOT="$ROOT/USE_THIS_DIRECTORY"
QUAR="$ROOT/Quarantine_Unrelated_From_USE_THIS_DIRECTORY"
LOGDIR="$ROOT/Verizon_Consolidation_Logs"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
AUDIT="$LOGDIR/use_this_directory_audit_$TS.txt"
MOVED="$LOGDIR/use_this_directory_moved_$TS.txt"

mkdir -p "$VERIZON_ROOT" "$QUAR" "$LOGDIR"

# Canonical Verizon subdirectories
mkdir -p \
  "$VERIZON_ROOT/evidence" \
  "$VERIZON_ROOT/scripts" \
  "$VERIZON_ROOT/manifests" \
  "$VERIZON_ROOT/legal" \
  "$VERIZON_ROOT/analysis" \
  "$VERIZON_ROOT/exports" \
  "$VERIZON_ROOT/misc_review"

echo "=== USE_THIS_DIRECTORY normalization audit ===" > "$AUDIT"
echo "UTC: $(date -u)" >> "$AUDIT"
echo >> "$AUDIT"

echo "[Initial tree: $VERIZON_ROOT]" >> "$AUDIT"
find "$VERIZON_ROOT" -maxdepth 5 | sort >> "$AUDIT" || true
echo >> "$AUDIT"

echo "[Moved files]" > "$MOVED"
echo "UTC: $(date -u)" >> "$MOVED"
echo >> "$MOVED"

move_if_obviously_unrelated() {
  local path="$1"
  local base dest
  base="$(basename "$path")"
  dest="$QUAR/$base"
  if [ -e "$dest" ]; then
    dest="$QUAR/${base%.*}_$TS.${base##*.}"
    [ "$base" = "${base##*.}" ] && dest="$QUAR/${base}_$TS"
  fi
  mv -n "$path" "$dest"
  printf '%s -> %s\n' "$path" "$dest" >> "$MOVED"
}

# Move only clearly unrelated contamination from Verizon root.
# Intentionally conservative.
while IFS= read -r -d '' p; do
  move_if_obviously_unrelated "$p"
done < <(
  find "$VERIZON_ROOT" -mindepth 1 -maxdepth 5 \
    \( \
      -iname "*happy*" -o \
      -iname "*happymod*" -o \
      -iname "*modded*" -o \
      -iname "*xapk*" -o \
      -iname "*.apk" \
    \) \
    ! -iname "*verizon*" \
    ! -iname "*vzw*" \
    ! -iname "*ims*" \
    ! -iname "*telephony*" \
    ! -iname "*radio*" \
    ! -iname "*epdg*" \
    ! -iname "*carrier*" \
    -print0
)

# Gather obviously Verizon-related scripts into Verizon root/scripts
# from common locations, without touching unrelated script names.
collect_script() {
  local src="$1"
  local name dest
  name="$(basename "$src")"
  dest="$VERIZON_ROOT/scripts/$name"
  if [ -e "$dest" ]; then
    dest="$VERIZON_ROOT/scripts/${name%.*}_$TS.${name##*.}"
    [ "$name" = "${name##*.}" ] && dest="$VERIZON_ROOT/scripts/${name}_$TS"
  fi
  cp -n "$src" "$dest" || true
  printf 'COPIED %s -> %s\n' "$src" "$dest" >> "$MOVED"
}

while IFS= read -r -d '' s; do
  collect_script "$s"
done < <(
  find "$HOME" "$ROOT/Download" "$ROOT/Downloads" "$ROOT/Verizon_Public_Case" "$ROOT" \
    -maxdepth 4 -type f \
    \( -iname "*.sh" -o -iname "*.bash" -o -iname "*.zsh" -o -iname "*.py" \) \
    \( \
      -iname "*verizon*" -o \
      -iname "*vzw*" -o \
      -iname "*ims*" -o \
      -iname "*telephony*" -o \
      -iname "*epdg*" -o \
      -iname "*provision*" -o \
      -iname "*carrier*" \
    \) \
    -print0 2>/dev/null
)

# Suggestive organization for files already inside Verizon root.
# Move only by strong filename signals; ambiguous files stay put.
safe_rehome() {
  local src="$1" sub="$2" base dest
  base="$(basename "$src")"
  dest="$VERIZON_ROOT/$sub/$base"
  [ "$src" = "$dest" ] && return 0
  if [ -e "$dest" ]; then
    dest="$VERIZON_ROOT/$sub/${base%.*}_$TS.${base##*.}"
    [ "$base" = "${base##*.}" ] && dest="$VERIZON_ROOT/$sub/${base}_$TS"
  fi
  mv -n "$src" "$dest"
  printf '%s -> %s\n' "$src" "$dest" >> "$MOVED"
}

while IFS= read -r -d '' f; do safe_rehome "$f" "manifests"; done < <(
  find "$VERIZON_ROOT" -maxdepth 2 -type f \
    \( -iname "*sha256*" -o -iname "*manifest*" -o -iname "*.tsv" \) -print0
)

while IFS= read -r -d '' f; do safe_rehome "$f" "legal"; done < <(
  find "$VERIZON_ROOT" -maxdepth 2 -type f \
    \( -iname "*fcc*rebuttal*.pdf" -o \
       -iname "*ims*timeline*.pdf" -o \
       -iname "*epdg*summary*.pdf" -o \
       -iname "*technical*appendix*.pdf" -o \
       -iname "*integrity*sha*.pdf" \) -print0
)

while IFS= read -r -d '' f; do safe_rehome "$f" "analysis"; done < <(
  find "$VERIZON_ROOT" -maxdepth 2 -type f \
    \( -iname "*.md" -o -iname "*.txt" \) \
    \( -iname "*analysis*" -o \
       -iname "*timeline*" -o \
       -iname "*ims*" -o \
       -iname "*epdg*" -o \
       -iname "*provision*" -o \
       -iname "*telephony*" -o \
       -iname "*session*" \) -print0
)

while IFS= read -r -d '' f; do safe_rehome "$f" "evidence"; done < <(
  find "$VERIZON_ROOT" -maxdepth 3 -type f \
    \( -iname "*radio*" -o \
       -iname "*telephony*" -o \
       -iname "*connectivity*" -o \
       -iname "*netpolicy*" -o \
       -iname "*ip_addr*" -o \
       -iname "*ip_route*" -o \
       -iname "*dumpsys*" -o \
       -iname "*telereg*" \) -print0
)

echo >> "$AUDIT"
echo "[Final tree: $VERIZON_ROOT]" >> "$AUDIT"
find "$VERIZON_ROOT" -maxdepth 5 | sort >> "$AUDIT" || true
echo >> "$AUDIT"

echo "[Quarantine tree: $QUAR]" >> "$AUDIT"
find "$QUAR" -maxdepth 5 | sort >> "$AUDIT" || true
echo >> "$AUDIT"

echo "Done."
echo "Audit log: $AUDIT"
echo "Move log:  $MOVED"
echo
echo "Review these directories:"
echo "  $VERIZON_ROOT"
echo "  $QUAR"
