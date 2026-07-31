# Phase 2 — TDD coverage for untested logic

**Goal:** every model, cubit, repository, and service named by the TDD rule has a
spec. Five units currently have none.

**Baseline:** 51 tests green as of 31 July 2026.

**Branch/commit naming:** `phase/2-logic-test-coverage`, with `subtask/2.x-...` commits.

---

## Coverage audit (how the gaps were found)

Each symbol was searched across `test/`:

| Unit | Existing coverage |
| --- | --- |
| `TicketsCubit` | `tickets_cubit_test.dart` |
| `TicketImageStore` | `ticket_image_store_test.dart` + 2 others |
| `TicketLocalRepository` | `secure_storage_fallback_test.dart` + 2 others |
| `TicketPayload` | `ticket_payload_test.dart` |
| `TicketCloudSync` | `ticket_cloud_sync_storage_free_test.dart` |
| `GenerateCubit` | `ticket_personal_defaults_test.dart`, `widget_test.dart` |
| **`TicketConfig`** | **none** |
| **`SecureStorageService`** | **none** |
| **`AuthCubit`** | **none** |
| **`TicketPublicVerify`** | **none** |
| **`appRouter`** | **none** |

> The existing "verifyAndCheckIn admits once then rejects reuse" test exercises
> `TicketsCubit.verifyAndCheckIn` (the host-side local path). The public door
> path in `TicketPublicVerify` is a **separate implementation against Firestore**
> and is not covered by it.

---

## 2.0 Test-harness prerequisite

`TicketPublicVerify({FirebaseFirestore? firestore})` already accepts an injected
instance, so it needs no production change — only a fake Firestore.

- [x] Add `fake_cloud_firestore` to `dev_dependencies` (not present today).
- [x] Add `mock_exceptions` as a direct dev dependency too — it ships with
      `fake_cloud_firestore` but must be declared to satisfy
      `depend_on_referenced_packages`, and it is what lets a spec force a
      Firestore write to be rejected.
- [x] Confirm `flutter test` still green after `flutter pub get`.

---

## 2.1 `TicketConfig` model specs → `test/ticket_config_test.dart`

Target: `lib/models/ticket_config.dart`.

- [x] Step 1 (failing specs first):
  - `TicketConfig.v1Default(guestName: ...)` yields event name
    **"Ejike's Birthday Bash"**, subtitle **"VIP Guest Pass"**, and a payload URL
    on **`https://ticketmaker.app`**. This test doubles as a guard on the V1
    defaults the workflow-integrity rule protects.
  - `toJsonString()` → `fromJsonString()` round-trips every field, with
    `generatedAt` preserved to the same instant.
  - `fromJsonString()` on malformed JSON and on JSON missing keys behaves as
    specified (throws a clear error or returns defaults — decide, then pin it).
- [x] Step 2: minimal implementation changes, if any spec fails.
- [x] Step 3: `flutter test` → green.
- [x] Step 4: tick this item.

---

## 2.2 `SecureStorageService` specs → `test/secure_storage_service_test.dart`

Target: `lib/services/secure_storage_service.dart`, which delegates to
`SecureKeyValueStore`.

- [x] Step 1 (failing specs first):
  - `saveTicket` then `getTicket` returns an equal `TicketConfig`.
  - `getTicket` for an unknown id returns `null` rather than throwing.
  - `deleteTicket` removes only the targeted id.
  - `clearAllTickets` removes every stored ticket and leaves unrelated keys
    intact.
  - Corrupt stored JSON is handled without crashing the caller.
- [x] Step 2: implement any missing behaviour.
- [x] Step 3: `flutter test` → green.
- [x] Step 4: tick this item.

> Reuse the mock-storage setup already proven in
> `secure_storage_fallback_test.dart` rather than inventing a second approach.

---

## 2.3 `AuthCubit` specs → `test/auth_cubit_test.dart`

Target: `lib/features/auth/presentation/bloc/auth_cubit.dart`. It takes
`AuthRepository?`, so a hand-written fake repository is enough — no mocking
package required.

- [x] Step 1 (failing specs first):
  - Construction calls `restoreSession`: a fake returning a user ends
    `authenticated`; returning `null` ends `unauthenticated`; throwing also ends
    `unauthenticated` with the user cleared.
  - `signIn` success → `authenticated`, `isSubmitting` false, message
    `'Signed in'`, returns `true`.
  - `signIn` raising `AuthException` → `unauthenticated`, surfaces
    `e.message`, returns `false`.
  - `signIn` raising an unexpected error → generic
    `'Could not sign in. Try again.'`, returns `false`.
  - `signUp` success sets `justSignedUp` true; `clearJustSignedUp` resets it.
  - `setPendingAction` / `takePendingAction`: the action is returned once and
    cleared, and a second call returns `null` (this is the guest → auth resume
    path).
  - `signOut` resets to a bare `unauthenticated` state with no user.
  - `updateProfile` with no signed-in user is a no-op that emits nothing.
- [x] Step 2: implement any missing behaviour.
- [x] Step 3: `flutter test` → green.
- [x] Step 4: tick this item.

---

## 2.4 `TicketPublicVerify` specs → `test/ticket_public_verify_test.dart`

Target: `lib/features/tickets/data/ticket_public_verify.dart`, the door-side
path behind `/verify/:id`. Seed `FakeFirebaseFirestore` and inject it.

- [x] Step 1 (failing specs first):
  - Malformed input (`'not-a-ticket'`) → `invalidPayload`, without a read.
  - Missing `tickets/{code}` document → `notFound`.
  - `status: 'valid'` → `success`, and the document is updated to
    `checkedIn: true` / `status: 'checked_in'` with a `checkedInAt`.
  - Second scan of the same code → `alreadyCheckedIn` (single-use guarantee).
  - Pre-existing `checkedIn: true` with no `status` → `alreadyCheckedIn`.
  - An unrecognised non-empty status (e.g. `'revoked'`) → `alreadyCheckedIn`.
  - A full QR URL and a bare code resolve to the same document.
  - When `hostUid` and `internalTicketId` are present, the owner document under
    `users/{hostUid}/tickets/{internalTicketId}` is synced; when that write
    fails the public admit **still succeeds** (best-effort, per the code).
  - Field fallbacks in `_ticketFromData`: `eventName` → `title` → `'Ticket'`,
    and a missing `qrData` falls back to `TicketPayload.verificationUrl(code)`.
- [x] Step 2: implement any missing behaviour.
- [x] Step 3: `flutter test` → green.
- [x] Step 4: tick this item.

> Observation for later, **not** for this phase: the admit logic is duplicated
> between `TicketsCubit.verifyAndCheckIn` and `TicketPublicVerify`. Once both are
> under test, unifying them becomes safe — but it is a post-V1 refactor, outside
> this milestone's scope.

---

## 2.5 `/verify/:id` deep-link specs → `test/app_router_test.dart`

Target: `lib/core/router/app_router.dart`. `TicketVerificationScreen` accepts an
injectable `verifier`, and the route builder constructs its own, so drive the
route with a fake Firestore behind a real `TicketPublicVerify`.

- [x] Step 1 (failing specs first):
  - `/verify/1234-5678-910` renders `TicketVerificationScreen` with that id.
  - The verification route sits **outside** the bottom-nav shell: no
    `NavigationBar` is shown to a door scanner.
  - `/terms` and `/privacy` render `LegalDocumentPage` with the right titles.
  - The shell starts on Generate, and `/tickets/:ticketId` reaches
    `TicketDetailPage` with the id.
- [x] Step 2: implement any missing behaviour.
- [x] Step 3: `flutter test` → green.
- [x] Step 4: tick this item.

---

## Exit criteria

1. [x] Five new spec files exist and pass.
2. [x] `flutter analyze` clean; `flutter test` 100% green with a higher count
   than 51 — **109 tests passing**, up from 51.
3. [x] No production behaviour changed except where a spec proved a defect.
4. [x] Every box ticked and each subtask logged in `.taskmanager/tasks.json`.

---

## Outcome (31 July 2026)

58 new specs across five files: `ticket_config_test.dart` (9),
`secure_storage_service_test.dart` (9), `auth_cubit_test.dart` (18),
`ticket_public_verify_test.dart` (14), `app_router_test.dart` (8).

**Defect found and fixed.** `SecureStorageService.clearAllTickets` iterated the
key set returned by `readAll()` while deleting from the same store, which threw
`Concurrent modification during iteration`. It now deletes from a snapshot of the
matching keys. Production platforms return a fresh map from the channel, so this
was latent rather than user-visible, but the fallback and mock paths hand back the
live map.

**Route coverage approach.** The `/verify/:id` builder constructs its own
`TicketPublicVerify`, which reaches for `FirebaseFirestore.instance` and cannot
run un-initialised in a test. The specs therefore assert the route table
structurally (path, name, and that verification sits outside the nav shell) and
render `TicketVerificationScreen` directly with an injected verifier over a fake
Firestore. That covers the deep-link contract without restructuring production
code for testability.

**Finding for a later phase, deliberately not acted on here.** `ScanPage`
(`lib/features/scan/presentation/pages/scan_page.dart`) is referenced nowhere —
no route registers it, nothing navigates to it, and no test touches it, despite
declaring `routePath = '/scan'`. Door scanning in practice happens through the
guest's QR opening `/verify/:id`. Decide whether to wire it up or remove it; both
are scope decisions rather than test coverage.
