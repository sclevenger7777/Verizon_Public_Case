#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SRC="/storage/emulated/0/Verizon_Public_Case"
DST_PARENT="$HOME/repos"
DST="$DST_PARENT/Verizon_Public_Case"

mkdir -p "$DST_PARENT"

if [ ! -d "$SRC/.git" ]; then
  echo "[ERROR] Source repo not found: $SRC"
  exit 1
fi

if [ -e "$DST" ]; then
  echo "[ERROR] Destination already exists: $DST"
  exit 1
fi

echo "[i] Copying repo from shared storage to Termux home..."
cp -a "$SRC" "$DST"

echo "[i] Reinstalling executable hooks on real filesystem..."
cat > "$DST/.git/hooks/pre-commit" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if git diff --cached --name-only | grep -E '^(raw_candidates/|core/|artifacts/|.*\.(pcap|pcapng|qmdl|bin|mbn|gz|tgz|tar|zip|7z|img|iso))$' >/dev/null; then
  echo "[BLOCKED] Raw-file additions to public repo are frozen."
  exit 1
fi
EOF

cat > "$DST/.git/hooks/pre-push" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if git diff --cached --name-only | grep -E '^(raw_candidates/|core/|artifacts/|.*\.(pcap|pcapng|qmdl|bin|mbn|gz|tgz|tar|zip|7z|img|iso))$' >/dev/null; then
  echo "[BLOCKED] Raw-file additions to public repo are frozen."
  exit 1
fi
EOF

chmod 755 "$DST/.git/hooks/pre-commit" "$DST/.git/hooks/pre-push"

echo "[i] Hook modes:"
ls -l "$DST/.git/hooks/pre-commit" "$DST/.git/hooks/pre-push"

echo "[i] Verifying repo identity:"
git -C "$DST" remote -v
git -C "$DST" branch --show-current

echo
echo "[done] Repo migrated to:"
echo "  $DST"
echo
echo "[next shell]"
echo "  cd \"$DST\""
