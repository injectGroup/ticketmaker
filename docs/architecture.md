# Architecture

## Purpose

Describe the software architecture of Quick Ticket Maker for maintainers and reviewers. This document supports ISO/IEC/IEEE 12207 design and ISO/IEC 25010 maintainability goals.

**Revision:** 2.0 — V1 personal ticket share (31 July 2026)

---

## System context

```text
┌──────────────────────────────────────────────┐
│                 Host device                  │
│  ┌────────────────────────────────────────┐  │
│  │           Quick Ticket Maker           │  │
│  │  Generate tab │ Tickets tab │ Share    │  │
│  │  Secure local store + image store      │  │
│  └───────┬────────────────────────┬───────┘  │
└──────────┼────────────────────────┼──────────┘
           │ HTTPS                  │ PNG or PDF via OS share sheet
           ▼                        ▼
  ┌────────────────────┐     Guest's phone / chat app
  │ Firebase           │              │
  │  • Auth (optional) │              │ opens QR link
  │  • Cloud Firestore │              ▼
  │    users/{uid}/…   │   ┌──────────────────────────┐
  │    tickets/{code}  │◀──│ Door: /verify/:id in any  │
  └────────────────────┘   │ browser (no account)      │
                           └──────────────────────────┘
```

Firebase **Storage is deliberately not used.** The project runs on the Spark
plan without Storage initialised, and browser CORS on Storage downloads broke
web share. Flyers are embedded in the Firestore document (Base64) or kept as a
local path instead (commit `4c90706`). `storage.rules` denies everything and is
kept only in case Storage is enabled later.

**Current boundaries**

- **No custom server.** There is no first-party API, Cloud Function, or admin
  backend. The client talks to Firebase directly.
- **Verification trusts Firestore rules, not a server.** `tickets/{guestCode}`
  is world-readable so the door can verify without an account, and the
  valid → checked-in transition is allowed unauthenticated but constrained by
  rules to that one shape. See [security/threat-model.md](security/threat-model.md).
- **Check-in is single-use and client-initiated.** The first successful
  `/verify/:id` load flips the document; later loads report the earlier
  check-in. Nothing prevents a determined party from replaying the *image* of a
  ticket before its first scan.
- **Accounts are optional.** The guest-first flow saves and shares locally with
  no sign-in. Signing in through Firebase Auth (email/password, Google, Apple)
  adds owner-scoped cloud copies under `users/{uid}/tickets/{id}`.
- **Ticket codes are not cryptographic.** A code is `####-####-###`; it is an
  identifier, not a signed credential.

---

## Logical architecture

The codebase follows a lightweight feature-first layout inspired by clean
architecture, without over-engineering unused layers.

```text
lib/
├── main.dart / app.dart              Bootstrap, Firebase init, providers
├── core/
│   ├── router/app_router.dart        go_router: shell (Generate|Tickets)
│   │                                 + public /verify/:id, /terms, /privacy
│   ├── theme/                        Design tokens, brand #E0405B
│   ├── utils/color_contrast.dart     Readable foreground selection
│   └── widgets/                      Shared pure UI
├── models/ticket_config.dart         Host ticket configuration
├── services/
│   ├── secure_key_value_store.dart   Secure storage + prefs fallback
│   └── secure_storage_service.dart   TicketConfig persistence
└── features/
    ├── account/                      Legal document pages
    ├── auth/                         AuthCubit, auth gate, pending actions
    ├── generate/                     GenerateCubit, preview widgets
    ├── tickets/
    │   ├── data/                     Local repo, image store/codec,
    │   │                             raster export, share, cloud sync,
    │   │                             payload, public verify
    │   └── presentation/             TicketsCubit, list, detail, share dialog
    ├── scan/                         ScanPage — built, not yet routed
    └── verify/                       TicketVerificationScreen
```

### Layering rules

| Layer | May depend on | Must not depend on |
| --- | --- | --- |
| `presentation` | `domain`, `data` repositories, `core` | Unrelated features’ internals |
| `data` | `domain`, platform SDKs (Firestore, storage, files) | Widgets outside raster export |
| `domain` | Dart / equatable only (prefer) | Flutter UI widgets where avoidable |
| `core` | Flutter / shared packages | Feature-specific business rules |

---

## Runtime composition

1. `main()` initialises Flutter bindings and Firebase, then runs `TicketMakerApp`.
2. `TicketMakerApp` provides `AuthCubit` and `TicketsCubit` and configures
   `MaterialApp.router` with `AppTheme` and `appRouter`. Repositories and stores
   are injectable so tests can supply fakes.
3. Public routes sit **outside** the shell: `/verify/:id`, `/terms`, `/privacy`.
4. `StatefulShellRoute.indexedStack` hosts the two signed-in-optional tabs:
   - `/generate` → `GeneratePage` (provides `GenerateCubit`)
   - `/tickets` → `TicketsPage`, with `/tickets/:ticketId` → `TicketDetailPage`
5. `GenerateCubit` owns the mutable draft; `TicketsCubit` owns the saved list.

### Core journey data flow

`GenerateCubit` holds the draft → `TicketPayload` builds the
`https://quick-ticket-maker-sandbox.web.app/verify/<code>` QR string → save writes through
`TicketLocalRepository` (secure) and publishes a public `tickets/{guestCode}`
document via `TicketCloudSync` → share asks for a format and either rasterises
`SavedTicketView` to PNG or draws a PDF from the ticket model, handing the bytes
to `TicketShareTransport` → the door opens `/verify/:id`, which reads the public
document and performs a single-use check-in.

---

## Local persistence and the secure-storage fallback chain

Guest ticket data is sensitive under
[`.cursor/rules/ticket-security.mdc`](../.cursor/rules/ticket-security.mdc), so
it must not sit in plaintext `SharedPreferences`. `SecureKeyValueStore` is the
single seam that enforces this:

1. **Preferred:** `FlutterSecureStorage` (Keychain / EncryptedSharedPreferences /
   WebCrypto).
2. **Fallback:** `SharedPreferences`, entered only when the secure plugin is
   genuinely unavailable — `MissingPluginException`, `PlatformException`, or
   `UnsupportedError`.

The fallback exists because a stale `web_plugin_registrant.dart` left
`flutter_secure_storage` unregistered on Flutter web and threw
`MissingPluginException` at runtime, losing saved tickets. It is a documented
exception rather than a licence to store plaintext: `scripts/build_web.sh` fails
the build if the registrant omits the plugin, so the fallback should never be
reached on a correctly built web bundle.

`TicketLocalRepository` performs a one-time migration of any pre-existing
plaintext ticket list into the secure store and then clears the legacy key.
Ticket images live in `TicketImageStore` (files on device, `SharedPreferences`
index for non-sensitive paths only).

---

## State management

- Pattern: **Cubit** (`flutter_bloc`)
- State objects: `GenerateState`, `TicketsState`, `AuthState` (all Equatable)
- Domain entities: `Ticket`, `TicketConfig` (immutable `copyWith`)

### Primary commands (`GenerateCubit`)

| Method | Effect |
| --- | --- |
| `cycleQrColors()` / `toggleQrShape()` | QR palette and square ↔ circle modules |
| `cycleBackgroundColors()` / `setTopBackgroundGradient()` / `applyTopBackgroundSolid()` | Card gradients |
| `applyCategoryPalette(category)` | Apply a category's preset look |
| `updateTitle()` / `updateSubtitle()` / `updateVenue()` / `updateHeaderLabel()` | Editable event metadata |
| `setEventDateTime(eventAt)` | Event date/time and their display labels |
| `setImagePath()` / `setPickedImage()` | Flyer from assets or the picker |
| `ensureTicketPayload()` | Guarantee a code and its `/t/<code>` QR string |
| `resetToDefault()` / `clearMessage()` | Reset draft; clear one-shot UI message |

Date labels are formatted by `formatDateLabel` (persisted short form),
`formatFullDateLabel` (`Friday, 31 July 2026`), and `formatCompactDateLabel`
(`Fri, 31 Jul 2026`), the last two chosen at layout time by `TicketDateText`.

---

## Navigation

Implemented with `go_router`:

- Shell preserves tab state via `indexedStack`; bottom `NavigationBar` switches branches
- Route constants live on page classes (`routePath`, `routeName`)
- `/verify/:id` is a public deep link reachable without the shell or an account,
  so a scanned QR opens straight into verification

---

## UI composition (Generate)

1. **TicketHeaderSection** — QR, `TICKET ID` label, and stub controls
2. **TicketPerforation** — visual tear line
3. **TicketDetailsSection** — flyer, `ABOUT THIS EVENT`, date/time row, `Scan at
   entrance` hint, and the `Powered by Quick Ticket` footer

`SavedTicketView` is the read-only twin of this composition and is what the PNG
export rasterises, so the shared image matches the preview. The PDF is drawn
independently by `TicketPdfExport` from the same ticket model, so it needs no
painted widget and can be shared from the list as well as the detail page.

Shared visual language is defined in `AppColors` / `AppTheme` (Outfit + Readex
Pro + Space Mono, **bundled as assets** rather than fetched at runtime — see
`test/bundled_fonts_test.dart`).

---

## External dependencies (runtime)

| Package | Role | Trust notes |
| --- | --- | --- |
| `flutter_bloc` | State management | Official bloc ecosystem |
| `go_router` | Declarative routing | Flutter favorite / widely used |
| `qr_flutter` / `qr` | QR rendering | Local generation; no network |
| `mobile_scanner` | Door-side QR scanning | Camera permission required |
| `firebase_core` / `firebase_auth` / `cloud_firestore` | Auth and ticket documents | Client keys are public; rules are the control |
| `google_sign_in` / `sign_in_with_apple` | Social sign-in | Optional providers |
| `flutter_secure_storage` | Encrypted local store | Fallback chain above |
| `shared_preferences` | Non-sensitive indexes, fallback store | Plaintext — never for ticket data by default |
| `share_plus` / `path_provider` / `image` / `image_picker` | PNG export and share | Local file access |
| `pdf` / `printing` | Printable ticket PDF and its share sheet | Document built in memory; only the PDF standard fonts and the app's bundled typefaces are used, never a font CDN |
| `geolocator` / `geocoding` | Venue convenience | Location permission required |
| `google_fonts` | Typography | Resolves from bundled assets; runtime fetch not relied on |
| `equatable` | Value equality | Pure Dart |

Network use is Firebase, optional remote flyer images, and (only if an asset is
ever missing) fonts. Treat remote media as untrusted input — see threat model.

---

## Quality attributes (ISO/IEC 25010 mapping)

| Characteristic | Approach |
| --- | --- |
| Maintainability | Feature modules, small widgets, Cubit isolation |
| Reliability | Analyzer + unit/widget tests as merge gates; drift guards for docs and release config |
| Security | Secure local storage, deny-by-default Firestore rules, secrets ban, disclosure policy |
| Usability | Material 3, clear primary actions, responsive date/label handling |
| Portability | Flutter multi-platform targets; web share and secure-storage fallbacks |
| Performance | Lightweight local state; avoid unnecessary rebuilds |

---

## Still unbuilt

Documented for planning only — **not current features**:

- Server-side ticket issuance and signed payloads (today a code is an
  identifier; validity is a Firestore document, not a signature)
- App Check enforcement, which would close unauthenticated public writes
- Shared/host-side collections, seating, inventory, or payments
- Push notifications
- Admin console and door-staff accounts
- An in-app scanner entry point. `lib/features/scan/presentation/pages/scan_page.dart`
  exists and uses `mobile_scanner`, but no route or navigation reaches it — the
  door path today is a phone camera opening `/verify/:id` in a browser.

What earlier revisions of this document listed as unbuilt has since shipped:
local persistence (`TicketLocalRepository`), optional auth (`AuthCubit`),
verification (`/verify/:id`), PNG export and share (`TicketShareHelper`), and
editable event fields.

When adding to this list, update this document, the threat model, and the
privacy notice in the same change set. `test/docs_accuracy_test.dart` fails if
these documents drift back to describing a preview-only demo.
