#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==[ VZ EVIDENCE CONSOLIDATE (MOVE-ONLY, NO PG) ]=="

DL_ROOT="$HOME/storage/downloads"

if [ ! -d "$DL_ROOT" ]; then
  echo "[ERR] DL_ROOT not found: $DL_ROOT" >&2
  exit 1
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
VZ_ROOT="$DL_ROOT/verizon_case_master_$TS"

echo "[INFO] DL_ROOT = $DL_ROOT"
echo "[INFO] VZ_ROOT = $VZ_ROOT"

mkdir -p \
  "$VZ_ROOT/01_radio_logs" \
  "$VZ_ROOT/02_ims_artifacts" \
  "$VZ_ROOT/03_pcap_and_captures" \
  "$VZ_ROOT/04_telephony_phone_dumps" \
  "$VZ_ROOT/05_speed_tests" \
  "$VZ_ROOT/06_net_policy_stats" \
  "$VZ_ROOT/07_sim_apn" \
  "$VZ_ROOT/08_reports_summaries" \
  "$VZ_ROOT/09_bundles_archives" \
  "$VZ_ROOT/10_misc_verizon_logs"

# Helper: move any matches under DL_ROOT into a target dir
_mv_glob() {
  local target_dir="$1"; shift
  for pattern in "$@"; do
    for f in "$DL_ROOT"/$pattern; do
      # Skip if glob didn't match
      [ -e "$f" ] || continue

      # Never touch any AgentZero-related trees
      case "$f" in
        *"/AgentZero"* | *"/AgentZeroMirror"* | *"/AgentZero_Project_Mirror"*)
          echo "[SKIP] AgentZero-related path: $f"
          continue
          ;;
      esac

      echo "[MOVE] $f -> $target_dir/"
      mv -n -- "$f" "$target_dir"/
    done
  done
}

echo "[STEP] Move Verizon-specific directories (top-level buckets)"
_mv_glob "$VZ_ROOT/09_bundles_archives" \
  "verizon_evidence" \
  "verizon_net_logs" \
  "VZW_evidence_*" \
  "vzw_device_bundle_*" \
  "vzw_working_*"

echo "[STEP] Move radio logs"
_mv_glob "$VZ_ROOT/01_radio_logs" \
  "radio*.txt" \
  "radio_*.txt" \
  "radio_*.log" \
  "radio_full.log" \
  "radio_only_*.log" \
  "radio_grep_*.txt" \
  "radio_uim_slice_*.txt" \
  "radio_recent.txt" \
  "radio_all_*.txt"

echo "[STEP] Move IMS artifacts"
_mv_glob "$VZ_ROOT/02_ims_artifacts" \
  "ims.txt" \
  "ims_*.txt" \
  "ims_extract_*.txt" \
  "ims_extract_*.txt.gz" \
  "ims_artifacts_*.tgz" \
  "IMS_auth_timeline_*.txt" \
  "IMS_key_evidence_*.txt" \
  "ims_hits_vz_tier3_packet_*.txt" \
  "IMS_auth_timeline*-1.txt" \
  "IMS_auth_timeline*-2.txt" \
  "IMS_key_evidence*-1.txt" \
  "IMS_key_evidence*-2.txt" \
  "REPORT_reject_auth_ims_*.txt"

echo "[STEP] Move PDN / packet diff logs"
_mv_glob "$VZ_ROOT/02_ims_artifacts" \
  "pdn_hits_vz_tier3_packet_*.txt" \
  "diff_ims_hits_vz_tier3_packet_*.diff" \
  "diff_pdn_hits_vz_tier3_packet_*.diff" \
  "vz_tier3_packet_*.html" \
  "vz_tier3_packet_diff.html"

echo "[STEP] Move PCAP and related capture bundles"
_mv_glob "$VZ_ROOT/03_pcap_and_captures" \
  "PCAPdroid_*.pcap" \
  "PCAPdroid_*.csv" \
  "vz_bgcap_*" \
  "vz_bgcap_run_*" \
  "vz_wwan_capture_*" \
  "vz_reject_auth_ims_*" \
  "vz_bgcap_*.tar.gz" \
  "vz_wwan_capture_*.tar.gz"

echo "[STEP] Move telephony / phone dumps"
_mv_glob "$VZ_ROOT/04_telephony_phone_dumps" \
  "telephony*.txt" \
  "telephony_registry*.txt" \
  "phone_state.txt" \
  "phone.txt" \
  "phone (1).txt" \
  "phone (2).txt" \
  "phone (3).txt"

echo "[STEP] Move network policy / stats / connectivity"
_mv_glob "$VZ_ROOT/06_net_policy_stats" \
  "netpolicy.txt" \
  "netstats.txt" \
  "conn_dump.txt" \
  "connectivity.txt" \
  "huawei_connectivity_full.txt" \
  "huawei_connectivity_service.txt" \
  "ip_addr.txt" \
  "ip_route.txt" \
  "ip_rule.txt"

echo "[STEP] Move SIM / APN / subscription props"
_mv_glob "$VZ_ROOT/07_sim_apn" \
  "sim_props.txt" \
  "apn_global.txt" \
  "preferapn.txt" \
  "subscriptions.txt" \
  "mms_radio_trimmed.log"

echo "[STEP] Move speed test logs"
_mv_glob "$VZ_ROOT/05_speed_tests" \
  "speedtest_basic.log" \
  "speedtest_basic.log (1)" \
  "ping_basic.log"

echo "[STEP] Move bundles and archives (case-level packages)"
_mv_glob "$VZ_ROOT/09_bundles_archives" \
  "FCC_Submission_*.zip" \
  "forensics-review-*.zip" \
  "forensics-review-*.tar.gz" \
  "forensics_review_minimal_*.tar.gz" \
  "forensics_review_minimal_*.tar.gz (1).part_*" \
  "forensics_review_minimal_*.part_*" \
  "vzw_working_*.tar.gz" \
  "vzw_device_bundle_*.tar.gz"

echo "[STEP] Move reports / summaries (human-readable outputs)"
_mv_glob "$VZ_ROOT/08_reports_summaries" \
  "REPORT_reject_auth_ims_*.txt" \
  "IMS_auth_timeline_*.txt" \
  "IMS_key_evidence_*.txt" \
  "vz_wwan_check_*.txt" \
  "vz_wwan_check_priv_*.txt" \
  "IMS_auth_timeline*-1.txt" \
  "IMS_auth_timeline*-2.txt"

echo "[STEP] Move remaining clearly Verizon-tagged dirs/files (catch-all)"
_mv_glob "$VZ_ROOT/10_misc_verizon_logs" \
  "vz_wwan_capture_*.tar.gz" \
  "vzw_reject_auth_ims_*.txt" \
  "vzw_*" \
  "VZW_*"

echo "==[ DONE ]=="
echo "[INFO] Consolidated VZ evidence at: $VZ_ROOT"
