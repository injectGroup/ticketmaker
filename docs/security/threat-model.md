# Threat model

## Purpose

Identify assets, trust boundaries, threats, and mitigations for Quick Ticket Maker. Methodologically aligned with common secure design practice used alongside ISO/IEC 27005 risk concepts and STRIDE-style analysis.

**Model version:** 2.0  
**Date:** 2026-07-27  
**System version:** app with Firebase Auth + cloud ticket sync / public GitHub remotes

---

## 1. In-scope assets

| Asset | Sensitivity | Notes |
| --- | --- | --- |
| Source code | Proprietary (LICENSE) | Public remotes; legal restriction ≠ access control |
| Firebase client config | Low (public client keys) | `lib/firebase_options.dart`; restrict via Console + App Check |
| Auth credentials (user passwords / OAuth tokens) | High | Handled by Firebase Auth; never logged or committed |
| Firestore `users/{uid}` profiles | Medium | Owner-only rules |
| Firestore ticket metadata | Medium | `users/{uid}/tickets/{id}` |
| Storage ticket JPEGs | Medium | `users/{uid}/tickets/{id}.jpg` |
| Ticket preview / QR payloads | Low–Medium | Client-generated; not admission credentials |
| Remote images / fonts | Untrusted input | Loaded over the network |
| CI / Chat webhook secrets | High | GitHub Actions secrets only |

---

## 2. Trust boundaries

```text
[ Developer workstation ] --git/ssh--> [ GitHub public remotes ]
[ App process ] --https--> [ Firebase Auth ]
[ App process ] --https--> [ Cloud Firestore ]  (rules enforce auth.uid)
[ App process ] --https--> [ Firebase Storage ] (rules enforce auth.uid)
[ App process ] --https--> [ Remote image CDN / font hosts ]
[ GitHub Actions ] --secret--> [ Google Chat webhook ] (optional notify)
```

---

## 3. Entry points

| Entry point | Authn | Notes |
| --- | --- | --- |
| UI Generate / Tickets | Optional account | Local preview + optional cloud sync |
| Auth sheet (email / Google / Apple) | Firebase Auth | Passwords never logged |
| Network image URLs | None | Untrusted content |
| GitHub PR / CI | Collaborator auth | Supply-chain vector; Security CI + branch protection |
| Deep links / QR open actions | N/A / future | Allowlist if introduced |

---

## 4. STRIDE summary

| Category | Example threat | Current mitigation | Residual risk |
| --- | --- | --- | --- |
| Spoofing | Stolen Firebase client key abused | API key restrictions + App Check; Auth required for data | Medium until App Check enforced |
| Spoofing | Auth bypass to another user’s tickets | Firestore/Storage `request.auth.uid == uid` | Low if rules deployed |
| Tampering | Dependency compromise | Lockfile, Dependabot, PR review, Security CI | Medium |
| Tampering | Malicious PR to public repo | Branch protection + required checks | Medium without reviewers |
| Repudiation | Unclear who merged risky change | GitHub audit / PR history | Low–Medium |
| Information disclosure | Secrets in git | `.gitignore`, gitleaks CI, push protection | Medium if discipline fails |
| Information disclosure | Public clone of proprietary code | LICENSE (legal); not technical hiding | Accepted for public remotes |
| Denial of service | Huge image decode / Storage abuse | JPEG size limit in Storage rules; Flutter constraints | Low–Medium |
| Elevation of privilege | Cross-user Firestore/Storage access | Deny-by-default rules | Low if rules deployed |

---

## 5. Application-specific risks

### 5.1 QR codes are not authentication

Generated QR content and ticket codes are **preview artifacts**. They must not be treated as secure admission credentials without server-side issuance and validation.

### 5.2 Untrusted media

`Image.network` loads remote content. Prefer allowlists when URLs become user-controlled.

### 5.3 Firebase Auth + cloud sync

- Guest local save may work without cloud writes; cloud paths require signed-in `uid`.
- Never treat client API keys as confidential server credentials.
- Rotate / restrict keys if abuse is observed.

### 5.4 Supply chain

Malicious or vulnerable pub.dev packages can execute at build/runtime.

**Controls:** Minimize dependencies; review upgrades; Dependabot; Security CI.

---

## 6. Abuse cases (illustrative)

1. Attacker opens a PR that adds exfiltration code → review + required CI + branch protection.
2. Attacker uses extracted client API key without App Check → API restrictions + App Check enforcement.
3. Attacker guesses another uid path → Firestore/Storage rules deny.
4. Attacker tricks a user into scanning a malicious QR from a modified build → education; code signing for distribution.

---

## 7. Security requirements derived from this model

1. No server secrets or webhooks in repository.
2. No public vulnerability Issues (use private reporting / email).
3. Network calls must use HTTPS.
4. Firestore and Storage must enforce owner-only access.
5. User-generated URLs require validation/allowlisting before use.
6. Production releases should use platform code signing where applicable.
7. Public remotes require compensating GitHub + Firebase controls (see checklists).

---

## 8. Review triggers

Update this threat model when:

- Changing Auth providers or data models
- Adding payments, admin backends, or shared ticket collections
- Adding push notifications or deep links
- Changing repository visibility
- After a security incident
