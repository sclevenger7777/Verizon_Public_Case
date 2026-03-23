#!/usr/bin/env bash
set -euo pipefail

echo "[*] PG IMS artifact collector starting..."
echo "[*] NOTE: This script is intended for base Termux (Android userland), NOT inside any proot distro."

# ---------- environment sanity log ----------
ENV_INFO_FILE="${HOME}/pg_collect_ims_env_last.txt"
{
  echo "=== ENV SNAPSHOT ==="
  date -u +"UTC: %Y-%m-%dT%H:%M:%SZ"
  echo "PWD: $(pwd)"
  echo "WHOAMI: $(whoami 2>/dev/null || echo '?')"
  echo "UNAME: $(uname -a 2>/dev/null || echo '?')"
  echo "PREFIX: ${PREFIX:-unset}"
  if [ -f /etc/os-release ]; then
    echo "--- /etc/os-release ---"
    cat /etc/os-release
  fi
  if [ -f /etc/arch-release ]; then
    echo "--- /etc/arch-release ---"
    cat /etc/arch-release
  fi
  echo "====================="
} > "${ENV_INFO_FILE}" 2>/dev/null || true
echo "[*] Wrote env snapshot to ${ENV_INFO_FILE}"

# best-effort guard: warn if we appear to be in an Arch proot
if [ -f /etc/arch-release ]; then
  echo "[!] WARNING: /etc/arch-release present – this looks like an Arch environment (likely proot)."
  echo "[!] rish/Shizuku will NOT work correctly here. Prefer to run this script in base Termux."
fi

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# ---------- basic time / bundle paths ----------
NOW_UTC="$(date -u +%Y%m%dT%H%M%SZ)"
BUNDLE_DIR="/sdcard/Download/PG_ims_bundle_${NOW_UTC}"

mkdir -p "${BUNDLE_DIR}/files" "${BUNDLE_DIR}/system"

# ---------- helper: safe rish wrapper ----------
RISH_AVAILABLE=0
if have_cmd rish; then
  if rish -c 'id' >/dev/null 2>&1; then
    RISH_AVAILABLE=1
    echo "[*] rish is available and responding (Shizuku OK)."
  else
    echo "[!] rish found but not responding; Shizuku may not be running or not usable from this env."
  fi
else
  echo "[!] rish not found in PATH; system context will be limited."
fi

# ---------- collect basic device info ----------
ANDROID_SDK="unknown"
BUILD_FINGERPRINT="unknown"
CARRIER_PROP_SUMMARY=""

if [ "${RISH_AVAILABLE}" -eq 1 ]; then
  ANDROID_SDK="$(rish -c 'getprop ro.build.version.sdk' 2>/dev/null | tr -d '\r' || echo unknown)"
  BUILD_FINGERPRINT="$(rish -c 'getprop ro.build.fingerprint' 2>/dev/null | tr -d '\r' || echo unknown)"
  CARRIER_PROP_SUMMARY="$(rish -c 'getprop | grep -iE \"carrier|ims|rcs|ril|radio\" 2>/dev/null' || true)"
fi

HOSTNAME_LOCAL="$(hostname 2>/dev/null || echo unknown)"
NOW_LOCAL="$(date '+%Y-%m-%dT%H:%M:%S%z')"

# ---------- write bundle_meta.json ----------
cat > "${BUNDLE_DIR}/bundle_meta.json" << METAEOF
{
  "bundle_type": "ims_artifacts",
  "created_utc": "${NOW_UTC}",
  "created_local": "${NOW_LOCAL}",
  "host": {
    "hostname": "${HOSTNAME_LOCAL}"
  },
  "device": {
    "android_sdk": "${ANDROID_SDK}",
    "build_fingerprint": "${BUILD_FINGERPRINT}"
  },
  "notes": [
    "Automatically collected IMS-related artifacts and context.",
    "Non-destructive: source files are only read and copied.",
    "Intended for Privacy Guardian / Verizon provisioning case.",
    "Environment snapshot saved at: ${ENV_INFO_FILE}"
  ]
}
METAEOF

echo "[*] Wrote ${BUNDLE_DIR}/bundle_meta.json"

# ---------- search roots for IMS artifacts ----------
declare -a SEARCH_ROOTS=(
  "/sdcard/Download"
  "/sdcard/Downloads"
  "/sdcard/LOG"
  "/sdcard/Logs"
  "/sdcard/logs"
  "/storage/emulated/0/Download"
)

FILES_LIST="${BUNDLE_DIR}/files_list.txt"
: > "${FILES_LIST}"

echo "[*] Scanning for IMS-related files..."
for root in "${SEARCH_ROOTS[@]}"; do
  if [ -d "${root}" ]; then
    find "${root}" -maxdepth 3 -type f \
      \( -iname "ims_*" -o -iname "*ims_extract*" -o -iname "IMS_*" -o -iname "REPORT_reject_*" \) \
      2>/dev/null >> "${FILES_LIST}" || true
  fi
done

if [ -s "${FILES_LIST}" ]; then
  sort -u -o "${FILES_LIST}" "${FILES_LIST}"
else
  echo "[!] No IMS pattern files found under common paths."
fi

# ---------- copy + hash files ----------
FILES_JSONL="${BUNDLE_DIR}/files.jsonl"
: > "${FILES_JSONL}"

if [ -s "${FILES_LIST}" ]; then
  echo "[*] Copying and hashing files..."
  while IFS= read -r src; do
    [ -n "${src}" ] || continue
    if [ ! -f "${src}" ]; then
      continue
    fi
    base="$(basename -- "${src}")"
    dst="${BUNDLE_DIR}/files/${base}"

    if [ ! -f "${dst}" ]; then
      cp -p "${src}" "${dst}"
    fi

    sha256="$(sha256sum "${dst}" | awk '{print $1}')"
    size_bytes="$(stat -c '%s' "${dst}" 2>/dev/null || echo 0)"

    m_raw="$(stat -c '%y' "${dst}" 2>/dev/null || echo "")"
    if [ -n "${m_raw}" ]; then
      m_trim="$(printf '%s\n' "${m_raw}" | sed 's/\.[0-9]\+ .*//')"
      m_utc="$(date -u -d "${m_trim}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")"
    else
      m_utc=""
    fi

    esc_src="$(printf '%s' "${src}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    esc_dst_rel="$(printf '%s' "files/${base}" | sed 's/\\/\\\\/g; s/"/\\"/g')"

    printf '{ "src": "%s", "dst_rel": "%s", "sha256": "%s", "size_bytes": %s, "mtime_utc": "%s" }\n' \
      "${esc_src}" "${esc_dst_rel}" "${sha256}" "${size_bytes}" "${m_utc}" >> "${FILES_JSONL}"
  done < "${FILES_LIST}"
  echo "[*] File hashes written to ${FILES_JSONL}"
else
  echo "[!] No files to hash; ${FILES_LIST} is empty."
fi

# ---------- collect system / telephony context ----------
if [ "${RISH_AVAILABLE}" -eq 1 ]; then
  echo "[*] Collecting telephony / IMS context via rish..."

  rish -c 'pm list packages | grep -i ims || true' \
    > "${BUNDLE_DIR}/system/pm_list_ims.txt" 2>/dev/null || true

  rish -c 'dumpsys telephony.registry' \
    > "${BUNDLE_DIR}/system/dumpsys_telephony_registry.txt" 2>/dev/null || true

  rish -c 'dumpsys carrier_config' \
    > "${BUNDLE_DIR}/system/dumpsys_carrier_config.txt" 2>/dev/null || true

  rish -c 'logcat -d | grep -iE "ims|rcs|downloadmanager" | tail -n 1000' \
    > "${BUNDLE_DIR}/system/logcat_ims_downloadmanager_tail.txt" 2>/dev/null || true

  printf '%s\n' "${CARRIER_PROP_SUMMARY}" \
    > "${BUNDLE_DIR}/system/getprop_ims_subset.txt" 2>/dev/null || true
else
  echo "[!] Skipping rish-based context collection; rish unavailable or not usable from this environment."
fi

# ---------- README for human context ----------
cat > "${BUNDLE_DIR}/README_PG_IMS_BUNDLE.txt" << READMEEOF
PG IMS BUNDLE
=============

Bundle ID: PG_ims_bundle_${NOW_UTC}
Created UTC: ${NOW_UTC}
Created Local: ${NOW_LOCAL}

This directory is a non-destructive copy of IMS-related artifacts and
limited system context, intended for forensic analysis within Privacy Guardian.

Structure:
  bundle_meta.json      - high-level metadata about this bundle
  files_list.txt        - original absolute paths where files were found
  files.jsonl           - one JSON record per copied file (path, sha256, size, mtime_utc)
  files/                - copied artifacts (ims_*, IMS_*, REPORT_reject_*)
  system/               - telephony / IMS context from rish (pm, dumpsys, logcat, getprop)
  ${ENV_INFO_FILE}      - environment snapshot from the Termux shell that ran this script
READMEEOF

echo "[*] README_PG_IMS_BUNDLE.txt written."

echo
echo "[*] IMS artifact collection complete."
echo "[*] Bundle directory: ${BUNDLE_DIR}"
echo "[*] You can now mirror/ingest this into Privacy Guardian as a case bundle."
