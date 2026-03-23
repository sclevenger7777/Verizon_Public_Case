#!/data/data/com.termux/files/usr/bin/bash
#
# verizon_build_timeline.sh
# One-and-done helper to build a chronological artifact index
# for the Verizon provisioning / drift investigation.
#
# Output: verizon_artifact_timeline.csv in current directory.

set -euo pipefail

# --- CONFIG: add or adjust roots as needed ---
ROOTS=(
  "$HOME/net_diags"
  "$HOME/PG_logs"
  "$HOME/PG_uploads"
  "$HOME/Downloads/Verizon"
  "$HOME/Downloads/Screenshots"
)

OUT="verizon_artifact_timeline.csv"

echo "timestamp_utc,epoch,path,basename,size_bytes" > "\$OUT"

for root in "\${ROOTS[@]}"; do
  [ -d "\$root" ] || continue
  find "\$root" -type f -printf '%T@,%TF %TTZ,%p,%f,%s\n' >> "\$OUT"
done

# Sort by time (epoch)
sort -t',' -k1,1n "\$OUT" -o "\$OUT"

echo "Wrote timeline to: \$OUT"
