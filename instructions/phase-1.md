# Phase 1 — Android internal-track release readiness

**Goal:** make `flutter build appbundle --release` produce an artifact Play
Console will accept, and get the in-flight configuration committed.

**Why this phase exists:** the working tree already carries an unfinished
release-prep change, and the release build type is still signed with the debug
keystore, which Play Console rejects.

**Branch/commit naming:** `phase/1-android-release-readiness`, with
`subtask/1.x-...` commits.

---

## 1.1 Commit the in-flight release configuration

The working tree currently holds uncommitted changes that belong together:

- `android/app/build.gradle.kts`: `applicationId` moved from
  `com.injectgroup.ticket_maker` to `com.agathakakalogical.quickticketmaker`,
  `targetSdk` pinned to `34`, `versionCode 1`, `versionName "1.0.0"`.
- `lib/firebase_options.dart`: Android `appId` and `apiKey` switched to the
  Firebase Android app registered for the new package name.

This is the one change the workflow-integrity rule permits, because it is
Play Console Internal Track preparation.

- [ ] Confirm `android/app/google-services.json` contains a client for
      `com.agathakakalogical.quickticketmaker` (verified present on 31 Jul 2026,
      alongside the legacy `com.injectgroup.ticket_maker` and
      `com.ticketmaker.ticketmaker` clients).
- [ ] Confirm the `appId` in `firebase_options.dart` matches that client's
      `mobilesdk_app_id`.
- [ ] Decide whether pinning `targetSdk = 34` is intended, or whether it should
      return to `flutter.targetSdkVersion` (see note below).
- [ ] Commit both files together with a message explaining the Play Console intent.

> **Note on `targetSdk = 34`:** Play requires new apps and updates to target a
> recent API level, and the requirement rises annually. Hardcoding `34` freezes
> the target even when the Flutter toolchain moves on. Prefer
> `flutter.targetSdkVersion` unless you have a specific reason to pin.

---

## 1.2 Replace debug release signing with an upload keystore

Current state in `android/app/build.gradle.kts`:

```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        // Signing with the debug keys for now, so `flutter run --release` works.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

A debug-signed bundle cannot be uploaded to any Play track. **Blocks 4.5.**

**D1 settled:** generate a new upload keystore locally; credentials live in a
gitignored `android/key.properties` and the keystore file never enters git.

- [ ] Step 1 (spec first): add `test/android_release_config_test.dart` asserting,
      by reading `android/app/build.gradle.kts` as text, that the `release` block
      does not reference `signingConfigs.getByName("debug")` and does reference a
      named `release` signing config. Watch it fail.
- [ ] Step 2: add a `signingConfigs { create("release") { ... } }` block sourced
      from a gitignored `android/key.properties`, falling back to a clear build
      error (not silent debug signing) when the file is absent.
- [ ] Step 3: add `key.properties` and `android/key.properties` to `.gitignore`.
      `*.jks` and `*.keystore` are already covered at lines 54–55, but the
      properties file that holds the key passwords is **not**.
- [ ] Step 4: run `flutter test` → green; tick this item.
- [ ] Never commit the keystore or its passwords; document the setup in
      `docs/development.md` instead.

---

## 1.3 Fix the on-device app label

`android/app/src/main/AndroidManifest.xml` sets `android:label="ticket_maker"`,
so the launcher shows the Gradle project name rather than the product name.

- [ ] Step 1 (spec first): extend `test/android_release_config_test.dart` to
      assert the manifest label is `Quick Ticket Maker`. Watch it fail.
- [ ] Step 2: update `android:label`.
- [ ] Step 3: `flutter test` → green; tick this item.
- [ ] Check the iOS `CFBundleDisplayName` and `web/manifest.json` names for the
      same mismatch while you are here.

---

## 1.4 Decide the Gradle `namespace` alignment

`namespace` is still `com.injectgroup.ticket_maker` while `applicationId` is now
`com.agathakakalogical.quickticketmaker`. This is legal — the namespace only
governs the generated `R` class and Kotlin package — and
`MainActivity.kt` currently lives at
`android/app/src/main/kotlin/com/injectgroup/ticket_maker/MainActivity.kt`,
consistent with the namespace.

**D2 settled:** align the namespace to the new package.

- [ ] Set `namespace = "com.agathakakalogical.quickticketmaker"`.
- [ ] Move `MainActivity.kt` to
      `android/app/src/main/kotlin/com/agathakakalogical/quickticketmaker/` and
      update its `package` declaration; remove the now-empty old directories.
- [ ] Rebuild from clean (`flutter clean`) so the generated `R` class and
      `GeneratedPluginRegistrant` pick up the new namespace.
- [ ] Either way, confirm `flutter run --release` still launches on a device.

---

## 1.5 Verify the release App Bundle

- [ ] `flutter build appbundle --release` completes.
- [ ] Verify the signer is the upload key, not the debug key:
      `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`
      (or `keytool -printcert`) — the CN must not be `Android Debug`.
- [ ] Record the `versionCode` policy for future uploads: Play rejects a reused
      `versionCode`, so decide whether it is driven by `pubspec.yaml`'s build
      number or maintained by hand in Gradle (ties into D3).
- [ ] Note the resulting artifact path and size in the phase-4 checklist.

---

## Exit criteria

1. No uncommitted Android release configuration remains.
2. `test/android_release_config_test.dart` passes and pins both the signing
   config and the app label.
3. A release App Bundle exists, signed with a non-debug key.
4. `flutter analyze` clean, `flutter test` 100% green.
5. Every box above ticked, and each subtask logged in `.taskmanager/tasks.json`.
