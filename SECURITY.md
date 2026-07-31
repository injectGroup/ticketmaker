# Security Policy

This security policy describes how to report vulnerabilities in **Quick Ticket Maker** (`injectGroup/ticketmaker`, `ejike-art/ticketmaker-gen-and-tickets-only`) and how Inject handles those reports.

It is written to align with:

- [GitHub: Adding a security policy to your repository](https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository)
- **ISO/IEC 29147** — Vulnerability disclosure
- **ISO/IEC 30111** — Vulnerability handling processes
- **ISO/IEC 27001 / 27002** — Information security management controls

---

## Supported versions

| Version | Supported |
| --- | --- |
| `1.x` (branch `main`) | ✅ Yes |
| Pre-release / forks | ❌ No (report only if the issue also affects `main`) |
| Archived / abandoned branches | ❌ No |

Security fixes are applied to the latest release line on `main` first. Backports are decided case by case.

---

## Reporting a vulnerability

### Preferred channels (private)

1. **GitHub Private Vulnerability Reporting** (recommended when enabled on the repository)  
   Repository → **Security** → **Advisories** → **Report a vulnerability**
2. **Email:** `security@inject.group`  
   Subject line prefix: `[SECURITY] ticketmaker`

If you cannot use those channels, contact an Inject maintainer privately. Do **not** use public Issues, Discussions, or Pull Requests to disclose exploitable details.

### What to include

Provide enough detail for maintainers to reproduce and assess impact:

- Affected version / commit SHA / platform (iOS, Android, web, desktop)
- Description of the vulnerability and attack scenario
- Step-by-step reproduction (PoC)
- Expected vs actual behaviour
- Impact assessment (confidentiality, integrity, availability)
- Any known workarounds
- Your preferred contact method and whether you wish to be credited

### Rules for reporters

- Do **not** include secrets, production credentials, or personal data belonging to third parties in reports unless redacted.
- Do **not** publicly disclose the issue until Inject confirms a fix or publishes an advisory.
- Do **not** perform testing that degrades availability of systems you do not own (no DoS against shared infrastructure).
- Social engineering of Inject staff or customers is out of scope for research authorization.

---

## Our commitment (handling process)

Aligned with ISO/IEC 30111 handling stages:

| Stage | Target | Activity |
| --- | --- | --- |
| Acknowledgement | Within **3 business days** | Confirm receipt and assign a tracking ID |
| Triage | Within **7 business days** | Validate, classify severity, determine scope |
| Remediation | Severity-dependent | Develop, review, and test a fix |
| Disclosure | Coordinated | Publish advisory / release notes when safe |

### Severity guidance

We classify using industry-standard impact thinking (e.g. CVSS-like factors):

| Severity | Examples in this app context |
| --- | --- |
| Critical | Remote code execution; wholesale secret exfiltration |
| High | Auth bypass (when auth exists); sensitive data exposure |
| Medium | XSS/injection in any future web surfaces; insecure storage of PII |
| Low | Hardening gaps, missing TLS pinning opportunities, informational |

Current product note: the app includes **Firebase Auth** and optional cloud sync (Firestore/Storage). Client API keys in source are public-by-design; server secrets and webhooks must never be committed. Supply-chain, dependency, auth bypass, and cross-user data access risks remain in scope.

---

## Safe harbor

Inject will not pursue legal action against researchers who:

- Make a good-faith effort to follow this policy
- Avoid privacy violations, data destruction, and service disruption
- Report findings promptly through private channels

This safe harbor does not authorize access to systems outside this repository’s documented scope.

---

## Security practices in this repository

Maintainers and contributors must follow:

- [docs/security/information-security-policy.md](docs/security/information-security-policy.md)
- [docs/security/secure-coding.md](docs/security/secure-coding.md)
- [docs/security/threat-model.md](docs/security/threat-model.md)
- [docs/security/github-hardening-checklist.md](docs/security/github-hardening-checklist.md)
- [docs/security/firebase-console-hardening.md](docs/security/firebase-console-hardening.md)
- [docs/compliance/iso-alignment.md](docs/compliance/iso-alignment.md)

### Hard requirements

- Never commit secrets (API tokens, private keys, `.env` with credentials, keystores with production passwords, Chat webhooks).
- Never request or paste production secrets into Issues or PR descriptions.
- Prefer SSH remotes and least-privilege tokens for automation.
- Dependency updates must be reviewed for known CVEs before merge.
- Security-relevant changes require explicit review notes in the pull request.
- Firestore/Storage access must remain owner-only via deployed rules.

---

## Supply chain and dependencies

- Dependencies are declared in `pubspec.yaml` / `pubspec.lock`.
- Prefer pinned or lockfile-controlled resolutions for reproducible builds.
- Report malicious or compromised packages immediately through this policy.
- GitHub Dependabot (when enabled) assists with vulnerable dependency alerts; human review remains mandatory.

---

## Coordinated disclosure

After a fix is released, Inject may publish:

- A GitHub Security Advisory
- Release notes describing the issue at an appropriate level of detail
- Credit to the reporter (optional, with consent)

Public disclosure timelines are coordinated with the reporter when feasible.

---

## Contact

| Purpose | Contact |
| --- | --- |
| Security reports | `security@inject.group` |
| Maintainer escalation | Inject repository maintainers via private GitHub channel |
| Non-security support | See [SUPPORT.md](SUPPORT.md) |

---

*Last reviewed: 2026-07-27*
