#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="/storage/emulated/0/Verizon_Public_Case"
OUT_BASE="/storage/emulated/0/Download"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

WORK="$OUT_BASE/verizon_repo_bundle_$STAMP"
ZIP="$OUT_BASE/verizon_repo_bundle_$STAMP.zip"

mkdir -p "$WORK"

cd "$REPO"

echo "[i] Generating tree snapshot"

if command -v tree >/dev/null 2>&1; then
    tree -a -L 4 > "$WORK/tree_a_L4.txt"
else
    find . -maxdepth 4 -print | sort > "$WORK/tree_a_L4.txt"
fi

echo "[i] Copying README"
cp "$REPO/README.md" "$WORK/README.md"

echo "[i] Collecting latest manifests"

LATEST_TREE="$(ls manifests/verizon_public_tree_*.tsv | sort | tail -n 1)"
LATEST_SHA="$(ls manifests/verizon_public_sha256_*.txt | sort | tail -n 1)"

cp "$LATEST_TREE" "$WORK/"
cp "$LATEST_TREE.sha256" "$WORK/"
cp "$LATEST_SHA" "$WORK/"
cp "$LATEST_SHA.sha256" "$WORK/"

echo "[i] Generating top-level file listing"

find "$REPO" \
  -path "$REPO/.git" -prune -o \
  -type f \
  -print \
| sed "s#$REPO/##" \
| sort > "$WORK/repo_file_listing.txt"

echo "[i] Collecting verification logs if present"

mkdir -p "$WORK/verification_logs"

find "$REPO/manifests" \
  -type f \
  \( -name "*.log" -o -name "*verify*" \) \
  -print 2>/dev/null | while read -r f; do
    cp "$f" "$WORK/verification_logs/" || true
done

echo "[i] Creating zip bundle"

cd "$OUT_BASE"
zip -r "$(basename "$ZIP")" "$(basename "$WORK")" >/dev/null

echo
echo "[done] Bundle created:"
echo "  $ZIP"
echo
echo "[contents]"
ls -lh "$ZIP"
