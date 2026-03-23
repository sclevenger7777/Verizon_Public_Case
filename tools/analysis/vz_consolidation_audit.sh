#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

TERMUX_HOME="$HOME"
DL_ROOT="$HOME/storage/downloads"
SD_ROOT="/sdcard"
VZ_ROOT="$DL_ROOT/verizon_case_master_20260219T162625Z"

if [ ! -d "$VZ_ROOT" ]; then
  echo "ERROR: Verizon case master not found at: $VZ_ROOT" >&2
  exit 1
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT_DIR="$VZ_ROOT/00_case_docs"
REPORT="$REPORT_DIR/vz_consolidation_audit_${TS}.txt"

mkdir -p "$REPORT_DIR"

echo "== VZ CONSOLIDATION AUDIT (UTC: $(date -u)) ==" > "$REPORT"
echo "[INFO] Case master: $VZ_ROOT" >> "$REPORT"
echo >> "$REPORT"

# Patterns that usually indicate Verizon / radio / IMS evidence
patterns=(
  "*verizon*"
  "vz_*"
  "*_vzw_*"
  "vzw_*"
  "ims_*"
  "IMS_*"
  "radio_*"
  "telephony*"
  "net_evidence_*"
  "net_vm_*"
  "forensics_review_*"
  "forensics-review-*"
  "pcap_archive"
  "FCC_Submission_*"
  "evidence_telereg_*"
)

scan_root() {
  local root="$1"
  local label="$2"

  {
    echo "== ROOT: ${label} (${root}) =="
    if [ ! -d "$root" ]; then
      echo "  (root missing)"
      echo
      return
    fi

    for patt in "${patterns[@]}"; do
      echo "-- pattern: $patt"
      # Search up to a reasonable depth to avoid walking the entire world
      hits=$(find "$root" -maxdepth 9 -iname "$patt" 2>/dev/null | grep -v "$VZ_ROOT" || true)
      if [ -n "$hits" ]; then
        echo "$hits"
      else
        echo "  (none outside case master)"
      fi
      echo
    done
    echo
  } >> "$REPORT"
}

scan_root "$TERMUX_HOME"        "TERMUX_HOME"
scan_root "$DL_ROOT"            "TERMUX_DOWNLOADS"
scan_root "$SD_ROOT"            "SDCARD_ROOT"

echo "== SUMMARY ==" >> "$REPORT"
echo "This report lists only paths that match Verizon/IMS/radio-style patterns" >> "$REPORT"
echo "and are *outside* the case master tree: $VZ_ROOT" >> "$REPORT"
echo >> "$REPORT"

echo "[OK] Audit complete."
echo "[OK] Report written to: $REPORT"
