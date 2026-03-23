# Verizon_Public_Case

Redacted technical dossier documenting observed Verizon mobile data performance and IMS / provisioning behavior.

This repository contains a curated, integrity-checked subset of a larger private forensic archive assembled in support of a consumer complaint (reference: CC-2025-12-004745).

---

## Snapshot Reference

- Commit: 33d98b1944d0c32d7ee281c064c4b506ec931064
- Snapshot: https://github.com/sclevenger7777/Verizon_Public_Case/tree/33d98b1944d0c32d7ee281c064c4b506ec931064

All observations correspond to this exact repository state.

---

## Contents

core/
  net_evidence_core/     Controlled radio/telephony logging runs with state + probe logs
  network_state/         Extracted network state, bearer lifecycle, and validation artifacts

manifests/
  Review manifests
  Tree hash verification logs
  Integrity verification outputs

SHA256SUMS_public_tree.txt
  SHA-256 checksums for all files in this public tree.

---

## Redaction Policy

This public repository excludes:

- large binary archives  
- unrelated or third-party personal data  
- raw diagnostic outputs not required for reproducibility  

This repository is derived from:

- radio / telephony logs (RIL, IMS, service state)  
- system-level network state artifacts  
- structured evidence extractions  

Purpose:

- preserve evidentiary integrity  
- enable reproducibility  
- avoid unnecessary exposure of unrelated data  

---

## Status

This repository reflects:

- user-collected measurements  
- reproducible system behavior  
- integrity-verified artifacts  

It does not represent:

- a carrier-issued analysis  
- a regulatory determination
