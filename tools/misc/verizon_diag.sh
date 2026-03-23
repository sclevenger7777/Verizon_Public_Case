#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "========================================"
echo "  Verizon Data Diagnostic via Termux"
echo "  Date: $(date)"
echo "  NOTE: Wi-Fi should be OFF (mobile data only)."
echo "========================================"
echo

# Make sure curl is available
pkg update -y
pkg install -y curl

###########################################
# SECTION A: THROUGHPUT (Cloudflare HTTP)
###########################################
echo
echo "=== SECTION A: THROUGHPUT TESTS (Cloudflare) ==="
echo "These measure how long it takes to download simple files."
echo

for size in 1000000 10000000 50000000; do
  echo
  echo "-> Download test: $size bytes"
  echo "   Command: curl -o /dev/null -L https://speed.cloudflare.com/__down?bytes=$size"
  time curl -o /dev/null -L "https://speed.cloudflare.com/__down?bytes=$size"
done

###########################################
# SECTION B: IPv4 vs IPv6 (2 MB each)
###########################################
echo
echo "=== SECTION B: IPv4 vs IPv6 (2 MB file each) ==="
echo

echo "-> IPv4 only (2 MB)"
time curl -4 -o /dev/null -L "https://speed.cloudflare.com/__down?bytes=2000000"

echo
echo "-> IPv6 only (2 MB)"
time curl -6 -o /dev/null -L "https://speed.cloudflare.com/__down?bytes=2000000"

###########################################
# SECTION C: DNS over HTTPS Reachability
###########################################
echo
echo "=== SECTION C: DNS over HTTPS Reachability ==="
echo "These check if DNS over HTTPS paths to major providers are reachable."
echo

echo "-> Cloudflare DoH (1.1.1.1)"
time curl -s -o /dev/null \
  "https://cloudflare-dns.com/dns-query?name=example.com&type=A&do=1" \
  -H "accept: application/dns-json"

echo
echo "-> Google DoH (dns.google)"
time curl -s -o /dev/null "https://dns.google/resolve?name=example.com&type=A"

###########################################
# SECTION D: ICMP Ping / Packet Loss
###########################################
echo
echo "=== SECTION D: ICMP PING / LOSS (may be blocked by network) ==="
echo

echo "-> IPv4 ping to 8.8.8.8 (10 packets)"
ping -c 10 8.8.8.8 || echo "IPv4 ping failed or blocked."

echo
echo "-> IPv6 ping to 2001:4860:4860::8888 (10 packets)"
ping -6 -c 10 2001:4860:4860::8888 || echo "IPv6 ping failed or blocked."

echo
echo "========================================"
echo "  DIAGNOSTIC SUITE COMPLETE"
echo "  Save this Termux output as evidence."
echo "========================================"
