#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

OUT="${1:-vz_evidence_extract_$(date +%Y%m%d_%H%M%S).txt}"
shift || true

# Default file set (edit as needed)
FILES=(
  "dumpsys_secims.out"
  "dumpsys_carrier_config.out"
  "dumpsys_connectivity.out"
  "getprop_ims_carrier.txt"
  "01_service_state.txt"
  "PROBE_FIXED.txt"
  "vz_tier3_packet_20260129_021027.txt"
)

# If args were provided, use them as FILES
if [ "$#" -gt 0 ]; then
  FILES=("$@")
fi

{
  echo "=== Verizon provisioning drift evidence extract ==="
  echo "Generated: $(date -Is)"
  echo

  for f in "${FILES[@]}"; do
    if [ ! -f "$f" ]; then
      echo "-- $f: MISSING --"
      echo
      continue
    fi

    echo "----- FILE: $f -----"

    # SIM/IMS identity
    echo "[SIM/IMS identity]"
    nl -ba "$f" | grep -E "SIM PLMN|mSimMno|IMSI|IMPI|IMPU|IMPUs|gid1|Operator:" | head -n 80 || true
    echo

    # Carrier config provisioning gates
    echo "[CarrierConfig IMS/VoLTE/WFC provisioning flags]"
    nl -ba "$f" | grep -E "carrier_(volte|wfc|ims)_|provision" | head -n 140 || true
    echo

    # Connectivity IMS bearer proof
    echo "[Connectivity IMS bearer / rmnet / P-CSCF]"
    nl -ba "$f" | grep -E "extra: IMS|PcscfAddresses|rmnet_data|Capabilities: IMS|MMTEL|VALIDATED" | head -n 120 || true
    echo

    # Drift / APN mapping failures
    echo "[APN/subId drift signatures]"
    nl -ba "$f" | grep -E "subId=-1|TempApn|MISSING_UNKNOWN_APN|networkType=UNKNOWN|fail cause" | head -n 120 || true
    echo
  done

  echo "=== END ==="
} > "$OUT"

chmod 0644 "$OUT"
echo "WROTE: $OUT"
