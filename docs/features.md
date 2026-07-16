# Features and functions

Functional specification for Quick Ticket Maker **as implemented on `main`**.

This document is the source of truth for shipped behaviour. Marketing language must not exceed this specification.

---

## 1. Product summary

Quick Ticket Maker lets a user **preview and visually customize** an event ticket, including a QR code. It is a client-side design tool, not a complete ticketing platform.

---

## 2. Actors

| Actor | Description |
| --- | --- |
| End user | Person running the app on a supported device |
| Maintainer | Inject engineer with repository access |

There is no authenticated end-user role in the current release.

---

## 3. Application shell

### 3.1 Bottom navigation

| Destination | Route | Description |
| --- | --- | --- |
| Generate | `/generate` | Ticket designer (default) |
| Tickets | `/tickets` | Sample tickets list |

Shell behaviour:

- Uses `StatefulShellRoute.indexedStack` so tab UI state is retained while switching.
- App bars are provided by each page.

---

## 4. Generate feature

### 4.1 Ticket preview layout

The Generate page shows a scrollable ticket composed of:

1. **Header / stub region** (top gradient)
2. **Perforation** (side notches + dashed divider)
3. **Details region** (bottom gradient)

### 4.2 Default sample content

| Field | Default |
| --- | --- |
| Title | Circu Du Freak |
| Subtitle | Vision & Sound Experience |
| Date label | Sat, Jul 18 |
| Time label | 8:00 PM |
| Ticket code | 1234-5678-910 |
| Initial QR data | LinkedIn URL sample (until Generate is pressed) |
| Image | `https://picsum.photos/seed/695/600` |
| QR shape | Circle modules/eyes |
| QR colors | Error / warning theme colors |

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

#### F-GEN-004 — Generate ticket code and QR payload

- **Trigger:** “Generate Qr Code” button.
- **Behaviour:**
  - Creates a code formatted `####-####-###`
  - Sets `qrData` to `https://ticketmaker.app/t/<code>`
  - Shows a snackbar: `QR code generated`
- **Acceptance:** Code label and QR content both reflect the new values.
- **Note:** The URL host is illustrative; no backend is guaranteed to resolve it.

#### F-GEN-005 — Cycle background gradients

- **Trigger:** “Bg color” controls (header and details regions).
- **Behaviour:** Cycles predefined gradient pairs for top and derived bottom gradients.
- **Acceptance:** Both ticket regions update visually.

#### F-GEN-006 — Refresh event image

- **Trigger:** Photo icon on the event image.
- **Behaviour:** Loads a new `picsum.photos` URL with a random seed.
- **Acceptance:** Image widget attempts to load the new URL; broken images show a fallback icon.

#### F-GEN-007 — Display event metadata

- Shows title, subtitle, date, and time labels from state.
- **Current limitation:** Fields are not editable in the UI.

#### F-GEN-008 — Unfocus on background tap

- Tapping outside inputs dismisses the soft keyboard / primary focus (defensive UX for future forms).

---

## 5. Tickets feature

#### F-TKT-001 — List sample tickets

- Displays two hardcoded sample tickets with title, subtitle, schedule text, and code.
- Row tap handler is a no-op placeholder.

#### F-TKT-002 — Persistence

- **Not implemented.** Tickets created on Generate are not saved to the Tickets tab.

---

## 6. Non-functional behaviour

| ID | Requirement | Current approach |
| --- | --- | --- |
| NFR-001 | Analyze clean | `flutter analyze` |
| NFR-002 | Automated tests | Widget test covers Generate branding/controls |
| NFR-003 | No committed secrets | Enforced by policy + `.gitignore` |
| NFR-004 | Accessibility | Material widgets; further a11y audits recommended before production release |
| NFR-005 | Offline | Core UI works offline; remote images/fonts may fail without network |

---

## 7. Out-of-scope functions (explicit)

The following are **not** provided in the current release:

- Account registration / login
- Payment processing
- Ticket inventory / seating maps
- Admission scanning and validation
- Push notifications
- Cloud sync
- PDF/PNG export and system share sheets
- Admin console

---

## 8. Traceability

| Function | Primary code location |
| --- | --- |
| F-GEN-001..008 | `lib/features/generate/` |
| Cubit commands | `presentation/bloc/generate_cubit.dart` |
| QR widget | `presentation/widgets/generate_qr_code.dart` |
| F-TKT-001 | `lib/features/tickets/presentation/pages/tickets_page.dart` |
| Navigation | `lib/core/router/app_router.dart` |
