# Google Sign-In setup (Quick Ticket Maker)

App configs now include OAuth client IDs from Firebase (`CLIENT_ID` / `REVERSED_CLIENT_ID` on iOS; web client on Android). The iOS URL scheme is registered in `ios/Runner/Info.plist`.

## Firebase Console checklist

1. Project: `quick-ticket-maker-sandbox`
2. Authentication → Sign-in method → enable **Google**
3. Project settings → Your apps → Android (`com.injectgroup.ticket_maker`) → add fingerprints, then re-download `google-services.json` if needed:

```
SHA-1:   D1:2F:17:EE:D6:AC:22:49:D4:43:C4:97:4A:CC:E5:DD:BD:A4:A8:47
SHA-256: 26:18:8F:24:43:13:F3:7E:90:17:80:72:B9:2A:7B:A9:A7:D4:84:8A:4A:77:77:4E:F9:C7:B5:EA:54:C7:F2:2F
```

(Debug keystore. Add release SHA-1 before shipping.)

4. After enabling Google / adding SHA-1, run:

```bash
flutterfire configure --project=quick-ticket-maker-sandbox --platforms=ios,android --yes
```

## App wiring already done

- `ios/Runner/GoogleService-Info.plist` — includes `CLIENT_ID` + `REVERSED_CLIENT_ID`
- `android/app/google-services.json` — includes OAuth client entries
- `ios/Runner/Info.plist` — `CFBundleURLTypes` for the reversed client ID
- `FirebaseAuthRepository` initializes `google_sign_in` with iOS `clientId` + web `serverClientId`
