#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BASE="/data/data/com.termux/files/home/storage/shared"

echo "=== Forensics (core evidence) ==="
du -sh "$BASE/Forensics" || true
find "$BASE/Forensics" -maxdepth 2 -type f | sort

echo
echo "=== Forensics/snapshots (baselines) ==="
du -sh "$BASE/Forensics/snapshots" || true
find "$BASE/Forensics/snapshots" -maxdepth 1 -type f | sort

echo
echo "=== Tools (collection tooling) ==="
du -sh "$BASE/Tools" || true
find "$BASE/Tools" -maxdepth 2 -type f | sort

echo
echo "=== Archives/backups (environment backups) ==="
du -sh "$BASE/Archives/backups" || true
find "$BASE/Archives/backups" -maxdepth 2 -mindepth 1 | sort

echo
echo "=== Personal (documents, Verizon texts, etc.) ==="
du -sh "$BASE/Personal" || true
find "$BASE/Personal" -maxdepth 3 -type f | sort
