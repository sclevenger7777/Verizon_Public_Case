#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT_SRC="/storage/emulated/0/Forensics"
ROOT_REPO="/storage/emulated/0/Verizon_Public_Case"

printf '[i] Source root: %s\n' "$ROOT_SRC"
printf '[i] Repo root:   %s\n' "$ROOT_REPO"
printf '\n[i] Inventory\n'

find "$ROOT_SRC" "$ROOT_REPO/raw_candidates/net_evidence_raw" \
  -type f \
  \( -name 'dumpsys_connectivity_rish.txt' -o -name 'rish_ip.txt' \) \
  2>/dev/null | sort | while IFS= read -r f; do
    sz="$(wc -c < "$f" | tr -d ' ')"
    sha="$(sha256sum "$f" | awk '{print $1}')"
    printf '%s | %s bytes | %s\n' "$f" "$sz" "$sha"
  done

printf '\n[i] Pairwise compare: source vs repo mirror\n'

find "$ROOT_SRC" -type f \( -name 'dumpsys_connectivity_rish.txt' -o -name 'rish_ip.txt' \) 2>/dev/null | sort | while IFS= read -r src; do
  rel="${src#"$ROOT_SRC"/}"
  repo="$ROOT_REPO/raw_candidates/net_evidence_raw/$rel"
  if [ -f "$repo" ]; then
    if cmp -s "$src" "$repo"; then
      printf '[MATCH] %s\n' "$rel"
    else
      printf '[DIFF ] %s\n' "$rel"
    fi
  else
    printf '[MISS ] %s\n' "$rel"
  fi
done

printf '\n[i] First 40 lines from the newest source bundle\n'
latest_dir="$(find "$ROOT_SRC" -maxdepth 1 -type d -name 'net_evidence_*' | sort | tail -n 1)"
printf '[i] Latest source bundle: %s\n' "$latest_dir"

for f in "$latest_dir/dumpsys_connectivity_rish.txt" "$latest_dir/rish_ip.txt"; do
  if [ -f "$f" ]; then
    printf '\n===== %s =====\n' "$f"
    sed -n '1,40p' "$f"
  fi
done
