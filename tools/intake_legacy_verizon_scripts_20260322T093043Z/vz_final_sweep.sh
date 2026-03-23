#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==[ VZ FINAL SWEEP (MOVE-ONLY, NO PG) ]=="

DL_ROOT="$HOME/storage/downloads"
VZ_ROOT="$DL_ROOT/verizon_case_master_20260219T162625Z"
HOME_ROOT="$HOME"

if [ ! -d "$VZ_ROOT" ]; then
  echo "[ERROR] Canonical VZ root not found:"
  echo "        $VZ_ROOT"
  exit 1
fi

mkdir -p \
  "$VZ_ROOT/02_ims_artifacts" \
  "$VZ_ROOT/03_pcap_and_captures" \
  "$VZ_ROOT/04_telephony_phone_dumps" \
  "$VZ_ROOT/06_net_policy_stats" \
  "$VZ_ROOT/07_sim_apn" \
  "$VZ_ROOT/10_misc_verizon_logs"

move_if_exists() {
  SRC="$1"
  DEST="$2"
  if [ -e "$SRC" ]; then
    echo "[MOVE] $SRC -> $DEST/"
    mkdir -p "$DEST"
    rsync -a --remove-source-files "$SRC" "$DEST/"
    if [ -d "$SRC" ]; then
      find "$SRC" -type d -empty -delete 2>/dev/null || true
      rmdir "$SRC" 2>/dev/null || true
    fi
  fi
}

echo "[STEP] Sweep HOME-level Verizon artifacts"

move_if_exists "$HOME_ROOT/vz_adb_report_20260131_103517" "$VZ_ROOT/03_pcap_and_captures"
move_if_exists "$HOME_ROOT/vz_adb_report_20260131_110013" "$VZ_ROOT/03_pcap_and_captures"
move_if_exists "$HOME_ROOT/wifi_diag_20251214T023822Z" "$VZ_ROOT/06_net_policy_stats"
move_if_exists "$HOME_ROOT/wifi_disable_bundle_20251214T021248Z" "$VZ_ROOT/06_net_policy_stats"
move_if_exists "$HOME_ROOT/telecom_evidence_central_20260219T142302Z" "$VZ_ROOT/10_misc_verizon_logs"
move_if_exists "$HOME_ROOT/pm_dumps" "$VZ_ROOT/04_telephony_phone_dumps"
move_if_exists "$HOME_ROOT/pm_pm_dumps" "$VZ_ROOT/04_telephony_phone_dumps"
move_if_exists "$HOME_ROOT/pm_verizon_dumps" "$VZ_ROOT/04_telephony_phone_dumps"
move_if_exists "$HOME_ROOT/pm_verizon_dumpsl" "$VZ_ROOT/04_telephony_phone_dumps"
move_if_exists "$HOME_ROOT/pg_collect_ims_env_last.txt" "$VZ_ROOT/02_ims_artifacts"

echo "[STEP] Sweep remaining DOWNLOADS Verizon artifacts"

move_if_exists "$DL_ROOT/carrier_config.txt" "$VZ_ROOT/07_sim_apn"
move_if_exists "$DL_ROOT/carrier_config (1).txt" "$VZ_ROOT/07_sim_apn"
move_if_exists "$DL_ROOT/carrier_config (2).txt" "$VZ_ROOT/07_sim_apn"
move_if_exists "$DL_ROOT/carrier_config (3).txt" "$VZ_ROOT/07_sim_apn"

move_if_exists "$DL_ROOT/broadcasts.txt" "$VZ_ROOT/06_net_policy_stats"
move_if_exists "$DL_ROOT/broadcasts (2).txt" "$VZ_ROOT/06_net_policy_stats"

move_if_exists "$DL_ROOT/pm.txt" "$VZ_ROOT/04_telephony_phone_dumps"
move_if_exists "$DL_ROOT/pm_dump_com_samsung_vzwapiservice_20251129T212334Z.txt" "$VZ_ROOT/04_telephony_phone_dumps"

move_if_exists "$DL_ROOT/radio_provisioning_focus.log~" "$VZ_ROOT/01_radio_logs"

echo "[STEP] Sweep IMS bundle if Verizon-related"
move_if_exists "$DL_ROOT/PG_ims_bundle_20260209T032119Z" "$VZ_ROOT/02_ims_artifacts"

echo "==[ DONE ]=="
echo "[INFO] Verizon evidence now centralized at:"
echo "       $VZ_ROOT"
