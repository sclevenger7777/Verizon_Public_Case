#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

IN_DIR="${1:-}"
if [[ -z "$IN_DIR" || ! -d "$IN_DIR" ]]; then
  echo "USAGE: $0 /path/to/capture_dir" >&2
  exit 2
fi

OUT_DIR="/sdcard/Download/vz_line_vs_device_extract_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT_DIR"

PY="$OUT_DIR/extract.py"
cat > "$PY" <<'PY'
import os, re, csv, sys, datetime

IN_DIR = sys.argv[1]
OUT_DIR = sys.argv[2]

# Patterns that would support "line/provisioning"
LINE_SIDE = {
  "esm_missing_unknown_apn": r"\bMISSING_UNKNOWN_APN\b|\bMissing or unknown APN\b",
  "service_option_not_subscribed": r"\bSERVICE_OPTION_NOT_SUBSCRIBED\b|\bnot subscribed\b",
  "pdn_reject_attach_reject": r"\bPDN\s*REJECT\b|\bATTACH\s*REJECT\b|\brejectCause=\s*[1-9]\d*\b",
  "ims_sip_failures": r"\bSIP\b.*\b(403|404|408|480|486|488|500|503)\b|\bREGISTER\b.*\b(403|404|408|480|486|488|500|503)\b",
  "ims_auth_fail": r"\b401\b.*\bSIP\b|\bUnauthorized\b.*\bIMS\b",
}

# Patterns that support "device/subscription state instability"
DEVICE_SIDE = {
  "no_subscription_context": r"\bsubId=-1\b|activeDataSubId=-1|\bmSubId\s*=\s*-1\b",
  "sim_not_ready_or_absent": r"\bSIM_STATE_(ABSENT|NOT_READY|UNKNOWN)\b|\bsimState\b.*(ABSENT|NOT_READY|UNKNOWN)",
  "carrier_privileges_missing": r"mCarrierPrivilegeState=\{\s*packages=\[\]\s*\}|\bcarrier privilege\b.*\bempty\b",
  "framework_perm_denied": r"SecurityException|Permission Denial|not allowed to access",
}

# Neutral-but-useful (correlation / sanity checks)
NEUTRAL = {
  "service_state_oos": r"\bOUT_OF_SERVICE\b",
  "not_reg_states": r"\bNOT_REG\b|\bNOT_REG_SEARCHING\b|\bNOT_REG_MT_SEARCHING_OP\b",
  "apn_vzwinternet": r"\bVZWINTERNET\b|\bDNN:\s*VZWINTERNET\b|\bapnSetting\b.*VZWINTERNET",
  "pcscf_present": r"\bP-CSCF\b|\bpcscf\b|\bPcscfAddresses\b",
  "data_call_ok": r"SetupDataCallResult\{cause:\s*NONE\b|\bCONNECTED\b.*rmnet",
  "lost_connection": r"\bcause:\s*LOST_CONNECTION\b|\bLOST_CONNECTION\b",
}

ALL = []
for group, patterns in [("line", LINE_SIDE), ("device", DEVICE_SIDE), ("neutral", NEUTRAL)]:
  for name, pat in patterns.items():
    ALL.append((group, name, re.compile(pat, re.IGNORECASE)))

# Scan candidate text-ish files
CAND = []
for root, _, files in os.walk(IN_DIR):
  for fn in files:
    if fn.lower().endswith((".txt",".log",".out",".csv",".md")) or fn.startswith(("0","1","9")):
      CAND.append(os.path.join(root, fn))

hits = []
seen_any = {name: False for _, name, _ in ALL}

for path in sorted(CAND):
  try:
    with open(path, "r", errors="replace") as f:
      for i, line in enumerate(f, start=1):
        for group, name, rx in ALL:
          if rx.search(line):
            seen_any[name] = True
            hits.append({
              "group": group,
              "pattern": name,
              "file": os.path.relpath(path, IN_DIR),
              "line": i,
              "text": line.rstrip("\n")[:500],
            })
  except Exception as e:
    hits.append({
      "group": "error",
      "pattern": "read_error",
      "file": os.path.relpath(path, IN_DIR),
      "line": 0,
      "text": f"{type(e).__name__}: {e}",
    })

# Write CSV
csv_path = os.path.join(OUT_DIR, "hits.csv")
with open(csv_path, "w", newline="") as f:
  w = csv.DictWriter(f, fieldnames=["group","pattern","file","line","text"])
  w.writeheader()
  w.writerows(hits)

# Write not_found
nf_path = os.path.join(OUT_DIR, "not_found.txt")
with open(nf_path, "w") as f:
  for _, name, _ in ALL:
    if not seen_any[name]:
      f.write(name + "\n")

# Summarize
def count(group):
  return sum(1 for h in hits if h["group"] == group)

md_path = os.path.join(OUT_DIR, "report.md")
now = datetime.datetime.now().isoformat(timespec="seconds")
with open(md_path, "w") as f:
  f.write(f"# VZ line vs device evidence extract\n\n")
  f.write(f"- input: `{IN_DIR}`\n- generated: `{now}`\n- hits: line={count('line')} device={count('device')} neutral={count('neutral')}\n\n")

  f.write("## Strong line-side indicators (if present)\n\n")
  for h in hits:
    if h["group"] == "line":
      f.write(f"- **{h['pattern']}** {h['file']}:{h['line']}\n  - `{h['text']}`\n")
  if count("line") == 0:
    f.write("- (none found in this capture)\n")

  f.write("\n## Strong device-side indicators (if present)\n\n")
  for h in hits:
    if h["group"] == "device":
      f.write(f"- **{h['pattern']}** {h['file']}:{h['line']}\n  - `{h['text']}`\n")
  if count("device") == 0:
    f.write("- (none found in this capture)\n")

  f.write("\n## Neutral correlation signals\n\n")
  # keep report readable
  shown = 0
  for h in hits:
    if h["group"] == "neutral":
      f.write(f"- **{h['pattern']}** {h['file']}:{h['line']}\n  - `{h['text']}`\n")
      shown += 1
      if shown >= 80:
        f.write("- (truncated)\n")
        break

print("WROTE:", md_path)
print("WROTE:", csv_path)
print("WROTE:", nf_path)
PY

python "$PY" "$IN_DIR" "$OUT_DIR"
echo
echo "OPEN:"
echo "  $OUT_DIR/report.md"
echo "  $OUT_DIR/hits.csv"
echo "  $OUT_DIR/not_found.txt"
