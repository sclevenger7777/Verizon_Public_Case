#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Termux HOME
T_HOME="$HOME"
DL_ROOT="$HOME/storage/downloads"
VZ_ROOT="$DL_ROOT/verizon_case_master_20260219T162625Z"

REPORT_DIR="$VZ_ROOT/00_case_docs"

echo "==[ VZ POST-CONSOLIDATION SANITY ]=="
echo "[INFO] Case master: $VZ_ROOT"
echo "[INFO] Report dir : $REPORT_DIR"
echo

# 1) Show latest paths-only audit (already created earlier)
latest_paths="$(ls -1 "$REPORT_DIR"/vz_consolidation_audit_paths_*.txt 2>/dev/null | sort | tail -n1 || true)"
if [ -z "$latest_paths" ]; then
  echo "[WARN] No vz_consolidation_audit_paths_*.txt found; skipping paths-only view."
else
  echo "[STEP] Showing non-empty, non-comment lines from latest paths-only audit:"
  echo "       $(basename "$latest_paths")"
  echo
  grep -v '^\s*$' "$latest_paths" | grep -v '^==' || echo "[INFO] (no extra paths listed)"
  echo
fi

# 2) Quick greps for obvious vz/verizon patterns outside case master

echo "[STEP] Quick pattern scan outside case master (HOME, Downloads, /sdcard)"

# Helper: scoped find+grep that ignores the case master directory
scan_dir() {
  local label="$1"
  local root="$2"
  echo
  echo ">>> Scope: $label ($root)"
  if [ ! -d "$root" ]; then
    echo "    [SKIP] Not a directory"
    return
  fi
  # Look for VZ-ish names (vz_, vzw_, verizon_) excluding the case master
  find "$root" -mindepth 1 -maxdepth 4 \
    \( -name '*vz_*' -o -name '*vzw_*' -o -name '*verizon*' \) \
    ! -path "$VZ_ROOT/*" \
    -print 2>/dev/null || true
}

scan_dir "Termux HOME" "$T_HOME"
scan_dir "Termux Downloads" "$DL_ROOT"
scan_dir "External /sdcard" "/sdcard"

echo
echo "[OK] Sanity scan complete. Above paths (if any) are VZ-ish but remain outside case master."
echo "     You can either leave them (if out-of-scope) or add them manually as needed."
