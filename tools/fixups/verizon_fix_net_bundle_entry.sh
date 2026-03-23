#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="/storage/emulated/0/Forensics"
TS="20260227T201224Z"

NET_BUNDLE="${ROOT}/verizon_net_bundle_${TS}.tar.gz"
NET_MANIFEST="${ROOT}/verizon_net_manifest_${TS}.tsv"
NET_SHA="${ROOT}/verizon_net_bundle_${TS}.tar.gz.sha256"

echo "[*] Verifying Verizon net bundle artifacts for ${TS}"
echo "    ROOT:        ${ROOT}"
echo "    NET_BUNDLE:  ${NET_BUNDLE}"
echo "    NET_MANIFEST:${NET_MANIFEST}"
echo "    NET_SHA:     ${NET_SHA}"
echo

# 1) Check that bundle exists
if [[ ! -f "${NET_BUNDLE}" ]]; then
  echo "[!] Net bundle not found at:"
  echo "    ${NET_BUNDLE}"
  echo "[!] Re-run verizon_net_collect.sh before attempting to index this bundle."
  exit 1
fi

# 2) Check that manifest exists
if [[ ! -f "${NET_MANIFEST}" ]]; then
  echo "[!] Net manifest not found at:"
  echo "    ${NET_MANIFEST}"
  echo "[!] Either it was removed/renamed or the collect script didn't write it."
  echo "[!] Options:"
  echo "    - Re-run verizon_net_collect.sh, OR"
  echo "    - Manually verify where the manifest is and adjust verizon_rebuild_index.sh."
  exit 1
fi

# 3) Ensure .sha256 exists and has correct format
if [[ ! -f "${NET_SHA}" ]]; then
  echo "[*] Net bundle sha256 file missing; creating:"
  echo "    ${NET_SHA}"
  HASH=$(sha256sum "${NET_BUNDLE}" | awk '{print $1}')
  printf '%s  %s\n' "${HASH}" "${NET_BUNDLE}" > "${NET_SHA}"
else
  echo "[*] Existing sha256 file found, validating format..."
  # This will fail if the file is corrupted or doesn't match the bundle
  if ! sha256sum -c "${NET_SHA}" >/dev/null 2>&1; then
    echo "[!] Existing sha256 does NOT validate against bundle, regenerating..."
    HASH=$(sha256sum "${NET_BUNDLE}" | awk '{print $1}')
    printf '%s  %s\n' "${HASH}" "${NET_BUNDLE}" > "${NET_SHA}"
    echo "[*] Regenerated sha256 and stored in:"
    echo "    ${NET_SHA}"
  else
    echo "[*] sha256 file validates correctly."
  fi
fi

echo
echo "[*] Rebuilding Verizon evidence index with updated net bundle entry..."
bash ~/verizon_rebuild_index.sh

echo
echo "[*] Final verizon_evidence_index.tsv:"
cd "${ROOT}"
column -t -s $'\t' verizon_evidence_index.tsv || cat verizon_evidence_index.tsv
