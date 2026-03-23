#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="/storage/emulated/0/USE_THIS_DIRECTORY"
cd "$ROOT"

mkdir -p manifests

find . -type f | sort > manifests/repository_tree.tsv
find . -type f -exec sha256sum "{}" \; | sort > manifests/sha256_manifest.txt

{
  echo "# EVIDENCE_INDEX"
  echo
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo
  echo "## Top-level directories"
  find . -maxdepth 1 -mindepth 1 -type d | sort
  echo
  echo "## File counts"
  echo "- analysis: $(find analysis -type f 2>/dev/null | wc -l)"
  echo "- evidence: $(find evidence -type f 2>/dev/null | wc -l)"
  echo "- exports: $(find exports -type f 2>/dev/null | wc -l)"
  echo "- legal: $(find legal -type f 2>/dev/null | wc -l)"
  echo "- manifests: $(find manifests -type f 2>/dev/null | wc -l)"
  echo "- misc_review: $(find misc_review -type f 2>/dev/null | wc -l)"
  echo "- scripts: $(find scripts -type f 2>/dev/null | wc -l)"
  echo "- verizon_data: $(find verizon_data -type f 2>/dev/null | wc -l)"
} > manifests/EVIDENCE_INDEX.md

echo "Built:"
echo "  manifests/repository_tree.tsv"
echo "  manifests/sha256_manifest.txt"
echo "  manifests/EVIDENCE_INDEX.md"
