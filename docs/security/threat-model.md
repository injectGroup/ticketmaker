# Threat model

## Purpose

Identify assets, trust boundaries, threats, and mitigations for Quick Ticket Maker. Methodologically aligned with common secure design practice used alongside ISO/IEC 27005 risk concepts and STRIDE-style analysis.

**Model version:** 3.0  
**Date:** 2026-07-31  
**System version:** V1 personal ticket share — Firebase Auth (optional) + public door verification with single-use check-in; Firebase Storage disabled

---

## 1. In-scope assets

| Asset | Sensitivity | Notes |
| --- | --- | --- |
| Source code | Proprietary (LICENSE) | Public remotes; legal restriction ≠ access control |
| Firebase client config | Low (public client keys) | `lib/firebase_options.dart`; restrict via Console + App Check |
| Auth credentials (user passwords / OAuth tokens) | High | Handled by Firebase Auth; never logged or committed |
| Android upload keystore + `key.properties` | High | Local only, git-ignored; loss blocks Play updates |
| Firestore `users/{uid}` profiles | Medium | Owner-only rules |
| Owner ticket copies `users/{uid}/tickets/{id}` | Medium | Owner-only rules |
| Public ticket docs `tickets/{guestCode}` | **Medium — world-readable by design** | Event name, guest label, venue, date/time, Base64 flyer |
| Locally saved tickets + flyer files | Medium | `FlutterSecureStorage` + device image store |
| Ticket codes | Medium | Admission identifiers, **not** signed credentials |
| Check-in state | Medium | Integrity matters more than confidentiality — see 4/6 |
| Remote images / fonts | Untrusted input | Fonts now bundled; remote flyer URLs still possible |
| CI / Chat webhook secrets | High | GitHub Actions secrets only |

Firebase **Storage is not used**; `storage.rules` denies all access and no ticket
JPEGs are uploaded (flyers are embedded in Firestore).

---

## 2. Trust boundaries

```text
[ Developer workstation ] --git/ssh--> [ GitHub public remotes ]
[ Host app ] --https--> [ Firebase Auth ]                     (optional sign-in)
[ Host app ] --https--> [ Firestore users/{uid}/** ]          (rules: auth.uid == uid)
[ Host app ] --https--> [ Firestore tickets/{guestCode} ]     (unauthenticated create allowed)
[ Guest's messaging app ] <--PNG--  [ OS share sheet ]        (leaves our control)
[ Any browser at the door ] --https--> [ Firebase Hosting ] --> /verify/:id
[ Any browser at the door ] --https--> [ Firestore tickets/{guestCode} ]
                                       read: public; update: single-use check-in
[ GitHub Actions ] --secret--> [ Google Chat webhook ]        (optional notify)
```

The door boundary is the significant change from earlier revisions: verification
must work for someone with no account and no app, so `tickets/{guestCode}` is
readable by anyone and writable **unauthenticated** within the narrow shapes
allowed by `firestore.rules`. Everything private stays under `users/{uid}`.

---

## 3. Entry points

| Entry point | Authn | Notes |
| --- | --- | --- |
| UI Generate / Tickets | Optional account | Local design + save; cloud copy only when signed in |
| Auth sheet (email / Google / Apple) | Firebase Auth | Passwords never logged |
| `/verify/:id` public deep link | **None** | Any browser; reads and can check in a ticket |
| Public ticket document writes | **None** (rule-shaped) | Create a valid doc, or flip valid → checked-in |
| Shared PNG | None | Once shared, redistribution is outside our control |
| Camera / gallery / location permissions | OS prompt | User-granted, revocable |
| Network image URLs | None | Untrusted content |
| GitHub PR / CI | Collaborator auth | Supply-chain vector; Security CI + branch protection |

---

## 4. STRIDE summary

| Category | Example threat | Current mitigation | Residual risk |
| --- | --- | --- | --- |
| Spoofing | Guest forwards the ticket image; two people present the same code | Single-use check-in detects the **second** presentation | **Medium — accepted for V1** (see 5.1) |
| Spoofing | Attacker fabricates a ticket document for a plausible code | Rules require a well-formed code and `status: 'valid'`, but no issuer proof | Medium until App Check / server issuance |
| Spoofing | Stolen Firebase client key abused | API key restrictions + App Check | Medium until App Check enforced |
| Spoofing | Auth bypass to another user's tickets | Firestore `request.auth.uid == uid` | Low if rules deployed |
| Tampering | Unauthenticated bulk creation of junk ticket docs | Shape constraints only; no rate limit in rules | Medium — quota/App Check dependent |
| Tampering | Attacker with a code marks a valid ticket checked in **before** the guest arrives, causing refusal at the door | Transition is one-way and rule-shaped, but not authenticated | **Medium — denial of admission (see 6.2)** |
| Tampering | Dependency compromise | Lockfile, Dependabot, PR review, Security CI | Medium |
| Repudiation | Who checked a ticket in? | Only a timestamp is stored; no scanner identity | Medium — no door-staff accounts |
| Information disclosure | Anyone with a code reads the guest label, venue, and flyer | Documented in the privacy notice; minimisation guidance to hosts | **Medium — by design** |
| Information disclosure | Code enumeration across the 10<sup>11</sup> space | Impractical at scale, not prevented | Low–Medium |
| Information disclosure | Ticket data readable on a lost device | `FlutterSecureStorage` (Keychain / EncryptedSharedPreferences) | Low; Medium where the prefs fallback engages |
| Information disclosure | Secrets in git | `.gitignore` (incl. `key.properties`, keystores), gitleaks CI, push protection | Medium if discipline fails |
| Information disclosure | A real secret hidden behind the gitleaks allowlist | `gitleaks.toml` exempts only Google API-key shapes in the generated `lib/firebase_options.dart`; `test/secret_scan_config_test.dart` fails if that is widened | Low |
| Denial of service | Large Base64 flyer inflates documents | Client-side image sizing; Firestore 1 MiB doc limit | Low–Medium |
| Elevation of privilege | Cross-user Firestore access | Deny-by-default rules | Low if rules deployed |

---

## 5. Application-specific risks

### 5.1 Ticket codes are identifiers, not credentials

Codes and their QR strings are now genuinely used for door admission, so the
earlier "preview artifact" framing no longer holds. What they are **not** is a
signed credential:

- Validity is "a Firestore document says `valid`", not a signature the door can
  verify offline.
- Anyone who receives the ticket image receives a working ticket. The control is
  **single-use check-in**: the first successful `/verify/:id` flips the document,
  and later scans report that earlier admission rather than admitting again.
- That detects duplication only after the first scan. For a private party — the
  V1 use case — this is an accepted trade-off. Any event where admission has real
  value needs server-side issuance and signed payloads.

### 5.2 Unauthenticated writes to public ticket documents

Guests must be able to publish and check in without accounts, so the rules —
not authentication — are the whole control surface. They constrain writes to:
creating a well-formed `tickets/{guestCode}` with `status: 'valid'`; a single
valid → checked-in transition touching only `checkedIn`, `checkedInAt`,
`status`, `updatedAt`; a metadata refresh that keeps the code and status; and
host-owned edits or deletion when `hostUid == request.auth.uid`. Any change to
these rules is a change to the security model and must be reviewed as such.

### 5.3 Local data at rest

Ticket data is written through `SecureKeyValueStore`, which prefers
`FlutterSecureStorage`. It falls back to plaintext `SharedPreferences` only when
the secure plugin is genuinely unavailable — a documented exception in
`.cursor/rules/ticket-security.mdc`, guarded by the plugin-registration check in
`scripts/build_web.sh`. Treat any device that hits the fallback as storing ticket
data in the clear.

### 5.4 Untrusted media

`Image.network` loads remote content for older ticket URLs. Prefer allowlists
where URLs become user-controlled. Gallery images are user-chosen and decoded
locally.

### 5.5 Firebase Auth and client keys

- Guest use requires no `uid`; owner paths require a signed-in `uid`.
- Never treat client API keys as confidential server credentials.
- Rotate / restrict keys if abuse is observed.

### 5.6 Release signing

The Android upload key lives outside the repository and is referenced through an
untracked `key.properties`; release builds fail rather than silently falling back
to debug signing. Losing the keystore means losing the ability to ship updates
under the same listing.

### 5.7 Supply chain

Malicious or vulnerable pub.dev packages can execute at build/runtime.
**Controls:** minimize dependencies; review upgrades; Dependabot; Security CI.

---

## 6. Abuse cases (illustrative)

1. Guest forwards the ticket PNG to a friend who arrives first → the friend is
   admitted, the guest is flagged as already checked in. Mitigation is procedural
   at V1 (door staff see the check-in time); technically it needs signed,
   per-guest issuance.
2. Attacker who has seen a code flips it to `checked_in` before the event so the
   real guest is refused → detectable from the check-in timestamp, not prevented.
   App Check plus authenticated door staff would close it.
3. Attacker scripts creation of many junk `tickets/{code}` documents → quota
   abuse; mitigated by App Check enforcement and Firebase quotas.
4. Attacker enumerates codes to harvest guest labels → impractical at the full
   code space; minimisation guidance limits the damage.
5. Attacker opens a PR that adds exfiltration code → review + required CI +
   branch protection.
6. Attacker guesses another `uid` path → Firestore rules deny.

---

## 7. Security requirements derived from this model

1. No server secrets, webhooks, or signing material in the repository.
2. No public vulnerability Issues (use private reporting / email).
3. Network calls must use HTTPS.
4. Firestore must enforce owner-only access for `users/**`, and must keep public
   ticket writes constrained to the shapes in 5.2.
5. Sensitive local data goes through `SecureKeyValueStore`, never directly into
   `SharedPreferences`.
6. The QR payload carries only a ticket code — no guest PII.
7. User-generated URLs require validation/allowlisting before use.
8. Release builds must use the real upload key and fail closed without it.
9. Public remotes require compensating GitHub + Firebase controls (see checklists).

---

## 8. Review triggers

Update this threat model when:

- Changing Auth providers or data models
- Changing `firestore.rules`, especially the public `tickets/{guestCode}` block
- Moving to server-side issuance, signed payloads, or App Check enforcement
- Enabling Firebase Storage
- Adding payments, admin backends, door-staff accounts, or shared collections
- Adding push notifications or new deep links
- Changing repository visibility
- After a security incident
