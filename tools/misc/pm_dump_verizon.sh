p#!/data/data/com.termux/files/usr/bin/bash
# Dump all packages whose name looks Verizon-related using:
#   rish -c 'pm dump PACKAGE'
# and save each dump to a separate file.

set -euo pipefail

OUT_DIR="$HOME/pm_verizon_dumpsl"
mkdir -p "$OUT_DIR"

TS="$(date -u +%Y%m%dT%H%M%SZ)"

# Prefer rish (Shizuku), fallback to adb shell if present
if command -v rish >/dev/null 2>&1; then
    SHELL_CMD='rish -c'
elif command -v adb >/dev/null 2>&1; then
    SHELL_CMD='adb shell'
else
    echo "ERROR: Need either 'rish' (Shizuku) or 'adb' in PATH." >&2
    exit 1
fi

echo "[*] Using shell: $SHELL_CMD"
echo "[*] Output directory: $OUT_DIR"
echo "[*] Timestamp: $TS"
echo

# Build list of packages that look Verizon-related
PKG_LIST_FILE="$OUT_DIR/verizon_packages_$TS.txt"

echo "[*] Discovering Verizon-related packages..."
$SHELL_CMD "pm list packages" \
  | sed 's/^package://g' \
  | grep -Ei 'verizon|vzw' \
  | sort -u > "$PKG_LIST_FILE" || true

if ! [ -s "$PKG_LIST_FILE" ]; then
    echo "[!] No packages matched /verizon|vzw/."
    echo "    Checked output file: $PKG_LIST_FILE"
    exit 0
fi

echo "[*] Found these packages (saved to $PKG_LIST_FILE):"
cat "$PKG_LIST_FILE"
echo

dump_one_package() {
    local pkg="$1"
    # Make filename filesystem-safe
    local safe_pkg="${pkg//./_}"
    local out_file="$OUT_DIR/pm_dump_${safe_pkg}_$TS.txt"

    echo "  - dumping $pkg -> $out_file"
    $SHELL_CMD "pm dump $pkg" > "$out_file" 2>&1 || {
        echo "    [!] pm dump failed for $pkg (see file for details)"
    }
}

echo "[*] Starting pm dump for each Verizon-related package..."
while read -r pkg; do
    [ -n "$pkg" ] || continue
    dump_one_package "$pkg"
done < "$PKG_LIST_FILE"

echo
echo "[+] Done."
echo "    Package list : $PKG_LIST_FILE"
echo "    Dumps in     : $OUT_DIR/"
