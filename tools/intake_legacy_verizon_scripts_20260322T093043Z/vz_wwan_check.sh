#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
echo "=== WWAN CHECK ==="
date -Is
echo

echo "[settings global]"
for k in mobile_data multi_sim_data_call data_roaming; do
  echo -n "$k="; settings get global "$k" 2>/dev/null || true
done
echo

echo "[telephony.registry: default-data + RAT]"
dumpsys telephony.registry 2>/dev/null | grep -E \
' mDefaultDataSubId=|mDefaultVoiceSubId=|dataConnectionState=|dataNetworkType=|overrideNetworkType=|mServiceState=' \
|| true
echo

echo "[connectivity: active networks]"
dumpsys connectivity 2>/dev/null | grep -E \
'ActiveNetwork|NetworkAgentInfo|TRANSPORT_CELLULAR|TRANSPORT_WIFI|VALIDATED|CAPABILITY_INTERNET' \
|| true
