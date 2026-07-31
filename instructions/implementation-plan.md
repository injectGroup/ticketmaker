# Quick Ticket Maker — V1 Implementation Plan

**Branch:** `feature/v1-personal-ticket-share`
**Milestone:** V1 Personal Ticket Share → Play Console Internal Track
**Prepared:** 31 July 2026
**Baseline verified:** `flutter test` → 51 passing; branch is 108 commits ahead of `main`, 0 behind.

---

## 1. Where the project actually stands

The V1 feature set is functionally complete. The remaining work is release
readiness, test coverage for logic that was built without specs, and truing up
documentation that no longer describes the app.

| Area | State |
| --- | --- |
| Ticket creation, theming, live preview | Built (`features/generate`) |
| PNG export + native/web share | Built (`ticket_raster_export.dart`, `ticket_share_helper.dart`) |
| Local persistence | Built on `FlutterSecureStorage` with a SharedPreferences fallback |
| Public QR verification (`/verify/:id`) | Built (`features/verify`, `ticket_public_verify.dart`) |
| Optional auth + cloud publish | Built (`features/auth`, `ticket_cloud_sync.dart`) |
| Fonts | Bundled as assets; no runtime CDN fetch |
| Android release config | **In flight and uncommitted** — see Phase 1 |
| Test coverage | **109 tests**; the five previously unspecced logic units are now covered (Phase 2 done) |
| Product docs | **Stale** — describe a preview-only app — see Phase 3 |
| Release to `main` | Not started — see Phase 4 |

---

## 2. As-built architecture

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
    ├── auth/                         AuthCubit, auth gate, pending actions
    ├── generate/                     GenerateCubit, preview widgets
    ├── tickets/
    │   ├── data/                     Local repo, image store/codec,
    │   │                             raster export, share, cloud sync,
    │   │                             payload, public verify
    │   └── presentation/             TicketsCubit, list, detail, share dialog
    ├── scan/                         Door-side scanning
    └── verify/                       TicketVerificationScreen
```

**Data flow for the core journey:** `GenerateCubit` holds the draft →
`TicketPayload` builds the `https://ticketmaker.app/t/<code>` QR string →
save writes through `TicketLocalRepository` (secure) and publishes a public
`tickets/{guestCode}` document via `TicketCloudSync` → share rasterises the
`SavedTicketView` to PNG → the door opens `/verify/:id`, which reads the public
document and check-in is single-use.

**Layering rule:** `presentation` → `domain`/`core`; `data` stays behind
repositories; `domain` avoids Flutter widget imports.

---

## 3. Scope guardrails (do not violate)

Per `.cursor/rules/workflow-integrity.mdc`:

- Work only on `feature/v1-personal-ticket-share`; never generate code on `main`.
- No enterprise, commercial, or payment features in this phase.
- Do not alter the hardcoded V1 defaults: host event **"Ejike's Birthday Bash"**,
  subtitle **"VIP Guest Pass"**, base URL **`https://ticketmaker.app`**.
- `applicationId` and version parameters may change **only** as part of the
  Play Console Internal Track preparation in Phase 1.

Per `.cursor/rules/ticket-security.mdc`: no plaintext storage of ticket data
(the documented prefs fallback is the sole exception), no PII in QR payloads,
no hardcoded credentials.

---

## 4. Master checklist

### Phase 1 — Android internal-track release readiness → [phase-1.md](phase-1.md)
- [ ] 1.1 Commit the in-flight release configuration
- [ ] 1.2 Replace debug release signing with an upload keystore
- [ ] 1.3 Fix the on-device app label
- [ ] 1.4 Decide the Gradle `namespace` alignment
- [ ] 1.5 Verify a release App Bundle builds and is not debug-signed

### Phase 2 — TDD coverage for untested logic → [phase-2.md](phase-2.md) ✅ done
- [x] 2.1 `TicketConfig` model specs
- [x] 2.2 `SecureStorageService` specs
- [x] 2.3 `AuthCubit` specs
- [x] 2.4 `TicketPublicVerify` specs
- [x] 2.5 `/verify/:id` deep-link routing specs

### Phase 3 — Documentation and compliance truth-up → [phase-3.md](phase-3.md)
- [ ] 3.1 Rewrite `docs/architecture.md` to match the as-built system
- [ ] 3.2 Record the V1 feature set in `CHANGELOG.md`
- [ ] 3.3 Add structural bugs to `USER_RESEARCH_REPORT.md`
- [ ] 3.4 Sweep `docs/features.md` and `docs/privacy.md` for the same drift

### Phase 4 — Release and merge → [phase-4.md](phase-4.md)
- [ ] 4.1 Full green gate (analyze, test, web plugin check)
- [ ] 4.2 Open the PR to `main`
- [ ] 4.3 Settle the version and tag
- [ ] 4.4 Post-merge notifications and TaskManager backup
- [ ] 4.5 Play Console internal-track upload (operator checklist)

Phase 2 has no dependency on Phase 1 and can proceed in parallel. Phase 4
requires Phases 1–3 complete.

---

## 5. Definition of done for V1

1. `flutter analyze` reports no issues and `flutter test` is 100% green.
2. Every logic unit named in the TDD rule (models, cubits, repositories,
   services) has a spec.
3. A release App Bundle builds, signed with a real upload key.
4. `docs/`, `CHANGELOG.md`, and `USER_RESEARCH_REPORT.md` describe the shipped app.
5. `main` contains the V1 work and the milestone is recorded in TaskManager.

---

## 6. Open decisions (need your call before the affected subtask)

| # | Decision | Status |
| --- | --- | --- |
| D1 | Upload keystore source | **Settled 31 Jul 2026:** generate a new upload keystore locally, with credentials in a gitignored `key.properties` |
| D2 | Gradle `namespace` | **Settled 31 Jul 2026:** align the namespace to `com.agathakakalogical.quickticketmaker` and move `MainActivity.kt` to the matching package path |
| D3 | Version for this release | Open — `pubspec.yaml` says `1.0.0+1`; Gradle now hardcodes `versionCode 1` / `versionName "1.0.0"`; no git tags exist locally despite the changelog citing `v1.0.0` |
| D4 | Merge style for 108 commits | Open — merge commit (keeps granular history) vs. squash (single V1 commit) |
| D5 | Unreachable `ScanPage` | Open — found during Phase 2: `lib/features/scan/presentation/pages/scan_page.dart` is referenced nowhere (no route, no navigation, no test) despite declaring `routePath = '/scan'`. Wire it into the router as a host-side scanner, or remove it |
| D6 | Documented vs. implemented base URL | Open — the workflow-integrity rule names `https://ticketmaker.app` as the V1 base URL, but `TicketPayload.host` and `TicketConfig.v1Default` use `quick-ticket-maker-sandbox.web.app` (the domain that actually resolves). `ticketmaker.app` is accepted as a legacy host when parsing. Confirm which is canonical before launch |

**Execution order chosen:** Phase 2 first (it needs no decisions and protects the
merge), then Phase 1, then Phase 3, then Phase 4.

---

## 7. Working agreement

- Strict TDD for logic: spec first, minimal implementation, `flutter test` green,
  then tick the checklist item.
- Never start a subtask while tests are red or the previous item is unchecked.
- Commit per subtask using `subtask/`, `task/`, or `phase/` naming.
- Log each finished item in `.taskmanager/tasks.json` and keep it staged with
  the code it describes.
