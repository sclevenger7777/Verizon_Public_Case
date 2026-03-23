#!/usr/bin/env bash
set -euo pipefail

rish -c "
set -eu
ts=\$(date -u +%Y%m%dT%H%M%SZ)
BASE=/sdcard/Download
WORK=\$BASE/vzw_working_\$ts
QUAR=\$WORK/_quarantine
SRC1=\$BASE/vzw_device_bundle_20251221T234004Z
SRC2=\$(ls -1td \$BASE/dumpsys_probe_* 2>/dev/null | head -n 1 || true)

mkdir -p \"\$WORK\" \"\$QUAR\"

echo \"WORKDIR=\$WORK\" > \"\$WORK/INVENTORY.txt\"
echo \"SRC_BUNDLE=\$SRC1\" >> \"\$WORK/INVENTORY.txt\"
echo \"SRC_PROBE=\${SRC2:-NONE}\" >> \"\$WORK/INVENTORY.txt\"
echo >> \"\$WORK/INVENTORY.txt\"

keep_file() {
  src=\"\$1\"; dst=\"\$2\"; bn=\$(basename \"\$src\")
  if [ -f \"\$src\" ] && [ \"\$(wc -c < \"\$src\" 2>/dev/null || echo 0)\" -gt 0 ]; then
    cp -p \"\$src\" \"\$dst/\$bn\"
    echo \"KEEP  \$src  ->  \$dst/\$bn\" >> \"\$WORK/INVENTORY.txt\"
    return 0
  fi
  return 1
}

keep_err() {
  src=\"\$1\"; dst=\"\$2\"; bn=\$(basename \"\$src\")
  if [ -f \"\$src\" ]; then
    sz=\$(wc -c < \"\$src\" 2>/dev/null || echo 0)
    if [ \"\$sz\" -gt 0 ]; then
      cp -p \"\$src\" \"\$dst/\$bn\"
      echo \"KEEPERR \$src  ->  \$dst/\$bn (bytes=\$sz)\" >> \"\$WORK/INVENTORY.txt\"
      return 0
    fi
  fi
  return 1
}

quar_copy() {
  src=\"\$1\"; bn=\$(basename \"\$src\")
  if [ -e \"\$src\" ]; then
    cp -p \"\$src\" \"\$QUAR/\$bn\" 2>/dev/null || true
    echo \"QUAR  \$src  ->  \$QUAR/\$bn\" >> \"\$WORK/INVENTORY.txt\"
  fi
}

echo \"== collecting from vzw_device_bundle ==\" >> \"\$WORK/INVENTORY.txt\"

for f in carrier_config.txt connectivity.txt radio_logcat.txt telecom.txt telephony_registry.txt ip_addr.txt ip_route.txt netpolicy.txt ims.txt
do
  keep_file \"\$SRC1/\$f\" \"\$WORK\" || quar_copy \"\$SRC1/\$f\"
done

for f in telephony_full.txt dumpsys_ImsBase.txt dumpsys_epdgService.txt dumpsys_telephony_ims.txt dumpsys_vzwimsapiservice.txt
do
  quar_copy \"\$SRC1/\$f\"
done

echo >> \"\$WORK/INVENTORY.txt\"
echo \"== collecting from latest dumpsys_probe_* ==\" >> \"\$WORK/INVENTORY.txt\"

if [ -n \"\${SRC2:-}\" ] && [ -d \"\$SRC2\" ]; then
  keep_file \"\$SRC2/PROBE.txt\" \"\$WORK\" || quar_copy \"\$SRC2/PROBE.txt\"

  for p in \"\$SRC2\"/dumpsys_*.out; do
    [ -e \"\$p\" ] || continue
    keep_file \"\$p\" \"\$WORK\" || quar_copy \"\$p\"
  done

  for p in \"\$SRC2\"/dumpsys_*.err; do
    [ -e \"\$p\" ] || continue
    keep_err \"\$p\" \"\$WORK\" || quar_copy \"\$p\"
  done
else
  echo \"NOTE: no dumpsys_probe_* directory found under \$BASE\" >> \"\$WORK/INVENTORY.txt\"
fi

echo >> \"\$WORK/INVENTORY.txt\"
echo \"== final listing ==\" >> \"\$WORK/INVENTORY.txt\"
ls -la \"\$WORK\" >> \"\$WORK/INVENTORY.txt\" 2>&1 || true

( cd \"\$WORK\" && find . -maxdepth 1 -type f ! -name \"MANIFEST.sha256\" -print0 | sort -z | xargs -0 sha256sum ) > \"\$WORK/MANIFEST.sha256\" 2>/dev/null || true

echo \"DONE\"
echo \"WORKDIR=\$WORK\"
"
