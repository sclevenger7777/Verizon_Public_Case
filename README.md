# Verizon_Public_Case

Redacted technical dossier documenting observed Verizon mobile data
performance and IMS / provisioning behavior.

This repository contains a curated, integrity-checked subset of a
larger private forensic archive assembled in support of a consumer
complaint (reference: CC-2025-12-004745).

## Contents

core/
  net_evidence_core/     Controlled capture runs with state + probe logs
  pcap_summaries/        Derived packet-capture summaries

manifests/
  Review manifests
  Tree hash verification logs
  Integrity verification outputs

SHA256SUMS_public_tree.txt
  SHA-256 checksums for all files in this public tree.

## Redaction Policy

This public repository intentionally excludes:

- Raw .pcap / .pcapng files
- Large binary archives
- Any third-party or unrelated personal data

The objective is transparency of methodology and integrity, not public
release of full raw capture archives.

## Status

This repository reflects user-collected measurements and integrity-checked
artifacts. It is not an official statement from any carrier or regulator.
