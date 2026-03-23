#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==[ VZ HOME CONSOLIDATE (MOVE-ONLY, NO PG) ]=="

HOME_ROOT="/data/data/com.termux/files/home"
DL_ROOT="$HOME_ROOT/storage/downloads"

if [ ! -d "$HOME_ROOT" ]; then
  echo "[ERR] HOME_ROOT not found: $HOME_ROOT" >&2
  exit 1
fi

if [ ! -d "$DL_ROOT" ]; then
  echo "[ERR] DL_ROOT not found: $DL_ROOT" >&2
  exit 1
fi

# Find latest verizon_case_master_* in downloads
VZ_ROOT="$(ls -1dt "$DL_ROOT"/verizon_case_master_* 2>/dev/null | head -n1 || true)"

if [ -z "$VZ_ROOT" ] || [ ! -d "$VZ_ROOT" ]; then
  echo "[ERR] No verizon_case_master_* directory under $DL_ROOT" >&2
  exit 1
fi

echo "[INFO] Using VZ_ROOT = $VZ_ROOT"

# Ensure buckets exist
mkdir -p \
  "$VZ_ROOT/00_case_docs" \
  "$VZ_ROOT/03_pcap_and_captures" \
  "$VZ_ROOT/06_net_policy_stats" \
  "$VZ_ROOT/10_misc_verizon_logs" \
  "$VZ_ROOT/11_legacy_roots"

move_if_exists() {
  local src="$1"
  local dst_dir="$2"

  if [ -e "$src" ]; then
    echo "[MOVE] $src -> $dst_dir/"
    mv -- "$src" "$dst_dir/"
  else
    echo "[SKIP] $src (not found)"
  fi
}

echo "[STEP] Move case-level docs from HOME"
move_if_exists "$HOME_ROOT/verizon_case_ledger_skeleton_PREWIRED.md" \
               "$VZ_ROOT/00_case_docs"

echo "[STEP] Move connectivity dump (HOME-level)"
move_if_exists "$HOME_ROOT/conn_dump.txt" \
               "$VZ_ROOT/06_net_policy_stats"

echo "[STEP] Move VZ-specific dirs from HOME"

# IMS reject capture dir (HOME copy)
move_if_exists "$HOME_ROOT/vz_reject_auth_ims_20260131_112452" \
               "$VZ_ROOT/03_pcap_and_captures"

# VZ log bundles
move_if_exists "$HOME_ROOT/vzlogs" \
               "$VZ_ROOT/10_misc_verizon_logs"

# ADB report dirs
move_if_exists "$HOME_ROOT/vz_adb_report_20260131_103517" \
               "$VZ_ROOT/10_misc_verizon_logs"

move_if_exists "$HOME_ROOT/vz_adb_report_20260131_110013" \
               "$VZ_ROOT/10_misc_verizon_logs"

echo "[STEP] Move Wi-Fi diagnostic bundles"
move_if_exists "$HOME_ROOT/wifi_diag_20251214T023822Z" \
               "$VZ_ROOT/06_net_policy_stats"

move_if_exists "$HOME_ROOT/wifi_disable_bundle_20251214T021248Z" \
               "$VZ_ROOT/06_net_policy_stats"

echo "[STEP] Move earlier telecom evidence root into legacy bucket"
move_if_exists "$HOME_ROOT/telecom_evidence_central_20260219T142302Z" \
               "$VZ_ROOT/11_legacy_roots"

echo "[STEP] Move pm dump directories (baseline + Verizon-focused)"
move_if_exists "$HOME_ROOT/pm_dumps" \
               "$VZ_ROOT/06_net_policy_stats"

move_if_exists "$HOME_ROOT/pm_pm_dumps" \
               "$VZ_ROOT/06_net_policy_stats"

move_if_exists "$HOME_ROOT/pm_verizon_dumps" \
               "$VZ_ROOT/06_net_policy_stats"

move_if_exists "$HOME_ROOT/pm_verizon_dumpsl" \
               "$VZ_ROOT/06_net_policy_stats"

echo "[INFO] PG artifacts left in place:"
echo "       $HOME_ROOT/pg_collect_ims_env_last.txt"
echo "       $HOME_ROOT/pg_env_topology_REPORT_*.txt (if present)"

echo "==[ DONE ]=="
