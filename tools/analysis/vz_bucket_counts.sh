#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

DL_ROOT="$HOME/storage/downloads"
DEFAULT_VZ_ROOT="$DL_ROOT/verizon_case_master_20260219T162625Z"
VZ_ROOT="${1:-$DEFAULT_VZ_ROOT}"

if [ ! -d "$VZ_ROOT" ]; then
  echo "ERROR: Case master directory not found: $VZ_ROOT" >&2
  exit 1
fi

DOC_DIR="$VZ_ROOT/00_case_docs"
mkdir -p "$DOC_DIR"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$DOC_DIR/vz_case_bucket_counts_${TS}.tsv"

echo -e "bucket_path\tfile_count\tdir_count\tsize_bytes" > "$OUT"

cd "$VZ_ROOT"

for d in *; do
  [ -d "$d" ] || continue

  file_count="$(find "$d" -type f 2>/dev/null | wc -l | awk '{print $1}')"
  dir_count="$(find "$d" -type d 2>/dev/null | wc -l | awk '{print $1}')"
  # du -sb may not exist everywhere; Termux coreutils has it
  size_bytes="$(du -sb "$d" 2>/dev/null | awk '{print $1}')"

  echo -e "$d\t$file_count\t$dir_count\t$size_bytes" >> "$OUT"
done

echo "==[ BUCKET SUMMARY ]=="
echo "Root: $VZ_ROOT"
echo
echo "Top buckets by file_count:"
sort -t$'\t' -k2,2nr "$OUT" | head -10 | awk -F'\t' '{printf "  %-40s files=%8s  dirs=%6s  size=%s bytes\n", $1, $2, $3, $4}'

echo
echo "[OK] Bucket counts written to: $OUT"
