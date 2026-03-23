#!/usr/bin/env bash
set -euo pipefail

FORENSICS_ROOT="/storage/emulated/0/Forensics"
DISCOVERY_TSV="${1:-}"

echo "[*] Verizon GLOBAL discovery finalizer"
echo "[*] FORENSICS_ROOT: ${FORENSICS_ROOT}"

if [[ ! -d "${FORENSICS_ROOT}" ]]; then
  echo "[!] FORENSICS_ROOT does not exist: ${FORENSICS_ROOT}" >&2
  exit 1
fi

cd "${FORENSICS_ROOT}"

# If no TSV was passed, pick the most recent verizon_global_discovery_*.tsv
if [[ -z "${DISCOVERY_TSV}" ]]; then
  DISCOVERY_TSV="$(ls -1t verizon_global_discovery_*.tsv 2>/dev/null | head -n1 || true)"
  if [[ -z "${DISCOVERY_TSV}" ]]; then
    echo "[!] No verizon_global_discovery_*.tsv found in ${FORENSICS_ROOT}" >&2
    exit 1
  fi
else
  # If a path was passed, normalize it relative to FORENSICS_ROOT
  if [[ "${DISCOVERY_TSV}" != /* ]]; then
    DISCOVERY_TSV="${FORENSICS_ROOT}/${DISCOVERY_TSV}"
  fi
  if [[ ! -f "${DISCOVERY_TSV}" ]]; then
    echo "[!] Discovery TSV not found: ${DISCOVERY_TSV}" >&2
    exit 1
  fi
  # We want a path relative to FORENSICS_ROOT for registration
  case "${DISCOVERY_TSV}" in
    "${FORENSICS_ROOT}/"*)
      DISCOVERY_TSV="${DISCOVERY_TSV#${FORENSICS_ROOT}/}"
      ;;
    *)
      echo "[!] Discovery TSV is not under FORENSICS_ROOT (${FORENSICS_ROOT}): ${DISCOVERY_TSV}" >&2
      exit 1
      ;;
  esac
fi

# At this point, if DISCOVERY_TSV does not start with '/', treat it as relative to FORENSICS_ROOT.
if [[ "${DISCOVERY_TSV}" != /* ]]; then
  REL_PATH="${DISCOVERY_TSV}"
  ABS_PATH="${FORENSICS_ROOT}/${DISCOVERY_TSV}"
else
  ABS_PATH="${DISCOVERY_TSV}"
  # strip FORENSICS_ROOT prefix for REL_PATH if present
  case "${ABS_PATH}" in
    "${FORENSICS_ROOT}/"*)
      REL_PATH="${ABS_PATH#${FORENSICS_ROOT}/}"
      ;;
    *)
      echo "[!] ABS_PATH not under FORENSICS_ROOT: ${ABS_PATH}" >&2
      exit 1
      ;;
  esac
fi

if [[ ! -f "${ABS_PATH}" ]]; then
  echo "[!] Discovery TSV file does not exist: ${ABS_PATH}" >&2
  exit 1
fi

echo "[*] Using discovery TSV:"
echo "    ABS_PATH: ${ABS_PATH}"
echo "    REL_PATH: ${REL_PATH}"

# Derive EVIDENCE_ID from the filename
BASENAME="$(basename "${ABS_PATH}")"          # e.g. verizon_global_discovery_20260228T021508Z.tsv
BASENAME_NO_EXT="${BASENAME%.tsv}"           # verizon_global_discovery_20260228T021508Z
TS_PART="${BASENAME_NO_EXT#verizon_global_discovery_}"  # 20260228T021508Z (if pattern matches)

if [[ "${TS_PART}" == "${BASENAME_NO_EXT}" ]]; then
  # Fallback if pattern didn't match as expected
  EVIDENCE_ID="GLOBAL_DISCOVERY_${BASENAME_NO_EXT}"
else
  EVIDENCE_ID="GLOBAL_DISCOVERY_${TS_PART}"
fi

CHECKSUM="$(sha256sum "${ABS_PATH}" | awk '{print $1}')"
DESC="Verizon global artifact discovery TSV snapshot"

echo "[*] EVIDENCE_ID: ${EVIDENCE_ID}"
echo "[*] CHECKSUM:    ${CHECKSUM}"
echo "[*] DESC:        ${DESC}"

if [[ ! -x "${HOME}/verizon_register_evidence.sh" ]]; then
  echo "[!] Expected executable ~/verizon_register_evidence.sh not found or not executable" >&2
  echo "    Make sure verizon_register_evidence.sh exists and is chmod +x in your home directory." >&2
  exit 1
fi

echo "[*] Registering discovery TSV via verizon_register_evidence.sh ..."
bash "${HOME}/verizon_register_evidence.sh" \
  "${EVIDENCE_ID}" \
  "TSV" \
  "${REL_PATH}" \
  "${CHECKSUM}" \
  "${DESC}"

echo "[*] Done. Current verizon_evidence_index.tsv entries (tail -n 10):"
if [[ -f "verizon_evidence_index.tsv" ]]; then
  tail -n 10 verizon_evidence_index.tsv || true
else
  echo "[!] verizon_evidence_index.tsv not found in ${FORENSICS_ROOT}" >&2
fi
