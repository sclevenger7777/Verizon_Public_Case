# Verizon_Public_Case

Redacted technical dossier on observed Verizon mobile data performance and IMS / provisioning anomalies.

This repository contains:

- **core/net_evidence_core/** – curated summaries from a series of controlled capture runs
  on a single Android device. Each bundle includes:
  - `_run.log` – capture script execution log
  - `summary.txt` – high-level run summary
  - `state.txt` – capture-time state snapshot
  - `probes.txt` – connectivity probes and timing notes

- **core/pcap_summaries/** – derived summaries from packet-capture sessions
  (e.g. PCAPdroid exports), focusing on throughput, protocol mix, and continuity
  across different test scenarios.

- **manifests/** – integrity and review artefacts:
  - `review_manifest*` – human-readable index of evidence artefacts referenced in a consumer complaint
  - `tree_hashcheck*` – SHA-256 tree checks against the private, full forensic archive
  - `verify_inner_*` – logs from integrity verification of nested evidence bundles
  - `regulatory_verification_*` – notes and hash references prepared for regulatory review

- **SHA256SUMS_public_tree.txt** – SHA-256 checksums for every file in this public tree.

## Scope and redaction

This repository is a **redacted** subset of a larger private forensic archive.
It intentionally excludes:

- Raw packet-capture files (`.pcap`, `.pcapng`) and large binary artefacts
- Third-party investigations unrelated to mobile network performance
- Any materials that could expose unrelated personal data

The goal is to provide a transparent, technically-auditable record of the evidence
supporting an individual consumer complaint (reference: CC-2025-12-004745), while
keeping the underlying raw artefacts under stricter access control.

## Status

This repository is **not** an official statement by any carrier or regulator.
It is a good-faith technical record created by an end user, based on reproducible
measurements and integrity-checked artefacts.
