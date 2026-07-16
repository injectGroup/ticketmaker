# Privacy notice

## Document control

| Field | Value |
| --- | --- |
| Product | Quick Ticket Maker |
| Alignment | ISO/IEC 27701 privacy information management themes; transparency principles similar to GDPR Articles 12–14 |
| Last updated | 2026-07-16 |

This notice describes privacy characteristics of the **current** application. It is not legal advice.

---

## 1. Summary

Quick Ticket Maker is a local ticket design/preview client. In the current release:

- Inject does **not** operate a first-party backend for this app.
- The app does **not** require account registration.
- Ticket state lives in memory for the session (not persisted by the app).
- Limited network activity may occur for remote demo images and font retrieval.

---

## 2. Data controller

Inject (injectGroup)  
Privacy contact: `privacy@inject.group`

---

## 3. Categories of data

| Category | Collected by app today? | Examples |
| --- | --- | --- |
| Account credentials | No | — |
| Payment data | No | — |
| Contacts / precise location | No | — |
| Ticket preview fields | In-memory only | Title, code, QR string, colors |
| Diagnostics / analytics | No first-party analytics configured | — |
| Crash reports | Only if the platform/OS collects independently | Device OS behaviour |

---

## 4. Processing purposes

| Purpose | Legal basis style (when applicable) | Notes |
| --- | --- | --- |
| Provide ticket preview UI | Contract / legitimate interest (internal tools) | Core functionality |
| Load demo imagery | Legitimate interest / consent via network use | Third-party image host |
| Load fonts | Legitimate interest | `google_fonts` may fetch/cache |

---

## 5. Third parties / subprocessors (technical)

| Party | Role | Data |
| --- | --- | --- |
| GitHub | Source hosting for developers | Contributor identities, code |
| picsum.photos (or similar) | Demo images | IP address / request metadata to that host |
| Google Fonts infrastructure (as used by package) | Font files | IP address / request metadata may be visible to font host |

No Inject payment or identity provider is integrated in the current app binary feature set.

---

## 6. Retention

- In-app ticket state: discarded when the process is killed (no local DB in current release).
- Git history and Issues: retained per Inject/GitHub retention practices for the private repository.

---

## 7. Security measures

Technical and organizational measures are described in:

- [SECURITY.md](../SECURITY.md)
- [security/information-security-policy.md](security/information-security-policy.md)

---

## 8. International transfers

Developer collaboration via GitHub may involve transfers depending on GitHub’s service regions. Application end users of the current preview build do not create Inject cloud accounts through this app.

---

## 9. Your choices

Because the current app does not create user accounts with Inject:

- There is no in-app profile deletion flow.
- You can uninstall the app to remove local process state.
- Contributors should avoid putting personal data into Issues, commits, or screenshots.

---

## 10. Children

The product is intended for professional / adult business use within Inject contexts. It is not directed at children.

---

## 11. Changes

Material privacy changes (analytics, accounts, cloud sync) require:

1. Updating this notice in the same release
2. Security/privacy review
3. Communication to affected users where required by law or contract

---

## 12. Contact

`privacy@inject.group`
