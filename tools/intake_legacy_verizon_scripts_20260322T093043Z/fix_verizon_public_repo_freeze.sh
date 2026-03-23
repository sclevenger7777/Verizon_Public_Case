#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="${1:-$HOME/repos/Verizon_Public_Case}"

if [ ! -d "$REPO/.git" ]; then
  echo "[ERROR] Not a git repo: $REPO" >&2
  exit 1
fi

cd "$REPO"

echo "[i] Repo: $REPO"
echo "[i] Branch: $(git branch --show-current)"
echo "[i] HEAD:   $(git rev-parse --short HEAD)"

HOOK_PATTERN='^(raw_candidates/|raw_candidates/.*|core/|core/.*|artifacts/|artifacts/.*|.*\.(pcap|pcapng|qmdl|bin|mbn|gz|tgz|tar|zip|7z|img|iso))$'

mkdir -p .git/hooks

cat > .git/hooks/pre-commit <<EOF
#!/usr/bin/env bash
set -euo pipefail
if git diff --cached --name-only --diff-filter=ACMR | grep -E '$HOOK_PATTERN' >/dev/null; then
  echo "[BLOCKED] Raw-file additions to public repo are frozen."
  echo "[BLOCKED] Matched staged paths:"
  git diff --cached --name-only --diff-filter=ACMR | grep -E '$HOOK_PATTERN' || true
  exit 1
fi
EOF

cat > .git/hooks/pre-push <<EOF
#!/usr/bin/env bash
set -euo pipefail
if git diff --cached --name-only --diff-filter=ACMR | grep -E '$HOOK_PATTERN' >/dev/null; then
  echo "[BLOCKED] Raw-file additions to public repo are frozen."
  echo "[BLOCKED] Matched staged paths:"
  git diff --cached --name-only --diff-filter=ACMR | grep -E '$HOOK_PATTERN' || true
  exit 1
fi
EOF

chmod 755 .git/hooks/pre-commit .git/hooks/pre-push

echo "[i] Hook modes:"
ls -l .git/hooks/pre-commit .git/hooks/pre-push

BAD_COMMIT_SHORT="3c769f2"
HEAD_SHORT="$(git rev-parse --short HEAD)"

if [ "$HEAD_SHORT" = "$BAD_COMMIT_SHORT" ]; then
  echo "[i] Removing bad test commit at HEAD: $BAD_COMMIT_SHORT"
  git reset --hard HEAD~1
else
  echo "[i] HEAD is not the bad test commit; leaving history unchanged."
  echo "[i] If needed, inspect with: git log --oneline --decorate -n 5"
fi

mkdir -p artifacts
printf 'freeze-test\n' > artifacts/freeze_test.txt

set +e
git add artifacts/freeze_test.txt
COMMIT_OUTPUT="$(git commit -m "test freeze hook" 2>&1)"
COMMIT_RC=$?
set -e

echo "$COMMIT_OUTPUT"

if [ $COMMIT_RC -eq 0 ]; then
  echo "[ERROR] Hook still failed; test commit was allowed." >&2
  exit 2
fi

echo "[i] Hook block verified."

git reset HEAD artifacts/freeze_test.txt >/dev/null 2>&1 || true
rm -f artifacts/freeze_test.txt
rmdir artifacts >/dev/null 2>&1 || true

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[i] Cleaning residual working-tree changes"
  git restore --staged . >/dev/null 2>&1 || true
  git restore . >/dev/null 2>&1 || true
fi

git push origin "$(git branch --show-current)"

echo
echo "[done] Freeze hooks repaired and verified."
echo "[done] Repo clean state:"
git status --short
