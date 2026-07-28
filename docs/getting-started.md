# Getting started

This guide covers environment setup, first run, and verification for **Quick Ticket Maker**.

---

## 1. Prerequisites

| Tool | Requirement |
| --- | --- |
| Flutter SDK | 3.22+ recommended (developed on 3.44.x / Dart 3.12) |
| Git | With SSH access to `git@github.com:injectGroup/ticketmaker.git` |
| IDE | VS Code / Cursor / Android Studio with Flutter/Dart plugins |
| iOS builds | macOS + Xcode + CocoaPods |
| Android builds | Android SDK / emulator or device |
| Web builds | Chrome (or another supported browser) |

Verify Flutter:

```bash
flutter doctor -v
```

Resolve all issues relevant to your target platform before continuing.

---

## 2. Access control

1. Confirm you are authorized to access the private repository.
2. Prefer SSH authentication with your Inject-approved GitHub identity.
3. Do not store personal access tokens in the repository or in committed shell history scripts.
4. Use least-privilege tokens for CI (when configured).

---

## 3. Clone

```bash
git clone git@github.com:injectGroup/ticketmaker.git
cd ticketmaker
```

---

## 4. Install dependencies

```bash
flutter pub get
```

Dependencies are locked via `pubspec.lock`. Do not delete the lockfile unless intentionally regenerating with review.

---

## 5. Quality gates (required before coding)

```bash
flutter analyze
flutter test
```

Expected: no analyzer issues; all tests passing.

---

## 6. Run the app

List devices:

```bash
flutter devices
```

Run:

```bash
flutter run
# or
flutter run -d <device_id>
```

Hot reload: `r` · Hot restart: `R` · Quit: `q`

---

## 7. Useful commands

| Command | Purpose |
| --- | --- |
| `flutter pub outdated` | Review dependency updates |
| `flutter build apk` | Android release/debug build |
| `flutter build ios --no-codesign` | iOS compile check without signing |
| `./scripts/build_web.sh` | Clean web release build + cache-bust JS under `build/web` |
| `flutter build web` | Web build only (prefer `./scripts/build_web.sh` for Hosting deploys) |
| `flutter clean` | Clear build caches when tooling is inconsistent |

---

## 8. Project configuration notes

- App entry: `lib/main.dart`
- Theme: `lib/core/theme/app_theme.dart`
- Routes: `lib/core/router/app_router.dart`
- Lint rules: `analysis_options.yaml` (includes `flutter_lints`)

No `.env` secrets are required for the current local preview build. If future features add API keys:

1. Keep secrets out of git (use ignored local env files or CI secrets).
2. Document required variables in this file without values.
3. Rotate any credential that is ever committed.

---

## 9. Troubleshooting

| Symptom | Action |
| --- | --- |
| `flutter` not found | Install Flutter and add it to `PATH` |
| Package resolution errors | `flutter pub get` / check network / Flutter version |
| iOS build signing errors | Configure team/signing in Xcode for device runs |
| Analyzer errors after upgrade | Align Flutter SDK; re-run `flutter pub get` |
| Image network failures | Confirm device/simulator network access to remote image host |

---

## 10. Next steps

- Read [architecture.md](architecture.md)
- Read [features.md](features.md)
- Follow [../CONTRIBUTING.md](../CONTRIBUTING.md) for changes
