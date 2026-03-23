#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "[START] $(date)"

# Ensure directory exists
TARGET="/storage/emulated/0/Verizon_Public_Case"
mkdir -p "$TARGET"

# Snapshot current structure
echo "[SNAPSHOT]"
find "$TARGET" -maxdepth 2 -type f | sort > "$TARGET/file_index.txt"

# Generate hash manifest
echo "[HASHING]"
sha256sum $(find "$TARGET" -type f 2>/dev/null) > "$TARGET/manifest.sha256" || true

echo "[DONE] $(date)"
