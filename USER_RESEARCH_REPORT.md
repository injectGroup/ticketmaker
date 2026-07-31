# User Research & Field Test Report
**Project:** Quick Ticket Maker — V1 Personal Ticket Share
**Tester / Author:** Ejike Okoye
**Document Reference:** AG-HR-TR-26-V5
**Date:** July 31, 2026 (V4: July 28, 2026 — added §4 structural defects)

## 1. Executive Summary
Field test conducted for a birthday party scenario ("Ejike's Birthday Bash") to evaluate creation, distribution, presentation, and door verification.

## 2. Core Journey Stages

### Stage 1: Host Experience (Creation)
- **Time Taken:** 18 seconds to input party details, choose color theme, and upload event graphic.
- **Usability:** Intuitive form layout; instant live preview update.
- **Findings:** Smooth creation flow with no latency during color or shape customization.

### Stage 2: Distribution Experience (Sharing)
- **Share Method Tested:** WhatsApp & Direct PNG Download on Web/Mobile.
- **Export Reliability:** 100% success rate using pure-Dart memory rasterization (`ticket_raster_export.dart`).
- **Findings:** Share sheet triggers native app selection seamlessly. PNG payload generates cleanly without canvas CORS issues.

### Stage 3: Guest Experience (Presentation)
- **Receiving & Opening:** Guest received PNG ticket via messaging app.
- **Saving:** Saved directly to photo gallery / phone screen in 1 tap.
- **Findings:** High resolution; text details (Event Name, Date, Venue, Guest Pass Code) are easily readable on mobile screens.

### Stage 4: Entrance Experience (Confirmation)
- **Scan Success Rate:** 10/10 successful door checks.
- **Verification Speed:** ~1.5 seconds per scan.
- **Low-Lighting Performance:** Tested in dimmed indoor lighting; phone backlight provided sufficient contrast for the QR code payload (`https://ticketmaker.app/t/...`) to be scanned instantly by the doorman's camera.

## 3. Friction Points & Recommendations
- **Observed Friction:** Initial web caching/CORS canvas blocks during PNG export on browsers.
- **Resolution Applied:** Hardened app using cache-busting headers (`?v=`) and pure-Dart memory rasterization for fallback image rendering.

## 4. Structural defects found in local simulation

Recorded per `.cursor/rules/workflow-integrity.mdc` §3. Each defect surfaced
while simulating the journey locally rather than in the field test above, and
each now has a test that fails if it returns.

### 4.1 Saved tickets lost on Flutter web
- **Symptom:** Saving a ticket in the browser appeared to succeed, but the Tickets tab stayed empty and the console showed `MissingPluginException` from `flutter_secure_storage`.
- **Root cause:** A stale generated `web_plugin_registrant.dart` did not call `FlutterSecureStorageWeb.registerWith`, so the plugin had no web implementation at runtime.
- **Resolution:** Introduced `SecureKeyValueStore`, which prefers `FlutterSecureStorage` and falls back to `SharedPreferences` only on `MissingPluginException` / `PlatformException` / `UnsupportedError`, plus a one-time migration of any legacy plaintext list. `scripts/build_web.sh` now fails the build when the registrant omits a plugin, so the fallback is a safety net rather than the normal path.
- **Guarding test:** `test/secure_storage_fallback_test.dart` (fallback and legacy migration); the registration check runs in `scripts/build_web.sh`.

### 4.2 Fonts fetched at runtime
- **Symptom:** Text rendered in a fallback face on first paint, tests that disable runtime fetching failed with `font SpaceMono-Bold was not found`, and the web console warned "Could not find a set of Noto fonts".
- **Root cause:** `google_fonts` downloads from `fonts.gstatic.com` unless the family is present in the asset manifest, and the web engine separately fetches its own default Roboto when the app declares no `Roboto` family.
- **Resolution:** Bundled every requested variant (Readex Pro, Outfit, Space Mono) under `assets/fonts/` and declared a local `Roboto` family in `pubspec.yaml`. Verified with headless Chrome and the font CDN blocked — no font requests.
- **Guarding test:** `test/bundled_fonts_test.dart`, which disables runtime fetching and asserts each variant loads from assets.

### 4.3 Event date truncated at phone width
- **Symptom:** On phone-width browsers the date ellipsised mid-string (`Friday, 31 Jul…`) even though the row had unused space.
- **Root cause:** The date and time were both `Flexible` with equal flex, capping the date at half the row regardless of how little the time needed.
- **Resolution:** The date now takes the remaining space (`Expanded`) while the time sizes to its content, and `TicketDateText` measures the row to pick the longest format that fits, falling back from `Friday, 31 July 2026` to the compact `Fri, 31 Jul 2026`.
- **Guarding test:** narrow-viewport regression case in `test/widget_test.dart`, plus `formatCompactDateLabel` in `test/ticket_personal_defaults_test.dart`.

### 4.4 Clearing saved tickets threw mid-iteration
- **Symptom:** `SecureStorageService.clearAllTickets()` threw `Concurrent modification during iteration`.
- **Root cause:** It deleted keys while iterating the map returned by `readAll()`, which can be a live view.
- **Resolution:** Iterate a `toList()` snapshot of the keys before deleting. Found by writing the unit spec first, before any user hit it.
- **Guarding test:** `test/secure_storage_service_test.dart`.
