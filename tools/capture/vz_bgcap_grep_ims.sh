#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

command -v rish >/dev/null 2>&1 || { echo "Missing: rish" >&2; exit 1; }

# Find newest capture dir
DIR="$(rish -c "ls -1dt /sdcard/Download/vz_bgcap_* 2>/dev/null | head -n 1" | tr -d '\r')"
if [[ -z "${DIR}" ]]; then
  echo "No /sdcard/Download/vz_bgcap_* directories found." >&2
  exit 1
fi

echo "DIR=${DIR}"
echo
echo "== ls -la =="
rish -c "ls -la '${DIR}' || true"
echo

LOG="${DIR}/10_radio.log"
if rish -c "test -s '${LOG}'"; then
  echo "== IMS/SIP grep (first 200 hits) =="
  rish -c "grep -E 'SIP|REGISTER|regi|dereg|403|404|408|480|486|488|500|503|P-CSCF|pcscf|IMPU|IMPI|epdg' -n '${LOG}' | head -n 200" || true
  echo
  echo "== PDN/attach/reject grep (first 200 hits) =="
  rish -c "grep -E 'reject|REJECT|cause|not subscribed|auth|FAIL|DENIED|PDN|SetupDataCall|DATA_CALL|APN' -n '${LOG}' | head -n 200" || true
else
  echo "NOTE: '${LOG}' not present or empty."
  echo "Fallback: dumping current radio buffer (tail 400) to /sdcard/Download/radio_fallback_tail.txt"
  rish -c "logcat -b radio -d -v time | tail -n 400 > /sdcard/Download/radio_fallback_tail.txt 2>&1 || true"
  rish -c "ls -lh /sdcard/Download/radio_fallback_tail.txt || true"
fi
