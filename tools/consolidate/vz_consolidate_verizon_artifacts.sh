#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

FORENSICS_ROOT="/storage/emulated/0/Forensics"
INDEX="${FORENSICS_ROOT}/verizon_evidence_index.tsv"
MAP="${FORENSICS_ROOT}/.vz_consolidate_paths.map"

echo "[*] Verizon artifact consolidation -> single Forensics root"
echo "[*] Forensics root: ${FORENSICS_ROOT}"
echo "[*] Evidence index: ${INDEX}"

if [[ ! -d "$FORENSICS_ROOT" ]]; then
  echo "[!] Forensics root not found: $FORENSICS_ROOT" >&2
  exit 1
fi

if [[ ! -f "$INDEX" ]]; then
  echo "[!] Evidence index not found: $INDEX" >&2
  exit 1
fi

# Build mapping from non-Forensics bundle_path -> Forensics/basename
# Treat INDEX as TAB-separated to avoid splitting paths with spaces.
# EXPLICITLY skip anything that looks like a Git repo or github-related path.
: > "$MAP"
awk -F '\t' -v ROOT="$FORENSICS_ROOT" '
NR == 1 { next }  # skip header line
{
  bundle = $2

  # Skip non-/storage paths entirely
  if (bundle !~ "^/storage/emulated/0/") {
    next
  }

  # Skip already-canonical Forensics bundle paths
  if (bundle ~ "^" ROOT "/") {
    next
  }

  # Defensive skip: anything that looks like git or github
  if (bundle ~ /\.git/ || bundle ~ /\/github\// || bundle ~ /gitrepo/ || bundle ~ /verizon_repo/) {
    next
  }

  # Map to Forensics root by basename (preserves filename + spaces)
  n = split(bundle, parts, "/")
  base = parts[n]
  newbundle = ROOT "/" base
  printf("%s\t%s\n", bundle, newbundle)
}
' "$INDEX" > "$MAP"

if [[ ! -s "$MAP" ]]; then
  echo "[*] No bundle paths outside ${FORENSICS_ROOT} (excluding git/github) found in index; nothing to consolidate."
  exit 0
else
  echo "[*] Paths to consolidate (non-Forensics, non-git, TAB-safe):"
  cat "$MAP"
fi

# For each mapping, ensure the Forensics copy exists and remove/move originals (no new copies)
while IFS=$'\t' read -r ORIG DEST; do
  [[ -z "${ORIG:-}" ]] && continue

  echo
  echo "[*] Consolidating:"
  echo "    ORIG: ${ORIG}"
  echo "    DEST: ${DEST}"

  orig_exists=0
  dest_exists=0
  [[ -f "$ORIG" ]] && orig_exists=1
  [[ -f "$DEST" ]] && dest_exists=1

  if (( orig_exists == 1 && dest_exists == 1 )); then
    # Both exist; verify identical then drop the non-Forensics original
    orig_sha=$(sha256sum "$ORIG" | awk '{print $1}')
    dest_sha=$(sha256sum "$DEST" | awk '{print $1}')
    echo "    ORIG SHA : $orig_sha"
    echo "    DEST SHA : $dest_sha"

    if [[ "$orig_sha" == "$dest_sha" ]]; then
      echo "    [*] Hashes match; removing non-Forensics original: $ORIG"
      rm "$ORIG"
    else
      echo "    [!] Hash mismatch between ORIG and DEST; leaving both and NOT updating index for this entry."
      printf "#%s\t%s\n" "$ORIG" "$DEST" >> "${MAP}.bad"
    fi

  elif (( orig_exists == 1 && dest_exists == 0 )); then
    echo "    [*] Only original exists; moving into Forensics (no copy)."
    mv "$ORIG" "$DEST"

  elif (( orig_exists == 0 && dest_exists == 1 )); then
    echo "    [*] Original already gone; Forensics copy exists. Will just update index."

  else
    echo "    [!] Neither original nor Forensics copy exists; will not change index for this path."
    printf "#%s\t%s\n" "$ORIG" "$DEST" >> "${MAP}.bad"
  fi
done < "$MAP"

# Build a filtered mapping (exclude any bad mappings)
FILTERED_MAP="${MAP}.filtered"
if [[ -s "${MAP}.bad" ]]; then
  awk -F '\t' '
  FNR==NR {
    if ($0 ~ /^#/) {
      sub(/^#/, "", $1)
      bad[$1] = 1
    }
    next
  }
  {
    if (!($1 in bad)) print
  }
  ' "${MAP}.bad" "$MAP" > "$FILTERED_MAP"
else
  cp "$MAP" "$FILTERED_MAP"
fi

# Backup and rewrite the index with updated bundle_path values (TAB-aware)
TS=$(date -u +%Y%m%dT%H%M%SZ)
BACKUP="${INDEX}.${TS}.bak"
cp -a "$INDEX" "$BACKUP"
echo
echo "[*] Backed up index to: $BACKUP"

TMP="${INDEX}.tmp"

awk -v FMAP="$FILTERED_MAP" '
BEGIN {
  FS = OFS = "\t"
  # load mapping old->new
  while ((getline line < FMAP) > 0) {
    split(line, f, "\t")
    old = f[1]
    new = f[2]
    if (old != "" && new != "") {
      map[old] = new
    }
  }
  close(FMAP)
}
NR == 1 {
  # header
  print $0
  next
}
{
  if ($2 in map) {
    $2 = map[$2]
  }
  print $0
}
' "$INDEX" > "$TMP"

mv "$TMP" "$INDEX"

echo "[*] Consolidation complete."
echo "[*] Any remaining references to non-Forensics paths in index (including any git/github paths, which we did NOT touch):"
grep -n "/storage/emulated/0/" "$INDEX" | grep -v "/storage/emulated/0/Forensics" || echo "    (none)"
