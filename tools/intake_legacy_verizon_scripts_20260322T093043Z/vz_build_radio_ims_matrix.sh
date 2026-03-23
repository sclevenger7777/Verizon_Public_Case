#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

VZ_ROOT="$HOME/storage/downloads/verizon_case_master_20260219T162625Z"
OUT="$VZ_ROOT/00_case_docs/vz_radio_ims_matrix_$(date -u +%Y%m%dT%H%M%SZ).txt"

echo "==[ RADIO vs IMS MATRIX ]==" > "$OUT"
echo "Generated UTC: $(date -u)" >> "$OUT"
echo >> "$OUT"

# Radio logs
grep -E "REGISTRATION|AUTH|REJECT|GUTI|MME|UIM|EMM|EIMS|ATTACH" \
    "$VZ_ROOT/01_radio_logs/"* 2>/dev/null >> "$OUT"

echo >> "$OUT"
echo "---- IMS ARTIFACTS ----" >> "$OUT"
echo >> "$OUT"

grep -E "403|480|503|REGISTER|AUTH|REJECT|SIP|EPDG" \
    "$VZ_ROOT/02_ims_artifacts/"* 2>/dev/null >> "$OUT"

echo >> "$OUT"
echo "---- TELEPHONY DUMPS ----" >> "$OUT"
echo >> "$OUT"

grep -E "mServiceState|DataRegState|VoiceRegState|isImsRegistered" \
    "$VZ_ROOT/04_telephony_phone_dumps/"* 2>/dev/null >> "$OUT"

echo >> "$OUT"
echo "[OK] Matrix written to: $OUT"
