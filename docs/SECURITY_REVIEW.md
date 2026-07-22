# Security Review

Scope: local-only children's app; primary risks are child-safety gates,
payment integrity, and local data integrity.

## Threat review

| Area | Risk | Mitigation |
|---|---|---|
| Adult gate bypass | Child reaches purchase/export/links | Gate required on every sensitive route (router guard + in-flow checks); hold is time-verified against a clock, not animation completion; 3 fails → 30s cooldown enforced in the controller (UI cannot skip it) |
| Purchase spoofing | Fake unlock without payment | Entitlement cache is a *cache*; source of truth is Amazon receipts via restore. No client secret exists to steal. Sideload tampering with the local DB is out of scope for a local-only app (no server assets at risk) |
| Duplicate charge | Double-tap on Buy | Controller busy-latch + disabled buttons + idempotent `already_owned` handling |
| Path traversal | Malicious names writing outside app dirs | Ids sanitized to `[A-Za-z0-9_-]`; display names never used as paths; export filenames generated, not user-supplied |
| Data corruption | Power loss mid-save | Atomic temp+rename writes; SQLite transactions; `PRAGMA integrity_check` on boot → repair screen path |
| Injection | SQL via search/rename | All queries parameterized in repositories; no string-built SQL |
| Sensitive logs | Receipts/child content in logcat | No logging of documents or purchase payloads; release builds strip debug prints |
| Network attack surface | MITM etc. | No app-owned network I/O besides a DNS probe; IAP traffic is Amazon's client; no cleartext traffic permitted in manifest |
| Permissions | Over-permissioning | No dangerous permissions at install; media write only via MediaStore at export time; no INTERNET-dependent features for children |

## Dependencies

Four runtime packages (sqflite, path, path_provider, provider), all
mainstream, permissively licensed, no native network code. No Google
services. Supply-chain surface is minimal; pin exact versions in
`pubspec.lock` at release.

## Residual risks / notes

- Local entitlement cache can be edited on rooted devices — accepted for a
  $4.99 offline entitlement (standard for offline unlocks).
- Amazon SDK hooks in `MainActivity.kt` must map receipts → fulfillment
  exactly once (`notifyFulfillment`) — covered in AMAZON_IAP_SETUP.md.
- Placeholder legal copy is a release blocker.
