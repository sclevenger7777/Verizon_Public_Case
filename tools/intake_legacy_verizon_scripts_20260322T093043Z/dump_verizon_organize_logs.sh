#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BASE_DIR="/storage/emulated/0"
PATTERN="organize*.log"

cd "$BASE_DIR"

# Get the 3 most recently modified organize*.log files
mapfile -t FILES < <(ls -1t $PATTERN 2>/dev/null | head -n 3)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "No files matching $BASE_DIR/$PATTERN found." >&2
  exit 1
fi

echo "Dumping ${#FILES[@]} file(s) from $BASE_DIR:"
printf '  %s\n' "${FILES[@]}"
echo

for f in "${FILES[@]}"; do
  path="$BASE_DIR/$f"
  if [ ! -f "$path" ]; then
    echo "## SKIP (not found): $path" >&2
    continue
  fi

  echo "===== BEGIN_FILE:$path ====="
  cat "$path"
  echo
  echo "===== END_FILE:$path ====="
  echo
done
