# Quick Ticket Maker

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-lightgrey)](LICENSE)
[![Security Policy](https://img.shields.io/badge/Security-Policy-green)](SECURITY.md)
[![Code of Conduct](https://img.shields.io/badge/Contributor-Covenant-4baaaa)](CODE_OF_CONDUCT.md)

**Quick Ticket Maker** is a Flutter application for designing event tickets with customizable QR codes, sharing them as images, and verifying them at the door. It is owned and maintained by [Inject](https://github.com/injectGroup).

> **Scope note:** This is a personal-scale ticketing tool. Tickets are saved on the host's device and verified through a public link backed by Cloud Firestore — there is no custom server, no payments or ticket sales, and no seating or inventory management. Ticket codes are identifiers, not cryptographically signed credentials; see [docs/security/threat-model.md](docs/security/threat-model.md) before using it where admission has real value.

---

## Table of contents

- [Overview](#overview)
- [Features](#features)
- [Supported platforms](#supported-platforms)
- [Quick start](#quick-start)
- [Project structure](#project-structure)
- [Documentation](#documentation)
- [Security](#security)
- [Compliance](#compliance)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

---

## Overview

| Item | Detail |
| --- | --- |
| Product name | Quick Ticket Maker |
| Repository | [`injectGroup/ticketmaker`](https://github.com/injectGroup/ticketmaker) |
| Package name | `ticket_maker` |
| Current version | `1.0.0+1` |
| Primary language | Dart / Flutter |
| State management | `flutter_bloc` (Cubit) |
| Navigation | `go_router` |
| QR rendering | `qr_flutter` |
| Backend | Firebase Auth (optional) + Cloud Firestore + Hosting; no custom server |

The application presents a two-tab experience plus a public verification link:

1. **Generate** — design the ticket and save it (QR style, gradients, flyer, event details).
2. **Tickets** — open a saved ticket and share it as an image.
3. **`/verify/:id`** — what a scanned QR opens, in any browser, with no account.

---

## Features

### Generate

- Live QR preview with configurable eye/module colors and circle ↔ square shapes
- Editable event details: title, subtitle, header label, venue, date and time
- Ticket background gradients, category palettes, and contrast-aware text colors
- Flyer image from the device gallery or the bundled placeholder
- Ticket code (`XXXX-XXXX-XXX`) with a matching `/verify/<code>` QR payload on the Firebase Hosting domain
- Ticket perforation UI (side notches + dashed divider)

### Tickets

- Saved tickets persisted in **encrypted** local storage, with a detail page
- Share in the format the recipient needs: a PNG rendered in pure Dart, or a printable PDF drawn as text plus a QR code in scanner-safe print colours
- Both formats are built in memory and handed straight to the native share sheet — no copy is saved to the device first — with a Web Share API path and browser download fallback on web

### Verify

- Public `/verify/:id` route resolves a scanned code against Firestore
- **Single-use check-in:** the first successful scan admits, later scans report the earlier admission

### Accounts (optional)

- Firebase Auth with email/password, Google, and Apple
- Guest-first: nothing in the core journey requires signing in; signing in adds owner-scoped cloud copies

### Explicitly out of scope (current release)

- Payment or e-commerce checkout
- Ticket inventory, seating maps, or capacity limits
- Server-side issuance or cryptographically signed ticket payloads
- An in-app scanner entry point (door staff use a phone camera and the verify link)
- Push notifications
- Admin console or door-staff accounts
- Printing from inside the app (the shared PDF hands off to the OS print dialog)

See [docs/features.md](docs/features.md) for a complete functional description.

---

## Supported platforms

Flutter multi-platform targets included in this repository:

| Platform | Status |
| --- | --- |
| iOS | Supported |
| Android | Supported |
| Web | Supported |
| macOS | Supported |
| Windows | Supported |
| Linux | Supported |

---

## Quick start

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.22+** (project developed on Flutter 3.44 / Dart 3.12)
- Xcode (iOS/macOS), Android Studio / SDK (Android), or Chrome (web)
- Git with SSH access to `injectGroup` repositories

### Clone and run

```bash
git clone git@github.com:injectGroup/ticketmaker.git
cd ticketmaker
flutter pub get
flutter analyze
flutter test
flutter run
```

Device selection:

```bash
flutter devices
flutter run -d <device_id>
```

Full setup, toolchain, and quality gates: [docs/getting-started.md](docs/getting-started.md).

---

## Project structure

```text
lib/
  app.dart                 # MaterialApp.router root, providers
  main.dart                # Entry point, Firebase init
  core/
    router/                # go_router shell + public routes
    theme/                 # App colors and typography
    utils/                 # Contrast helpers
    widgets/               # Shared UI (e.g. dashed divider)
  models/                  # TicketConfig
  services/                # Secure key-value store and ticket config storage
  features/
    auth/                  # Optional accounts, auth gate, pending actions
    generate/              # Ticket designer (domain + Cubit + UI)
    tickets/               # Saved tickets: data layer + list, detail, share
    verify/                # Public door verification screen
    account/               # Legal document pages
assets/fonts/              # Bundled typefaces (no runtime font fetching)
docs/                      # Product, security, and compliance docs
instructions/              # Implementation plan and phase checklists
.github/                   # Issue/PR templates and automation config
.taskmanager/              # Local TaskManager backup (project tracking)
```

Architecture details: [docs/architecture.md](docs/architecture.md).

---

## Documentation

| Document | Purpose |
| --- | --- |
| [docs/README.md](docs/README.md) | Documentation index |
| [docs/getting-started.md](docs/getting-started.md) | Environment setup and first run |
| [docs/architecture.md](docs/architecture.md) | System design and module boundaries |
| [docs/features.md](docs/features.md) | Functional specification |
| [docs/development.md](docs/development.md) | Coding standards and quality gates |
| [docs/privacy.md](docs/privacy.md) | Privacy notice (ISO/IEC 27701 aligned) |
| [docs/security/](docs/security/) | Information security controls |
| [docs/compliance/iso-alignment.md](docs/compliance/iso-alignment.md) | ISO control mapping |
| [SECURITY.md](SECURITY.md) | Vulnerability disclosure policy |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution process |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Community standards |
| [SUPPORT.md](SUPPORT.md) | How to get help |

---

## Security

Security reporting and handling follow GitHub’s recommended private disclosure model and are aligned with **ISO/IEC 29147** (vulnerability disclosure) and **ISO/IEC 30111** (vulnerability handling processes).

- **Do not** open public issues for security vulnerabilities.
- Report via the process in [SECURITY.md](SECURITY.md).
- Engineering controls and secure development guidance: [docs/security/](docs/security/).

---

## Compliance

This project’s documentation and operating practices are mapped to relevant ISO families used by Inject for software delivery:

| Standard | Focus in this repository |
| --- | --- |
| ISO/IEC 27001 | Information security management controls (policy, access, secrets, logging) |
| ISO/IEC 27002 | Practical security control guidance referenced in security docs |
| ISO/IEC 27701 | Privacy information management (privacy notice and data minimization) |
| ISO/IEC 29147 | Vulnerability disclosure |
| ISO/IEC 30111 | Vulnerability handling |
| ISO/IEC/IEEE 12207 | Software life cycle processes (plan → build → verify → release) |
| ISO/IEC 25010 | Product quality characteristics (maintainability, security, usability) |

See [docs/compliance/iso-alignment.md](docs/compliance/iso-alignment.md).

> Documentation alignment does **not** by itself constitute a formal ISO certification claim for the product or organization.

---

## Contributing

Contributions are welcome from authorized Inject collaborators. Please read:

1. [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
2. [CONTRIBUTING.md](CONTRIBUTING.md)
3. [docs/development.md](docs/development.md)

All contributions must pass `flutter analyze` and `flutter test` before review.

---

## Support

See [SUPPORT.md](SUPPORT.md) for channels and response expectations.

---

## License

Copyright © Inject / injectGroup. All rights reserved.

This software is proprietary. See [LICENSE](LICENSE) for terms. Unauthorized copying, distribution, or use is prohibited except as expressly permitted in writing by Inject.
