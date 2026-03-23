#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

DL_ROOT="$HOME/storage/downloads"
DEFAULT_VZ_ROOT="$DL_ROOT/verizon_case_master_20260219T162625Z"
VZ_ROOT="${1:-$DEFAULT_VZ_ROOT}"

if [ ! -d "$VZ_ROOT" ]; then
  echo "ERROR: Case master directory not found: $VZ_ROOT" >&2
  exit 1
fi

echo "==[ VZ CORE COUNTS (EXCLUDING 09 & 11) ]=="
echo "Root: $VZ_ROOT"
echo

core_files="$(find "$VZ_ROOT" -type f \
  ! -path "$VZ_ROOT/09_bundles_archives/*" \
  ! -path "$VZ_ROOT/11_bugreports_root/*" \
  2>/dev/null | wc -l | awk '{print $1}')"

core_dirs="$(find "$VZ_ROOT" -type d \
  ! -path "$VZ_ROOT/09_bundles_archives/*" \
  ! -path "$VZ_ROOT/11_bugreports_root/*" \
  2>/dev/null | wc -l | awk '{print $1}')"

echo "Core files (no 09_bundles_archives, no 11_bugreports_root): $core_files"
echo "Core directories                          (same exclusion): $core_dirs"
