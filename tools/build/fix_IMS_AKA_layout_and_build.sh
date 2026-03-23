#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

WD="$HOME/storage/downloads/verizon_case_master_20260219T162625Z/00_case_docs"
SRC="$WD/IMS_AKA_Table_X.md"
OUT="$WD/IMS_AKA_Table_X.pdf"

cd "$WD"

# Rewrite the build script with better layout settings
cat > build_IMS_AKA_Table_X_pdf.sh <<'EOS'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

WD="$HOME/storage/downloads/verizon_case_master_20260219T162625Z/00_case_docs"
SRC="$WD/IMS_AKA_Table_X.md"
OUT="$WD/IMS_AKA_Table_X.pdf"

echo "[INFO] Working dir  : $WD"
echo "[INFO] Source MD    : $SRC"
echo "[INFO] Target PDF   : $OUT"
echo "[INFO] TeX engine   : pdflatex"
echo "[INFO] Page layout  : letter, 12pt, 0.75in margins"

cd "$WD"

pandoc "$SRC" \
  -o "$OUT" \
  --from markdown \
  --pdf-engine=pdflatex \
  -V papersize=letter \
  -V fontsize=12pt \
  -V geometry:margin=0.75in

echo "[OK] Rebuilt: $OUT"
EOS

chmod +x build_IMS_AKA_Table_X_pdf.sh

# Storage is noexec, so always run via bash
bash ./build_IMS_AKA_Table_X_pdf.sh
