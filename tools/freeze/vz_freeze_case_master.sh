#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

DL_ROOT="$HOME/storage/downloads"
VZ_ROOT="${1:-$DL_ROOT/verizon_case_master_20260219T162625Z}"

if [ ! -d "$VZ_ROOT" ]; then
  echo "ERROR: Case master directory not found: $VZ_ROOT" >&2
  exit 1
fi

ts="$(date -u +%Y%m%dT%H%M%SZ)"

# Place freeze artifact on /sdcard so it is visible off-device
OUT_DIR="/sdcard/Forensics"
mkdir -p "$OUT_DIR"

BASENAME="verizon_case_master_full_${ts}"
TAR_PATH="$OUT_DIR/${BASENAME}.tar.gz"
SHA_PATH="$OUT_DIR/${BASENAME}.tar.gz.sha256"

echo "==[ VZ CASE MASTER FREEZE ]=="
echo "Source : $VZ_ROOT"
echo "Tarball: $TAR_PATH"
echo

# Create tar.gz with relative paths
(
  cd "$(dirname "$VZ_ROOT")"
  root_name="$(basename "$VZ_ROOT")"
  tar -czf "$TAR_PATH" "$root_name"
)

# Compute SHA256
sha256sum "$TAR_PATH" > "$SHA_PATH"

echo "[OK] Freeze tarball created : $TAR_PATH"
echo "[OK] SHA256 manifest written: $SHA_PATH"
