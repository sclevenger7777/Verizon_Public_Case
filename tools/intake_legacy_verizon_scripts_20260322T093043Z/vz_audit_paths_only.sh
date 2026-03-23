#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

DL_ROOT="$HOME/storage/downloads"
VZ_ROOT="$DL_ROOT/verizon_case_master_20260219T162625Z"
REPORT_DIR="$VZ_ROOT/00_case_docs"

if [ ! -d "$REPORT_DIR" ]; then
  echo "ERROR: Report directory not found: $REPORT_DIR" >&2
  exit 1
fi

latest_report="$(ls -1 "$REPORT_DIR"/vz_consolidation_audit_*.txt 2>/dev/null | sort | tail -n1 || true)"
if [ -z "$latest_report" ]; then
  echo "ERROR: No vz_consolidation_audit_*.txt found in $REPORT_DIR" >&2
  exit 1
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$REPORT_DIR/vz_consolidation_audit_paths_${TS}.txt"

echo "== VZ CONSOLIDATION AUDIT PATHS (from: $(basename "$latest_report")) ==" > "$OUT"
echo >> "$OUT"

# Keep only lines that look like absolute paths and are outside the case master
grep '^/' "$latest_report" | grep -v "$VZ_ROOT" >> "$OUT" || true

echo >> "$OUT"
echo "NOTE: These are only hits matching VZ/IMS/radio patterns that remain outside:" >> "$OUT"
echo "      $VZ_ROOT" >> "$OUT"

echo "[OK] Paths-only audit written to: $OUT"
