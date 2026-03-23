#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-/data/data/com.termux/files/home/repos/Verizon_Public_Case}"

cd "$REPO"

HOOK_DIR=".git/hooks"

mkdir -p "$HOOK_DIR"

cat > "$HOOK_DIR/pre-commit" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Allowed paths (public-safe only)
ALLOW_REGEX='^(analysis/|docs/|evidence/network_state/redacted/|manifests/|README\.md$|\.gitignore$)'

# Collect staged paths (add/modify/rename/copy)
CHANGED=$(git diff --cached --name-only --diff-filter=ACMR || true)

# If nothing staged, allow
[ -z "$CHANGED" ] && exit 0

VIOLATIONS=$(echo "$CHANGED" | grep -Ev "$ALLOW_REGEX" || true)

if [ -n "$VIOLATIONS" ]; then
  echo "[BLOCKED] Non-allowlisted paths detected:"
  echo "$VIOLATIONS"
  echo
  echo "[POLICY] Only these paths are allowed:"
  echo "  analysis/"
  echo "  docs/"
  echo "  evidence/network_state/redacted/"
  echo "  manifests/"
  echo "  README.md"
  echo "  .gitignore"
  exit 1
fi

# Also block raw/binary types anywhere (defense-in-depth)
if echo "$CHANGED" | grep -E '\.(pcap|pcapng|qmdl|bin|mbn|gz|tgz|tar|zip|7z|img|iso)$' >/dev/null; then
  echo "[BLOCKED] Raw/binary artifact detected in staged changes"
  exit 1
fi
EOF

cat > "$HOOK_DIR/pre-push" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Re-check full commit range being pushed (stronger than pre-commit)
ALLOW_REGEX='^(analysis/|docs/|evidence/network_state/redacted/|manifests/|README\.md$|\.gitignore$)'

RANGE="$(git rev-parse --abbrev-ref HEAD)@{u}..HEAD 2>/dev/null || echo HEAD"

FILES=$(git diff --name-only "$RANGE" || true)

[ -z "$FILES" ] && exit 0

VIOLATIONS=$(echo "$FILES" | grep -Ev "$ALLOW_REGEX" || true)

if [ -n "$VIOLATIONS" ]; then
  echo "[BLOCKED] Push contains non-allowlisted paths:"
  echo "$VIOLATIONS"
  exit 1
fi

if echo "$FILES" | grep -E '\.(pcap|pcapng|qmdl|bin|mbn|gz|tgz|tar|zip|7z|img|iso)$' >/dev/null; then
  echo "[BLOCKED] Push contains raw/binary artifacts"
  exit 1
fi
EOF

chmod 755 "$HOOK_DIR/pre-commit" "$HOOK_DIR/pre-push"

echo "[done] Allowlist policy applied."
echo "[repo] $REPO"
echo "[allowed paths]"
echo "  analysis/"
echo "  docs/"
echo "  evidence/network_state/redacted/"
echo "  manifests/"
echo "  README.md"
echo "  .gitignore"
