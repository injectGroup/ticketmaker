# Quick Ticket Maker

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-lightgrey)](LICENSE)
[![Security Policy](https://img.shields.io/badge/Security-Policy-green)](SECURITY.md)
[![Code of Conduct](https://img.shields.io/badge/Contributor-Covenant-4baaaa)](CODE_OF_CONDUCT.md)

**Quick Ticket Maker** is a Flutter application for designing and previewing event-style tickets with customizable QR codes. It is owned and maintained by [Inject](https://github.com/injectGroup).

> **Scope note:** This repository is a ticket *design and preview* client. It does not currently provide ticket sales, payment processing, admission scanning, or a production ticketing backend.

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

The application presents a two-tab experience:

1. **Generate** — customize a live ticket preview (QR style, gradients, image, ticket code).
2. **Tickets** — browse a sample ticket list (placeholder until persistence is added).

---

## Features

### Generate

- Live QR code preview with configurable eye and data-module colors
- Toggle QR module/eye shape between circle and square
- Cycle ticket background gradients
- Generate a new ticket code (`XXXX-XXXX-XXX`) and QR payload
- Refresh the event image from a remote placeholder provider
- Ticket perforation UI (side notches + dashed divider)
- Event detail strip (title, subtitle, date, time)

### Tickets

- Sample “My Tickets” list UI
- Navigation shell shared with Generate

### Explicitly out of scope (current release)

- User authentication and authorization
- Payment or e-commerce checkout
- Persistent ticket storage / sync
- QR scanning / door admission workflows
- Editing event metadata via forms
- Export, share, or print pipelines

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
  app.dart                 # MaterialApp.router root
  main.dart                # Entry point
  core/
    router/                # go_router shell navigation
    theme/                 # App colors and typography
    widgets/               # Shared UI (e.g. dashed divider)
  features/
    generate/              # Ticket generator (domain + Cubit + UI)
    tickets/               # Tickets list UI
docs/                      # Product, security, and compliance docs
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
