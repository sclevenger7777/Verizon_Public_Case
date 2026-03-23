#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="/storage/emulated/0/Verizon_Public_Case"
MANIFEST_DIR="$REPO/manifests"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

cd "$REPO"

mkdir -p "$MANIFEST_DIR"

TREE_MANIFEST="$MANIFEST_DIR/verizon_public_tree_${STAMP}.tsv"
SHA_MANIFEST="$MANIFEST_DIR/verizon_public_sha256_${STAMP}.txt"

find . \
  -path './.git' -prune -o \
  -type f \
  -print \
| LC_ALL=C sort \
| sed 's#^\./##' \
| awk '{print $0}' \
> "$MANIFEST_DIR/.files_${STAMP}.tmp"

: > "$TREE_MANIFEST"
: > "$SHA_MANIFEST"

while IFS= read -r rel; do
  abs="$REPO/$rel"
  size="$(wc -c < "$abs" | tr -d ' ')"
  sha="$(sha256sum "$abs" | awk '{print $1}')"
  printf '%s\t%s\t%s\n' "$rel" "$size" "$sha" >> "$TREE_MANIFEST"
  printf '%s  %s\n' "$sha" "$rel" >> "$SHA_MANIFEST"
done < "$MANIFEST_DIR/.files_${STAMP}.tmp"

rm -f "$MANIFEST_DIR/.files_${STAMP}.tmp"

sha256sum "$TREE_MANIFEST" > "${TREE_MANIFEST}.sha256"
sha256sum "$SHA_MANIFEST" > "${SHA_MANIFEST}.sha256"

git add \
  "$TREE_MANIFEST" \
  "${TREE_MANIFEST}.sha256" \
  "$SHA_MANIFEST" \
  "${SHA_MANIFEST}.sha256"

if git diff --cached --quiet; then
  echo "[i] No staged changes detected."
  exit 0
fi

git commit -m "Add Verizon-only tree and SHA256 manifests for cleaned public repo"
git push origin "$(git branch --show-current)"

echo
echo "[done] Wrote:"
echo "  $TREE_MANIFEST"
echo "  ${TREE_MANIFEST}.sha256"
echo "  $SHA_MANIFEST"
echo "  ${SHA_MANIFEST}.sha256"
