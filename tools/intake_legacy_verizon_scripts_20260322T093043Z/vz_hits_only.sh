#!/usr/bin/env bash
set -euo pipefail

# INPUTS (edit if needed)
A="${1:-vz_tier3_packet_20260129_021027.txt}"
B="${2:-vz_tier3_packet_20260129_061609.txt}"

OUTDIR="/sdcard/Download"
TS="$(date +%Y%m%d_%H%M%S)"

# Ensure readable names
baseA="$(basename "$A")"
baseB="$(basename "$B")"

# Output files
IMS_A="$OUTDIR/ims_hits_${baseA%.txt}_${TS}.txt"
IMS_B="$OUTDIR/ims_hits_${baseB%.txt}_${TS}.txt"
PDN_A="$OUTDIR/pdn_hits_${baseA%.txt}_${TS}.txt"
PDN_B="$OUTDIR/pdn_hits_${baseB%.txt}_${TS}.txt"

DIFF_IMS="$OUTDIR/diff_ims_hits_${baseA%.txt}_vs_${baseB%.txt}_${TS}.diff"
DIFF_PDN="$OUTDIR/diff_pdn_hits_${baseA%.txt}_vs_${baseB%.txt}_${TS}.diff"

# Helper: safety
need() { [[ -f "$1" ]] || { echo "MISSING: $1" >&2; exit 2; }; }

need "$A"
need "$B"

# Patterns:
# IMS: SIP/REGISTER/PCSCF/IMS/DEREG/NOT REGISTERED and common SIP error codes
IMS_PAT='(IMS\b|Pcscf|P-CSCF|\bSIP\b|REGISTER|REGISTRATION|DEREG|not registered|S-CSCF|IMPI|IMPU|AKA|ISIM|VoLTE|vowifi|EAB|403|401|407|408|480|486|487|488|500|503)'

# PDN/Attach/Policy: reject/fail-cause/ESM/EMM/PDN/PDU/NOT_SUBSCRIBED/AUTH/etc
PDN_PAT='(attach reject|ATTACH REJECT|PDN|PDU session|ESM|EMM|reject|fail cause|FAILED|NOT_SUBSCRIBED|SERVICE_OPTION_NOT_SUBSCRIBED|MISSING_UNKNOWN_APN|APN.*not|AUTH|AUTHENTICATION|GMM|SM|EPS|5QI|qci|QoS|PCO|policy|PCRF|PCF|HSS|UDM|entitlement)'

# Extractor: keep line numbers (from packet), collapse obvious noise, keep context minimal but useful
extract_hits() {
  local infile="$1" pat="$2" outfile="$3"
  # Keep packet line numbers; strip trailing carriage; squeeze blank runs
  grep -nE "$pat" "$infile" \
    | sed 's/\r$//' \
    | sed -E 's/[[:space:]]+/ /g' \
    > "$outfile" || true

  # If empty, leave a marker (so Tier-3 sees "no IMS evidence in this capture")
  if [[ ! -s "$outfile" ]]; then
    echo "NO_HITS: pattern not found in $infile" > "$outfile"
  fi
}

extract_hits "$A" "$IMS_PAT" "$IMS_A"
extract_hits "$B" "$IMS_PAT" "$IMS_B"
extract_hits "$A" "$PDN_PAT" "$PDN_A"
extract_hits "$B" "$PDN_PAT" "$PDN_B"

# Human-readable diffs (unified, with line numbers preserved from the packets)
diff -u "$IMS_A" "$IMS_B" > "$DIFF_IMS" || true
diff -u "$PDN_A" "$PDN_B" > "$DIFF_PDN" || true

# Summary
echo "WROTE:"
echo "  $IMS_A"
echo "  $IMS_B"
echo "  $PDN_A"
echo "  $PDN_B"
echo "  $DIFF_IMS"
echo "  $DIFF_PDN"

# Try open output directory (optional)
if command -v termux-open >/dev/null 2>&1; then
  termux-open "$OUTDIR" >/dev/null 2>&1 || true
fi
