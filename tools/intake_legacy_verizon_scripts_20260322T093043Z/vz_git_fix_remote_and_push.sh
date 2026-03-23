#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="/storage/emulated/0/Verizon_Public_Case"
GH_USER="sclevenger7777"
REMOTE_HTTPS="https://github.com/${GH_USER}/Verizon_Public_Case.git"

cd "$REPO"

# Mark this path safe for git on Android shared storage
git config --global --add safe.directory "$REPO"

# Global identity for commits (adjust later if you want)
git config --global user.name  "GEMINIBANDIT"
git config --global user.email "geminibandit@example.invalid"

# Ensure repo + branch + remote are correct
git init
git branch -M main
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_HTTPS"

# Stage curated public contents
git add core manifests SHA256SUMS_public_tree.txt

# Commit and push
git commit -m "Initial public case export for Verizon provisioning drift (CC-2025-12-004745)"
git push -u origin main
