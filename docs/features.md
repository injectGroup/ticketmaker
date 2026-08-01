# Features and functions

Functional specification for Quick Ticket Maker **as implemented on the V1
personal ticket share milestone**.

This document is the source of truth for shipped behaviour. Marketing language
must not exceed this specification. `test/docs_accuracy_test.dart` guards it
against drifting back to the preview-only description.

---

## 1. Product summary

Quick Ticket Maker lets a host design an event ticket with a QR code, save it,
share it as an image, and have it verified at the door. It is a personal-scale
tool: no payments, no inventory, no seating.

---

## 2. Actors

| Actor | Description | Authentication |
| --- | --- | --- |
| Host | Designs, saves, and shares tickets | Optional — guest-first |
| Guest | Receives the ticket image and presents it | None |
| Door staff | Scans the QR and reads the verdict | None |
| Maintainer | Inject engineer with repository access | GitHub |

Accounts are **optional**. The full create → save → share → verify journey works
without signing in; Firebase Auth adds owner-scoped cloud copies of a host's
tickets.

---

## 3. Application shell

### 3.1 Routes

| Route | In shell? | Description |
| --- | --- | --- |
| `/generate` | Yes (tab 1, default) | Ticket designer |
| `/tickets` | Yes (tab 2) | Saved tickets list |
| `/tickets/:ticketId` | Nested | Saved ticket detail and share |
| `/verify/:id` | No — public | Door verification for a scanned code |
| `/terms`, `/privacy` | No — public | Legal documents |

Shell behaviour:

- Uses `StatefulShellRoute.indexedStack` so tab UI state is retained while switching.
- Bottom `NavigationBar` has two destinations: Generate and Tickets.
- Public routes sit outside the shell so a scanned link opens straight into
  verification without any tab chrome or account.

---

## 4. Generate feature

### 4.1 Ticket preview layout

The Generate page shows a scrollable ticket composed of:

1. **Header / stub region** — QR, `TICKET ID` label and code, stub controls
2. **Perforation** — side notches + dashed divider
3. **Details region** — flyer, `ABOUT THIS EVENT`, date/time row, `Scan at
   entrance` hint, `Powered by Quick Ticket` footer

### 4.2 Default content

| Field | Default |
| --- | --- |
| Header label | GUEST PASS |
| Title | Ejike's Birthday Bash |
| Subtitle | VIP Guest Pass |
| Venue | Private gathering |
| Date / time labels | Derived from "now" at first launch |
| Ticket code | Randomised `####-####-###` |
| QR data | `https://quick-ticket-maker-sandbox.web.app/verify/<code>` |
| QR style | Brand pink eyes, white circular modules, dark plum card |

These V1 defaults are pinned by `.cursor/rules/workflow-integrity.mdc` §2 and
by `test/ticket_personal_defaults_test.dart`.

### 4.3 Functions

#### F-GEN-001 — Display QR code

- **Description:** Render a QR code from the current `qrData` string.
- **UI:** Centered in the header region via `GenerateQrCode`.
- **Acceptance:** QR updates when `qrData`, colors, or shape change.

#### F-GEN-002 — Change QR colors

- **Trigger:** “Change color” control.
- **Behaviour:** Cycles through a fixed palette of eye/module color pairs.
- **Acceptance:** QR colors update immediately without restarting the app.

#### F-GEN-003 — Change QR shape

- **Trigger:** “Change shape” control.
- **Behaviour:** Toggles `isSquare` between `false` (circle) and `true` (square).
- **Acceptance:** Both eye and data-module shapes update together.

#### F-GEN-004 — Ticket code and QR payload

- **Behaviour:**
  - A code formatted `####-####-###` exists from first build; `ensureTicketPayload()`
    guarantees a code and matching QR string before save or share.
  - `qrData` is `https://quick-ticket-maker-sandbox.web.app/verify/<code>`, built
    by `TicketPayload`.
- **Acceptance:** Code label and QR content always reflect the same code.
- **Note:** The QR string carries only the code — no guest PII. The link resolves
  to `/verify/:id` (see F-VER-001).
- **Host caveat:** `TicketPayload.host` is the Firebase Hosting domain above
  because that is what resolves today. `ticketmaker.app`, `www.ticketmaker.app`,
  `localhost`, and bare codes are accepted when *parsing* a scanned payload, so
  older tickets still verify. Which host is canonical at launch is open decision
  D6 in [implementation-plan.md](../instructions/implementation-plan.md).

#### F-GEN-005 — Cycle background gradients

- **Trigger:** “Bg color” controls and the top-background customizer sheet.
- **Behaviour:** Cycles predefined gradient pairs, or applies a chosen solid.
  Foreground colors are re-derived for contrast via `core/utils/color_contrast.dart`.
- **Acceptance:** Both ticket regions update visually and text stays readable.

#### F-GEN-006 — Set the event flyer

- **Trigger:** Photo control on the event image.
- **Behaviour:** Picks an image from the device (`image_picker`) or uses the
  bundled placeholder asset; remote URLs are still supported for existing tickets.
- **Acceptance:** The chosen image renders in the preview and in the exported PNG;
  broken remote images show a fallback icon.

#### F-GEN-007 — Edit event metadata

- Title, subtitle, header label, and venue are editable in the UI.
- Date and time are set together via `setEventDateTime`, which also refreshes the
  display labels.
- `applyCategoryPalette` applies a category's preset look; `resetToDefault`
  returns to the V1 defaults.

#### F-GEN-008 — Save the ticket

- **Trigger:** “Save Ticket”.
- **Behaviour:** Writes the ticket to encrypted local storage, stores its flyer
  in the durable image store, publishes the public `tickets/{code}` document for
  door verification, and — if signed in — mirrors it under
  `users/{uid}/tickets/{id}`.
- **Acceptance:** The ticket appears in the Tickets tab and survives a restart.

#### F-GEN-009 — Unfocus on background tap

- Tapping outside inputs dismisses the soft keyboard / primary focus.

---

## 5. Tickets feature

#### F-TKT-001 — List saved tickets

- Displays the host's saved tickets (title, subtitle, schedule text, code) from
  `TicketLocalRepository`; empty state when nothing is saved yet.
- Tapping a row opens `/tickets/:ticketId`.

#### F-TKT-002 — Persistence

- **Implemented.** Tickets are persisted in `FlutterSecureStorage` via
  `SecureKeyValueStore`, with a one-time migration of any legacy plaintext list
  and a `SharedPreferences` fallback only where the secure plugin is
  unavailable. Flyer bytes live in `TicketImageStore`.

#### F-TKT-003 — Ticket detail

- Shows the read-only `SavedTicketView` — the same composition the PNG export
  rasterises, so the shared image matches what the host saw.

#### F-TKT-004 — Export and share

- **Trigger:** Share Ticket, from either the ticket detail page or a My Tickets
  row.
- **Behaviour:** The host is asked for a format first — **Share as image** or
  **Share as PDF** — and `TicketShareHelper` produces that format in memory and
  hands the bytes to the platform. Nothing is written to device storage on the
  way to the share sheet.
  - *Image:* `TicketRasterExport` rasterises the ticket to PNG (pure Dart, no
    canvas/CORS dependency), degrading to a JPEG capture and finally to a link
    share if the ticket cannot be painted.
  - *PDF:* `TicketPdfExport` draws an A4 page from the ticket model — the
    details as real text — using the app's bundled typefaces, so it stays
    legible when printed. The QR code is embedded as a high-resolution image
    in print colours: dark modules on white, with a quiet zone, whatever
    palette the ticket wears on screen, because a reader will not decode a
    pale or inverted code. Any event photo is embedded, and unusable photo
    bytes are dropped rather than failing the export.
- **Web:** `WebShareOptionsDialog` offers **Download Ticket Image**, **Share as
  PDF** (Web Share API, falling back to a browser download) and **Copy Share
  Link**.
- **Acceptance:** The recipient gets either a high-resolution image or a
  printable PDF, both with a scannable QR.

---

## 6. Verification feature

#### F-VER-001 — Verify a scanned ticket

- **Trigger:** Any browser opening `/verify/:id` from a scanned QR — no app
  install and no account required.
- **Behaviour:** `TicketPublicVerify` reads the public `tickets/{code}`
  document and reports valid, already checked in, or not found. Missing fields
  fall back to sensible defaults rather than failing the check.
- **Acceptance:** A shared ticket verifies at the door within a couple of seconds.

#### F-VER-002 — Single-use admission

- Admission is **single-use**: the first successful verification flips the
  document to `checked_in` and records the timestamp; subsequent scans report
  that earlier admission instead of admitting again.
- **Limitation:** This detects reuse *after* the first scan. It does not stop a
  guest forwarding the image before anyone has scanned it — the first person
  through the door wins. See
  [security/threat-model.md](security/threat-model.md).

---

## 7. Accounts (optional)

#### F-ACC-001 — Sign in / register

- Firebase Auth with email/password, Google, and Apple.
- `AuthGate` never blocks the core journey; it prompts only where an account is
  genuinely needed, and a **pending action** is replayed after sign-in so the
  host does not lose the step they were on.
- Profile display name/photo can be updated; sign-out returns to the guest flow
  with local tickets intact.

---

## 8. Non-functional behaviour

| ID | Requirement | Current approach |
| --- | --- | --- |
| NFR-001 | Analyze clean | `flutter analyze` |
| NFR-002 | Automated tests | Unit + widget suite covering models, cubits, services, verification, routing, release config, and doc accuracy |
| NFR-003 | No committed secrets | Policy + `.gitignore` (`key.properties`, keystores, `.env`) |
| NFR-004 | Accessibility | Material widgets, contrast-derived foregrounds; further a11y audit recommended before wide release |
| NFR-005 | Offline | Core design, save, and share work offline; fonts and assets are bundled. Publishing the public document and door verification need network |
| NFR-006 | Sensitive data at rest | Encrypted secure storage, documented fallback |

---

## 9. Out-of-scope functions (explicit)

The following are **not** provided:

- Payment processing or ticket sales
- Ticket inventory, seating maps, or capacity limits
- Server-side issuance or cryptographically signed payloads
- An in-app scanner entry point — `ScanPage` exists in the codebase but no route
  reaches it; door staff use a phone camera and `/verify/:id`
- Push notifications
- Admin console or door-staff accounts
- Printing from inside the app — the shared PDF is handed to the OS, which owns
  the print dialog

---

## 10. Traceability

| Function | Primary code location |
| --- | --- |
| F-GEN-001..009 | `lib/features/generate/` |
| Cubit commands | `features/generate/presentation/bloc/generate_cubit.dart` |
| QR widget / payload | `generate/presentation/widgets/generate_qr_code.dart`, `tickets/data/ticket_payload.dart` |
| F-TKT-001, F-TKT-003 | `features/tickets/presentation/` (`tickets_page.dart`, `ticket_detail_page.dart`, `saved_ticket_view.dart`) |
| F-TKT-002 | `tickets/data/ticket_local_repository.dart`, `services/secure_key_value_store.dart`, `tickets/data/ticket_image_store.dart` |
| F-TKT-004 | `tickets/data/ticket_raster_export.dart`, `ticket_pdf_export.dart`, `ticket_share_helper.dart`, `ticket_share_transport.dart`, `tickets/presentation/widgets/share_format_dialog.dart` |
| F-GEN-008 cloud copy | `tickets/data/ticket_cloud_sync.dart` |
| F-VER-001..002 | `tickets/data/ticket_public_verify.dart`, `features/verify/presentation/pages/ticket_verification_screen.dart` |
| F-ACC-001 | `features/auth/` |
| Navigation | `lib/core/router/app_router.dart` |
