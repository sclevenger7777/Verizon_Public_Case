#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SRC="/storage/emulated/0/Verizon_Public_Case/manifests"
DEST_PARENT="/storage/emulated/0/USE_THIS_DIRECTORY"
DEST="${DEST_PARENT}/manifests"

echo "SRC=$SRC"
echo "DEST_PARENT=$DEST_PARENT"
echo "DEST=$DEST"
echo

if [ ! -d "$SRC" ]; then
  echo "[ERROR] Source directory not found: $SRC"
  exit 1
fi

mkdir -p "$DEST_PARENT"

if [ -e "$DEST" ]; then
  echo "[ERROR] Destination already exists: $DEST"
  exit 1
fi

mv -- "$SRC" "$DEST"

echo
echo "[OK] moved"
echo "from: $SRC"
echo "to:   $DEST"
