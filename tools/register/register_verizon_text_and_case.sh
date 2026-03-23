#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="/storage/emulated/0/Forensics"
INDEX="${ROOT}/verizon_evidence_index.tsv"

echo "[*] Registering Verizon case master + text artifacts"
echo "[*] Root:  ${ROOT}"
echo "[*] Index: ${INDEX}"

# Ensure index header exists (compatible with the net script)
if [[ ! -f "${INDEX}" ]]; then
  echo "[*] Creating new index file"
  printf "timestamp\tbundle_path\tmanifest_path\tsha256_file\tsha256_value\ttype\tnotes\n" > "${INDEX}"
fi

append_row () {
  local ts="$1"
  local bundle="$2"
  local manifest="$3"
  local sha_file="$4"
  local sha_value="$5"
  local type="$6"
  local notes="$7"

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "${ts}" "${bundle}" "${manifest}" "${sha_file}" "${sha_value}" "${type}" "${notes}" \
    >> "${INDEX}"
}

shopt -s nullglob

# 1) verizon_case_master_full_*.tar.gz  (type: case_master_full_v1)
echo "[*] Scanning for verizon_case_master_full_*.tar.gz ..."
for bundle in "${ROOT}"/verizon_case_master_full_*.tar.gz; do
  base="$(basename "${bundle}")"
  ts_part="${base#verizon_case_master_full_}"
  ts_part="${ts_part%.tar.gz}"

  sha_file="${bundle}.sha256"
  if [[ ! -f "${sha_file}" ]]; then
    echo "[!] Missing sha256 for ${bundle}, skipping"
    continue
  fi

  sha_value="$(awk 'NF{print $1; exit}' "${sha_file}")"
  echo "    [+] case_master: ${base}"
  append_row "${ts_part}" "${bundle}" "" "${sha_file}" "${sha_value}" "case_master_full_v1" "Full Verizon case master archive"
done

# 2) evidence_telereg_*.txt  (type: telereg_log_v1)
echo "[*] Scanning for evidence_telereg_*.txt ..."
for txt in "${ROOT}"/evidence_telereg_*.txt; do
  base="$(basename "${txt}")"
  ts_part="${base#evidence_telereg_}"
  ts_part="${ts_part%.txt}"

  sha_file="${txt}.sha256"
  if [[ ! -f "${sha_file}" ]]; then
    echo "[!] Missing sha256 for ${txt}, skipping"
    continue
  fi

  sha_value="$(awk 'NF{print $1; exit}' "${sha_file}")"
  echo "    [+] telereg: ${base}"
  append_row "${ts_part}" "${txt}" "" "${sha_file}" "${sha_value}" "telereg_log_v1" "Tele-reg / provisioning narrative + logs"
done

# 3) regulatory_ve*.txt  (type: regulatory_log_v1)
echo "[*] Scanning for regulatory_ve*.txt ..."
for txt in "${ROOT}"/regulatory_ve*.txt; do
  base="$(basename "${txt}")"
  ts_part="${base#regulatory_ve}"
  ts_part="${ts_part%.txt}"

  sha_file="${txt}.sha256"
  if [[ ! -f "${sha_file}" ]]; then
    echo "[!] Missing sha256 for ${txt}, skipping"
    continue
  fi

  sha_value="$(awk 'NF{print $1; exit}' "${sha_file}")"
  echo "    [+] regulatory: ${base}"
  append_row "${ts_part}" "${txt}" "" "${sha_file}" "${sha_value}" "regulatory_log_v1" "Regulatory evidence bundle text (MO AG / FCC context)"
done

echo "[*] Done. Index is at: ${INDEX}"
