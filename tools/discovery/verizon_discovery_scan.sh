#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="/storage/emulated/0/Forensics"
INDEX="${ROOT}/verizon_evidence_index.tsv"
OUT="${ROOT}/verizon_unindexed_discovery_$(date -u +%Y%m%dT%H%M%SZ).tsv"

# Termux-safe tmp directory
TMP_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
mkdir -p "${TMP_DIR}"
INDEXED_PATHS="${TMP_DIR}/verizon_indexed_paths.txt"

echo "[*] Verizon artifact discovery scan"
echo "[*] ROOT:  ${ROOT}"
echo "[*] INDEX: ${INDEX}"
echo "[*] OUT:   ${OUT}"
echo "[*] TMP:   ${TMP_DIR}"
echo

if [[ ! -f "${INDEX}" ]]; then
  echo "[!] Index file not found. Abort."
  exit 1
fi

# Extract already indexed bundle paths (2nd column in TSV)
awk -F'\t' 'NR>1 {print $2}' "${INDEX}" > "${INDEXED_PATHS}"

# Header for discovery output
echo -e "path\tsize_bytes\tsha256" > "${OUT}"

# Walk all Verizon-looking files under ROOT
while IFS= read -r -d '' file; do
  # Skip if this exact path is already in the index
  if grep -Fxq "$file" "${INDEXED_PATHS}"; then
    continue
  fi

  size=$(stat -c%s "$file" 2>/dev/null || echo 0)
  hash=$(sha256sum "$file" | awk '{print $1}')

  echo -e "${file}\t${size}\t${hash}" >> "${OUT}"

done < <(
  find "${ROOT}" -type f \( \
    -iname "*verizon*"      -o \
    -iname "*net_evidence*" -o \
    -iname "*vm_bundle*"    -o \
    -iname "*telereg*"      -o \
    -iname "*regulatory*"   -o \
    -iname "*ims*"          -o \
    -iname "*epdg*"         -o \
    -iname "*provision*" \
  \) -print0
)

echo
echo "[*] Discovery complete."
echo "[*] Output:"
echo "    ${OUT}"
echo

# Human-readable view
column -t -s $'\t' "${OUT}" || cat "${OUT}"
