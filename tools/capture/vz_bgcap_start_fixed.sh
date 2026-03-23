#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

command -v rish >/dev/null 2>&1 || { echo "Missing: rish" >&2; exit 1; }

TS="$(date +%Y%m%d_%H%M%S)"
DIR="/sdcard/Download/vz_bgcap_${TS}"
rish -c "mkdir -p '${DIR}' && chmod 0775 '${DIR}'"

# Basic snapshot (keep it small)
rish -c "date -Is > '${DIR}/00_start_time.txt'"

# Start RADIO capture in background using only /system/bin/sh constructs
# Write stdout+stderr to files so failures are visible.
rish -c "
  ( logcat -b radio -v time -T 0 >> '${DIR}/10_radio.log' 2>> '${DIR}/10_radio.err' ) &
  echo \$! > '${DIR}/10_radio.pid'
  sleep 1
  if [ ! -s '${DIR}/10_radio.log' ] && [ -s '${DIR}/10_radio.err' ]; then
    echo 'radio log did not start; see 10_radio.err' >> '${DIR}/10_radio.err'
  fi
"

# Optional poll loop (telephony + connectivity) every 10s
rish -c "
  ( while true; do
      echo '=== '\"\$(date -Is)\"' ===' >> '${DIR}/11_poll.txt'
      dumpsys telephony.registry 2>/dev/null | sed -n '1,220p' >> '${DIR}/11_poll.txt'
      dumpsys connectivity 2>/dev/null | sed -n '1,260p' >> '${DIR}/11_poll.txt'
      echo >> '${DIR}/11_poll.txt'
      sleep 10
    done ) &
  echo \$! > '${DIR}/11_poll.pid'
"

echo "WROTE: ${DIR}"
echo "Radio PID: $(rish -c "cat '${DIR}/10_radio.pid' 2>/dev/null" | tr -d '\r' || true)"
echo "Poll  PID: $(rish -c "cat '${DIR}/11_poll.pid' 2>/dev/null" | tr -d '\r' || true)"
echo
echo "Verify:"
echo "  rish -c \"ls -lh '${DIR}/10_radio.'* '${DIR}/11_poll.txt' 2>/dev/null\""
