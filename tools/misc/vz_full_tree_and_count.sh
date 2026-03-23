#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Default case master root (Termux internal Downloads)
DL_ROOT="$HOME/storage/downloads"
DEFAULT_VZ_ROOT="$DL_ROOT/verizon_case_master_20260219T162625Z"

# Allow optional override as first argument
VZ_ROOT="${1:-$DEFAULT_VZ_ROOT}"

if [ ! -d "$VZ_ROOT" ]; then
  echo "ERROR: Case master directory not found: $VZ_ROOT" >&2
  exit 1
fi

DOC_DIR="$VZ_ROOT/00_case_docs"
mkdir -p "$DOC_DIR"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$DOC_DIR/vz_case_full_tree_${TS}.txt"

echo "==[ VZ CASE FULL TREE ]==" > "$OUT"
echo "# Root: $VZ_ROOT" >> "$OUT"
echo "# Generated UTC: $(date -u)" >> "$OUT"
echo >> "$OUT"

# Full tree listing (dirs + files), relative paths, sorted
(
  cd "$VZ_ROOT"
  find . -print | sort
) >> "$OUT"

# Counts
file_count="$(
  find "$VZ_ROOT" -type f 2>/dev/null | wc -l | awk '{print $1}'
)"
dir_count="$(
  find "$VZ_ROOT" -type d 2>/dev/null | wc -l | awk '{print $1}'
)"

{
  echo
  echo "==[ SUMMARY ]=="
  echo "Total files     : $file_count"
  echo "Total directories: $dir_count"
} >> "$OUT"

echo "[OK] Full tree written to: $OUT"
echo "[OK] Total files     : $file_count"
echo "[OK] Total directories: $dir_count"
