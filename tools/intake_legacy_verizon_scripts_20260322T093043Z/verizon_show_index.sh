#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="/storage/emulated/0/Forensics"
INDEX="${ROOT}/verizon_evidence_index.tsv"

if [[ ! -f "${INDEX}" ]]; then
  echo "[!] Index not found at ${INDEX}"
  exit 1
fi

echo "[*] Verizon evidence index:"
cd "${ROOT}"
column -t -s $'\t' verizon_evidence_index.tsv || cat verizon_evidence_index.tsv
