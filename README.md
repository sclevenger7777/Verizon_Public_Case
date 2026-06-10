# Verizon_Public_Case

Redacted technical dossier documenting observed Verizon mobile data performance, IMS registration behavior, subscription-state anomalies, and provisioning-related mobile data failures.

This repository contains a curated, integrity-checked subset of a larger private forensic archive assembled in support of a consumer complaint.

Complaint reference: `CC-2025-12-004745`

---

## Snapshot Reference

- Commit: `33d98b1944d0c32d7ee281c064c4b506ec931064`
- Snapshot: `https://github.com/sclevenger7777/Verizon_Public_Case/tree/33d98b1944d0c32d7ee281c064c4b506ec931064`

All observations in this public repository correspond to the checked-in evidence files and manifests.

---

## Purpose

This repository is intended to preserve a public, redacted, technically reviewable evidence set showing observed Verizon mobile service behavior, including mobile data failures, IMS / VoLTE registration inconsistencies, subscription-state anomalies, NR / LTE service-state transitions, DNS / HTTP / routing failures, and later known-good control measurements.

The repository is not a full private forensic archive. It is a public subset prepared for review, reproducibility, and escalation.

---

## Contents

- `core/net_evidence_core/` — controlled radio / telephony capture runs with state-plus-probe logs.
- `core/network_state/` — extracted network state, bearer lifecycle, routing, registration, and validation artifacts.
- `manifests/` — review manifests, tree-hash verification logs, and integrity-verification outputs.
- `SHA256SUMS_public_tree.txt` — SHA-256 checksums for files in the public evidence tree.

---

## Redaction Policy

This public repository intentionally excludes large binary archives, unnecessary raw diagnostic outputs, unrelated third-party data, unrelated personal data, credentials, tokens, authentication material, private account data, and private working notes that are not required for technical reproducibility.

This repository is derived from radio / telephony logs, Android service-state and registration artifacts, IMS / RIL / network-state observations, structured evidence extractions, controlled user-plane connectivity tests, and integrity manifests.

Its purpose is to preserve evidentiary integrity, enable technical review, support reproducibility, and avoid unnecessary exposure of unrelated data.

---

## Review Method

A reviewer should start with the manifest and checksum files, then compare the structured evidence under `core/` against the verification material under `manifests/`.

Recommended review path:

1. Inspect `SHA256SUMS_public_tree.txt`.
2. Review the manifest files under `manifests/`.
3. Review controlled captures under `core/net_evidence_core/`.
4. Review extracted bearer, registration, and connectivity state under `core/network_state/`.
5. Compare failed-state evidence against later known-good baseline measurements, if present.

---

## Scope and Limitations

This repository documents observed device-side and user-plane behavior. It does not claim direct access to Verizon internal systems, backend provisioning records, NRB records, account SOC history, IMS core logs, or carrier-side routing policy.

Where carrier-side root cause is discussed, it should be treated as inference unless supported by a Verizon-provided RCA, ticket disposition, provisioning audit, or written engineering finding.

Current preferred classification for any apparent recovery is:

`Service behavior changed after notice and evidence publication; Verizon has not provided RCA or confirmation.`

---

## Evidence Handling Notes

Raw diagnostic material should not be pasted directly into this README.

Large logs, radio dumps, app exports, or structured captures should be placed into appropriately named evidence files under `core/` or `manifests/`, with context, timestamps, redaction status, and checksums where applicable.

Conversational notes, drafting artifacts, temporary file IDs, and private working material should not be included in the public README.

---

## Integrity Verification

Run checksum verification from the repository root:

`sha256sum -c SHA256SUMS_public_tree.txt`

A clean verification confirms that the public evidence tree matches the committed checksum manifest.

---

## Status

Public redacted technical dossier.

No carrier-side RCA has been provided in this repository.
