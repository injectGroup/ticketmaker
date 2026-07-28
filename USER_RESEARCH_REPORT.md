# User Research & Field Test Report
**Project:** Quick Ticket Maker — V1 Personal Ticket Share
**Tester / Author:** Ejike Okoye
**Document Reference:** AG-HR-TR-26-V4
**Date:** July 28, 2026

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
