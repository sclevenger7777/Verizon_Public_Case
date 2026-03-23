#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="/storage/emulated/0/Verizon_Public_Case"
TARGET_DIR="$REPO/evidence/network_state/redacted/net_evidence_20260115T065405Z"

DUMP="$TARGET_DIR/dumpsys_connectivity_rish.redacted.txt"
IPTXT="$TARGET_DIR/rish_ip.redacted.txt"
README="$TARGET_DIR/README.md"

for f in "$DUMP" "$IPTXT" "$README"; do
  [ -f "$f" ] || { echo "[!] Missing expected file: $f" >&2; exit 1; }
done

python3 - <<'PY'
from pathlib import Path
import re

repo = Path("/storage/emulated/0/Verizon_Public_Case")
target_dir = repo / "evidence/network_state/redacted/net_evidence_20260115T065405Z"
files = [
    target_dir / "dumpsys_connectivity_rish.redacted.txt",
    target_dir / "rish_ip.redacted.txt",
]

# Add any new Wi-Fi identity strings here if discovered later.
wifi_labels = [
    "USA Keys",
    "USA keys",
]

def patch_text(text: str) -> str:
    # Generic SSID-ish quoted values that may survive inside Wifi transport text.
    text = re.sub(r'SSID:\s*"[^"]+"', 'SSID: "[REDACTED_WIFI_SSID]"', text)
    text = re.sub(r'Provider friendly name:\s*<[^>]*>', 'Provider friendly name: [REDACTED_WIFI_LABEL]', text)

    # Explicit additional labels found post-redaction.
    for label in wifi_labels:
        text = text.replace(label, "[REDACTED_WIFI_LABEL]")

    # Catch common Wi-Fi branding fragments that may still appear.
    text = re.sub(r'(?i)\b(?:wifi|wi-fi)\s+network\s+name:\s*[^,\n]+', 'Wi-Fi network name: [REDACTED_WIFI_LABEL]', text)

    return text

for p in files:
    original = p.read_text(encoding="utf-8", errors="replace")
    patched = patch_text(original)
    p.write_text(patched, encoding="utf-8")

readme = target_dir / "README.md"
note = readme.read_text(encoding="utf-8", errors="replace")
extra = "\nAdditional redaction update:\n- Removed residual human-readable Wi-Fi network labels from the public-safe derivative set.\n"
if "residual human-readable Wi-Fi network labels" not in note:
    readme.write_text(note.rstrip() + "\n" + extra, encoding="utf-8")
PY

cd "$REPO"
git add "$DUMP" "$IPTXT" "$README"

if git diff --cached --quiet; then
  echo "[i] No staged changes detected."
  exit 0
fi

git commit -m "Redact residual Wi-Fi network labels from public network evidence"
git push origin "$(git branch --show-current)"

echo "[done] Patched residual Wi-Fi label exposure in:"
echo "  $TARGET_DIR"
