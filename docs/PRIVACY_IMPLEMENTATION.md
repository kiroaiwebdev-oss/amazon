# Privacy Implementation

Designed for a children's audience (COPPA-conscious, though final legal
review is the owner's responsibility).

## What the app collects

**Nothing.** No accounts, no analytics, no crash reporting, no advertising
identifiers, no age collection, no names, no free-text that leaves the
device, no network calls except:

1. Amazon IAP product data / purchase / restore (initiated only behind the
   adult gate; handled by the Amazon Appstore client, not our code).
2. A lightweight connectivity probe (DNS lookup) to decide whether to show
   offline states — no payload, nothing logged.
3. External legal/support links: opened in the browser only after the adult
   gate; URLs are static.

## Data at rest

- All data lives in **app-private storage** (`getApplicationDocumentsDirectory`):
  SQLite db (settings, catalog progress, badges, entitlement cache, artwork
  metadata) and JSON artwork documents + PNG thumbnails.
- Exported PNGs go to shared Pictures/TinyCanvas **only** when a caregiver
  explicitly starts an export (permission requested at that moment, never at
  launch).
- "Erase my creations" (adult gate + 5s hold) deletes artworks, progress,
  badges, recents, thumbnails. It clearly does **not** claim to erase the
  Amazon purchase record — ownership restores via Amazon.

## Code-level protections

- File names/paths sanitized: artwork ids filtered to `[A-Za-z0-9_-]`,
  display names 1–40 chars with path-unsafe characters stripped; documents
  addressed only by generated ids — no user-controlled path segments → no
  path traversal.
- Atomic writes (temp + rename) prevent partial files; corrupt documents are
  detected (FormatException) and recovered without crashing.
- No sensitive logging: release builds log nothing; debug logs never include
  artwork content or receipts.
- No WebViews. Legal text renders natively.
- Child-facing surfaces contain no external links, no purchase entry points
  outside gated flows, no manipulative mechanics.

## Release blockers

- `PRIVACY POLICY PLACEHOLDER` and `TERMS PLACEHOLDER` in the legal screens
  **must** be replaced with counsel-approved copy before submission
  (tracked in RELEASE_CHECKLIST.md).
