#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PREFIX="/data/data/com.termux/files/usr"
TL_PROFILE="$PREFIX/etc/profile.d/texlive.sh"

echo "[INFO] Sourcing TeX Live profile: $TL_PROFILE"
if [ -f "$TL_PROFILE" ]; then
  . "$TL_PROFILE"
else
  echo "[ERROR] TeX Live profile not found at: $TL_PROFILE" >&2
  exit 1
fi

echo "[DEBUG] xelatex:  $(command -v xelatex  || echo 'NOT FOUND')"
echo "[DEBUG] pdflatex: $(command -v pdflatex || echo 'NOT FOUND')"

CASE_DIR="$HOME/storage/downloads/verizon_case_master_20260219T162625Z/00_case_docs"
echo "[INFO] Changing to: $CASE_DIR"
cd "$CASE_DIR"

echo "[INFO] Rewriting build_IMS_AKA_Table_X_pdf.sh to use pdflatex..."

cat > build_IMS_AKA_Table_X_pdf.sh << 'EOS'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SRC_MD="IMS_AKA_Table_X.md"
OUT_PDF="IMS_AKA_Table_X.pdf"

echo "[INFO] Source MD  : $SRC_MD"
echo "[INFO] Target PDF : $OUT_PDF"
echo "[INFO] TeX engine : pdflatex"

if [ ! -f "$SRC_MD" ]; then
  echo "[ERROR] Markdown source not found: $SRC_MD" >&2
  exit 1
fi

if ! command -v pdflatex >/dev/null 2>&1; then
  echo "[ERROR] pdflatex not found on PATH (TeX Live not fully initialized)." >&2
  exit 1
fi

pandoc "$SRC_MD" \
  -o "$OUT_PDF" \
  --from markdown \
  --toc \
  --pdf-engine=pdflatex

echo "[OK] PDF built at: $OUT_PDF"
EOS

chmod +x build_IMS_AKA_Table_X_pdf.sh

echo "[INFO] Running build_IMS_AKA_Table_X_pdf.sh via bash (storage is noexec)..."
bash build_IMS_AKA_Table_X_pdf.sh
