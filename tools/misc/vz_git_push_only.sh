#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="/storage/emulated/0/Verizon_Public_Case"
GH_USER="sclevenger7777"
REMOTE_HTTPS="https://github.com/${GH_USER}/Verizon_Public_Case.git"

cd "$REPO"

# Make sure Android shared storage repo is trusted
git config --global --add safe.directory "$REPO"

# Make sure identity is set (harmless if already configured)
git config --global user.name  "GEMINIBANDIT"
git config --global user.email "geminibandit@example.invalid"

# Ensure branch + remote are correct, but DO NOT re-commit
git branch -M main
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_HTTPS"

echo "[INFO] Remote:"
git remote -v

echo "[INFO] About to push existing commits on 'main' to GitHub..."
git status

# Push the already-existing commit(s)
git push -u origin main
