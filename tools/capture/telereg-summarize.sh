#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ts="$(date -u +%Y%m%dT%H%M%SZ)"
out="${PWD}/telereg_summary_${ts}.txt"

f_telereg="${1:-telereg}"
f_telereg2="${2:-telereg2}"
f_telereg3="${3:-telereg3}"

{
  echo "utc=$ts"
  echo

  if [ -f "$f_telereg" ]; then
    echo "=== telereg (filtered telephony.registry) ==="
    grep -nE 'mActiveDataSubId=|mDefaultSubId=|Default subscription updated|notifyActiveDataSubIdChanged|notifyServiceStateForSubscriber' "$f_telereg" || true
    echo
  else
    echo "=== telereg: missing ==="
    echo
  fi

  if [ -f "$f_telereg2" ]; then
    echo "=== telereg2 (full telephony.registry) key lines ==="
    grep -nE 'mActiveDataSubId=|mDefaultSubId=|mDefaultPhoneId=|TelephonyDisplayInfo|mCarrierPrivilegeState=|notifyActiveDataSubIdChanged|notifyDisplayInfoChanged|notifyServiceStateForSubscriber|notifyDataConnectionForSubscriber' "$f_telereg2" || true
    echo
  else
    echo "=== telereg2: missing ==="
    echo
  fi

  if [ -f "$f_telereg3" ]; then
    echo "=== telereg3 (dumpsys isub) key lines ==="
    grep -nE 'SubscriptionManagerService:|Logical SIM slot|default(SubId|VoiceSubId|DataSubId|SmsSubId)|activeDataSubId=|mSimState|Active subscriptions:|All subscriptions:|Embedded subscriptions:|Euicc enabled=' "$f_telereg3" || true
    echo
  else
    echo "=== telereg3: missing ==="
    echo
  fi

  echo "done"
} > "$out"

echo "$out"
