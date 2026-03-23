#!/usr/bin/env bash
set -euo pipefail

FORENSICS_ROOT="/storage/emulated/0/Forensics"
INDEX="${FORENSICS_ROOT}/verizon_evidence_index.tsv"

mkdir -p "${FORENSICS_ROOT}"

if [[ ! -f "${INDEX}" ]]; then
  printf 'timestamp_utc\tevidence_id\ttype\trel_path\tsha256\tdescription\n' > "${INDEX}"
fi

if [[ "$#" -ne 5 ]]; then
  echo "Usage: $(basename "$0") EVIDENCE_ID TYPE REL_PATH SHA256 DESCRIPTION" >&2
  echo "Example:" >&2
  echo "  $(basename "$0") GLOBAL_DISCOVERY_20260228T021508Z TSV verizon_global_discovery_20260228T021508Z.tsv \\" >&2
  echo "    9bae5ab625b121bf47f96659dc641acd401ae93e14a531bd9638096dd5a0f3fb \\" >&2
  echo "    \"Verizon global artifact discovery TSV snapshot\"" >&2
  exit 1
fi

EVIDENCE_ID="$1"
TYPE="$2"
REL_PATH="$3"
SHA256="$4"
DESC="$5"

TS="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

# Sanitize description: no tabs/newlines
DESC_CLEAN="${DESC//$'\n'/ }"
DESC_CLEAN="${DESC_CLEAN//$'\t'/ }"

# De-duplicate on evidence_id (field 2) but keep header
tmp="${INDEX}.tmp.$$"
awk -v id="$EVIDENCE_ID" -F'\t' 'NR==1 || $2 != id' "${INDEX}" > "${tmp}"
mv "${tmp}" "${INDEX}"

printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$TS" "$EVIDENCE_ID" "$TYPE" "$REL_PATH" "$SHA256" "$DESC_CLEAN" >> "${INDEX}"

echo "[*] Registered evidence entry:"
tail -n 3 "${INDEX}"
