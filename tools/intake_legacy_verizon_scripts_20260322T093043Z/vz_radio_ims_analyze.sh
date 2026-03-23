#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

VZ_ROOT="$HOME/storage/downloads/verizon_case_master_20260219T162625Z"
DOCS="$VZ_ROOT/00_case_docs"
mkdir -p "$DOCS"

TS_UTC="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_TSV="$DOCS/vz_radio_ims_table_${TS_UTC}.tsv"
OUT_SUM="$DOCS/vz_radio_ims_summary_${TS_UTC}.txt"

echo "==[ VZ RADIO/IMS ANALYZE ]=="
echo "Root    : $VZ_ROOT"
echo "TSV out : $OUT_TSV"
echo "Summary : $OUT_SUM"
echo

extract_ts() {
    local line="$1"
    if [[ "$line" =~ ^([0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{3})?) ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "$line" =~ ^(20[0-9]{2}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return 0
    fi
    printf '%s' "UNKNOWN"
}

categorize_line() {
    local bucket="$1"
    local line="$2"

    shopt -s nocasematch

    if [[ "$bucket" == "radio" ]]; then
        if [[ "$line" =~ ATTACH_REJECT|EMM_CAUSE|EMM|MME|GUTI|LTE_REG_FAIL ]]; then
            echo "RADIO_ATTACH_OR_CORE"
        elif [[ "$line" =~ RRC|RAT_SWITCH|HANDOVER ]]; then
            echo "RADIO_RRC_EVENT"
        else
            echo "RADIO_OTHER"
        fi
        shopt -u nocasematch
        return
    fi

    if [[ "$bucket" == "ims" ]]; then
        if   [[ "$line" =~ SIP[[:space:]]+403|403[[:space:]]+Forbidden ]]; then
            echo "IMS_SIP_403"
        elif [[ "$line" =~ SIP[[:space:]]+480|480[[:space:]]+Temporarily ]]; then
            echo "IMS_SIP_480"
        elif [[ "$line" =~ 503[[:space:]]+Service|SIP[[:space:]]+503 ]]; then
            echo "IMS_SIP_503"
        elif [[ "$line" =~ 401[[:space:]]+Unauthorized|407[[:space:]]+Proxy ]]; then
            echo "IMS_SIP_AUTH_4xx"
        elif [[ "$line" =~ AUTH|AKA|AUTH_REJECT ]]; then
            echo "IMS_AUTH_EVENT"
        elif [[ "$line" =~ EPDG|IWLAN ]]; then
            echo "IMS_EPDG_EVENT"
        elif [[ "$line" =~ REGISTRATION|REGISTER|isImsRegistered ]]; then
            echo "IMS_REG_EVENT"
        else
            echo "IMS_OTHER"
        fi
        shopt -u nocasematch
        return
    fi

    if [[ "$bucket" == "telephony" ]]; then
        if [[ "$line" =~ mServiceState|VoiceRegState|DataRegState ]]; then
            echo "SERVICE_STATE"
        elif [[ "$line" =~ isImsRegistered|IMS_REG|VOLTE ]]; then
            echo "IMS_FLAG_STATE"
        else
            echo "TELEPHONY_OTHER"
        fi
        shopt -u nocasematch
        return
    fi

    shopt -u nocasematch
    echo "OTHER"
}

process_file() {
    local bucket="$1"
    local f="$2"
    local tag
    tag="$(basename "$f")"

    local grep_expr
    case "$bucket" in
        radio)
            grep_expr='REGISTRATION|AUTH|REJECT|GUTI|MME|UIM|EMM|ATTACH'
            ;;
        ims)
            grep_expr='403|480|503|401|407|REGISTER|AUTH|REJECT|SIP|EPDG|IMS'
            ;;
        telephony)
            grep_expr='mServiceState|DataRegState|VoiceRegState|isImsRegistered|IMS'
            ;;
        *)
            return 0
            ;;
    esac

    # Use process substitution; ignore grep exit 1 (no matches)
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local ts cat
        ts="$(extract_ts "$line")"
        cat="$(categorize_line "$bucket" "$line")"
        line="${line///    }"
        echo -e "${ts}\t${bucket}\t${tag}\t${cat}\t${line}"
    done < <(grep -E "$grep_expr" "$f" 2>/dev/null || true)
}

echo -e "timestamp\tbucket\tfile\tcategory\tline" > "$OUT_TSV"

if [ -d "$VZ_ROOT/01_radio_logs" ]; then
  echo "[SCAN] 01_radio_logs"
  for f in "$VZ_ROOT/01_radio_logs/"*; do
      [ -f "$f" ] && process_file "radio" "$f" >> "$OUT_TSV"
  done
fi

if [ -d "$VZ_ROOT/02_ims_artifacts" ]; then
  echo "[SCAN] 02_ims_artifacts"
  for f in "$VZ_ROOT/02_ims_artifacts/"*; do
      [ -f "$f" ] && process_file "ims" "$f" >> "$OUT_TSV"
  done
fi

if [ -d "$VZ_ROOT/04_telephony_phone_dumps" ]; then
  echo "[SCAN] 04_telephony_phone_dumps"
  for f in "$VZ_ROOT/04_telephony_phone_dumps/"*; do
      [ -f "$f" ] && process_file "telephony" "$f" >> "$OUT_TSV"
  done
fi

# Compute event count (exclude header)
TOTAL_EVENTS=0
if [ -f "$OUT_TSV" ]; then
    local_lines="$(wc -l < "$OUT_TSV" || echo 1)"
    if [ "$local_lines" -gt 1 ]; then
        TOTAL_EVENTS=$((local_lines - 1))
    fi
fi

{
  echo "==[ VZ RADIO/IMS SUMMARY ]=="
  echo "Source TSV    : $OUT_TSV"
  echo "Total events  : $TOTAL_EVENTS"
  echo

  if [ "$TOTAL_EVENTS" -eq 0 ]; then
      echo "[INFO] No matching lines found in radio/IMS/telephony logs using current patterns."
      echo "[INFO] You may need to widen grep expressions if you expect hits."
  else
      echo "[CATEGORY COUNTS]"
      cut -f4 "$OUT_TSV" | tail -n +2 | sort | uniq -c | sort -nr
      echo

      echo "[BUCKET COUNTS]"
      cut -f2 "$OUT_TSV" | tail -n +2 | sort | uniq -c | sort -nr
      echo

      echo "[CATEGORY x BUCKET CROSS-TAB]"
      awk -F'\t' 'NR>1 {count[$2 FS $4]++} END {for (k in count) print count[k], k}' "$OUT_TSV" \
        | sort -nr
  fi
} > "$OUT_SUM"

echo
echo "[OK] Events found    : $TOTAL_EVENTS"
echo "[OK] TSV written to  : $OUT_TSV"
echo "[OK] Summary written : $OUT_SUM"
