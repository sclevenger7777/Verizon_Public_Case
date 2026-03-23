#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
TL_PROFILE="$PREFIX/etc/profile.d/texlive.sh"

echo "[INFO] Loading TeX Live env from: $TL_PROFILE"
if [ -f "$TL_PROFILE" ]; then
  . "$TL_PROFILE"
else
  echo "[ERROR] TeX Live profile not found at: $TL_PROFILE" >&2
  exit 1
fi

echo "[INFO] Checking for xelatex..."
if ! command -v xelatex >/dev/null 2>&1; then
  echo "[ERROR] xelatex still not on PATH after sourcing TeX Live profile." >&2
  echo "[HINT] Check contents of: $TL_PROFILE" >&2
  exit 1
fi

echo "[OK] xelatex found: $(command -v xelatex)"

CASE_DIR="$HOME/storage/downloads/verizon_case_master_20260219T162625Z/00_case_docs"
echo "[INFO] Changing to case dir: $CASE_DIR"
cd "$CASE_DIR"

# Ensure build script is executable
chmod +x build_IMS_AKA_Table_X_pdf.sh || true

echo "[INFO] Running build_IMS_AKA_Table_X_pdf.sh..."
./build_IMS_AKA_Table_X_pdf.sh

echo "[DONE] If no errors above, IMS_AKA_Table_X.pdf should be in:"
echo "       $CASE_DIR/IMS_AKA_Table_X.pdf"
