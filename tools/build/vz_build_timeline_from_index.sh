#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

DL_ROOT="$HOME/storage/downloads"
VZ_ROOT="$DL_ROOT/verizon_case_master_20260219T162625Z"
DOC_DIR="$VZ_ROOT/00_case_docs"

if [ ! -d "$DOC_DIR" ]; then
  echo "ERROR: Case docs dir not found: $DOC_DIR" >&2
  exit 1
fi

latest_index="$(ls -1 "$DOC_DIR"/vz_case_file_index_*.tsv 2>/dev/null | sort | tail -n1 || true)"
if [ -z "$latest_index" ]; then
  echo "ERROR: No vz_case_file_index_*.tsv found in $DOC_DIR" >&2
  exit 1
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$DOC_DIR/vz_case_timeline_${TS}.tsv"

echo "==[ VZ CASE TIMELINE ]==" > "$OUT"
echo "# Source index: $(basename "$latest_index")" >> "$OUT"
echo "# Generated UTC: $(date -u)" >> "$OUT"
echo >> "$OUT"
echo -e "mtime_utc\tsize_bytes\tbucket\trelpath" >> "$OUT"

# Skip header/comment lines; classify based on leading directory
awk -F '\t' '
BEGIN {
  OFS = "\t"
}
# skip comments and header
/^#/ { next }
NR == 1 && $1 ~ /mtime_utc/ { next }
NF < 3 { next }

{
  mtime = $1
  size  = $2
  rel   = $3

  # Extract top-level dir (before first "/")
  bucket = "other"
  if (match(rel, /^[^\/]+/)) {
    dir = substr(rel, RSTART, RLENGTH)
    if      (dir == "01_radio_logs")           bucket = "radio"
    else if (dir == "02_ims_artifacts")        bucket = "ims"
    else if (dir == "03_pcap_and_captures")    bucket = "pcap"
    else if (dir == "04_telephony_phone_dumps")bucket = "telephony"
    else if (dir == "05_speed_tests")          bucket = "speed"
    else if (dir == "06_net_policy_stats")     bucket = "net_policy"
    else if (dir == "07_sim_apn")              bucket = "sim_apn"
    else if (dir == "08_reports_summaries")    bucket = "reports"
    else if (dir == "09_bundles_archives")     bucket = "bundles"
    else if (dir == "10_misc_verizon_logs")    bucket = "misc_vz"
    else if (dir == "11_bugreports_root")      bucket = "bugreports"
    else if (dir == "12_device_state_snapshots") bucket = "snapshots"
  }

  print mtime, size, bucket, rel
}
' "$latest_index" | sort >> "$OUT"

echo "[OK] Timeline with buckets written to: $OUT"
