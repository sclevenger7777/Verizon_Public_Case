#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="/storage/emulated/0/Verizon_Public_Case"
TODAY_LOCAL="2026-03-21"
STAMP="$(date +%Y%m%d_%H%M%S)"

# Candidate roots for today's collected material.
CANDIDATE_ROOTS=(
  "/storage/emulated/0/USE_THIS_DIRECTORY"
  "/data/data/com.termux/files/home/vz_reextract_20260321_132627"
)

# Public repo allowlist destinations.
DEST_ANALYSIS="$REPO/analysis/daily_ingest/$TODAY_LOCAL"
DEST_DOCS="$REPO/docs/daily_ingest/$TODAY_LOCAL"
DEST_EVID="$REPO/evidence/network_state/redacted/$TODAY_LOCAL"
DEST_MANI="$REPO/manifests/daily_ingest/$TODAY_LOCAL"

mkdir -p "$DEST_ANALYSIS" "$DEST_DOCS" "$DEST_EVID" "$DEST_MANI"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

MANIFEST="$DEST_MANI/ingest_manifest_${STAMP}.tsv"
REDACTION_REPORT="$DEST_MANI/redaction_report_${STAMP}.txt"
RESIDUAL_REPORT="$DEST_MANI/residual_sensitive_hits_${STAMP}.txt"
COPY_LOG="$DEST_MANI/copy_log_${STAMP}.txt"

: > "$MANIFEST"
: > "$REDACTION_REPORT"
: > "$RESIDUAL_REPORT"
: > "$COPY_LOG"

printf "src_path\tdest_path\tsha256_before\tsha256_after\tbytes_after\n" >> "$MANIFEST"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[FATAL] Missing required command: $1" >&2
    exit 1
  }
}

need_cmd git
need_cmd find
need_cmd python3
need_cmd sha256sum
need_cmd file
need_cmd grep
need_cmd sed

if [[ ! -d "$REPO/.git" ]]; then
  echo "[FATAL] Repo root is not a Git working tree: $REPO" >&2
  exit 1
fi

cd "$REPO"

echo "[INFO] Repo baseline"
git rev-parse --show-toplevel
git branch --show-current
git rev-parse --short HEAD
git status --short

python3 - <<'PY' "$WORKDIR/redact.py"
import re, sys, pathlib

out = pathlib.Path(sys.argv[1])
out.write_text(r'''#!/usr/bin/env python3
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8", errors="replace")
orig = text

rules = [
    # Email
    (re.compile(r'(?i)\b[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}\b'), '[REDACTED_EMAIL]'),

    # URLs with embedded tokens/queries are risky; keep host/path only if present.
    (re.compile(r'(?i)\b(https?://[^\s?#]+)\?[^ \n\r\t]*'), r'\1?[REDACTED_QUERY]'),

    # Phone / MSISDN-like sequences
    (re.compile(r'(?<!\d)(?:\+?1[-.\s]?)?(?:\(?\d{3}\)?[-.\s]?){2}\d{4}(?!\d)'), '[REDACTED_PHONE]'),

    # ICCID / IMSI / IMEI / long identifiers
    (re.compile(r'(?<!\d)\d{19,20}(?!\d)'), '[REDACTED_ICCID]'),
    (re.compile(r'(?<!\d)\d{15}(?!\d)'), '[REDACTED_15DIGIT_ID]'),
    (re.compile(r'(?i)\bIMEI\s*[:=]\s*\S+'), 'IMEI=[REDACTED]'),
    (re.compile(r'(?i)\bIMSI\s*[:=]\s*\S+'), 'IMSI=[REDACTED]'),
    (re.compile(r'(?i)\bICCID\s*[:=]\s*\S+'), 'ICCID=[REDACTED]'),
    (re.compile(r'(?i)\bEID\s*[:=]\s*\S+'), 'EID=[REDACTED]'),
    (re.compile(r'(?i)\bMEID\s*[:=]\s*\S+'), 'MEID=[REDACTED]'),

    # IP addresses
    (re.compile(r'(?<![:.\w])(?:\d{1,3}\.){3}\d{1,3}(?![:.\w])'), '[REDACTED_IPV4]'),
    (re.compile(r'(?i)\b(?:[0-9a-f]{0,4}:){2,7}[0-9a-f]{0,4}\b'), '[REDACTED_IPV6]'),

    # MAC / BSSID
    (re.compile(r'(?i)\b(?:[0-9a-f]{2}:){5}[0-9a-f]{2}\b'), '[REDACTED_MAC]'),
    (re.compile(r'(?i)\b(?:[0-9a-f]{2}-){5}[0-9a-f]{2}\b'), '[REDACTED_MAC]'),

    # GPS-ish coordinates
    (re.compile(r'(?<!\d)([-+]?([1-8]?\d(\.\d+)?|90(\.0+)?)),\s*([-+]?((1[0-7]\d)|([1-9]?\d))(\.\d+)?|180(\.0+)?)(?!\d)'), '[REDACTED_COORDS]'),

    # Wi-Fi / SSID / subscriber-ish explicit keys
    (re.compile(r'(?im)^(\s*(?:ssid|wifi_ssid|bssid|subscriberid|subscriber_id|line1number|msisdn|nai|username|impu|impi|realm|deviceid|device_id)\s*[:=]\s*).*$'), r'\1[REDACTED]'),

    # Android/Unix absolute paths may leak usernames or folder names
    (re.compile(r'(?<!\w)(?:/storage/emulated/0|/data/data|/sdcard)/[^\s"\'<>]+'), '[REDACTED_PATH]'),
]

for rx, repl in rules:
    text = rx.sub(repl, text)

# Normalize repeated redaction markers
text = re.sub(r'(\[REDACTED_[A-Z0-9_]+\])(?:\s+\1)+', r'\1', text)

if text != orig:
    path.write_text(text, encoding="utf-8")
''', encoding='utf-8')
PY

chmod 755 "$WORKDIR/redact.py"

is_textual() {
  local f="$1"
  local m
  m="$(file -b --mime-type "$f" 2>/dev/null || true)"
  [[ "$m" == text/* || "$m" == application/json || "$m" == application/xml || "$m" == application/x-sh || "$m" == application/javascript ]]
}

route_dest_dir() {
  local src="$1"
  local base lower
  base="$(basename "$src")"
  lower="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
  case "$lower" in
    *.md|readme* ) printf '%s\n' "$DEST_DOCS" ;;
    *.tsv|*.csv|*.json|*.txt|*.log|*.xml|*.yml|*.yaml )
      if printf '%s' "$lower" | grep -Eq '(manifest|sha256|hash|tree|listing)'; then
        printf '%s\n' "$DEST_MANI"
      elif printf '%s' "$lower" | grep -Eq '(summary|analysis|report|corroboration|README|readme)'; then
        printf '%s\n' "$DEST_ANALYSIS"
      else
        printf '%s\n' "$DEST_EVID"
      fi
      ;;
    * ) printf '%s\n' "$DEST_EVID" ;;
  esac
}

copy_and_redact() {
  local src="$1"
  local dest_dir dest base sha_before sha_after bytes_after
  base="$(basename "$src")"
  dest_dir="$(route_dest_dir "$src")"
  dest="$dest_dir/$base"

  # avoid collisions
  if [[ -e "$dest" ]]; then
    dest="${dest_dir}/${base%.*}__${STAMP}.${base##*.}"
    [[ "$base" != *.* ]] && dest="${dest_dir}/${base}__${STAMP}"
  fi

  cp -f "$src" "$dest"

  if is_textual "$dest"; then
    sha_before="$(sha256sum "$dest" | awk '{print $1}')"
    python3 "$WORKDIR/redact.py" "$dest"
    sha_after="$(sha256sum "$dest" | awk '{print $1}')"
  else
    # do not publish non-text artifacts through this path
    rm -f "$dest"
    echo "[SKIP_BINARY] $src" >> "$COPY_LOG"
    return 0
  fi

  bytes_after="$(wc -c < "$dest" | tr -d ' ')"

  printf "%s\t%s\t%s\t%s\t%s\n" \
    "$src" "$dest" "$sha_before" "$sha_after" "$bytes_after" >> "$MANIFEST"

  if [[ "$sha_before" != "$sha_after" ]]; then
    printf "[REDACTED] %s -> %s\n" "$src" "$dest" >> "$REDACTION_REPORT"
  else
    printf "[COPIED_NO_CHANGE] %s -> %s\n" "$src" "$dest" >> "$REDACTION_REPORT"
  fi
}

echo "[INFO] Collecting candidates modified on $TODAY_LOCAL"

for root in "${CANDIDATE_ROOTS[@]}"; do
  [[ -d "$root" ]] || continue
  while IFS= read -r -d '' f; do
    copy_and_redact "$f"
  done < <(
    find "$root" -type f \
      ! -path '*/.git/*' \
      ! -path '*/raw_candidates/*' \
      ! -path '*/node_modules/*' \
      ! -path '*/.venv/*' \
      ! -path '*/venv/*' \
      \( -iname '*.md' -o -iname '*.txt' -o -iname '*.tsv' -o -iname '*.csv' -o -iname '*.json' -o -iname '*.log' -o -iname '*.xml' -o -iname '*.yml' -o -iname '*.yaml' \) \
      -newermt "${TODAY_LOCAL} 00:00:00" ! -newermt "2026-03-22 00:00:00" \
      -print0
  )
done

echo "[INFO] Residual sensitive-pattern scan"
RG_PATTERNS=(
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
  '(^|[^0-9])([0-9]{19,20})([^0-9]|$)'
  '(^|[^0-9])([0-9]{15})([^0-9]|$)'
  '([0-9]{1,3}\.){3}[0-9]{1,3}'
  '([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}'
  '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}'
  '(?i)(imei|imsi|iccid|meid|eid|subscriberid|line1number|msisdn)\s*[:=]'
)

SCAN_DIRS=("$DEST_ANALYSIS" "$DEST_DOCS" "$DEST_EVID" "$DEST_MANI")
RESIDUAL_HITS=0

for d in "${SCAN_DIRS[@]}"; do
  [[ -d "$d" ]] || continue
  while IFS= read -r file; do
    for pat in "${RG_PATTERNS[@]}"; do
      if grep -RInaE -- "$pat" "$file" >> "$RESIDUAL_REPORT" 2>/dev/null; then
        RESIDUAL_HITS=1
      fi
    done
  done < <(find "$d" -type f | sort)
done

echo "[INFO] Writing session summary"
SESSION_SUMMARY="$DEST_ANALYSIS/PUBLIC_INGEST_SUMMARY_${STAMP}.md"
cat > "$SESSION_SUMMARY" <<EOF
# Public Ingest Summary — $TODAY_LOCAL

## Repo
- Root: \`$REPO\`
- Branch: \`$(git branch --show-current)\`
- Base HEAD before ingest: \`$(git rev-parse --short HEAD)\`

## Source roots scanned
$(for r in "${CANDIDATE_ROOTS[@]}"; do [[ -d "$r" ]] && printf -- "- \`%s\`\n" "$r"; done)

## Outputs
- Analysis: \`$DEST_ANALYSIS\`
- Docs: \`$DEST_DOCS\`
- Evidence: \`$DEST_EVID\`
- Manifests: \`$DEST_MANI\`

## Artifacts
- Manifest TSV: \`$(basename "$MANIFEST")\`
- Redaction report: \`$(basename "$REDACTION_REPORT")\`
- Copy log: \`$(basename "$COPY_LOG")\`
- Residual scan report: \`$(basename "$RESIDUAL_REPORT")\`

## Guardrail
This ingest used regex-based conservative public redaction and a residual sensitive-pattern gate.
EOF

if [[ "$RESIDUAL_HITS" -ne 0 ]]; then
  echo "[BLOCKED] Residual sensitive patterns detected."
  echo "[BLOCKED] See: $RESIDUAL_REPORT"
  echo "[BLOCKED] Nothing will be committed or pushed."
  git status --short
  exit 2
fi

echo "[INFO] Staging public-safe outputs"
git add \
  "analysis/daily_ingest/$TODAY_LOCAL" \
  "docs/daily_ingest/$TODAY_LOCAL" \
  "evidence/network_state/redacted/$TODAY_LOCAL" \
  "manifests/daily_ingest/$TODAY_LOCAL"

if git diff --cached --quiet; then
  echo "[INFO] No staged changes after ingest/redaction. Exiting cleanly."
  exit 0
fi

echo "[INFO] Commit + push"
git commit -m "Add public-safe redacted evidence and MD ingest for $TODAY_LOCAL"
git push origin main

echo
echo "[OK] Completed."
echo "[OK] Commit: $(git rev-parse --short HEAD)"
echo "[OK] Remote: $(git remote get-url origin)"
echo "[OK] Review:"
echo "  $SESSION_SUMMARY"
echo "  $MANIFEST"
echo "  $REDACTION_REPORT"
echo "  $RESIDUAL_REPORT"
