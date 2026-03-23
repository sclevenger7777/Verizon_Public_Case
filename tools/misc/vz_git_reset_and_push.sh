#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="/storage/emulated/0/Verizon_Public_Case"
GH_USER="sclevenger7777"
REMOTE_HTTPS="https://github.com/${GH_USER}/Verizon_Public_Case.git"

echo "[INFO] Repo: $REPO"
cd "$REPO"

echo "[INFO] Removing oversized case tarball from working tree (if present)..."
rm -f manifests/verizon_case_master_full_20260220T140814Z.tar.gz
rm -f manifests/verizon_case_master_full_20260220T140814Z.tar.gz.sha256

echo "[INFO] Removing existing .git to drop large blob from history..."
rm -rf .git

echo "[INFO] Reinitializing git repo..."
git init
git branch -M main

echo "[INFO] Marking Android shared-storage path as safe..."
git config --global --add safe.directory "$REPO"

echo "[INFO] Setting global identity (can be changed later)..."
git config --global user.name  "GEMINIBANDIT"
git config --global user.email "geminibandit@example.invalid"

echo "[INFO] Wiring remote origin -> $REMOTE_HTTPS"
git remote add origin "$REMOTE_HTTPS"

echo "[INFO] Staging curated public contents..."
git add core manifests SHA256SUMS_public_tree.txt

echo "[INFO] Commiting curated initial snapshot..."
git commit -m "Initial public case export (curated Verizon provisioning evidence + integrity manifests)"

echo "[INFO] Git status before push:"
git status

echo "[INFO] Pushing to GitHub (will prompt for credentials / token)..."
git push -u origin main

echo "[DONE] Push complete. Verify contents on GitHub: ${REMOTE_HTTPS}"
