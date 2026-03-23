#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Base Forensics dir (canonical from your logs)
FORENSICS_BASE="/data/data/com.termux/files/home/storage/shared/Forensics"

# Public-case export root
PUB_ROOT="/data/data/com.termux/files/home/storage/shared/Verizon_Public_Case"

CORE_DIR="$PUB_ROOT/core"
RAW_DIR="$PUB_ROOT/raw_candidates"
MANIFEST_DIR="$PUB_ROOT/manifests"

mkdir -p "$CORE_DIR" "$RAW_DIR" "$MANIFEST_DIR"

echo "[INFO] Forensics base: $FORENSICS_BASE"
echo "[INFO] Public case root: $PUB_ROOT"
echo

copy_if_exists() {
  local src="$1"
  local dest="$2"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    echo "[COPY] $src -> $dest"
    cp -p "$src" "$dest"
  else
    echo "[SKIP] Missing: $src" >&2
  fi
}

copy_dir_if_exists() {
  local src="$1"
  local dest="$2"
  if [[ -d "$src" ]]; then
    echo "[COPYDIR] $src -> $dest"
    mkdir -p "$(dirname "$dest")"
    # Only copy files, preserve structure under src
    (cd "$src" && find . -type f -print0) | while IFS= read -r -d '' rel; do
      mkdir -p "$dest/$(dirname "$rel")"
      cp -p "$src/$rel" "$dest/$rel"
    done
  else
    echo "[SKIPDIR] Missing dir: $src" >&2
  fi
}

echo "=== STAGE 1: manifests / integrity files ==="

# Core manifest / regulatory / hashcheck files -> manifests/
for f in \
  regulatory_verification_20260122T001452Z.txt \
  regulatory_verification_20260122T001452Z.txt.sha256 \
  review_manifest_20260119T160327Z.txt \
  review_manifest_20260119T160327Z.txt.sha256 \
  review_manifest_full_20260119T160757Z.txt \
  review_manifest_full_20260119T160757Z.txt.sha256 \
  tree_hashcheck_20260119T160757Z.txt \
  tree_hashcheck_20260119T160757Z.txt.sha256 \
  tree_hashcheck_fullmanifest_20260123T220826Z.txt \
  tree_hashcheck_fullmanifest_20260123T220826Z.txt.sha256 \
  tree_hashcheck_fullmanifest_20260123T220826Z.txt.sha256.portable \
  verizon_case_master_full_20260220T140814Z.tar.gz.sha256 \
  verizon_case_master_full_20260220T140814Z.tar.gz
do
  copy_if_exists "$FORENSICS_BASE/$f" "$MANIFEST_DIR/$f"
done

echo
echo "=== STAGE 2: Verizon-specific evidence (core) ==="

# Telephony registry evidence (highly relevant, potentially PII-heavy)
# For now, place it under raw_candidates; you may redact or move later.
TELEREG_SRC="$FORENSICS_BASE/evidence_telereg_20260115T071837Z.txt"
copy_if_exists "$TELEREG_SRC" "$RAW_DIR/evidence_telereg_20260115T071837Z.txt"

# Net evidence runs: create structured layout
for d in "$FORENSICS_BASE"/net_evidence_20260115T*; do
  [[ -d "$d" ]] || continue
  bn="$(basename "$d")"

  core_target="$CORE_DIR/net_evidence_core/$bn"
  raw_target="$RAW_DIR/net_evidence_raw/$bn"

  echo "[INFO] Processing net_evidence bundle: $bn"

  # 2a) Core subset: summaries and run metadata (safer for GitHub)
  for cf in _run.log summary.txt state.txt probes.txt; do
    src="$d/$cf"
    if [[ -f "$src" ]]; then
      copy_if_exists "$src" "$core_target/$cf"
    fi
  done

  # 2b) Raw/high-PII subset: dumpsys, interfaces, proc_net, rish_ip, tar.gz
  for rf in \
    dumpsys_connectivity.txt \
    dumpsys_connectivity_rish.txt \
    dumpsys_connectivity_unpriv.txt \
    dumpsys_telephony_registry.txt \
    dumpsys_telephony_registry_rish.txt \
    dumpsys_telephony_registry_unpriv.txt \
    interfaces.txt \
    proc_net.txt \
    rish_ip.txt \
    net_evidence_20260115T063331Z.tar.gz \
    net_evidence_20260115T063903Z.tar.gz \
    net_evidence_20260115T064054Z.tar.gz \
    net_evidence_20260115T064130Z.tar.gz \
    net_evidence_20260115T065405Z.tar.gz
  do
    src="$d/$rf"
    if [[ -f "$src" ]]; then
      copy_if_exists "$src" "$raw_target/$rf"
    fi
  done
done

echo
echo "=== STAGE 3: PCAP summaries / case-wide texts ==="

# PCAP summary texts and CSV – these are descriptive, not raw pcap
for f in \
  PCAPBOTH.txt \
  PCAPBoth1.txt \
  PCAPdroid_14_Aug_11_30_02.csv
do
  copy_if_exists "$FORENSICS_BASE/$f" "$CORE_DIR/pcap_summaries/$f"
done

# case-wide verification / verification logs that are not app-specific
for f in \
  verify_inner_20251231T080138Z.log \
  verify_inner_20251231T080138Z.log.sha256
do
  copy_if_exists "$FORENSICS_BASE/$f" "$MANIFEST_DIR/$f"
done

echo
echo "=== STAGE 4: EXCLUDE non-Verizon investigations (HappyMod, quarantine, etc.) ==="
echo "[INFO] No action needed; we simply do not copy:"
echo "       - HappyMod_Evidence/"
echo "       - happymod_* bundles / screens"
echo "       - Quarantine_Artifacts/"
echo "       - Case_20250917_*"
echo

echo "=== STAGE 5: SHA256 for public tree ==="

(
  cd "$PUB_ROOT"
  # Hash everything in the export tree
  find . -type f -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS_public_tree.txt
)
echo "[INFO] SHA256SUMS_public_tree.txt written under $PUB_ROOT"

echo
echo "[DONE] Public-case tree created at: $PUB_ROOT"
echo "       Review core/ vs raw_candidates/ before pushing to GitHub."
