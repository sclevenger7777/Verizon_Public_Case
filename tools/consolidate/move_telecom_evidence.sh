#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

TS=$(date -u +"%Y%m%dT%H%M%SZ")
BASE="$HOME/telecom_evidence_central_$TS"

echo "[*] Creating central evidence directory:"
echo "    $BASE"
mkdir -p "$BASE"

# --- helper: normalize path under $HOME for relative storage ---
rel_under_home() {
  local f="$1"
  case "$f" in
    "$HOME"/*) printf '%s\n' "${f#$HOME/}" ;;
    *)         printf '%s\n' "$(basename "$f")" ;;
  esac
}

# --- helper: move files matching pattern from a list of dirs ---
move_match() {
  local pattern="$1"; shift
  local dir
  for dir in "$@"; do
    [ -d "$dir" ] || continue
    find "$dir" -maxdepth 7 -type f -iname "$pattern" -print0 2>/dev/null | \
    while IFS= read -r -d '' f; do
      # Skip files already inside BASE to avoid loops
      case "$f" in
        "$BASE"/*) continue ;;
      esac

      local rel path_dir dest_dir dest_path
      rel=$(rel_under_home "$f")
      path_dir=$(dirname "$rel")
      dest_dir="$BASE/$path_dir"
      mkdir -p "$dest_dir"

      dest_path="$dest_dir/$(basename "$f")"

      # Avoid overwriting: if exists, add .moved-<n>
      if [ -e "$dest_path" ]; then
        local n=1
        while [ -e "${dest_path}.moved${n}" ]; do
          n=$((n+1))
        done
        dest_path="${dest_path}.moved${n}"
      fi

      echo "    mv: $f -> $dest_path"
      mv "$f" "$dest_path"
    done
  done
}

echo "[*] Defining source directories..."

SRC_DIRS=(
  "$HOME"
  "$HOME/storage/downloads"
  "$HOME/storage/shared/Download"
  "$HOME/storage/shared/Documents"
  "$HOME/storage/shared/Documents/Verizon"
  "$HOME/storage/shared/Download/PCAPdroid"
  "$HOME/collab-ai-system"
  "$HOME/arch"
)

echo "[*] Moving known telecom / evidence files into central tree..."

# Very specific known file names you’ve used in this project
move_match "ip_addr.txt"         "${SRC_DIRS[@]}"
move_match "ip_route.txt"        "${SRC_DIRS[@]}"
move_match "ip_rule.txt"         "${SRC_DIRS[@]}"
move_match "sim_props.txt"       "${SRC_DIRS[@]}"
move_match "carrier_config.txt"  "${SRC_DIRS[@]}"
move_match "connectivity.txt"    "${SRC_DIRS[@]}"
move_match "netpolicy.txt"       "${SRC_DIRS[@]}"
move_match "phone.txt"           "${SRC_DIRS[@]}"
move_match "connectivity_service.txt" "${SRC_DIRS[@]}"
move_match "connectivity_full.txt"    "${SRC_DIRS[@]}"
move_match "telephony_registry.txt"   "${SRC_DIRS[@]}"
move_match "telephony_registry_full.txt" "${SRC_DIRS[@]}"
move_match "net_diag_*.log"      "${SRC_DIRS[@]}"
move_match "radio_logcat*.txt"   "${SRC_DIRS[@]}"
move_match "radio_recent*.txt"   "${SRC_DIRS[@]}"
move_match "imscar*.txt"         "${SRC_DIRS[@]}"
move_match "carconf*.txt"        "${SRC_DIRS[@]}"
move_match "query*.txt"          "${SRC_DIRS[@]}"
move_match "30c-*.txt"           "${SRC_DIRS[@]}"
move_match "verizon_packages*.txt" "${SRC_DIRS[@]}"

# More generic patterns for telecom-related logs and IMS/Verizon artifacts
move_match "*telephony*reg*.*"   "${SRC_DIRS[@]}"
move_match "*carrier*config*.*"  "${SRC_DIRS[@]}"
move_match "*ims*log*.*"         "${SRC_DIRS[@]}"
move_match "*ims*bundle*.*"      "${SRC_DIRS[@]}"
move_match "*vzw*log*.*"         "${SRC_DIRS[@]}"
move_match "*verizon*log*.*"     "${SRC_DIRS[@]}"
move_match "*radio*log*.*"       "${SRC_DIRS[@]}"
move_match "*net_diag*.*"        "${SRC_DIRS[@]}"
move_match "*pcapdroid*.*"       "${SRC_DIRS[@]}"
move_match "*.pcap"              "${SRC_DIRS[@]}"
move_match "*.pcapng"            "${SRC_DIRS[@]}"

echo "[*] Creating SHA256 manifest for the new central tree..."
find "$BASE" -type f -print0 | xargs -0 sha256sum > "$BASE/SHA256_MANIFEST.txt"

echo "[*] (Optional) Compressing central tree..."
tar -czf "$HOME/telecom_evidence_central_$TS.tar.gz" -C "$HOME" "$(basename "$BASE")"

echo "[*] DONE."
echo "Central evidence directory:"
echo "    $BASE"
echo "Archive:"
echo "    $HOME/telecom_evidence_central_$TS.tar.gz"
