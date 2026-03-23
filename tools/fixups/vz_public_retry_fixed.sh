#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="/storage/emulated/0/Verizon_Public_Case"
DAY="2026-03-21"
DEST_ANALYSIS="$REPO/analysis/daily_ingest/$DAY"
DEST_DOCS="$REPO/docs/daily_ingest/$DAY"
DEST_EVID="$REPO/evidence/network_state/redacted/$DAY"
DEST_MANI="$REPO/manifests/daily_ingest/$DAY"

cd "$REPO"

LATEST_REPORT="$(find "$DEST_MANI" -maxdepth 1 -type f -name 'residual_sensitive_hits_*.txt' | sort | tail -n1)"
if [[ -z "${LATEST_REPORT:-}" || ! -f "$LATEST_REPORT" ]]; then
  echo "[FATAL] No residual report found in $DEST_MANI" >&2
  exit 1
fi

echo "[INFO] Using prior residual report:"
echo "  $LATEST_REPORT"

python3 - <<'PY' "$LATEST_REPORT"
import re, sys, pathlib

report = pathlib.Path(sys.argv[1])
files = set()

for line in report.read_text(encoding="utf-8", errors="replace").splitlines():
    if not line.strip():
        continue
    # first colon-delimited field is the path
    path = line.split(":", 1)[0]
    if path.startswith("/storage/emulated/0/Verizon_Public_Case/"):
        files.add(path)

rules = [
    (re.compile(r'(?i)\b[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}\b'), '[REDACTED_EMAIL]'),
    (re.compile(r'(?<!\d)(?:\d{1,3}\.){3}\d{1,3}(?!\d)'), '[REDACTED_IPV4]'),
    (re.compile(r'(?i)\b(?:[0-9a-f]{0,4}:){2,7}[0-9a-f]{0,4}\b'), '[REDACTED_IPV6]'),
    (re.compile(r'(?i)\b(?:[0-9a-f]{2}:){5}[0-9a-f]{2}\b'), '[REDACTED_MAC]'),
    (re.compile(r'(?<!\d)\d{19,20}(?!\d)'), '[REDACTED_ICCID]'),
    (re.compile(r'(?<!\d)\d{15}(?!\d)'), '[REDACTED_15DIGIT_ID]'),
    (re.compile(r'(?i)\b(imei|imsi|iccid|meid|eid|subscriberid|subscriber_id|line1number|msisdn)\s*[:=]\s*\S+'), r'\1=[REDACTED]'),
]

for p in sorted(files):
    path = pathlib.Path(p)
    if not path.is_file():
        continue
    if path.name.startswith("residual_sensitive_hits_"):
        continue
    text = path.read_text(encoding="utf-8", errors="replace")
    orig = text
    for rx, repl in rules:
        text = rx.sub(repl, text)
    if text != orig:
        path.write_text(text, encoding="utf-8")
        print(f"[REDACTED] {p}")
    else:
        print(f"[NO_CHANGE] {p}")
PY

NEW_REPORT="$DEST_MANI/residual_sensitive_hits_retry_$(date +%Y%m%d_%H%M%S).txt"
SUMMARY="$DEST_MANI/residual_sensitive_summary_retry_$(date +%Y%m%d_%H%M%S).txt"
: > "$NEW_REPORT"
: > "$SUMMARY"

python3 - <<'PY' "$DEST_ANALYSIS" "$DEST_DOCS" "$DEST_EVID" "$DEST_MANI" "$NEW_REPORT" "$SUMMARY"
import os, re, sys, pathlib, collections

scan_dirs = [pathlib.Path(p) for p in sys.argv[1:5]]
report = pathlib.Path(sys.argv[5])
summary = pathlib.Path(sys.argv[6])

patterns = [
    ("email", re.compile(r'(?i)\b[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}\b')),
    ("iccid", re.compile(r'(?<!\d)\d{19,20}(?!\d)')),
    ("id15", re.compile(r'(?<!\d)\d{15}(?!\d)')),
    ("ipv4", re.compile(r'(?<!\d)(?:\d{1,3}\.){3}\d{1,3}(?!\d)')),
    ("ipv6", re.compile(r'(?i)\b(?:[0-9a-f]{0,4}:){2,7}[0-9a-f]{0,4}\b')),
    ("mac", re.compile(r'(?i)\b(?:[0-9a-f]{2}:){5}[0-9a-f]{2}\b')),
    ("subscriber_key", re.compile(r'(?i)\b(imei|imsi|iccid|meid|eid|subscriberid|subscriber_id|line1number|msisdn)\s*[:=]')),
]

placeholder_rx = re.compile(r'\[REDACTED_[A-Z0-9_]+\]')

hits_by_file = collections.Counter()
hits_by_type = collections.Counter()
total_hits = 0

for d in scan_dirs:
    if not d.exists():
        continue
    for f in sorted(d.rglob("*")):
        if not f.is_file():
            continue
        if f.name.startswith("residual_sensitive_hits_"):
            continue
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue

        for lineno, line in enumerate(text.splitlines(), start=1):
            # remove placeholders before scanning so they cannot self-trigger
            scrubbed = placeholder_rx.sub("", line)

            for name, rx in patterns:
                if rx.search(scrubbed):
                    report.write_text(report.read_text(encoding="utf-8", errors="replace") + f"{f}:{lineno}:{name}:{line}\n", encoding="utf-8")
                    hits_by_file[str(f)] += 1
                    hits_by_type[name] += 1
                    total_hits += 1

with summary.open("w", encoding="utf-8") as out:
    out.write("== residual hits by file ==\n")
    for path, count in hits_by_file.most_common():
        out.write(f"{count}\t{path}\n")
    out.write("\n== residual hits by type ==\n")
    for name, count in hits_by_type.most_common():
        out.write(f"{count}\t{name}\n")
    out.write(f"\n== total residual hits ==\n{total_hits}\n")

print(total_hits)
PY

TOTAL_HITS="$(tail -n1 "$SUMMARY" | tr -d '[:space:]')"

echo "[INFO] New residual report: $NEW_REPORT"
echo "[INFO] New summary: $SUMMARY"

if [[ "$TOTAL_HITS" != "0" ]]; then
  echo "[BLOCKED] Residual hits still present."
  echo "[BLOCKED] Top of summary:"
  sed -n '1,80p' "$SUMMARY"
  exit 2
fi

git add \
  "analysis/daily_ingest/$DAY" \
  "docs/daily_ingest/$DAY" \
  "evidence/network_state/redacted/$DAY" \
  "manifests/daily_ingest/$DAY"

if git diff --cached --quiet; then
  echo "[INFO] No staged changes."
  exit 0
fi

git commit -m "Add public-safe redacted evidence and MD ingest for $DAY"
git push origin main

echo "[OK] Commit: $(git rev-parse --short HEAD)"
echo "[OK] Push complete."
