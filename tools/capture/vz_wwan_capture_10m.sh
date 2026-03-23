#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

OUT="/sdcard/Download/vz_wwan_capture_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

echo "== baseline state ==" | tee "$OUT/00_notes.txt"
date -Is | tee -a "$OUT/00_notes.txt"
settings get global mobile_data 2>/dev/null | tee -a "$OUT/00_notes.txt" || true

echo "== starting radio logcat (10 min) =="
logcat -c || true
logcat -b radio -v time > "$OUT/01_logcat_radio.txt" &
LPID=$!

# snapshot dumps at start
dumpsys telephony.registry > "$OUT/02_telephony_registry_start.txt" 2>/dev/null || true
dumpsys connectivity      > "$OUT/03_connectivity_start.txt" 2>/dev/null || true
dumpsys secims            > "$OUT/04_secims_start.txt" 2>/dev/null || true

echo "== ACTIONS FOR NEXT 10 MIN (do these on the phone) ==" | tee -a "$OUT/00_notes.txt"
cat >> "$OUT/00_notes.txt" <<'ACTIONS'
1) With Wi-Fi OFF and Mobile data ON, open a web page (forces default data PDN).
2) Place one normal voice call for ~30 seconds (forces IMS behavior).
3) Send 1 SMS + 1 MMS (small photo) if possible.
4) Toggle Airplane mode ON 10s → OFF once mid-run (re-attach).
ACTIONS

sleep 600

kill "$LPID" 2>/dev/null || true

# snapshot dumps at end
dumpsys telephony.registry > "$OUT/05_telephony_registry_end.txt" 2>/dev/null || true
dumpsys connectivity      > "$OUT/06_connectivity_end.txt" 2>/dev/null || true
dumpsys secims            > "$OUT/07_secims_end.txt" 2>/dev/null || true

tar -czf "${OUT}.tar.gz" -C "$(dirname "$OUT")" "$(basename "$OUT")"
echo "WROTE: ${OUT}.tar.gz"
