# Changelog

All notable changes to Quick Ticket Maker are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Nothing yet.

## [1.0.0] - 2026-07-31

First tagged release. The `1.0.0` heading previously carried a 2026-07-16 date,
but no `v1.0.0` tag was ever cut, so the Flutter rewrite and the V1 personal
ticket share milestone ship together as one release.

### Added

- **Saved tickets.** Generated tickets persist locally in encrypted secure storage and appear in the Tickets tab, with a detail page and a durable image store for flyers
- **Editable event details.** Title, subtitle, header label, venue, date/time, flyer image, and category palettes are all editable in the designer
- **PNG export and share.** The saved ticket rasterises to a PNG and goes out through the native share sheet, with a web download path where sharing is unavailable
- **Door verification.** Public `/verify/:id` deep link resolves a scanned QR against Firestore and performs a **single-use check-in**; repeat scans report the earlier admission
- **Optional accounts.** Firebase Auth (email/password, Google, Apple) layered over a guest-first flow — nothing requires sign-in; signing in adds owner-scoped cloud copies and restores a pending action afterwards
- **Bundled typography.** Readex Pro, Outfit, Space Mono, and the web engine's Roboto ship as assets, so text never waits on a font CDN
- **Ticket polish.** `TICKET ID` label, full-format event date, `ABOUT THIS EVENT` heading, `Scan at entrance` hint in place of the raw URL, and a `Powered by Quick Ticket` footer
- **Android release signing.** Upload keystore sourced from an untracked `key.properties`, with the release build failing fast when it is absent
- Full GitHub community health documentation set (README, SECURITY, CONTRIBUTING, CODE_OF_CONDUCT, SUPPORT, LICENSE)
- Product docs under `docs/` (architecture, features, getting started, development, privacy)
- Security pack (information security policy, threat model, secure coding)
- ISO alignment mapping (`docs/compliance/iso-alignment.md`)
- GitHub Issue/PR templates and Dependabot configuration
- Hardened `.gitignore` for secrets and credential files
- Baseline from the initial Flutter rewrite: Generate + Tickets shell, QR
  customization (colors, shape), ticket code generation, background gradients,
  Cubit state management, `go_router` navigation, and the TaskManager backup
  under `.taskmanager/`

### Changed

- Ticket flyers are embedded in the Firestore document instead of Firebase Storage; Storage is not initialised and its rules deny all access
- Documentation now describes the shipped app rather than the preview-only demo, and `test/docs_accuracy_test.dart` fails if it drifts back

### Fixed

- `MissingPluginException` from `flutter_secure_storage` on Flutter web, which silently lost saved tickets — added a fallback store plus a build-time plugin-registration check in `scripts/build_web.sh`
- `NOT FOUND` at the door when a shared QR pointed at a ticket whose public document was missing or stale
- Web share failing on Firebase Storage downloads due to browser CORS
- Google Fonts and the web engine's default Roboto being fetched at runtime, which broke offline and CDN-blocked loads and produced the "Could not find a set of Noto fonts" warning
- Event date truncating at phone width because the date and time split the row equally; the date now falls back to a compact format instead of ellipsising
- `SecureStorageService.clearAllTickets` throwing `Concurrent modification during iteration`

### Security

- Guest ticket data migrated off plaintext `SharedPreferences` into `FlutterSecureStorage`, with a one-time migration that clears the legacy key
- The `SharedPreferences` fallback is a documented exception in [`.cursor/rules/ticket-security.mdc`](.cursor/rules/ticket-security.mdc), reached only when the secure plugin is genuinely unavailable and guarded by the web build check
- QR payloads carry only a ticket code — no guest PII in the scanned string
- Firestore rules keep owner documents owner-only and constrain the public ticket document to creation, a single valid → checked-in transition, and host-owned edits

### Known limitations

- Ticket codes are identifiers, not signed credentials: reuse is detected only
  after the first check-in, and anyone holding a code can read that ticket's
  public document. See [docs/security/threat-model.md](docs/security/threat-model.md)
  and [docs/privacy.md](docs/privacy.md) §5
- `ScanPage` is built but not routed; door staff use a phone camera against the
  verification link
- The canonical QR host is the Firebase Hosting domain
  (`quick-ticket-maker-sandbox.web.app`); `ticketmaker.app` is still accepted
  when parsing older payloads

[Unreleased]: https://github.com/injectGroup/ticketmaker/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/injectGroup/ticketmaker/releases/tag/v1.0.0
