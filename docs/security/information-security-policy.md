# Information security policy (repository scope)

## Document control

| Field | Value |
| --- | --- |
| Title | Quick Ticket Maker — Information Security Policy |
| Scope | `injectGroup/ticketmaker` repository and related development activities |
| Alignment | ISO/IEC 27001:2022 Annex A themes; ISO/IEC 27002 guidance |
| Classification | Internal |
| Owner | Inject maintainers |
| Effective date | 2026-07-16 |
| Review cadence | Annual, or after significant incidents / architecture changes |

This policy defines **repository-level** controls. It does not replace Inject’s organization-wide ISMS documents where those exist.

---

## 1. Purpose

Protect the confidentiality, integrity, and availability of:

- Source code and documentation
- Build and release artifacts
- Contributor and reporter personal data processed during development
- Any future secrets and customer data integrated into the product

---

## 2. Scope

In scope:

- GitHub repository access and collaboration
- Local development environments used for this project
- CI/CD (when configured) for this repository
- Third-party packages consumed by the app
- Vulnerability intake and handling for this product

Out of scope of this document:

- Corporate endpoint management details (covered by org policies)
- Production cloud accounts not yet used by this app

---

## 3. Roles and responsibilities

| Role | Responsibilities |
| --- | --- |
| Repository admins | Access control, branch protection, secret scanning settings |
| Maintainers | Code review, merge decisions, security triage support |
| Contributors | Follow secure coding and disclosure rules |
| Security contact | Intake reports per `SECURITY.md` |

---

## 4. Access control (ISO/IEC 27001 A.5 / A.8 themes)

1. Repository remains **private** unless Inject leadership approves publication.
2. Access is least-privilege (read / triage / write / maintain / admin).
3. Departing collaborators must have access revoked promptly.
4. Prefer SSO / org-managed identities when available.
5. Personal access tokens must be short-lived, scoped, and never committed.
6. SSH keys must be individual, passphrase-protected where feasible, and revoked when lost.

---

## 5. Secure development (A.8.25–A.8.28 themes)

1. Changes land through reviewed pull requests on protected branches when enabled.
2. `flutter analyze` and `flutter test` are mandatory quality gates.
3. Dependencies are reviewed for known vulnerabilities before upgrade merge.
4. Secrets are prohibited in source control.
5. Security-sensitive PRs require explicit risk notes.
6. Follow [secure-coding.md](secure-coding.md) and [threat-model.md](threat-model.md).

---

## 6. Vulnerability management (ISO/IEC 29147 / 30111)

1. Public disclosure of vulnerabilities before mitigation is prohibited.
2. Intake and handling follow [SECURITY.md](../../SECURITY.md).
3. Confirmed issues are tracked to remediation and verification.
4. High/Critical issues block release when they affect supported versions, unless an approved risk acceptance is recorded.

---

## 7. Cryptography and communications

1. Use TLS for all network communications introduced by future features.
2. Do not implement custom cryptography; use platform/libraries vetted by Flutter/Dart ecosystems.
3. QR payloads must not embed secrets or long-lived credentials.

---

## 8. Logging and privacy

1. Do not log secrets, payment data, or unnecessary personal data.
2. Crash/log collection (if added later) must be disclosed in [privacy.md](../privacy.md) and minimized by default.
3. Security incident records are confidential.

---

## 9. Backup and continuity

1. Source of truth is GitHub `main`.
2. Contributors keep recoverable local clones; do not rely on a single workstation.
3. TaskManager local JSON is a project backup aid, not a substitute for git.

---

## 10. Exceptions

Exceptions to this policy require:

- Written maintainer approval
- Time-bounded duration
- Compensating controls
- Record in the PR or internal security register

---

## 11. Violations

Violations may result in removal of repository access and escalation under Inject employment / contractor agreements and the Code of Conduct.
