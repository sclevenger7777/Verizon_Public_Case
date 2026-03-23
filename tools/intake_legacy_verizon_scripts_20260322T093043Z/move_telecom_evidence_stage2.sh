#!/usr/bin/env bash
set -euo pipefail

echo "[*] Telecom evidence stage2 mover starting..."

HOME_DIR="${HOME}"

# Find latest telecom_evidence_central_* directory
CENTRAL_DIR="$(ls -d "${HOME_DIR}"/telecom_evidence_central_* 2>/dev/null | sort | tail -n 1 || true)"

if [[ -z "${CENTRAL_DIR}" ]]; then
  echo "[!] No telecom_evidence_central_* directory found in ${HOME_DIR}"
  echo "[!] Run the first mover script again or create the central dir before running this."
  exit 1
fi

echo "[*] Using existing central directory: ${CENTRAL_DIR}"

# Helper: move file into CENTRAL_DIR preserving relative path under $HOME
move_file() {
  local src="$1"

  # Normalize
  src="$(readlink -f -- "${src}")" || return 0

  # Skip if already under CENTRAL_DIR
  case "${src}" in
    "${CENTRAL_DIR}"/*)
      return 0
      ;;
  esac

  # Only operate on files under HOME_DIR
  case "${src}" in
    "${HOME_DIR}"/*)
      ;;
    *)
      return 0
      ;;
  esac

  # Compute relative path under HOME_DIR
  local rel="${src#${HOME_DIR}/}"
  local dest="${CENTRAL_DIR}/from_termux/${rel}"

  local dest_dir
  dest_dir="$(dirname -- "${dest}")"

  mkdir -p -- "${dest_dir}"

  echo "[*] mv '${src}' -> '${dest}'"
  mv -- "${src}" "${dest}"
}

# Helper: find and move files matching a glob, but only data artifacts (not .sh, not binaries)
move_glob() {
  local pattern="$1"
  shopt -s nullglob
  for f in ${pattern}; do
    # Skip dirs
    [[ -d "${f}" ]] && continue

    # Skip obvious scripts/binaries
    case "${f}" in
      *.sh|*.dex|*.so|*.js|*.ts|*.py|*.apk|*.aab|*.jar)
        continue
        ;;
    esac

    move_file "${f}"
  done
  shopt -u nullglob
}

cd "${HOME_DIR}"

echo "[*] Moving direct known files if present..."
for f in \
  "carconf1.txt" \
  "imscar1.txt" \
  "connect.txt" \
  "network1.txt" \
  "radio1.txt" \
  "telereg" \
  "telereg2" \
  "telereg3" \
  "vz_evidence_extract_"*.txt \
  "vz_line_vs_device_evidence_"*.txt \
  "vz_tier3_packet_"*.txt \
  "vz_tier3_packet_"*.log
do
  if [[ -e "${f}" ]]; then
    move_file "${f}"
  fi
done

echo "[*] Sweeping for additional vz/telecom txt/log/csv/tsv/pcap artifacts in top-level HOME..."

# Only sweep top-level files in $HOME (avoid deep case bundles and tools)
shopt -s nullglob
for f in "${HOME_DIR}"/vz_* "${HOME_DIR}"/verizon_* "${HOME_DIR}"/telereg*; do
  [[ -d "${f}" ]] && continue
  case "${f}" in
    *.txt|*.log|*.csv|*.tsv|*.pcap|*.pcapng|*.gz)
      move_file "${f}"
      ;;
    # Skip scripts
    *.sh)
      ;;
  esac
done
shopt -u nullglob

echo "[*] Stage2 telecom evidence move complete."
echo "[*] Everything collected in: ${CENTRAL_DIR}/from_termux"
