# Privacy notice

## Document control

| Field | Value |
| --- | --- |
| Product | Quick Ticket Maker |
| Alignment | ISO/IEC 27701 privacy information management themes; transparency principles similar to GDPR Articles 12–14 |
| Last updated | 2026-07-31 |
| Supersedes | 2026-07-16 revision, which described a local preview-only build with no backend |

This notice describes privacy characteristics of the **current** application. It
is not legal advice.

---

## 1. Summary

Quick Ticket Maker designs a ticket on the host's device, saves it locally, and
publishes a small document so the ticket can be verified at the door. In the
current release:

- Inject runs **no custom server**, but the app does use **Google Firebase**
  (Auth, Cloud Firestore, Hosting) — so ticket data does leave the device when a
  ticket is saved.
- Accounts are **optional**. The whole design → save → share → verify journey
  works without registering.
- Saved tickets are kept on the device in **encrypted** storage.
- **The public ticket document is readable by anyone who has the ticket code.**
  This is deliberate: door staff must verify a scanned code without an account.
  See §5.
- The QR code itself carries only a verification link and the ticket code
  (`https://quick-ticket-maker-sandbox.web.app/verify/<code>`) — no name, phone
  number, or email.

---

## 2. Data controller

Inject (injectGroup)  
Privacy contact: `privacy@inject.group`

---

## 3. Categories of data

| Category | Handled by app today? | Examples |
| --- | --- | --- |
| Ticket content | Yes — stored locally and published | Event name, guest-pass label, venue, date/time, ticket code, flyer image |
| Account credentials | Only if the user chooses to sign in | Email/password via Firebase Auth; Google or Apple OAuth |
| Profile data | Only for signed-in users | Display name, photo URL in `users/{uid}` |
| Admission events | Yes | Checked-in flag and timestamp on the ticket document |
| Photos / media | Yes, user-selected | Flyer chosen from the device gallery |
| Precise location | Only if the user invokes venue lookup | Coordinates resolved to a place name (`geolocator` / `geocoding`) |
| Payment data | No | — |
| Contacts | No | — |
| Diagnostics / analytics | No first-party analytics configured | — |
| Crash reports | Only if the platform/OS collects independently | Device OS behaviour |

**Free-text caution.** The guest-pass label, event name, and venue are whatever
the host types. If a host types a real person's name there, that name becomes
part of the published document described in §5.

---

## 4. What leaves the device, and when

| Action | What leaves | Destination |
| --- | --- | --- |
| Designing a ticket | Nothing | — |
| Saving a ticket | Ticket code, event name, guest-pass label, venue, date/time, QR string, status, and the flyer image embedded as Base64 | Cloud Firestore `tickets/{code}` — **publicly readable** |
| Saving while signed in | The same fields plus `hostUid`, mirrored to an owner-only copy | Firestore `users/{uid}/tickets/{id}` |
| Sharing a ticket | A PNG image of the ticket | Whichever app or contact the host picks in the OS share sheet — outside our control from that point |
| Verifying at the door | The scanned code, then a check-in flag and timestamp written back | Firestore `tickets/{code}` |
| Signing in | Credentials or OAuth tokens | Firebase Auth (never logged by the app, never committed) |
| Venue lookup | Device coordinates | `geocoding` provider |
| Loading a remote flyer URL | An HTTP request revealing IP and request metadata | That image host |

Firebase **Storage is not used**; its rules deny all access. Flyers travel inside
the Firestore document instead.

---

## 5. The public ticket document

To verify a ticket, door staff open the scanned link in an ordinary browser with
no app and no account. That is only possible if the document is readable without
authentication, so `firestore.rules` allows `read` on `tickets/{code}` for
anyone, and allows an unauthenticated client to create a correctly shaped
document and to perform the one-way valid → checked-in transition.

Consequences a host should understand:

- Anyone holding a ticket code — for example anyone the ticket image was
  forwarded to — can read that ticket's event name, **guest name/label**, venue,
  date/time, and flyer.
- Codes are `####-####-###` and are not secret. Brute-force enumeration of the
  full space is impractical but not cryptographically prevented.
- Owner documents under `users/{uid}` are **not** public; they remain
  owner-only.

**Data minimisation guidance:** treat the guest-pass label as public text. Use
a first name or a pass type rather than full names, phone numbers, or anything
you would not put on a printed ticket.

---

## 6. Processing purposes

| Purpose | Legal basis style (when applicable) | Notes |
| --- | --- | --- |
| Provide the ticket designer | Contract / legitimate interest | Core functionality; local only |
| Persist saved tickets | Contract | Encrypted device storage |
| Publish a verifiable ticket document | Contract / legitimate interest | Necessary for door verification |
| Record a single-use check-in | Legitimate interest (preventing reuse) | Flag + timestamp |
| Optional account and cloud copies | Consent (the user chooses to sign in) | Firebase Auth + owner-only Firestore |
| Venue lookup | Consent (OS location permission) | Only when invoked |
| Load remote flyer imagery | Legitimate interest | Third-party image host |

---

## 7. Third parties / subprocessors (technical)

| Party | Role | Data |
| --- | --- | --- |
| Google (Firebase Auth) | Authentication for optional accounts | Email, password hash, OAuth identifiers, device/IP metadata |
| Google (Cloud Firestore) | Ticket documents and profiles | Everything listed in §4; public ticket docs are world-readable |
| Google (Firebase Hosting) | Serves the web build and `/verify/:id` | Request metadata, IP addresses in hosting logs |
| Google / Apple (sign-in providers) | Social sign-in, where chosen | Identity assertion for the chosen provider |
| Google (Play / geocoding services) | Venue name lookup, where invoked | Coordinates |
| GitHub | Source hosting for developers | Contributor identities, code |
| Remote image hosts | Optional flyer URLs on older tickets | IP address / request metadata to that host |
| OS share targets | Whatever app the host shares the PNG into | The ticket image |

Google Fonts infrastructure is **no longer contacted at runtime** — the required
fonts ship as bundled assets.

No Inject payment or identity provider is integrated.

---

## 8. Retention

- **On device:** saved tickets and flyers persist in encrypted storage until the
  host deletes them or uninstalls the app.
- **Public ticket documents:** persist in Firestore until deleted. A signed-in
  host owns the document (`hostUid`) and can delete it; a ticket published
  without signing in has no owner and no in-app deletion path — request removal
  via the privacy contact.
- **Check-in records:** retained on the ticket document for the life of that
  document.
- **Account data:** retained while the account exists.
- **Git history and Issues:** retained per Inject/GitHub practices.

---

## 9. Security measures

Technical and organizational measures:

- Guest ticket data is held in `FlutterSecureStorage` (Keychain /
  EncryptedSharedPreferences / WebCrypto). A `SharedPreferences` fallback exists
  only for platforms where the secure plugin is unavailable, and the web build
  fails if the plugin is not registered.
- Firestore rules are deny-by-default; owner data requires `request.auth.uid`,
  and public ticket writes are constrained to specific field shapes.
- No API keys or service credentials in source; `.env`, `key.properties`, and
  keystores are git-ignored.

Further detail:

- [SECURITY.md](../SECURITY.md)
- [security/information-security-policy.md](security/information-security-policy.md)
- [security/threat-model.md](security/threat-model.md)

---

## 10. International transfers

Firebase processing occurs in Google Cloud regions for the
`quick-ticket-maker-sandbox` project and may involve transfers outside the
host's country. Developer collaboration via GitHub may involve transfers
depending on GitHub's service regions.

---

## 11. Your choices

- You can use the app entirely without an account.
- You can delete a saved ticket from the device.
- A signed-in host can delete the ticket's public document; for a ticket
  published without an account, contact `privacy@inject.group`.
- You control whether to grant camera, gallery, and location permissions;
  declining them only removes the corresponding convenience.
- Keep personal data out of the free-text ticket fields (see §5).
- Contributors should avoid putting personal data into Issues, commits, or
  screenshots.

---

## 12. Children

The product is intended for professional / adult business use within Inject
contexts. It is not directed at children.

---

## 13. Changes

Material privacy changes (analytics, new processors, changes to what the public
document contains) require:

1. Updating this notice in the same release
2. Security/privacy review
3. Communication to affected users where required by law or contract

---

## 14. Contact

`privacy@inject.group`
