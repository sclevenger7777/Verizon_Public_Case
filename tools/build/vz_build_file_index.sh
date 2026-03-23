#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

DL_ROOT="$HOME/storage/downloads"
VZ_ROOT="$DL_ROOT/verizon_case_master_20260219T162625Z"

if [ ! -d "$VZ_ROOT" ]; then
  echo "ERROR: VZ_ROOT not found at: $VZ_ROOT" >&2
  exit 1
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="$VZ_ROOT/00_case_docs"
OUT_FILE="$OUT_DIR/vz_case_file_index_${TS}.tsv"

mkdir -p "$OUT_DIR"

echo "==[ VZ CASE FILE INDEX ]==" > "$OUT_FILE"
echo "# Generated UTC: $(date -u)" >> "$OUT_FILE"
echo "# Root: $VZ_ROOT" >> "$OUT_FILE"
echo >> "$OUT_FILE"
echo -e "mtime_utc\tsize_bytes\trelpath" >> "$OUT_FILE"

cd "$VZ_ROOT"

# Requires GNU find (Termux findutils) for -printf
find . -type f -printf '%TY-%Tm-%TdT%TH:%TM:%TSZ\t%s\t%P\n' \
  | sort >> "$OUT_FILE"

echo "[OK] Case file index written to: $OUT_FILE"
