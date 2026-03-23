#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="/storage/emulated/0/Forensics"
INDEX="${ROOT}/verizon_evidence_index.tsv"

echo "[*] Registering latest Verizon net bundle in index"
echo "[*] Root:    ${ROOT}"
echo "[*] Index:   ${INDEX}"

# Find latest net bundle, manifest, and sha256
bundle="$(ls -1t "${ROOT}"/verizon_net_bundle_*.tar.gz 2>/dev/null | head -n1 || true)"
manifest="$(ls -1t "${ROOT}"/verizon_net_manifest_*.tsv 2>/dev/null | head -n1 || true)"
sha_file="$(ls -1t "${ROOT}"/verizon_net_bundle_*.sha256 2>/dev/null | head -n1 || true)"

if [[ -z "${bundle}" || -z "${manifest}" || -z "${sha_file}" ]]; then
  echo "[!] Could not find bundle/manifest/sha256 in ${ROOT}"
  exit 1
fi

# Extract timestamp from bundle filename
# verizon_net_bundle_YYYYMMDDThhmmssZ.tar.gz
base_bundle="$(basename "${bundle}")"
ts_part="${base_bundle#verizon_net_bundle_}"
ts_part="${ts_part%.tar.gz}"

# Read sha256 value
sha_value="$(awk 'NR==1 {print $1}' "${sha_file}")"

echo "[*] Bundle:   ${bundle}"
echo "[*] Manifest: ${manifest}"
echo "[*] SHA256:   ${sha_value}"
echo "[*] Timestamp: ${ts_part}"

# Create index with header if it does not exist
if [[ ! -f "${INDEX}" ]]; then
  echo "[*] Creating new index file"
  printf "timestamp\tbundle_path\tmanifest_path\tsha256_file\tsha256_value\ttype\tnotes\n" > "${INDEX}"
fi

# Append entry
printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
  "${ts_part}" \
  "${bundle}" \
  "${manifest}" \
  "${sha_file}" \
  "${sha_value}" \
  "net_evidence_v1" \
  "PCAP/VM net evidence trees (8 dirs, Verizon; see manifest)" \
  >> "${INDEX}"

echo "[*] Index updated:"
echo "    ${INDEX}"
