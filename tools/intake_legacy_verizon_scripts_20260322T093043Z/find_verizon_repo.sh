#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

export PATH="/data/data/com.termux/files/usr/bin:$PATH"

echo "[i] Ensuring shared storage is available..."
if [ ! -e "$HOME/storage/shared" ] || [ ! -e "$HOME/storage/downloads" ]; then
  echo "[i] Running termux-setup-storage if needed..."
  termux-setup-storage || true
  sleep 2
fi

SEARCH_ROOTS=(
  "$HOME"
  "$HOME/github"
  "$HOME/repos"
  "$HOME/Downloads"
  "$HOME/storage/shared"
  "$HOME/storage/downloads"
  "/storage/emulated/0"
  "/storage/emulated/0/Download"
)

TMP_GIT="$(mktemp)"
TMP_NAME="$(mktemp)"
trap 'rm -f "$TMP_GIT" "$TMP_NAME"' EXIT

echo "[i] Searching for real Git repositories..."
for root in "${SEARCH_ROOTS[@]}"; do
  [ -d "$root" ] || continue
  find "$root" -type d -name .git 2>/dev/null >> "$TMP_GIT" || true
done
sort -u "$TMP_GIT" -o "$TMP_GIT"

MATCHED=0

if [ -s "$TMP_GIT" ]; then
  echo
  echo "[i] Git repository inventory:"
  while IFS= read -r gitdir; do
    repo="${gitdir%/.git}"
    remote="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
    branch="$(git -C "$repo" branch --show-current 2>/dev/null || true)"

    printf '\n[repo] %s\n' "$repo"
    printf '       remote: %s\n' "${remote:-<none>}"
    printf '       branch: %s\n' "${branch:-<unknown>}"

    case "$remote" in
      *sclevenger7777/Verizon_Public_Case*|*Verizon_Public_Case.git*)
        MATCHED=1
        echo "       MATCH: YES"
        echo
        echo "[SUCCESS] Local clone found:"
        echo "$repo"
        ;;
      *)
        case "$repo" in
          *Verizon_Public_Case*|*verizon*case*)
            echo "       NAME-HIT: yes"
            ;;
          *)
            echo "       MATCH: no"
            ;;
        esac
        ;;
    esac
  done < "$TMP_GIT"
else
  echo "[!] No .git directories found in searched roots."
fi

echo
echo "[i] Searching for repo-like names, including Downloads parent directory..."
find \
  "$HOME" \
  "$HOME/Downloads" \
  "$HOME/storage/shared" \
  "$HOME/storage/downloads" \
  "/storage/emulated/0" \
  "/storage/emulated/0/Download" \
  -maxdepth 5 \
  \( -type d -o -type f \) \
  \( -iname '*Verizon_Public_Case*' -o -iname '*verizon*case*' -o -iname '*public*case*' \) \
  2>/dev/null | sort -u > "$TMP_NAME" || true

if [ -s "$TMP_NAME" ]; then
  echo "[i] Name hits:"
  sed 's/^/    /' "$TMP_NAME"
else
  echo "[i] No repo-like names found."
fi

echo
if [ "$MATCHED" -eq 0 ]; then
  echo "[RESULT] No confirmed local clone found for sclevenger7777/Verizon_Public_Case."
  echo "[RESULT] If one of the name hits above is the intended folder but lacks .git, it is not an active clone."
  exit 2
fi
