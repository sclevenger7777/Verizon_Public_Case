#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
shopt -s nullglob

SD_ROOT="/sdcard"
VZ_ROOT="$SD_ROOT/Download/verizon_case_master_20260219T162625Z"

if [ ! -d "$VZ_ROOT" ]; then
  echo "ERROR: Verizon case master not found at: $VZ_ROOT" >&2
  exit 1
fi

echo "==[ VZ SDCARD FINAL CONSOLIDATE (MOVE-ONLY, NO PG) ]=="
echo "[INFO] SD_ROOT = $SD_ROOT"
echo "[INFO] VZ_ROOT = $VZ_ROOT"

move_if_exists() {
  local src="$1"
  local dest_dir="$2"

  if [ ! -e "$src" ]; then
    return 0
  fi

  mkdir -p "$dest_dir"
  local base
  base="$(basename "$src")"
  local dest="$dest_dir/$base"

  if [ -e "$dest" ]; then
    echo "[SKIP] $src -> $dest (already exists)"
  else
    echo "[MOVE] $src -> $dest_dir/"
    mv "$src" "$dest_dir/"
  fi
}

echo "[STEP] Move full Android bugreports into case master"
move_if_exists "$SD_ROOT/bugreports" "$VZ_ROOT/11_bugreports_root"

FORENSICS_DIR="$SD_ROOT/Forensics"

if [ -d "$FORENSICS_DIR" ]; then
  echo "[STEP] Move network / telco evidence bundles from Forensics"

  # Direct evidence bundles and reports
  for patt in \
    net_evidence_* \
    net_vm_bundle_* \
    evidence_telereg_* \
    net_vm_* \
    net_*evidence_* \
    net_vm_bundle_*
  do
    for item in "$FORENSICS_DIR"/$patt; do
      [ -e "$item" ] || continue
      move_if_exists "$item" "$VZ_ROOT/06_net_policy_stats/net_evidence_root"
    done
  done

  echo "[STEP] Move forensics_review* / minimal bundles from Forensics"
  for patt in \
    forensics_review_* \
    forensics_review_minimal_* \
    forensics-review-* \
    forensics_review_minimal_*.tar.gz* \
    forensics_review_minimal_*.parts.sha256 \
    forensics_review_minimal_*.worktree.*
  do
    for item in "$FORENSICS_DIR"/$patt; do
      [ -e "$item" ] || continue
      move_if_exists "$item" "$VZ_ROOT/09_bundles_archives"
    done
  done

  echo "[STEP] Move case directories that may contain VZ evidence"
  for patt in \
    Case_20* \
    net_evidence_* \
    net_vm_bundle_* \
    pcap_archive \
    reports \
    snapshots \
    evidence_telereg_*
  do
    for item in "$FORENSICS_DIR"/$patt; do
      [ -e "$item" ] || continue
      if [ -d "$item" ]; then
        move_if_exists "$item" "$VZ_ROOT/09_bundles_archives/forensics_cases"
      fi
    done
  done
fi

echo "[STEP] Move root-level Verizon pkg dump script from /sdcard"
for item in "$SD_ROOT"/verizon_pkg_dump.sh; do
  [ -e "$item" ] || continue
  move_if_exists "$item" "$VZ_ROOT/10_misc_verizon_logs"
done

echo "[STEP] Move device-state snapshots from /sdcard root"
DEVICE_STATE_DIR="$VZ_ROOT/12_device_state_snapshots"

for patt in \
  proc_sys_shell_snapshot_* \
  proc_sys_snapshot_* \
  red_tree_* \
  shared_top_* \
  .shared_tree_* \
  .shared_top_* \
  red_top_level.sha256 \
  shared_top_level.sha256 \
  .shared_tree_l2.sha256
do
  for item in "$SD_ROOT"/$patt; do
    [ -e "$item" ] || continue
    move_if_exists "$item" "$DEVICE_STATE_DIR"
  done
done

echo "[INFO] PG-related dirs (PG_chats, PCAPdroid exports, etc.) left untouched."
echo "[INFO] App-specific quarantine dirs (HappyMod_Evidence, happymod_*, espayloads, etc.) left in Forensics."
echo "==[ DONE ]=="
echo "[INFO] Final case master location: $VZ_ROOT"
