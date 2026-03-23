#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

DOC_MD="IMS_AKA_Table_X.md"
DOC_PDF="IMS_AKA_Table_X.pdf"

echo "[INFO] Working dir : $(pwd)"
echo "[INFO] Source MD   : $DOC_MD"
echo "[INFO] Target PDF  : $DOC_PDF"
echo

if [ ! -f "$DOC_MD" ]; then
  echo "[ERROR] Markdown not found: $DOC_MD" >&2
  exit 1
fi

if ! command -v pandoc >/dev/null 2>&1; then
  echo "[ERROR] pandoc is not installed." >&2
  echo "[HINT]  Install: pkg install pandoc" >&2
  exit 1
fi

if ! command -v xelatex >/dev/null 2>&1; then
  echo "[ERROR] xelatex is not installed (TeX Live not configured)." >&2
  echo
  echo "[NEXT STEPS] From Termux, run the following (large install, GBs of data):"
  echo "  pkg update"
  echo "  pkg install texlive-installer texlive-bin"
  echo "  termux-install-tl"
  echo
  echo "After TeX Live finishes installing and xelatex is on PATH, rerun:"
  echo "  ./build_IMS_AKA_Table_X_pdf.sh"
  exit 1
fi

echo "[OK] xelatex found at: $(command -v xelatex)"
echo "[INFO] Running pandoc + xelatex ..."
pandoc "$DOC_MD" \
  -o "$DOC_PDF" \
  --from markdown \
  --toc \
  --pdf-engine=xelatex

echo
echo "[DONE] Generated PDF: $DOC_PDF"
