#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="/storage/emulated/0/Forensics"
TEL="${ROOT}/evidence_telereg_20260115T071837Z.txt"
SHA="${TEL}.sha256"

echo "[*] Fixing telereg SHA entry"
echo "[*] TXT:  ${TEL}"
echo "[*] SHA:  ${SHA}"

if [[ ! -f "${TEL}" ]]; then
  echo "[!] Telereg text not found at ${TEL}" >&2
  exit 1
fi

# Compute SHA-256 with full path in the second column (matches your other .sha256 files)
hash_value="$(sha256sum "${TEL}" | awk '{print $1}')"
printf "%s  %s\n" "${hash_value}" "${TEL}" > "${SHA}"

echo "[*] Wrote SHA file:"
cat "${SHA}"

# Re-run the text/case registration script to add this row into the index
if [[ -x "${HOME}/register_verizon_text_and_case.sh" ]]; then
  echo "[*] Re-running register_verizon_text_and_case.sh ..."
  "${HOME}/register_verizon_text_and_case.sh"
else
  echo "[!] ${HOME}/register_verizon_text_and_case.sh not executable or missing; falling back to bash call."
  bash "${HOME}/register_verizon_text_and_case.sh"
fi

echo "[*] Done. Current index:"
cd "${ROOT}"
column -t -s $'\t' verizon_evidence_index.tsv || cat verizon_evidence_index.tsv
