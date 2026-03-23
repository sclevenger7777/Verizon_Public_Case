#!/data/data/com.termux/files/usr/bin/bash
# Build a markdown skeleton ledger from verizon_artifact_timeline.csv
set -euo pipefail

CSV="$HOME/verizon_artifact_timeline.csv"
LEDGER="$HOME/verizon_case_ledger_skeleton.md"

if [ ! -f "$CSV" ]; then
  echo "[PG-VERIZON] ERROR: CSV not found: $CSV" >&2
  exit 1
fi

echo "[PG-VERIZON] Building ledger skeleton from: $CSV"
echo "[PG-VERIZON] Output: $LEDGER"

# Header
cat <<'HDR' > "$LEDGER"
# Verizon Case Ledger – Skeleton

## Hypotheses

- T1 – Carrier-side provisioning / policy / tower-side issues
- T2 – Device-side / OS / app / VPN / DNS / store interference
- T3 – Mixed cause: T1 + T2 interacting
- T4 – Other / unknown

## Global Facts (to fill later)
<!-- F-G-001, F-G-002, etc. -->

## Artifact Entries (generated from verizon_artifact_timeline.csv)
HDR

# Artifact sections
awk -F',' 'NR>1 {
  id       = sprintf("A-%04d", NR-1);
  epoch    = $1;
  path     = $3;
  base     = $4;
  size     = $5;

  printf "\n---\n\n";
  printf "### %s – %s\n", id, base;
  printf "- Path: `%s`\n", path;
  printf "- Size: %s bytes\n", size;
  printf "- Timestamp epoch: %s\n\n", epoch;

  printf "**Raw facts (to extract):**\n";
  printf "- F-%s-01: \n", id;
  printf "- F-%s-02: \n\n", id;

  printf "**Supports:**\n";
  printf "- T1 (carrier-side): [ ] yes  [ ] no  [ ] unknown\n";
  printf "- T2 (device-side):  [ ] yes  [ ] no  [ ] unknown\n";
  printf "- T3 (mixed):        [ ] yes  [ ] no  [ ] unknown\n";
  printf "- T4 (other):        [ ] yes  [ ] no  [ ] unknown\n\n";

  printf "**Contradictions / corrections:**\n";
  printf "- C-%s-01: \n", id;
}' "$CSV" >> "$LEDGER"

echo "[PG-VERIZON] Ledger skeleton written to: $LEDGER"
