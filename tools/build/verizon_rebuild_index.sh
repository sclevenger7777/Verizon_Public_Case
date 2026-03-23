#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="/storage/emulated/0/Forensics"
INDEX="${ROOT}/verizon_evidence_index.tsv"

echo "[*] Rebuilding Verizon evidence index from disk"
echo "[*] ROOT:  ${ROOT}"
echo "[*] INDEX: ${INDEX}"

mkdir -p "${ROOT}"

# Clean up any bogus telereg sha from earlier broken runs
if [[ -f "${ROOT}/evidence_telereg_telereg.txt.sha256" ]]; then
  echo "[*] Removing bogus telereg sha: ${ROOT}/evidence_telereg_telereg.txt.sha256"
  rm -f "${ROOT}/evidence_telereg_telereg.txt.sha256"
fi

# Helper: return first match for a glob, or empty
find_one() {
  local pattern="$1"
  local f
  # shellcheck disable=SC2086
  f=$(ls -1 $pattern 2>/dev/null | head -n1 || true)
  if [[ -n "${f:-}" ]]; then
    printf '%s' "$f"
    return 0
  fi
  return 1
}

# Helper: extract YYYYMMDDThhmmssZ from name
ts_from_name() {
  local name="$1"
  local ts
  ts=$(printf '%s\n' "${name}" | grep -oE '[0-9]{8}T[0-9]{6}Z' | head -n1 || true)
  printf '%s' "${ts}"
}

# Start new TSV with header (overwrite any existing)
printf 'timestamp\tbundle_path\tmanifest_path\tsha256_file\tsha256_value\ttype\tnotes\n' > "${INDEX}"

########################################
# 1) Net evidence bundle (verizon_net_*)
########################################
NET_BUNDLE=$(find_one "${ROOT}/verizon_net_bundle_"*".tar.gz" || true)
if [[ -n "${NET_BUNDLE}" ]]; then
  NET_BASE=$(basename "${NET_BUNDLE}")
  NET_TS=$(ts_from_name "${NET_BASE}")
  if [[ -z "${NET_TS}" ]]; then
    echo "[!] Could not extract timestamp from ${NET_BASE}, skipping net_evidence_v1" >&2
  else
    NET_MANIFEST="${ROOT}/verizon_net_manifest_${NET_TS}.tsv"
    NET_SHA="${ROOT}/verizon_net_bundle_${NET_TS}.tar.gz.sha256"

    if [[ -f "${NET_MANIFEST}" && -f "${NET_SHA}" ]]; then
      NET_SHA_VAL=$(awk '{print $1}' "${NET_SHA}")
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "${NET_TS}" \
        "${NET_BUNDLE}" \
        "${NET_MANIFEST}" \
        "${NET_SHA}" \
        "${NET_SHA_VAL}" \
        "net_evidence_v1" \
        "PCAP/VM net evidence trees (8 dirs, Verizon; see manifest)" \
        >> "${INDEX}"
      echo "[+] Registered net_evidence_v1 (${NET_TS})"
    else
      echo "[!] Missing manifest or sha for net bundle timestamp=${NET_TS}, skipping" >&2
    fi
  fi
else
  echo "[*] No verizon_net_bundle_*.tar.gz found; skipping net_evidence_v1"
fi

########################################
# 2) Case master full (verizon_case_master_full_*)
########################################
CASE_BUNDLE=$(find_one "${ROOT}/verizon_case_master_full_"*".tar.gz" || true)
if [[ -n "${CASE_BUNDLE}" ]]; then
  CASE_BASE=$(basename "${CASE_BUNDLE}")
  CASE_TS=$(ts_from_name "${CASE_BASE}")
  if [[ -z "${CASE_TS}" ]]; then
    echo "[!] Could not extract timestamp from ${CASE_BASE}, skipping case_master_full_v1" >&2
  else
    CASE_SHA="${ROOT}/verizon_case_master_full_${CASE_TS}.tar.gz.sha256"

    if [[ -f "${CASE_SHA}" ]]; then
      CASE_SHA_VAL=$(awk '{print $1}' "${CASE_SHA}")
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "${CASE_TS}" \
        "${CASE_BUNDLE}" \
        "" \
        "${CASE_SHA}" \
        "${CASE_SHA_VAL}" \
        "case_master_full_v1" \
        "Full Verizon case master archive" \
        >> "${INDEX}"
      echo "[+] Registered case_master_full_v1 (${CASE_TS})"
    else
      echo "[!] Missing sha for case master ${CASE_BUNDLE}, skipping" >&2
    fi
  fi
else
  echo "[*] No verizon_case_master_full_*.tar.gz found; skipping case_master_full_v1"
fi

########################################
# 3) Regulatory verification text
#    regulatory_verification_*.txt
########################################
REG_TXT=$(find_one "${ROOT}/regulatory_verification_"*".txt" || true)
if [[ -n "${REG_TXT}" ]]; then
  REG_BASE=$(basename "${REG_TXT}")
  REG_TS=$(ts_from_name "${REG_BASE}")
  if [[ -z "${REG_TS}" ]]; then
    echo "[!] Could not extract timestamp from ${REG_BASE}, skipping regulatory_log_v1" >&2
  else
    REG_SHA="${ROOT}/regulatory_verification_${REG_TS}.txt.sha256"

    if [[ -f "${REG_SHA}" ]]; then
      REG_SHA_VAL=$(awk '{print $1}' "${REG_SHA}")
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "${REG_TS}" \
        "${REG_TXT}" \
        "" \
        "${REG_SHA}" \
        "${REG_SHA_VAL}" \
        "regulatory_log_v1" \
        "Regulatory evidence bundle text (MO AG / FCC context)" \
        >> "${INDEX}"
      echo "[+] Registered regulatory_log_v1 (${REG_TS})"
    else
      echo "[!] Missing sha for regulatory_verification text, skipping" >&2
    fi
  fi
else
  echo "[*] No regulatory_verification_*.txt found; skipping regulatory_log_v1"
fi

########################################
# 4) Telereg evidence text (evidence_telereg_*.txt)
########################################
TEL_TXT=$(find_one "${ROOT}/evidence_telereg_"*".txt" || true)
if [[ -n "${TEL_TXT}" ]]; then
  TEL_BASE=$(basename "${TEL_TXT}")
  TEL_TS=$(ts_from_name "${TEL_BASE}")
  if [[ -z "${TEL_TS}" ]]; then
    echo "[!] Could not extract timestamp from ${TEL_BASE}, skipping telereg_log_v1" >&2
  else
    TEL_SHA="${ROOT}/evidence_telereg_${TEL_TS}.txt.sha256"

    if [[ ! -f "${TEL_SHA}" ]]; then
      echo "[*] Telereg sha256 not found; creating ${TEL_SHA}"
      TEL_HASH=$(sha256sum "${TEL_TXT}" | awk '{print $1}')
      printf '%s  %s\n' "${TEL_HASH}" "${TEL_TXT}" > "${TEL_SHA}"
    fi

    TEL_SHA_VAL=$(awk '{print $1}' "${TEL_SHA}")
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "${TEL_TS}" \
      "${TEL_TXT}" \
      "" \
      "${TEL_SHA}" \
      "${TEL_SHA_VAL}" \
      "telereg_log_v1" \
      "Telereg evidence text (IMS / provisioning complaint context)" \
      >> "${INDEX}"
    echo "[+] Registered telereg_log_v1 (${TEL_TS})"
  fi
else
  echo "[*] No evidence_telereg_*.txt found; skipping telereg_log_v1"
fi

echo "[*] Rebuild complete. Current index:"
column -t -s $'\t' "${INDEX}" || cat "${INDEX}"
