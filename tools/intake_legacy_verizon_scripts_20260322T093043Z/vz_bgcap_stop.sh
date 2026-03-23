#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

DIR="${1:-}"
if [[ -z "$DIR" ]]; then
  echo "Usage: $0 /sdcard/Download/vz_bgcap_YYYYmmdd_HHMMSS" >&2
  exit 1
fi

command -v rish >/dev/null 2>&1 || { echo "Missing: rish" >&2; exit 1; }

# Stop poll + radio capture (best-effort)
rish -c "sh -c 'test -f \"$DIR/11_poll.pid\" && kill \$(cat \"$DIR/11_poll.pid\") >/dev/null 2>&1 || true'"
rish -c "sh -c 'test -f \"$DIR/10_radio.pid\" && kill \$(cat \"$DIR/10_radio.pid\") >/dev/null 2>&1 || true'"

# End snapshots
rish -c "date -Is > '$DIR/90_end_time.txt'"
rish -c "dumpsys telephony.registry > '$DIR/91_telephony_registry_end.txt' 2>&1 || true"
rish -c "dumpsys connectivity > '$DIR/92_connectivity_end.txt' 2>&1 || true"
rish -c "dumpsys secims > '$DIR/93_secims_end.bin' 2>&1 || true"
rish -c "logcat -b radio -d -v time | tail -n 400 > '$DIR/94_radio_tail.txt' 2>&1 || true"

# Bundle for upload
OUTTGZ="/sdcard/Download/$(basename "$DIR").tar.gz"
rish -c "tar -czf '$OUTTGZ' -C '$(dirname "$DIR")' '$(basename "$DIR")'"

echo "WROTE: $OUTTGZ"
