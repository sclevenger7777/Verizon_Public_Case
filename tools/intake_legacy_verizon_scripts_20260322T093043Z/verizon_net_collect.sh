#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="/storage/emulated/0/Forensics"
TS="$(date -u +%Y%m%dT%H%M%SZ)"

MANIFEST="${ROOT}/verizon_net_manifest_${TS}.tsv"
ARCHIVE="${ROOT}/verizon_net_bundle_${TS}.tar.gz"
HASHFILE="${ROOT}/verizon_net_bundle_${TS}.sha256"

echo "[*] Verizon net evidence collect"
echo "[*] Root: ${ROOT}"
echo "[*] Timestamp: ${TS}"
echo "[*] Manifest: ${MANIFEST}"
echo "[*] Archive:  ${ARCHIVE}"
echo

# 1) Discover Verizon-related evidence directories
#    (net_evidence_* and net_vm_bun*)
echo "[*] Scanning for Verizon net evidence directories..."
mapfile -t VERIZON_DIRS < <(
  find "${ROOT}" -maxdepth 1 -type d \( \
      -name 'net_evidence_*' -o \
      -name 'net_vm_bun*' \
  \) | sort
)

if [ "${#VERIZON_DIRS[@]}" -eq 0 ]; then
  echo "[!] No matching Verizon net evidence directories found under ${ROOT}"
  exit 1
fi

echo "[*] Found ${#VERIZON_DIRS[@]} directories:"
for d in "${VERIZON_DIRS[@]}"; do
  echo "    - ${d}"
done
echo

# 2) Build TSV manifest (path, type, size, mtime_iso8601_utc)
echo "[*] Building manifest..."
{
  echo -e "path\ttype\tsize_bytes\tmtime_utc"
  for d in "${VERIZON_DIRS[@]}"; do
    # Directory entry itself
    MTIME_DIR="$(TZ=UTC stat -c '%y' "${d}" | sed 's/ /T/' | cut -d'.' -f1)Z"
    echo -e "${d}\tdir\t0\t${MTIME_DIR}"

    # Contents
    find "${d}" -mindepth 1 -printf '%p\t%y\t%s\t%TY-%Tm-%TdT%TH:%TM:%TSZ\n' |
      sed 's/\.[0-9]\+Z$/Z/'    # normalize fractional seconds
  done
} > "${MANIFEST}"

echo "[*] Manifest written: ${MANIFEST}"
echo

# 3) Create tar.gz bundle of the Verizon evidence directories
echo "[*] Creating archive (this may take a while)..."
(
  cd "${ROOT}"
  # Strip ROOT prefix so entries are relative to Forensics/
  rel_dirs=()
  for d in "${VERIZON_DIRS[@]}"; do
    rel_dirs+=( "$(basename "${d}")" )
  done
  tar -czf "${ARCHIVE}" "${rel_dirs[@]}"
)

echo "[*] Archive created: ${ARCHIVE}"
echo

# 4) SHA-256 for manifest + archive
echo "[*] Computing SHA-256 hashes..."
sha256sum "${MANIFEST}" "${ARCHIVE}" > "${HASHFILE}"

echo "[*] Hashes written to: ${HASHFILE}"
echo
echo "[*] Done."
