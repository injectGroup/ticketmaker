# Phase 1 — Android internal-track release readiness

**Goal:** make `flutter build appbundle --release` produce an artifact Play
Console will accept, and get the in-flight configuration committed.

**Branch/commit naming:** `phase/1-android-release-readiness`

**Status:** ✅ done — 31 July 2026

---

## 1.1 Commit the in-flight release configuration

- [x] Confirm `android/app/google-services.json` contains a client for
      `com.agathakakalogical.quickticketmaker` (alongside the legacy clients).
- [x] Confirm the `appId` in `firebase_options.dart` matches that client's
      `mobilesdk_app_id` (`1:107781542059:android:21121105f99c18fdc9e7ee`).
- [x] Rejected pinning `targetSdk = 34` — restored `flutter.targetSdkVersion`
      (36 on Flutter 3.44.6). Play raises the required target annually.
- [x] Restored `versionCode` / `versionName` from `flutter.versionCode` /
      `flutter.versionName` so `pubspec.yaml` remains the single source of truth.
- [x] Commit both files with the rest of Phase 1.

---

## 1.2 Replace debug release signing with an upload keystore

**D1 settled:** generate a new upload keystore locally; credentials live in a
gitignored `android/key.properties` and the keystore file never enters git.

- [x] Step 1 (spec first): `test/android_release_config_test.dart` asserts the
      `release` block does not reference the debug signing config and does
      reference a named `release` signing config. Watched it fail (9 red).
- [x] Step 2: added `signingConfigs { create("release") { ... } }` sourced from
      `android/key.properties`, with a fail-fast `GradleException` when the file
      is missing during a release build (verified by temporarily renaming it).
- [x] Step 3: `key.properties` ignored via both `android/.gitignore` (already
      present) and the root `.gitignore`. `*.jks` / `*.keystore` already covered.
- [x] Step 4: `flutter test` → green (120 passing including 11 release-config
      specs).
- [x] Keystore lives at `~/.keystores/ticketmaker-upload.jks` (alias `upload`,
      PKCS12, RSA 2048, ~27-year validity). Setup documented in
      `docs/development.md`.

---

## 1.3 Fix the on-device app label

- [x] Step 1 (spec first): assert the Android manifest label is
      `Quick Ticket Maker`. Watched it fail.
- [x] Step 2: updated `android:label`.
- [x] Step 3: `flutter test` → green.
- [x] Also aligned iOS `CFBundleDisplayName` and `web/manifest.json` name /
      short_name to the same product name (pinned by the same test file).

---

## 1.4 Align the Gradle `namespace`

**D2 settled:** align the namespace to the new package.

- [x] Set `namespace = "com.agathakakalogical.quickticketmaker"`.
- [x] Moved `MainActivity.kt` to
      `android/app/src/main/kotlin/com/agathakakalogical/quickticketmaker/` and
      updated its `package` declaration; removed the old
      `com/injectgroup/ticket_maker/` tree.
- [x] Rebuilt from clean; release App Bundle succeeds.

---

## 1.5 Verify the release App Bundle

- [x] `flutter build appbundle --release` completes →
      `build/app/outputs/bundle/release/app-release.aab` (66 MB / 69.5 MB reported).
- [x] Signer verified via `META-INF/UPLOAD.RSA`:
      `Owner: CN=Quick Ticket Maker, OU=Mobile, O=Agatha Kakalogical, L=Lagos,
      ST=Lagos, C=NG` — **not** `CN=Android Debug`.
- [x] Version policy: driven by `pubspec.yaml` (`1.0.0+1` today). Play rejects a
      reused `versionCode`, so bump the `+N` build number for every upload.
- [x] Artifact path: `build/app/outputs/bundle/release/app-release.aab`.

---

## Exit criteria

1. [x] No unfinished Android release configuration remains uncommitted.
2. [x] `test/android_release_config_test.dart` passes and pins signing, package
   identity, MainActivity path, and product name.
3. [x] A release App Bundle exists, signed with a non-debug upload key.
4. [x] `flutter analyze` clean, `flutter test` 100% green (120 passing).
5. [x] Every box above ticked, and the subtask logged in `.taskmanager/tasks.json`.

---

## Outcome (31 July 2026)

Play-ready release config is now committed on
`feature/v1-personal-ticket-share`. The previously unfinished `applicationId` /
Firebase Android app switch is finished, the package `namespace` matches, and
the release build type no longer falls back to the debug keystore.

**Operator reminder:** back up `~/.keystores/ticketmaker-upload.jks` and the
passwords in `android/key.properties` offline. Losing them permanently blocks
Play uploads until an upload-key reset through Play Console (only possible if
Play App Signing is enrolled).
