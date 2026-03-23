#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="/storage/emulated/0/Verizon_Public_Case"
HOOKS_DIR="$REPO/.git/hooks"
GITIGNORE="$REPO/.gitignore"
POLICY_DIR="$REPO/docs/repo_policy"
POLICY_FILE="$POLICY_DIR/public_repo_freeze_policy.md"

if [ ! -d "$REPO/.git" ]; then
  echo "[ERROR] Repo not found or not a git repo: $REPO" >&2
  exit 1
fi

mkdir -p "$HOOKS_DIR" "$POLICY_DIR"

touch "$GITIGNORE"

append_once() {
  local file="$1"
  local marker="$2"
  local content="$3"
  if ! grep -Fq "$marker" "$file"; then
    {
      echo
      echo "$marker"
      printf '%s\n' "$content"
    } >> "$file"
  fi
}

append_once "$GITIGNORE" "# === Verizon public repo raw-freeze policy ===" \
"raw_candidates/
core/net_evidence_core/
core/pcap_summaries/
*.pcap
*.pcapng
*.cap
*.qmdl
*.sdm
*.dmp
*.diag
*.bin
*.mbn
*.qcn
*.gz
*.tgz
*.tar
*.tar.gz
*.tar.xz
*.zip
*.7z
*.apks
*.apkm
*.xapk"

cat > "$POLICY_FILE" <<'EOF'
# Public Repo Freeze Policy

This public repository is frozen against further raw-file additions.

## Effective rule

Do not add:
- raw capture bundles
- raw network dumps
- raw mirrored evidence trees
- packet captures
- modem/diag binaries
- compressed forensic archives
- app package bundles

## Allowed content

The public repo may accept only:
- analytical markdown
- redacted derivatives prepared for public release
- manifests generated from the cleaned public tree
- README / methodology / scope documents
- small helper scripts directly related to public-safe repo maintenance

## Intent

This repository is for public-safe, scope-correct, integrity-checked publication artifacts only.
Raw evidence remains outside the public repo.
EOF

cat > "$HOOKS_DIR/pre-commit" <<'EOF'
#!/bin/sh
set -eu

blocked='
^raw_candidates/
^core/net_evidence_core/
^core/pcap_summaries/
\.pcap$
\.pcapng$
\.cap$
\.qmdl$
\.sdm$
\.dmp$
\.diag$
\.bin$
\.mbn$
\.qcn$
\.gz$
\.tgz$
\.tar$
\.tar\.gz$
\.tar\.xz$
\.zip$
\.7z$
\.apks$
\.apkm$
\.xapk$
'

staged="$(git diff --cached --name-only --diff-filter=AR || true)"

if [ -z "$staged" ]; then
  exit 0
fi

bad="$(printf '%s\n' "$staged" | grep -E "$blocked" || true)"

if [ -n "$bad" ]; then
  echo "[BLOCKED] Raw-file freeze policy prevented this commit."
  echo
  echo "Disallowed staged paths:"
  printf '%s\n' "$bad"
  echo
  echo "Allowed: analysis docs, redacted derivatives, manifests, README/methodology, small maintenance scripts."
  exit 1
fi

exit 0
EOF

cat > "$HOOKS_DIR/pre-push" <<'EOF'
#!/bin/sh
set -eu

blocked='
^raw_candidates/
^core/net_evidence_core/
^core/pcap_summaries/
\.pcap$
\.pcapng$
\.cap$
\.qmdl$
\.sdm$
\.dmp$
\.diag$
\.bin$
\.mbn$
\.qcn$
\.gz$
\.tgz$
\.tar$
\.tar\.gz$
\.tar\.xz$
\.zip$
\.7z$
\.apks$
\.apkm$
\.xapk$
'

staged="$(git diff --cached --name-only --diff-filter=AR || true)"
bad="$(printf '%s\n' "$staged" | grep -E "$blocked" || true)"

if [ -n "$bad" ]; then
  echo "[BLOCKED] Raw-file freeze policy prevented push."
  echo
  echo "Disallowed staged paths:"
  printf '%s\n' "$bad"
  exit 1
fi

exit 0
EOF

chmod +x "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/pre-push"

cd "$REPO"

git add .gitignore docs/repo_policy/public_repo_freeze_policy.md

if git diff --cached --quiet; then
  echo "[i] Freeze policy already present. No staged changes detected."
  exit 0
fi

git commit -m "Freeze public repo against further raw-file additions"
git push origin "$(git branch --show-current)"

echo
echo "[done] Public repo raw-file freeze is active."
echo "Repo: $REPO"
echo "Policy: $POLICY_FILE"
echo "Hooks:"
echo "  $HOOKS_DIR/pre-commit"
echo "  $HOOKS_DIR/pre-push"
