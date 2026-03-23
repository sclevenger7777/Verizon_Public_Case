#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

command -v rish >/dev/null 2>&1 || { echo "Missing: rish" >&2; exit 1; }

DUR="${1:-900}" # seconds (900=15m)
TS="$(date +%Y%m%d_%H%M%S)"
DIR="/sdcard/Download/vz_bgcap_run_${TS}"
rish -c "mkdir -p '$DIR' && chmod 0775 '$DIR'"

# Baseline
rish -c "date -Is > '$DIR/00_start_time.txt'"
rish -c "id > '$DIR/00_id.txt'"
rish -c "settings get global mobile_data > '$DIR/01_mobile_data.txt' 2>&1 || true"
rish -c "settings get global data_roaming > '$DIR/01_data_roaming.txt' 2>&1 || true"
rish -c "settings get global multi_sim_data_call > '$DIR/01_multi_sim_data_call.txt' 2>&1 || true"

# Clear radio buffer to make the capture high-signal
rish -c "logcat -b radio -c >/dev/null 2>&1 || true"

# Start captures (no nohup; keep PIDs)
rish -c "sh -c '(logcat -b radio -v time >> \"$DIR/10_radio.log\" 2>> \"$DIR/10_radio.err\") & echo \$! > \"$DIR/10_radio.pid\"'"
rish -c "sh -c '(while true; do echo \"=== \$(date -Is) ===\"; \
  dumpsys telephony.registry 2>/dev/null | grep -E \"mServiceState=|mPreciseDataConnectionStates=|mDefaultDataSubId=|dataNetworkType=|overrideNetworkType=|mNetworkRegistrationInfos=\"; \
  dumpsys connectivity 2>/dev/null | grep -E \"ActiveNetwork|NetworkAgentInfo\\{network\\{|TRANSPORT_CELLULAR|extra: IMS\"; \
  echo; sleep 10; done) >> \"$DIR/11_poll.txt\" 2>> \"$DIR/11_poll.err\" & echo \$! > \"$DIR/11_poll.pid\"'"

echo "RUNNING: $DIR"
echo "Do now for the next $DUR seconds:"
echo "  - Keep Wi-Fi ON (for rish), but use Mobile data for tests."
echo "  - Toggle Airplane mode ON 10s -> OFF once mid-run."
echo "  - Attempt: open web page, place a call, send SMS/MMS (forces IMS + data)."
echo

sleep "$DUR"

# Stop captures
rish -c "sh -c 'test -s \"$DIR/11_poll.pid\" && kill \$(cat \"$DIR/11_poll.pid\") >/dev/null 2>&1 || true'"
rish -c "sh -c 'test -s \"$DIR/10_radio.pid\" && kill \$(cat \"$DIR/10_radio.pid\") >/dev/null 2>&1 || true'"

# End snapshots
rish -c "date -Is > '$DIR/90_end_time.txt'"
rish -c "dumpsys telephony.registry > '$DIR/91_telephony_registry_end.txt' 2>&1 || true"
rish -c "dumpsys connectivity > '$DIR/92_connectivity_end.txt' 2>&1 || true"
rish -c "dumpsys secims > '$DIR/93_secims_end.bin' 2>&1 || true"

# Evidence extract
rish -c "sh -c '{
  echo \"=== IMS/SIP bucket ===\";
  grep -E \"SIP|REGISTER|regi|dereg|403|404|408|480|486|488|500|503|P-CSCF|pcscf|IMPU|IMPI|epdg\" -n \"$DIR/10_radio.log\" | head -n 400 || true;
  echo;
  echo \"=== PDN/attach/reject bucket ===\";
  grep -E \"reject|REJECT|cause|not subscribed|auth|FAIL|DENIED|PDN|SetupDataCall|DATA_CALL|APN|apn|EPS|EMM|ESM\" -n \"$DIR/10_radio.log\" | head -n 400 || true;
} > \"$DIR/95_evidence_extract.txt\" 2>/dev/null || true'"

# Bundle
OUTTGZ="/sdcard/Download/$(basename "$DIR").tar.gz"
rish -c "tar -czf '$OUTTGZ' -C '$(dirname "$DIR")' '$(basename "$DIR")'"

echo "WROTE: $OUTTGZ"
rish -c "ls -lh '$DIR/10_radio.log' '$DIR/10_radio.err' '$DIR/11_poll.txt' '$DIR/95_evidence_extract.txt' '$OUTTGZ' 2>/dev/null || true"
