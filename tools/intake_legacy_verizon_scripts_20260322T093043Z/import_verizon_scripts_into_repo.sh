#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SRC="$HOME"
REPO="/storage/emulated/0/Verizon_Public_Case"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
DEST="$REPO/tools/intake_legacy_verizon_scripts_$STAMP"
LOGDIR="$REPO/_import_logs"
INV="$LOGDIR/import_inventory_$STAMP.tsv"
MAN="$LOGDIR/import_manifest_$STAMP.sha256"
SUM="$LOGDIR/import_summary_$STAMP.txt"

mkdir -p "$DEST" "$LOGDIR"

echo "[START] $(date)"
echo "[SRC] $SRC"
echo "[REPO] $REPO"
echo "[DEST] $DEST"

printf "src_path\tdest_path\tsize_bytes\tsha256\n" > "$INV"

find "$SRC" -maxdepth 1 -type f \
  \( \
    -name 'verizon_*' -o \
    -name 'vz_*' -o \
    -name 'vzw_*' -o \
    -name '*verizon*.sh' -o \
    -name '*Verizon*.sh' -o \
    -name '*telecom*.sh' -o \
    -name '*ims*.sh' -o \
    -name '*IMS*.sh' -o \
    -name '*telereg*.sh' -o \
    -name '*net*evidence*.sh' -o \
    -name '*radio*.sh' -o \
    -name '*carrier*.sh' -o \
    -name '*apn*.sh' \
  \) \
  ! -name 'run_verizon_centralize.sh' \
  ! -name 'run_verizon_script_inventory.sh' \
  ! -name 'run_verizon_full_census.sh' \
  -print0 |
while IFS= read -r -d '' f; do
  base="$(basename "$f")"
  dest="$DEST/$base"

  if [ -e "$dest" ]; then
    n=1
    while [ -e "$DEST/${base}.dup$n" ]; do
      n=$((n+1))
    done
    dest="$DEST/${base}.dup$n"
  fi

  cp -p "$f" "$dest"
  size="$(wc -c < "$dest" 2>/dev/null || echo 0)"
  sha="$(sha256sum "$dest" | awk '{print $1}')"
  printf "%s\t%s\t%s\t%s\n" "$f" "$dest" "$size" "$sha" >> "$INV"
done

find "$DEST" -type f -print0 | sort -z | xargs -0 sha256sum > "$MAN"

{
  echo "VERIZON SCRIPT IMPORT SUMMARY"
  echo "generated=$(date)"
  echo "src=$SRC"
  echo "repo=$REPO"
  echo "dest=$DEST"
  echo "imported_count=$(($(wc -l < "$INV") - 1))"
  echo "inventory=$INV"
  echo "manifest=$MAN"
} > "$SUM"

echo "[DONE] $(date)"
echo "[OUTPUT] $DEST"
echo "[OUTPUT] $INV"
echo "[OUTPUT] $MAN"
echo "[OUTPUT] $SUM"
