# Phase 3 — Documentation and compliance truth-up

**Goal:** make the published documentation describe the app that actually ships.

**Why this phase exists:** the docs still describe a preview-only demo. Several
statements are now the opposite of the truth, and one of them is in the privacy
notice, which is a compliance concern rather than a cosmetic one.
`docs/architecture.md` itself instructs (line 152) that these documents be
updated in the same change set as the features that landed.

**Branch/commit naming:** `phase/3-docs-truth-up`, with `subtask/3.x-...` commits.
No test-first requirement here: these are documents, not logic. Do not change
behaviour in this phase.

---

## Evidence of drift (verified 31 July 2026)

| File | Line | Stale claim | Reality |
| --- | --- | --- | --- |
| `docs/architecture.md` | 26 | "No first-party backend API" | Firestore public `tickets/{code}` + owner docs |
| `docs/architecture.md` | 27 | "No authentication service" | Firebase Auth with email, Google, Apple |
| `docs/architecture.md` | 28 | "No persistent local database" | `FlutterSecureStorage` + durable image store |
| `docs/architecture.md` | 29 | "QR payloads ... for preview only" | Scanned at the door; single-use check-in |
| `docs/architecture.md` | 38–53 | lib tree omits `auth/`, `scan/`, `verify/`, `tickets/data/`, `services/`, `models/` | All exist |
| `docs/architecture.md` | 142–151 | "Future extension points (not implemented)" lists persistence, auth, backend validation, share/export, editable fields | All five are implemented |
| `docs/features.md` | 22 | "no authenticated end-user role" | Auth is implemented (optional for guests) |
| `docs/features.md` | 96 | "no backend is guaranteed to resolve" the URL | `/verify/:id` resolves it |
| `docs/features.md` | 123–130 | "two hardcoded sample tickets", "Not implemented ... not saved to the Tickets tab" | Saving is the core journey |
| `docs/privacy.md` | 61 | third-party table lists only picsum.photos | Ticket data now goes to Firebase |

---

## 3.1 Rewrite `docs/architecture.md`

- [ ] Redraw the system context to include Firebase Auth and Cloud Firestore, and
      note that Firebase **Storage is deliberately not used** — flyers are
      embedded in Firestore (commit `4c90706`).
- [ ] Replace "Current boundaries" with accurate ones, keeping the honest tone:
      no custom server, verification trusts Firestore rules, check-in is
      single-use and client-initiated.
- [ ] Refresh the `lib/` tree to match the as-built layout in
      [implementation-plan.md](implementation-plan.md#2-as-built-architecture).
- [ ] Delete the four implemented items from "Future extension points" and keep
      only what is genuinely still unbuilt; state what replaced them.
- [ ] Add a short section for the secure-storage fallback chain, since it is a
      deliberate architectural exception documented in the security rule.

---

## 3.2 Record the V1 feature set in `CHANGELOG.md`

`[Unreleased]` currently lists only the docs/community-health work, so the entire
V1 personal ticket share milestone is missing.

- [ ] Under `[Unreleased] / Added`, cover: local ticket persistence in secure
      storage; PNG export and native/web share; public `/verify/:id` door
      verification with single-use check-in; optional accounts with guest-first
      flow; bundled fonts; ticket detail and preview polish.
- [ ] Add `### Fixed` for: web `MissingPluginException` for secure storage;
      stale-QR `NOT FOUND` at verification; Firebase Storage CORS avoidance;
      runtime font fetching; phone-width date truncation.
- [ ] Add `### Security` for: secure-storage migration off plaintext
      SharedPreferences, and the documented fallback.
- [ ] Leave the version heading alone until decision D3 is settled in Phase 4.

---

## 3.3 Add structural bugs to `USER_RESEARCH_REPORT.md`

`.cursor/rules/workflow-integrity.mdc` §3 requires structural bugs found during
local simulation to be documented here. The report currently records only the
successful field test plus the CORS friction point.

- [ ] Add a "Structural defects found in local simulation" section covering:
  - `flutter_secure_storage` threw `MissingPluginException` on Flutter web from a
    stale `web_plugin_registrant.dart`; resolved with a fallback store plus a
    build-time registration check in `scripts/build_web.sh`.
  - Google Fonts and the web engine's default Roboto were fetched at runtime,
    breaking offline/CDN-blocked loads; resolved by bundling the font assets.
  - The event date ellipsised at phone width because the date and time shared the
    row equally; resolved with a responsive date that falls back to a compact
    format.
- [ ] For each: symptom, root cause, resolution, and the guarding test.
- [ ] Keep the existing document reference (`AG-HR-TR-26-V4`) and bump its
      revision if that is the convention you follow.

---

## 3.4 Sweep the remaining docs

- [ ] `docs/features.md`: correct the auth role statement, the "no backend"
      note, and the Tickets tab section that still says saving is not
      implemented.
- [ ] `docs/privacy.md`: add Firebase (Auth, Firestore, Hosting) to the
      third-party data table, state what leaves the device on save and share, and
      confirm the QR payload carries only a code — no PII.
- [ ] `docs/security/threat-model.md`: add the door-verification trust boundary
      and the reuse/forgery cases now that verification is live.
- [ ] `docs/compliance/iso-alignment.md`: re-check the gaps table against the
      shipped app.
- [ ] `README.md`: confirm the feature list and screenshots match V1.

---

## Exit criteria

1. No document contradicts shipped behaviour; the drift table above is fully
   addressed.
2. The privacy notice names every third party that receives data.
3. `USER_RESEARCH_REPORT.md` records the three structural defects, satisfying the
   workflow-integrity rule.
4. No code changed in this phase; `flutter test` still 100% green.
5. Every box ticked and each subtask logged in `.taskmanager/tasks.json`.
