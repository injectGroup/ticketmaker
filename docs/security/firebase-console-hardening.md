# Firebase Console hardening (sandbox)

Project: **`quick-ticket-maker-sandbox`**

Client config lives in `lib/firebase_options.dart` and is expected to be public on a public GitHub remote. Enforce these Console controls so keys alone cannot abuse backend resources.

Last reviewed: 2026-07-27

---

## 1. API key restrictions (Google Cloud Console → APIs & Services → Credentials)

For each Browser / Android / iOS key used by the app:

| Platform | Restriction |
| --- | --- |
| Web | HTTP referrers: Firebase Hosting domains + localhost for dev |
| Android | Package name + SHA-1 / SHA-256 of signing certs |
| iOS / macOS | Bundle ID |

Also restrict each key to only the APIs the app needs (Firebase / Identity Toolkit / etc.).

## 2. App Check

1. Firebase Console → App Check → register apps (web reCAPTCHA / DeviceCheck / Play Integrity as appropriate).
2. Enforce App Check for **Authentication**, **Cloud Firestore**, and **Storage**.
3. Keep a short debug-token allowlist for local development only; rotate if leaked.

## 3. Auth providers

- Keep Email/Password enabled only if product requires it.
- Confirm **Authorized domains** list is least-necessary (Hosting domain, `localhost`).
- Prefer Google / Apple providers with Console OAuth clients; never commit OAuth client **secrets** (web client IDs in source are public by design).

## 4. Security rules deploy

Repo files:

- [`firestore.rules`](../../firestore.rules) — owner-only `users/{uid}` and `users/{uid}/tickets/{id}`
- [`storage.rules`](../../storage.rules) — owner-only `users/{uid}/tickets/*.jpg`, JPEG &lt; 5 MB

Deploy when authenticated:

```bash
firebase deploy --only firestore:rules,storage --project quick-ticket-maker-sandbox
```

## 5. Verification

- Unauthenticated Firestore/Storage reads/writes fail.
- User A cannot read/write User B’s `users/{uid}/tickets` or Storage paths.
- Auth debug logs never include raw passwords (boolean emptiness only).
