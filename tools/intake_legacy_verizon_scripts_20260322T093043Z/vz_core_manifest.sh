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

ts="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$DOC_DIR/vz_core_manifest_${ts}.tsv"

echo "==[ VZ CORE MANIFEST (EXCLUDING 09 & 11) ]=="
echo "Root: $VZ_ROOT"
echo "Out : $OUT"
echo

# Header
printf "sha256\tsize_bytes\trel_path\n" > "$OUT"

# Find core files (exclude heavy bundles/bugreports)
while IFS= read -r -d '' f; do
  rel="\${f#"$VZ_ROOT/"}"
  size="$(stat -c '%s' "$f" 2>/dev/null || stat -f '%z' "$f" 2>/dev/null || echo 0)"
  sha="$(sha256sum "$f" 2>/dev/null | awk '{print $1}')"
  printf "%s\t%s\t%s\n" "$sha" "$size" "$rel" >> "$OUT"
done < <(find "$VZ_ROOT" -type f \
          ! -path "$VZ_ROOT/09_bundles_archives/*" \
          ! -path "$VZ_ROOT/11_bugreports_root/*" \
          -print0 2>/dev/null)

core_count="$(wc -l < "$OUT")"
# subtract header
core_count=$((core_count - 1))

echo "[OK] Core manifest written to: $OUT"
echo "[OK] Core files recorded     : $core_count"
