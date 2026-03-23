#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ---- config ----
TS="$(date +%Y%m%d_%H%M%S)"
HOST_DIR="${PWD}/vz_reject_auth_ims_${TS}"
DEV_DIR="/sdcard/Download/vz_reject_auth_ims_${TS}"

# Patterns: tuned for attach/reject/auth/IMS/SIP
P_SIP='SIP|REGISTER|regi|dereg|403|404|408|480|486|488|500|503|P-CSCF|pcscf|IMPU|IMPI|epdg|ePDG|secims|ims|MMTEL|VoLTE|VoWiFi'
P_REJ='reject|Reject|REJECT|fail|FAIL|Fail|denied|not allowed|forbidden|barred|EMM|ESM|ATTACH|TAU|REG(ISTRATION)?|PLMN|CSFB|cause|DataFailCause|NO_SERVICE|OUT_OF_SERVICE|NOT_REG|limited service'
P_AUTH='EAP|AKA|USIM|ISIM|UICC|SIM auth|AUTH|authentication|GBA|IK|CK|RES|XRES|AUTN|RAND|MAC failure|sync failure|SQN|MILENAGE'

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "FATAL: missing $1"; exit 2; }; }
need_cmd adb
need_cmd awk
need_cmd sed
need_cmd grep
need_cmd sort
need_cmd uniq
need_cmd head
need_cmd tail
need_cmd tr

# ---- ensure device ----
if ! adb get-state >/dev/null 2>&1; then
  echo "FATAL: no adb device. Run: adb devices -l"
  exit 3
fi

mkdir -p "$HOST_DIR"

echo "[1/4] creating device dir: $DEV_DIR"
adb shell "mkdir -p '$DEV_DIR'"

echo "[2/4] collecting (dump-only, no waiting)"
# logcat dumps
adb shell "logcat -b radio  -v time -d > '$DEV_DIR/10_radio.log' 2> '$DEV_DIR/10_radio.err' || true"
adb shell "logcat -b main   -v time -d > '$DEV_DIR/11_main.log'   2> '$DEV_DIR/11_main.err'  || true"
adb shell "logcat -b events -v time -d > '$DEV_DIR/12_events.log' 2> '$DEV_DIR/12_events.err'|| true"

# dumpsys snapshots
adb shell "dumpsys telephony.registry > '$DEV_DIR/20_telephony_registry.txt' 2>/dev/null || true"
adb shell "dumpsys carrier_config     > '$DEV_DIR/21_carrier_config.txt'     2>/dev/null || true"
adb shell "dumpsys connectivity       > '$DEV_DIR/22_connectivity.txt'       2>/dev/null || true"
adb shell "dumpsys ims                > '$DEV_DIR/23_dumpsys_ims.txt'        2>/dev/null || true"
adb shell "dumpsys secims             > '$DEV_DIR/24_dumpsys_secims.txt'     2>/dev/null || true"
adb shell "getprop                    > '$DEV_DIR/25_getprop_all.txt'        2>/dev/null || true"
adb shell "getprop | grep -iE 'gsm|ims|volte|vowifi|wfc|carrier|sub|ril|radio|epdg|ePDG' > '$DEV_DIR/26_getprop_focus.txt' 2>/dev/null || true"

echo "[3/4] pulling to host: $HOST_DIR"
adb pull "$DEV_DIR" "$HOST_DIR" >/dev/null

# ---- helper functions ----
section() { printf "\n=== %s ===\n" "$*"; }
file_exists() { [ -f "$1" ] && [ -s "$1" ]; }
first_hits() {
  local label="$1" pattern="$2" file="$3" n="${4:-120}"
  section "$label :: first ${n} hits"
  if file_exists "$file"; then
    nl -ba "$file" | grep -E "$pattern" | head -n "$n" || true
  else
    echo "(missing/empty) $file"
  fi
}
counts_sip_codes() {
  local file="$1"
  section "SIP response code counts (radio+main)"
  if file_exists "$file"; then
    # Extract common SIP codes only (avoid IPs)
    grep -Eo '(^|[^0-9])(403|404|408|480|486|488|500|503)($|[^0-9])' "$file" \
      | tr -cd '0-9\n' \
      | awk 'NF{print $0}' \
      | sort | uniq -c | sort -nr || true
  else
    echo "(missing/empty) $file"
  fi
}
telephony_state_summary() {
  local file="$1"
  section "Telephony state summary (service state + registration)"
  if file_exists "$file"; then
    # Pull the dense ServiceState line + NetworkRegistrationInfo block starters
    grep -nE 'mServiceState=|mVoiceRegState=|mDataRegState=|NetworkRegistrationInfo\{|mPreciseDataConnectionStates=|getRilVoiceRadioTechnology=|getRilDataRadioTechnology=' "$file" \
      | head -n 120 || true
  else
    echo "(missing/empty) $file"
  fi
}
carrier_config_summary() {
  local file="$1"
  section "CarrierConfig IMS/VoLTE/WFC provisioning flags (subset)"
  if file_exists "$file"; then
    grep -nE 'carrier_.*(ims|volte|wfc)|(_ims_|_volte_|_wfc_)|provision|editable|entitlement|epdg|ePDG|mmtel|vowifi|vowlan' "$file" \
      | head -n 220 || true
  else
    echo "(missing/empty) $file"
  fi
}
connectivity_ims_summary() {
  local file="$1"
  section "Connectivity IMS bearer / P-CSCF / rmnet evidence"
  if file_exists "$file"; then
    grep -nE 'extra: IMS|Capabilities: IMS|MMTEL|PcscfAddresses|pcscf|rmnet|iwlan|ePDG|epdg|Transport.*CELLULAR|TelephonyNetworkSpecifier|mSubId' "$file" \
      | head -n 220 || true
  else
    echo "(missing/empty) $file"
  fi
}
auth_reject_counts() {
  local file="$1"
  section "AUTH/REJECT keyword counts (quick signal)"
  if file_exists "$file"; then
    printf "auth_hits=%s\n"  "$(grep -Eci "$P_AUTH" "$file" || true)"
    printf "rej_hits=%s\n"   "$(grep -Eci "$P_REJ"  "$file" || true)"
    printf "ims_sip_hits=%s\n" "$(grep -Eci "$P_SIP" "$file" || true)"
  else
    echo "(missing/empty) $file"
  fi
}

# ---- generate report ----
REPORT="$HOST_DIR/REPORT_reject_auth_ims_${TS}.txt"
RADIO="$HOST_DIR/$(basename "$DEV_DIR")/10_radio.log"
MAIN="$HOST_DIR/$(basename "$DEV_DIR")/11_main.log"
EVENTS="$HOST_DIR/$(basename "$DEV_DIR")/12_events.log"
TELEREG="$HOST_DIR/$(basename "$DEV_DIR")/20_telephony_registry.txt"
CARCFG="$HOST_DIR/$(basename "$DEV_DIR")/21_carrier_config.txt"
CONN="$HOST_DIR/$(basename "$DEV_DIR")/22_connectivity.txt"
IMS="$HOST_DIR/$(basename "$DEV_DIR")/23_dumpsys_ims.txt"
SECIMS="$HOST_DIR/$(basename "$DEV_DIR")/24_dumpsys_secims.txt"
GPROPF="$HOST_DIR/$(basename "$DEV_DIR")/26_getprop_focus.txt"

{
  echo "=== Reject/Auth/IMS Compact Report ==="
  echo "Generated: $(date -Is)"
  echo "Device dir: $DEV_DIR"
  echo "Host dir  : $HOST_DIR"
  echo

  section "Files pulled"
  ls -lh "$HOST_DIR/$(basename "$DEV_DIR")" | sed 's/^/  /'

  auth_reject_counts "$RADIO"
  auth_reject_counts "$MAIN"

  counts_sip_codes "$RADIO"
  counts_sip_codes "$MAIN"

  telephony_state_summary "$TELEREG"
  carrier_config_summary "$CARCFG"
  connectivity_ims_summary "$CONN"

  first_hits "RADIO: IMS/SIP/EPDG" "$P_SIP" "$RADIO" 200
  first_hits "RADIO: AUTH signals" "$P_AUTH" "$RADIO" 200
  first_hits "RADIO: REJECT/FAIL/CAUSE" "$P_REJ" "$RADIO" 220

  first_hits "MAIN: IMS/SIP/EPDG" "$P_SIP" "$MAIN" 160
  first_hits "EVENTS: relevant"    "$P_REJ|$P_AUTH|$P_SIP" "$EVENTS" 120

  first_hits "dumpsys ims: relevant" "$P_SIP|$P_REJ|$P_AUTH" "$IMS" 160
  first_hits "dumpsys secims: relevant" "$P_SIP|$P_REJ|$P_AUTH" "$SECIMS" 220

  section "getprop focus"
  if file_exists "$GPROPF"; then
    sed 's/^/  /' "$GPROPF" | head -n 220
  else
    echo "(missing/empty) $GPROPF"
  fi

  section "Quick heuristics"
  echo "- If telephony.registry shows OUT_OF_SERVICE/NOT_REG while connectivity shows an IMS NetworkAgent (extra: IMS) => likely IWLAN/IMS present but WWAN registration missing."
  echo "- SIP 403/404/488/500/503 bursts often indicate provisioning/entitlement or P-CSCF/IMS core rejection; confirm with secims/dumpsys ims lines around those codes."
  echo "- Look for explicit rejectCause / DataFailCause / 'not allowed' lines in RADIO: REJECT/FAIL/CAUSE section."
  echo
  echo "=== END ==="
} > "$REPORT"

chmod 0644 "$REPORT"
echo "[4/4] WROTE: $REPORT"
echo "Pulled logs: $HOST_DIR/$(basename "$DEV_DIR")/"
