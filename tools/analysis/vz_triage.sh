#!/usr/bin/env bash
set -euo pipefail

OUT="vz_tier3_packet_$(date +%Y%m%d_%H%M%S).txt"

FILES=(
  "radio_logcat.txt"
  "radio_recent.txt"
  "telephony_registry.txt"
  "telephony_registry_full.txt"
  "telereg"
  "telereg2"
  "connectivity_service.txt"
  "connectivity_full.txt"
  "net_diag_20251113_164204.log"
  "phone.txt"
  "carrier_config.txt"
  "carconf1.txt"
  "imscar1.txt"
  "ip_addr.txt"
  "ip_route.txt"
  "ip_rule.txt"
)

have() { [[ -f "$1" ]]; }

PAT='(SetupDataCallResult|DataProfile|ApnSetting|VZWINTERNET|IMS\b|Pcscf|P-CSCF|IMPU|IMPI|SIP|REGISTER|401|403|404|407|408|480|486|488|500|503|not registered|REGISTRATION|DEREG|attach reject|ATTACH REJECT|PDN|PDU session|reject|fail cause|SERVICE_OPTION_NOT_SUBSCRIBED|MISSING_UNKNOWN_APN|NO_RETRY|NOT_SUBSCRIBED|AUTH|AUTHENTICATION|EMM|ESM|qci|QoS|EPS|5QI|PCO|entitlement)'

{
  echo "=== Verizon Tier-3 Triage Packet ==="
  echo "Generated: $(date -Is)"
  echo

  echo "== Files present =="
  for f in "${FILES[@]}"; do
    if have "$f"; then
      echo "OK   $f"
    else
      echo "MISS $f"
    fi
  done

  echo
  echo "== High-signal patterns (PDN bringup / rejects / IMS) =="
  for f in "${FILES[@]}"; do
    have "$f" || continue
    echo
    echo "--- $f ---"
    grep -nE "$PAT" "$f" || true
  done

  echo
  echo "== Summary counts (quick severity glance) =="
  for f in "${FILES[@]}"; do
    have "$f" || continue
    echo
    echo "--- $f ---"
    echo -n "reject/fail/not_subscribed/auth/sip errors: "
    grep -Eci '(reject|fail cause|NOT_SUBSCRIBED|AUTH|AUTHENTICATION|\bSIP\b| 4[0-9]{2} | 5[0-9]{2} )' "$f" || true
    echo -n "VZWINTERNET hits: "
    grep -Eci 'VZWINTERNET' "$f" || true
    echo -n "IMS hits: "
    grep -Eci '(\bIMS\b|Pcscf|P-CSCF|REGISTER|SIP)' "$f" || true
  done

  echo
  echo "== Notes =="
  echo "If you see SIP REGISTER failures (401/403/407/488/5xx) or PDN/attach rejects with causes, that is carrier-core evidence suitable for Tier-3."
} > "$OUT"

chmod 0644 "$OUT"
echo "$OUT"
