#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ts="$(date -u +%Y%m%dT%H%M%SZ)"
outbase="$HOME"
if [ -d "$HOME/storage/shared" ]; then outbase="$HOME/storage/shared"; fi
outdir="$outbase/net_evidence_$ts"
mkdir -p "$outdir"

log(){ printf "%s\n" "$*" | tee -a "$outdir/_run.log" >/dev/null; }

RISH="$(command -v rish 2>/dev/null || true)"   # Shizuku shell bridge if installed
PING4=""
PING6=""

# prefer system ping (usually exists)
if [ -x /system/bin/ping ]; then
  PING4=/system/bin/ping
  if /system/bin/ping -6 -c 1 -W 1 ::1 >/dev/null 2>&1; then PING6=/system/bin/ping; fi
elif command -v ping >/dev/null 2>&1; then
  PING4="$(command -v ping)"
  if "$PING4" -6 -c 1 -W 1 ::1 >/dev/null 2>&1; then PING6="$PING4"; fi
elif [ -x /system/bin/ping6 ]; then
  PING6=/system/bin/ping6
fi

log "outdir=$outdir"
log "utc=$ts"
log "uid=$(id -u) user=$(id -un 2>/dev/null || true)"
log "rish=${RISH:-none}"
log "ping4=${PING4:-none} ping6=${PING6:-none}"

# -------- snapshots (unprivileged) --------
{
  echo "=== date -u ==="; date -u
  echo; echo "=== uname -a ==="; uname -a || true
  echo; echo "=== getprop (filtered) ==="
  getprop | grep -E -i 'ro.build.fingerprint|ro.product|ro.build.version|gsm|ril|radio|carrier|operator|net\.|dhcp\.' || true
  echo; echo "=== settings (best-effort) ==="
  /system/bin/settings get global mobile_data 2>/dev/null || true
  /system/bin/settings get global data_roaming 2>/dev/null || true
  /system/bin/settings get global preferred_network_mode 2>/dev/null || true
} > "$outdir/state.txt" 2>&1 || true

{
  echo "=== /proc/net/dev ==="; cat /proc/net/dev 2>/dev/null || true
  echo; echo "=== /proc/net/route ==="; cat /proc/net/route 2>/dev/null || true
  echo; echo "=== /proc/net/ipv6_route ==="; cat /proc/net/ipv6_route 2>/dev/null || true
  echo; echo "=== /proc/net/if_inet6 ==="; cat /proc/net/if_inet6 2>/dev/null || true
} > "$outdir/proc_net.txt" 2>&1 || true

# dumpsys from unprivileged context (may be permission denied, still useful as evidence)
(dumpsys connectivity > "$outdir/dumpsys_connectivity_unpriv.txt" 2>&1) || true
(dumpsys telephony.registry > "$outdir/dumpsys_telephony_registry_unpriv.txt" 2>&1) || true

# -------- snapshots (privileged via Shizuku/rish if available) --------
if [ -n "${RISH:-}" ]; then
  # shell context typically has READ_DUMPSYS and netlink access
  ($RISH -c "id; ip -br addr; ip route show table all; ip rule show" > "$outdir/rish_ip.txt" 2>&1) || true
  ($RISH -c "dumpsys connectivity" > "$outdir/dumpsys_connectivity_rish.txt" 2>&1) || true
  ($RISH -c "dumpsys telephony.registry" > "$outdir/dumpsys_telephony_registry_rish.txt" 2>&1) || true
fi

# -------- interface enumeration (no netlink) --------
mapfile -t ifs < <(ls -1 /sys/class/net 2>/dev/null | grep -E '^(wlan|rmnet|ccmni|pdp|usb|rndis)' || true)
if [ "${#ifs[@]}" -eq 0 ]; then
  mapfile -t ifs < <(ls -1 /sys/class/net 2>/dev/null | grep -v '^lo$' || true)
fi

: > "$outdir/interfaces.txt"
for i in "${ifs[@]:-}"; do
  echo "=== iface=$i ===" >> "$outdir/interfaces.txt"
  for f in operstate carrier mtu address ifindex type; do
    p="/sys/class/net/$i/$f"
    if [ -r "$p" ]; then printf "%s=%s\n" "$f" "$(cat "$p" 2>/dev/null)" >> "$outdir/interfaces.txt"; fi
  done
  if [ -r /proc/net/if_inet6 ]; then
    echo "-- ipv6 (/proc/net/if_inet6) --" >> "$outdir/interfaces.txt"
    awk -v dev="$i" '$6==dev{print}' /proc/net/if_inet6 >> "$outdir/interfaces.txt" 2>/dev/null || true
  fi
  echo >> "$outdir/interfaces.txt"
done

probe() {
  local iface="$1" fam="$2" bytes="$3"
  local url="https://speed.cloudflare.com/__down?bytes=${bytes}"
  if [ "$fam" = "v4" ]; then
    curl -4 --interface "$iface" -L --max-time 45 -o /dev/null -sS \
      -w "iface=%{interface} fam=v4 bytes=${bytes} http=%{http_code} time=%{time_total} speedBps=%{speed_download}\n" \
      "$url" >> "$outdir/probes.txt" 2>&1 || echo "iface=$iface fam=v4 bytes=$bytes FAILED" >> "$outdir/probes.txt"
  else
    curl -6 --interface "$iface" -L --max-time 45 -o /dev/null -sS \
      -w "iface=%{interface} fam=v6 bytes=${bytes} http=%{http_code} time=%{time_total} speedBps=%{speed_download}\n" \
      "$url" >> "$outdir/probes.txt" 2>&1 || echo "iface=$iface fam=v6 bytes=$bytes FAILED" >> "$outdir/probes.txt"
  fi
}

: > "$outdir/probes.txt"
log "interfaces: ${ifs[*]:-none}"

for i in "${ifs[@]:-}"; do
  echo "=== iface=$i ===" >> "$outdir/probes.txt"

  # reachability (best-effort)
  if [ -n "${PING4:-}" ]; then
    ($PING4 -I "$i" -c 3 -W 2 1.1.1.1 >> "$outdir/probes.txt" 2>&1) || echo "ping4 iface=$i FAILED" >> "$outdir/probes.txt"
  else
    echo "ping4 iface=$i SKIP(no ping)" >> "$outdir/probes.txt"
  fi
  if [ -n "${PING6:-}" ]; then
    ($PING6 -6 -I "$i" -c 3 -W 2 2606:4700:4700::1111 >> "$outdir/probes.txt" 2>&1) || echo "ping6 iface=$i FAILED" >> "$outdir/probes.txt"
  else
    echo "ping6 iface=$i SKIP(no ping6)" >> "$outdir/probes.txt"
  fi

  # throughput probes (non-Netflix)
  probe "$i" v4 1048576
  probe "$i" v6 1048576
  probe "$i" v4 10485760
  probe "$i" v6 10485760
done

# summary
{
  echo "=== summary (computed Mbps) ==="
  awk '
    /speedBps=/ {
      iface=fam=bytes=http=time=""
      for (i=1;i<=NF;i++){
        if ($i ~ /^iface=/) iface=$i
        if ($i ~ /^fam=/) fam=$i
        if ($i ~ /^bytes=/) bytes=$i
        if ($i ~ /^http=/) http=$i
        if ($i ~ /^time=/) time=$i
        if ($i ~ /^speedBps=/){
          split($i,a,"="); bps=a[2]+0; mbps=(bps*8)/1000000;
          printf "%s %s %s %s %s speedMbps=%.3f\n", iface,fam,bytes,http,time,mbps;
        }
      }
    }
  ' "$outdir/probes.txt" 2>/dev/null || true
} > "$outdir/summary.txt"

tar -czf "${outdir}.tar.gz" -C "$(dirname "$outdir")" "$(basename "$outdir")" >/dev/null 2>&1 || true
log "done"
log "bundle_dir=$outdir"
log "bundle_tgz=${outdir}.tar.gz"
