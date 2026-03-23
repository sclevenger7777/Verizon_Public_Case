#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

FORENSICS_ROOT="/storage/emulated/0/Forensics"
INDEX="${FORENSICS_ROOT}/verizon_evidence_index.tsv"

FILES=(
"/storage/emulated/0/Personal/documents/Verizon support_123.txt"
"/storage/emulated/0/Personal/documents/Verizon short_123.txt"
)

echo "[*] Registering Personal Verizon document artifacts"

for FILE in "${FILES[@]}"; do
    if [[ ! -f "$FILE" ]]; then
        echo "[!] Missing: $FILE"
        continue
    fi

    BASENAME=$(basename "$FILE")
    SHA=$(sha256sum "$FILE" | awk '{print $1}')
    TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "[*] $BASENAME"
    echo "    SHA256: $SHA"

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$TS" \
        "$FILE" \
        "" \
        "" \
        "$SHA" \
        "personal_doc_v1" \
        "Verizon support written artifact (Personal/documents)" \
        >> "$INDEX"

done

echo
echo "[*] Done. Last 5 index entries:"
tail -n 5 "$INDEX"
