#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

command -v rish >/dev/null 2>&1 || { echo "Missing: rish" >&2; exit 1; }

DIR="${1:-}"
if [[ -z "$DIR" ]]; then
  DIR="$(rish -c "ls -1dt /sdcard/Download/vz_bgcap_* 2>/dev/null | head -n 1" | tr -d '\r')"
fi
[[ -n "$DIR" ]] || { echo "No capture dir found." >&2; exit 1; }

echo "DIR=$DIR"

# stop poll + radio if pid exists
rish -c "
  for f in '${DIR}/11_poll.pid' '${DIR}/10_radio.pid'; do
    [ -s \"\$f\" ] || continue
    pid=\$(cat \"\$f\")
    kill \"\$pid\" 2>/dev/null || true
  done
"

# Confirm files
rish -c "ls -lh '${DIR}/10_radio.log' '${DIR}/10_radio.err' '${DIR}/11_poll.txt' 2>/dev/null || true"

LOG="${DIR}/10_radio.log"
OUT="${DIR}/90_evidence_extract.txt"

# Evidence extract (first 400 hits each bucket)
rish -c "
  {
    echo '=== IMS/SIP (REGISTER/regi/dereg, 403/404/408/480/486/488/500/503, P-CSCF/epdg) ==='
    if [ -s '${LOG}' ]; then
      grep -E 'SIP|REGISTER|regi|dereg|403|404|408|480|486|488|500|503|P-CSCF|pcscf|IMPU|IMPI|epdg' -n '${LOG}' | head -n 400 || true
    else
      echo 'NO 10_radio.log (missing/empty)'
      [ -s '${DIR}/10_radio.err' ] && echo '--- 10_radio.err ---' && sed -n '1,200p' '${DIR}/10_radio.err'
    fi

    echo
    echo '=== Data/PDN/attach/reject/cause/APN/SetupDataCall ==='
    if [ -s '${LOG}' ]; then
      grep -E 'reject|REJECT|cause|not subscribed|auth|FAIL|DENIED|PDN|SetupDataCall|DATA_CALL|APN|apn|EPS|EMM|ESM' -n '${LOG}' | head -n 400 || true
    fi
  } > '${OUT}'
"
echo "WROTE: ${DIR}/90_evidence_extract.txt"
