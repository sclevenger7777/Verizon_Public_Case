#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

OUT="/sdcard/Download/vz_wwan_check_priv_$(date +%Y%m%d_%H%M%S).txt"

run_shell() {
  if command -v rish >/dev/null 2>&1; then
    rish -c "$*"
    return $?
  fi
  if command -v su >/dev/null 2>&1; then
    su -c "$*"
    return $?
  fi
  # unprivileged fallback
  sh -c "$*"
}

whoami_mode() {
  if command -v rish >/dev/null 2>&1; then
    echo "MODE=shizuku(rish)"
  elif command -v su >/dev/null 2>&1; then
    echo "MODE=root(su)"
  else
    echo "MODE=unprivileged(app_uid)"
  fi
}

{
  echo "=== WWAN CHECK (priv-aware) ==="
  date -Is
  whoami_mode
  echo

  echo "[id]"
  run_shell id || true
  echo

  echo "[global settings]"
  # these will work only in shell/root mode
  for k in mobile_data multi_sim_data_call data_roaming; do
    echo -n "$k="
    run_shell "settings get global $k" 2>/dev/null || echo "UNAVAILABLE"
  done
  echo

  echo "[telephony.registry: key fields]"
  run_shell "dumpsys telephony.registry" 2>/dev/null | grep -E \
' mDefaultDataSubId=|mDefaultVoiceSubId=|mDefaultSmsSubId=|dataConnectionState=|dataNetworkType=|overrideNetworkType=|mServiceState=|mPreciseDataConnectionStates=|mImsRegistrationState=|mImsVoiceCapable=|mVoNrEnabled=|mVoLteEnabled=|mIwlanOperationMode=' \
  || echo "UNAVAILABLE (need shell/root)"
  echo

  echo "[connectivity: active + transports]"
  run_shell "dumpsys connectivity" 2>/dev/null | grep -E \
'ActiveNetwork|NetworkAgentInfo|TRANSPORT_CELLULAR|TRANSPORT_WIFI|CAPABILITY_INTERNET|VALIDATED|LinkProperties|DnsAddresses' \
  || echo "UNAVAILABLE (need shell/root)"
  echo

  echo "[secims (Samsung IMS) quick]"
  run_shell "dumpsys secims" 2>/dev/null | grep -E \
'REGI|REGISTER|dereg|P-CSCF|pcscf|IMPU|IMPI|error|403|404|408|480|486|488|500|503' \
  || echo "UNAVAILABLE (need shell/root or not Samsung)"
  echo

  echo "[radio logcat access test]"
  # If this prints lines, you can actually capture Tier-3 evidence from the device side.
  run_shell "logcat -b radio -d -v time | tail -n 30" 2>/dev/null \
  || echo "UNAVAILABLE (need shell/root for radio buffer)"
  echo
} | tee "$OUT"

echo "WROTE: $OUT"
