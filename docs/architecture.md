# Architecture

## Purpose

Describe the software architecture of Quick Ticket Maker for maintainers and reviewers. This document supports ISO/IEC/IEEE 12207 design and ISO/IEC 25010 maintainability goals.

---

## System context

```text
┌─────────────────────────────────────────────┐
│                 User device                 │
│  ┌───────────────────────────────────────┐  │
│  │         Quick Ticket Maker            │  │
│  │  Generate tab │ Tickets tab           │  │
│  └───────────────┬───────────────────────┘  │
└──────────────────┼──────────────────────────┘
                   │ HTTPS (optional)
                   ▼
        Remote image host (picsum.photos)
```

**Current boundaries**

- No first-party backend API
- No authentication service
- No persistent local database
- QR payloads are client-generated strings/URLs for preview only

---

## Logical architecture

The codebase follows a lightweight feature-first layout inspired by clean architecture, without over-engineering unused layers.

```text
lib/
├── main.dart / app.dart          Presentation bootstrap
├── core/                         Cross-cutting concerns
│   ├── router/                   Navigation (go_router shell)
│   ├── theme/                    Design tokens / ThemeData
│   └── widgets/                  Shared pure UI widgets
└── features/
    ├── generate/
    │   ├── domain/entities/      Ticket model
    │   └── presentation/
    │       ├── bloc/             GenerateCubit + state
    │       ├── pages/            GeneratePage
    │       └── widgets/          QR, header, details, perforation
    └── tickets/
        └── presentation/pages/   TicketsPage (sample list)
```

### Layering rules

| Layer | May depend on | Must not depend on |
| --- | --- | --- |
| `presentation` | `domain`, `core` | Unrelated features’ internals |
| `domain` | Dart / equatable only (prefer) | Flutter UI widgets where avoidable |
| `core` | Flutter / shared packages | Feature-specific business rules |

---

## Runtime composition

1. `main()` initializes Flutter bindings and runs `TicketMakerApp`.
2. `TicketMakerApp` configures `MaterialApp.router` with `AppTheme.light` and `appRouter`.
3. `StatefulShellRoute.indexedStack` hosts:
   - `/generate` → `GeneratePage` (provides `GenerateCubit`)
   - `/tickets` → `TicketsPage`
4. `GenerateCubit` owns mutable ticket preview state and emits `GenerateState`.

---

## State management

- Pattern: **Cubit** (`flutter_bloc`)
- State object: `GenerateState` (Equatable)
- Domain entity: `Ticket` (immutable `copyWith`)

### Primary commands (`GenerateCubit`)

| Method | Effect |
| --- | --- |
| `cycleQrColors()` | Rotate QR eye/module color palette |
| `toggleQrShape()` | Square ↔ circle modules/eyes |
| `cycleBackgroundColors()` | Rotate ticket gradients |
| `refreshImage()` | New picsum seed URL |
| `generateTicketCode()` | New code + QR data URL + snackbar message |
| `clearMessage()` | Clear one-shot UI message |

---

## Navigation

Implemented with `go_router`:

- Shell preserves tab state via `indexedStack`
- Bottom `NavigationBar` switches branches
- Route constants live on page classes (`routePath`, `routeName`)

---

## UI composition (Generate)

1. **TicketHeaderSection** — QR and stub controls
2. **TicketPerforation** — visual tear line
3. **TicketDetailsSection** — event imagery and metadata

Shared visual language is defined in `AppColors` / `AppTheme` (Outfit + Readex Pro via `google_fonts`).

---

## External dependencies (runtime)

| Package | Role | Trust notes |
| --- | --- | --- |
| `flutter_bloc` | State management | Official bloc ecosystem |
| `go_router` | Declarative routing | Flutter favorite / widely used |
| `qr_flutter` | QR rendering | Local generation; no network |
| `google_fonts` | Typography | May fetch fonts; cache locally after first load |
| `equatable` | Value equality | Pure Dart |

Network use today is limited to optional remote images and font fetching. Treat both as untrusted input surfaces (see threat model).

---

## Quality attributes (ISO/IEC 25010 mapping)

| Characteristic | Approach |
| --- | --- |
| Maintainability | Feature modules, small widgets, Cubit isolation |
| Reliability | Analyzer + widget tests as merge gates |
| Security | Secrets ban, disclosure policy, secure coding guide |
| Usability | Material 3, clear primary actions, bottom navigation |
| Portability | Flutter multi-platform targets |
| Performance | Lightweight local state; avoid unnecessary rebuilds |

---

## Future extension points (not implemented)

Documented for planning only — **not current features**:

- Repository + local persistence for saved tickets
- Auth and multi-user ownership
- Backend ticket issuance and validation
- Export / share / print
- Editable event form fields

When adding these, update this document, the threat model, and privacy notice in the same change set.
