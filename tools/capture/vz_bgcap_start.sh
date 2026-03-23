#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }
need rish

DIR="/sdcard/Download/vz_bgcap_$(date +%Y%m%d_%H%M%S)"
rish -c "mkdir -p '$DIR'"

# Baseline snapshots
rish -c "date -Is > '$DIR/00_start_time.txt'"
rish -c "id > '$DIR/00_id.txt'"
rish -c "settings get global mobile_data > '$DIR/01_mobile_data.txt' 2>&1 || true"
rish -c "settings get global data_roaming > '$DIR/01_data_roaming.txt' 2>&1 || true"
rish -c "settings get global multi_sim_data_call > '$DIR/01_multi_sim_data_call.txt' 2>&1 || true"
rish -c "dumpsys telephony.registry > '$DIR/02_telephony_registry_start.txt' 2>&1 || true"
rish -c "dumpsys connectivity > '$DIR/03_connectivity_start.txt' 2>&1 || true"
rish -c "dumpsys secims > '$DIR/04_secims_start.bin' 2>&1 || true"

# Clear radio buffer (optional but helpful)
rish -c "logcat -b radio -c >/dev/null 2>&1 || true"

# Start continuous radio capture (detached)
rish -c "sh -c 'nohup logcat -b radio -v time -f \"$DIR/10_radio.log\" >/dev/null 2>&1 & echo \$! > \"$DIR/10_radio.pid\"'"

# Start a lightweight periodic snapshot (every 30s) of key fields (detached)
rish -c "sh -c 'nohup sh -c \"while true; do date -Is; dumpsys telephony.registry | grep -E \\\"mServiceState=|mPreciseDataConnectionStates=|mDefaultDataSubId=|dataNetworkType=|mNetworkRegistrationInfos=\\\"; echo; dumpsys connectivity | grep -E \\\"ActiveNetwork|NetworkAgentInfo\\{network\\{|TRANSPORT_CELLULAR|extra: IMS\\\"; echo; sleep 30; done\" > \"$DIR/11_poll.txt\" 2>&1 & echo \$! > \"$DIR/11_poll.pid\"'"

cat <<MSG
STARTED: $DIR

NOW DO THIS:
1) Turn OFF Wi-Fi (cellular-only).
2) Reproduce the problem (calls, SMS, data, IMS/VoLTE/VoNR attempts) for 5-15 minutes.
3) Turn Wi-Fi back ON (so rish works again).
4) Run:  ./vz_bgcap_stop.sh "$DIR"

MSG
