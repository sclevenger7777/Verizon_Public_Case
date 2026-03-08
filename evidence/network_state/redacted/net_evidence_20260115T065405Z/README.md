# Redacted network evidence

Source bundle:
- `/storage/emulated/0/Forensics/net_evidence_20260115T065405Z`

Public-repo handling:
- Raw mirrored copies were removed from the public repo.
- This directory contains redacted public-safe derivatives.
- Redactions remove home-network identifiers and unrelated app fingerprinting.
- Verizon-relevant cellular, IMS, and bearer/interface evidence was retained.

Redacted classes:
- SSID / BSSID / Wi-Fi MAC
- LAN IPv4 / gateway
- home IPv6 GUA / ULA prefixes
- unrelated app inventory from NetworkRequest blocks

Additional redaction update:
- Removed residual human-readable Wi-Fi network labels from the public-safe derivative set.
