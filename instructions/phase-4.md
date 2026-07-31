# Phase 4 — Release and merge

**Goal:** land V1 on `main` and produce an internal-track build, with the
milestone recorded.

**Prerequisites:** Phases 1–3 complete, every checklist item ticked.

**Branch/commit naming:** `phase/4-v1-release`, with `subtask/4.x-...` commits.

**Standing constraint:** all code is written on
`feature/v1-personal-ticket-share`. `main` changes only by merging a reviewed PR
— never by direct commits. No branches are deleted as part of this phase.

---

## 4.1 Full green gate

- [ ] `flutter analyze` → no issues.
- [ ] `flutter test` → 100% green (expect >51 tests after Phase 2).
- [ ] `bash scripts/build_web.sh` → succeeds, including its web plugin
      registration check (the guard added after the secure-storage web failure).
- [ ] Spot-check the built web app with the font CDN blocked: no font warnings,
      no `MissingPluginException`.
- [ ] Manually walk the core journey once on a phone-width viewport: create →
      save → share PNG → open `/verify/:id` → confirm second scan is refused.

---

## 4.2 Open the PR to `main`

The branch is **108 commits ahead of `main` and 0 behind**, so this is a large
but conflict-free merge.

**Depends on decision D4 (merge commit vs. squash).**

- [ ] Push the branch to the remote.
- [ ] Open the PR with a summary covering the V1 journey, the security posture
      (secure storage, no PII in payloads), the Android release prep, and the
      documentation truth-up.
- [ ] Link `USER_RESEARCH_REPORT.md` and the phase checklists as evidence.
- [ ] Let CI finish; fix anything red before merging.
- [ ] Request review if branch protection requires it (see
      `docs/compliance/iso-alignment.md`, which notes reviewers are configured on
      the primary remote when an admin is available).

---

## 4.3 Settle the version and tag

**Depends on decision D3.** Current inconsistencies to reconcile:

- `pubspec.yaml` says `version: 1.0.0+1`.
- `android/app/build.gradle.kts` now hardcodes `versionCode 1` / `versionName "1.0.0"`.
- `CHANGELOG.md` links a `v1.0.0` tag, but **no git tags exist locally**.

- [ ] Decide the version for this release. V1 personal ticket share is a feature
      milestone on top of the 1.0.0 baseline, so `1.1.0` is the natural choice
      under semver; `versionCode` must then increment too, since Play rejects a
      reused one.
- [ ] Align `pubspec.yaml`, the Gradle version parameters, and the changelog
      heading (replace `[Unreleased]` with the chosen version and date, and add
      the compare link).
- [ ] Confirm whether the `v1.0.0` tag exists on the remote; create the new
      annotated tag after the merge lands, not before.

---

## 4.4 Post-merge notifications and backup

Per `.cursor/rules/taskmanager-app-notifications.mdc`:

- [ ] Record the Web UI milestone via `notify_milestone_reached` using
      `notificationProjectId` (`project-1784709204130`) — never the legacy
      `S48ODI73lfsZJSn8Kke2` id. If Firebase is unavailable, write
      `projects[].lastMilestone` in `.taskmanager/tasks.json` instead.
- [ ] Confirm the Google Chat post. `.github/workflows/notify-app-update.yml`
      fires on `main` pushes; if `GOOGLE_CHAT_WEBHOOK_URL` is unset, note that in
      the session summary rather than inventing a URL.
- [ ] Ensure every phase subtask is logged in `.taskmanager/tasks.json` with an
      accurate status, then run `tkl sync`.
- [ ] Keep messages short, with no secrets, tokens, or webhook URLs.

---

## 4.5 Play Console internal track upload (operator checklist)

Manual steps outside the repo, listed so nothing is missed:

- [ ] Upload the signed App Bundle from Phase 1.5 to the **Internal testing** track.
- [ ] Confirm the package name reads `com.agathakakalogical.quickticketmaker`.
- [ ] Add internal testers and share the opt-in link.
- [ ] Complete the required declarations: data safety (ticket data in Firestore,
      camera use for scanning, photo picker for flyers), content rating, target
      audience, and the privacy policy URL — which must point at the corrected
      `docs/privacy.md` content.
- [ ] Apply the Firebase console hardening steps in
      `docs/security/firebase-console-hardening.md`, including App Check and API
      key restrictions, before widening distribution.
- [ ] Install from the internal track on a real device and repeat the door-scan
      check once more.

---

## Exit criteria

1. `main` contains the V1 work through a reviewed PR.
2. Version, tag, and changelog agree.
3. A signed App Bundle is live on the internal track and installs on a device.
4. The milestone is recorded in TaskManager and announced on Chat.
5. Every box ticked across all four phase files.
