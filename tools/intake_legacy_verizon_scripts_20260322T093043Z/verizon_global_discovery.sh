#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

FORENSICS_ROOT="/storage/emulated/0/Forensics"
TS_UTC="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${FORENSICS_ROOT}/verizon_global_discovery_${TS_UTC}.tsv"

# Roots to scan for Verizon-related artefacts
ROOTS=(
  "/storage/emulated/0"
  "/data/data/com.termux/files/home"
)

echo "[*] Verizon GLOBAL artifact discovery scan"
echo "[*] FORENSICS_ROOT: ${FORENSICS_ROOT}"
echo "[*] OUTPUT:         ${OUT}"
echo

mkdir -p "${FORENSICS_ROOT}"

# TSV header
printf 'root\tpath\tsize_bytes\tsha256\n' > "${OUT}"

scan_root() {
  local base="$1"

  if [[ ! -d "${base}" ]]; then
    echo "[*] Skipping missing base: ${base}"
    return 0
  fi

  echo "[*] Scanning base: ${base}"

  if [[ "${base}" = "/storage/emulated/0" ]]; then
    # Prune known no-go or already-managed trees:
    #  - ${FORENSICS_ROOT}: curated forensic archive
    #  - ${base}/Android/data: app-private dirs blocked by scoped storage
    find "${base}" \
      \( -path "${FORENSICS_ROOT}" -o -path "${base}/Android/data" \) -prune -o \
      -type f \( \
        -iname "*verizon*"      -o \
        -iname "*vzw*"          -o \
        -iname "*net_evidence*" -o \
        -iname "*vm_bundle*"    -o \
        -iname "*telereg*"      -o \
        -iname "*regulatory*"   -o \
        -iname "*ims*"          -o \
        -iname "*epdg*"         -o \
        -iname "*provision*"    -o \
        -iname "*speedtest*"    -o \
        -iname "*ookla*"        -o \
        -iname "*fast.com*" \
      \) -size -500M -print0
  else
    find "${base}" \
      -type f \( \
        -iname "*verizon*"      -o \
        -iname "*vzw*"          -o \
        -iname "*net_evidence*" -o \
        -iname "*vm_bundle*"    -o \
        -iname "*telereg*"      -o \
        -iname "*regulatory*"   -o \
        -iname "*ims*"          -o \
        -iname "*epdg*"         -o \
        -iname "*provision*"    -o \
        -iname "*speedtest*"    -o \
        -iname "*ookla*"        -o \
        -iname "*fast.com*" \
      \) -size -500M -print0
  fi
}

for base in "${ROOTS[@]}"; do
  while IFS= read -r -d '' file; do
    [[ -f "${file}" ]] || continue

    size="$(stat -c%s "${file}" 2>/dev/null || echo 0)"
    hash="$(sha256sum "${file}" | awk '{print $1}')"

    printf '%s\t%s\t%s\t%s\n' \
      "${base}" \
      "${file}" \
      "${size}" \
      "${hash}" >> "${OUT}"
  done < <(scan_root "${base}")
done

echo
echo "[*] Global discovery complete."
echo "[*] Output TSV:"
echo "    ${OUT}"
echo

if command -v column >/dev/null 2>&1; then
  column -t -s $'\t' "${OUT}" || cat "${OUT}"
else
  cat "${OUT}"
fi
