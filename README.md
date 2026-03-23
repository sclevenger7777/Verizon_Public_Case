# Verizon_Public_Case

Redacted technical dossier documenting observed Verizon mobile data performance and IMS / provisioning behavior.

This repository contains a curated, integrity-checked subset of a larger private forensic archive assembled in support of a consumer complaint (reference: CC-2025-12-004745).

---

## Snapshot Reference

- Commit: 33d98b1944d0c32d7ee281c064c4b506ec931064
- Snapshot: https://github.com/sclevenger7777/Verizon_Public_Case/tree/33d98b1944d0c32d7ee281c064c4b506ec931064

All observations correspond to this exact repository state.

## Contents

core/
  net_evidence_core/     Controlled radio/telephony capture runs with state-plus-probe logs
  network_state/         Extracted network state, bearer life-cycle, and validation artefacts

manifests/
  Review manifests
  Tree-hash verification logs
  Integrity-verification outputs

SHA256SUMS_public_tree.txt
  SHA-256 checksums for every file in this public tree.

---

## Redaction Policy

This public repository intentionally excludes

- large binary archives
- any third-party or unrelated personal data
- raw diagnostic outputs that are not required for reproducibility

The repository is derived from

- radio / telephony logs (RIL, IMS, service-state)
- system-level network-state artefacts
- structured evidence extractions

Its purpose is to

- preserve evidentiary integrity  
- enable reproducibility  
- avoid unnecessary exposure of unrelated data  
