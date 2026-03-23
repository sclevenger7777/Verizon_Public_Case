#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="/storage/emulated/0/Verizon_Public_Case"
SRC_BASE="/storage/emulated/0/Forensics/net_evidence_20260115T065405Z"

SRC_DUMP="$SRC_BASE/dumpsys_connectivity_rish.txt"
SRC_IP="$SRC_BASE/rish_ip.txt"

OUT_DIR="$REPO/evidence/network_state/redacted/net_evidence_20260115T065405Z"
OUT_DUMP="$OUT_DIR/dumpsys_connectivity_rish.redacted.txt"
OUT_IP="$OUT_DIR/rish_ip.redacted.txt"
OUT_NOTE="$OUT_DIR/README.md"

if [ ! -d "$REPO/.git" ]; then
  echo "[!] Repo not found or not a git repo: $REPO" >&2
  exit 1
fi

for f in "$SRC_DUMP" "$SRC_IP"; do
  if [ ! -f "$f" ]; then
    echo "[!] Missing source file: $f" >&2
    exit 1
  fi
done

mkdir -p "$OUT_DIR"

python3 - <<'PY'
from pathlib import Path
import re

repo = Path("/storage/emulated/0/Verizon_Public_Case")
src_dump = Path("/storage/emulated/0/Forensics/net_evidence_20260115T065405Z/dumpsys_connectivity_rish.txt")
src_ip = Path("/storage/emulated/0/Forensics/net_evidence_20260115T065405Z/rish_ip.txt")
out_dir = repo / "evidence/network_state/redacted/net_evidence_20260115T065405Z"
out_dump = out_dir / "dumpsys_connectivity_rish.redacted.txt"
out_ip = out_dir / "rish_ip.redacted.txt"
out_note = out_dir / "README.md"

def redact_text(text: str) -> str:
    replacements = [
        (r'"STARLINK"', '"[REDACTED_SSID]"'),
        (r'\bSTARLINK\b', '[REDACTED_SSID]'),
        (r'\bd6:d9:91:3c:b4:a1\b', '[REDACTED_BSSID]'),
        (r'\b72:62:1f:bd:0a:48\b', '[REDACTED_WIFI_MAC]'),
        (r'\b192\.168\.1\.179\b', '[REDACTED_LAN_IPV4]'),
        (r'\b192\.168\.1\.1\b', '[REDACTED_LAN_GATEWAY]'),
        (r'\b2605:59c8:49b4:e110:[0-9a-f:]+\b', '[REDACTED_HOME_GUA_IPV6]'),
        (r'\b2605:59c8:49b4:e110::/64\b', '[REDACTED_HOME_GUA_PREFIX]'),
        (r'\bfdd9:91bc:b4a1:10:[0-9a-f:]+\b', '[REDACTED_HOME_ULA_IPV6]'),
        (r'\bfdd9:91bc:b4a1:10::/64\b', '[REDACTED_HOME_ULA_PREFIX]'),
        (r'\bfdd9:91bc:b4a1::/48\b', '[REDACTED_HOME_ULA_SUPERPREFIX]'),
    ]
    for pat, repl in replacements:
        text = re.sub(pat, repl, text, flags=re.IGNORECASE)
    return text

def filter_networkrequest_inventory(text: str) -> str:
    lines = text.splitlines()
    kept = []
    in_requests = False

    allow_terms = (
        'ims', 'epdg', 'telephony', 'cellular', 'wifi', 'android',
        'com.sec.imsservice', 'com.sec.epdg', 'com.android.systemui'
    )

    for line in lines:
        s = line.strip()

        if s.startswith("Requests: REQUEST:"):
            in_requests = True
            kept.append(line)
            continue

        if in_requests:
            if line.startswith("    Inactivity Timers:") or line.startswith("  NetworkAgentInfo{"):
                in_requests = False
                kept.append(line)
                continue

            if "NetworkRequest [" in line:
                low = line.lower()
                if any(term in low for term in allow_terms):
                    kept.append(line)
                else:
                    kept.append("      [REDACTED_NON_VERIZON_APP_NETWORKREQUEST]")
                continue

        kept.append(line)

    return "\n".join(kept) + ("\n" if text.endswith("\n") else "")

dump_text = src_dump.read_text(encoding="utf-8", errors="replace")
ip_text = src_ip.read_text(encoding="utf-8", errors="replace")

dump_text = redact_text(dump_text)
ip_text = redact_text(ip_text)

dump_text = filter_networkrequest_inventory(dump_text)

out_dump.write_text(dump_text, encoding="utf-8")
out_ip.write_text(ip_text, encoding="utf-8")

note = """# Redacted network evidence

Source bundle:
- `/storage/emulated/0/Forensics/net_evidence_20260115T065405Z`

Public-repo handling:
- Raw mirrored copies were removed from the public repo.
- This directory contains redacted public-safe derivatives.
- Redactions remove home-network identifiers and unrelated app fingerprinting.
- Verizon-relevant cellular, IMS, and bearer/interface evidence was retained.

Redacted classes:
- SSID / BSSID / Wi-Fi MAC
- LAN IPv4 / gateway
- home IPv6 GUA / ULA prefixes
- unrelated app inventory from NetworkRequest blocks
"""
out_note.write_text(note, encoding="utf-8")
PY

cd "$REPO"

if [ -d "$REPO/raw_candidates/net_evidence_raw" ]; then
  rm -rf "$REPO/raw_candidates/net_evidence_raw"
fi

git add \
  "evidence/network_state/redacted/net_evidence_20260115T065405Z/dumpsys_connectivity_rish.redacted.txt" \
  "evidence/network_state/redacted/net_evidence_20260115T065405Z/rish_ip.redacted.txt" \
  "evidence/network_state/redacted/net_evidence_20260115T065405Z/README.md"

if git ls-files --error-unmatch "raw_candidates/net_evidence_raw" >/dev/null 2>&1; then
  git rm -r --cached --ignore-unmatch "raw_candidates/net_evidence_raw" || true
fi

git add -A

if git diff --cached --quiet; then
  echo "[i] No staged changes detected."
  exit 0
fi

git commit -m "Redact home-network identifiers and remove raw mirrored net evidence"
git push origin "$(git branch --show-current)"

echo
echo "[done] Redacted public copies written to:"
echo "  $OUT_DIR"
