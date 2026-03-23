#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "==[ VZ EVIDENCE MOP-UP (MOVE-ONLY, NO PG) ]=="

DL_ROOT="/data/data/com.termux/files/home/storage/downloads"

if [ ! -d "$DL_ROOT" ]; then
  echo "[ERR] DL_ROOT not found: $DL_ROOT" >&2
  exit 1
fi

# Find the most recent verizon_case_master_* directory
VZ_ROOT="$(ls -1dt "$DL_ROOT"/verizon_case_master_* 2>/dev/null | head -n1 || true)"

if [ -z "$VZ_ROOT" ] || [ ! -d "$VZ_ROOT" ]; then
  echo "[ERR] No verizon_case_master_* directory under $DL_ROOT" >&2
  exit 1
fi

echo "[INFO] Using VZ_ROOT = $VZ_ROOT"

# Ensure target subdirs exist
mkdir -p \
  "$VZ_ROOT/01_radio_logs" \
  "$VZ_ROOT/06_net_policy_stats" \
  "$VZ_ROOT/07_sim_apn" \
  "$VZ_ROOT/10_misc_verizon_logs"

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

# 1) Radio-focused log
move_if_exists "$DL_ROOT/radio_provisioning_focus.log~" \
               "$VZ_ROOT/01_radio_logs"

# 2) pm dumps / vzwapiservice dump
move_if_exists "$DL_ROOT/pm.txt" \
               "$VZ_ROOT/10_misc_verizon_logs"

move_if_exists "$DL_ROOT/pm_dump_com_samsung_vzwapiservice_20251129T212334Z.txt" \
               "$VZ_ROOT/06_net_policy_stats"

# 3) Carrier config dumps
move_if_exists "$DL_ROOT/carrier_config.txt" \
               "$VZ_ROOT/07_sim_apn"

move_if_exists "$DL_ROOT/carrier_config (1).txt" \
               "$VZ_ROOT/07_sim_apn"

move_if_exists "$DL_ROOT/carrier_config (2).txt" \
               "$VZ_ROOT/07_sim_apn"

move_if_exists "$DL_ROOT/carrier_config (3).txt" \
               "$VZ_ROOT/07_sim_apn"

# 4) Broadcast logs
move_if_exists "$DL_ROOT/broadcasts.txt" \
               "$VZ_ROOT/10_misc_verizon_logs"

move_if_exists "$DL_ROOT/broadcasts (2).txt" \
               "$VZ_ROOT/10_misc_verizon_logs"

echo "==[ DONE ]=="
