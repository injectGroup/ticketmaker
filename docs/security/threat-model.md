# Threat model

## Purpose

Identify assets, trust boundaries, threats, and mitigations for Quick Ticket Maker. Methodologically aligned with common secure design practice used alongside ISO/IEC 27005 risk concepts and STRIDE-style analysis.

**Model version:** 1.0  
**Date:** 2026-07-16  
**System version:** app `1.0.0+1` / branch `main`

---

## 1. In-scope assets

| Asset | Sensitivity | Notes |
| --- | --- | --- |
| Source code | Confidential (proprietary) | Private GitHub repository |
| Ticket preview state | Low | Local ephemeral UI state |
| Generated ticket codes | Low–Medium | Guessable format; not proof of authenticity |
| QR payload strings | Low–Medium | Client-generated; may encode URLs |
| Remote images | Untrusted input | Loaded over the network |
| Fonts (google_fonts) | Low | May be fetched/cached |
| Future auth tokens / PII | High | Not present yet; design for later |

---

## 2. Trust boundaries

```text
[ Developer workstation ] --git/ssh--> [ GitHub injectGroup/ticketmaker ]
[ App process ] --https--> [ Remote image CDN / font hosts ]
[ App process ] --(none today)--> [ Inject backend ]
```

---

## 3. Entry points

| Entry point | Authn | Notes |
| --- | --- | --- |
| UI controls on Generate/Tickets | None | Local only |
| Network image URLs | None | Attacker can influence if URL source becomes user-controlled |
| GitHub PR / CI | Collaborator auth | Supply-chain vector |
| Deep links / QR open actions | N/A today | Future risk if app handles arbitrary URLs |

---

## 4. STRIDE summary

| Category | Example threat | Current mitigation | Residual risk |
| --- | --- | --- | --- |
| Spoofing | Malicious collaborator pushes code | Private repo + review expectations | Medium without enforced branch protection |
| Tampering | Dependency compromise | Lockfile + review upgrades | Medium |
| Repudiation | Unclear who merged risky change | GitHub audit log / PR history | Low–Medium |
| Information disclosure | Secrets in git | Policy + `.gitignore` + disclosure process | Medium if discipline fails |
| Denial of service | Huge image decode / UI jank | Flutter image constraints; limited surface | Low |
| Elevation of privilege | N/A (no authz model yet) | Keep auth designs least-privilege later | N/A now |

---

## 5. Application-specific risks

### 5.1 QR codes are not authentication

Generated QR content and ticket codes are **preview artifacts**. They must not be treated as secure admission credentials without a server-side issuance and validation design.

### 5.2 Untrusted media

`Image.network` loads remote content. Risks include unexpected content and future SSRF-like issues if URLs become fully user-controlled without allowlisting.

**Controls:**

- Prefer allowlists when user-provided URLs are introduced
- Always provide error builders / placeholders
- Do not execute remote content as code

### 5.3 Privacy of demo data

Default sample content includes a third-party profile URL used historically as demo QR data. Prefer non-personal demo URLs for future defaults when practical.

### 5.4 Supply chain

Malicious or vulnerable pub.dev packages can execute at build/runtime.

**Controls:**

- Minimize dependencies
- Review new packages
- Keep Flutter/Dart updated
- Enable Dependabot / advisory alerts when available

---

## 6. Abuse cases (illustrative)

1. Attacker opens a PR that adds exfiltration code → mitigated by review and private collaborator model.
2. Attacker tricks a user into scanning a malicious QR produced by a modified build → user education; code signing for distribution builds.
3. Future feature stores PII in logs → blocked by secure coding + privacy policy updates.

---

## 7. Security requirements derived from this model

1. No secrets in repository.
2. No public vulnerability Issues.
3. Network calls must use HTTPS.
4. Ticket authenticity requires future cryptographic server design (out of scope now).
5. User-generated URLs require validation/allowlisting before use.
6. Production releases should use platform code signing and notarization where applicable.

---

## 8. Review triggers

Update this threat model when:

- Adding authentication, payments, or backends
- Adding file export/share
- Adding push notifications or deep links
- Changing dependency major versions with network/crypto impact
- After a security incident
