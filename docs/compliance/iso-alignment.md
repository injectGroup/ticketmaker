# ISO alignment

## Purpose

Map Quick Ticket Maker repository practices to selected ISO/IEC standards used by Inject for software security, privacy, and life-cycle quality.

> **Important:** This mapping demonstrates **alignment of documentation and engineering practices**. It is **not** a claim that Inject or this product is formally ISO-certified.

---

## Document control

| Field | Value |
| --- | --- |
| Product | Quick Ticket Maker |
| Repository | injectGroup/ticketmaker; ejike-art/ticketmaker-gen-and-tickets-only |
| Last reviewed | 2026-07-27 |

---

## Standards covered

| Standard | Title (short) | Relevance |
| --- | --- | --- |
| ISO/IEC 27001 | Information security management | Policy, access, secure development themes |
| ISO/IEC 27002 | Security controls guidance | Practical control wording |
| ISO/IEC 27701 | Privacy information management | Privacy notice and minimization |
| ISO/IEC 29147 | Vulnerability disclosure | `SECURITY.md` process |
| ISO/IEC 30111 | Vulnerability handling | Triage/remediation SLA stages |
| ISO/IEC/IEEE 12207 | Software life cycle processes | Plan, build, verify, release docs |
| ISO/IEC 25010 | Systems and software quality models | Quality attributes in architecture/dev docs |

---

## Control mapping

### A. Information security (27001/27002 themes)

| Theme | Repository implementation |
| --- | --- |
| Policies for information security | [security/information-security-policy.md](../security/information-security-policy.md) |
| Access control / least privilege | Public-by-decision remotes + LICENSE; collaborator roles; SSH preferred; [github-hardening-checklist.md](../security/github-hardening-checklist.md) |
| Secure development life cycle | PR reviews, Security CI (`flutter analyze` / `test` / gitleaks), [secure-coding.md](../security/secure-coding.md) |
| Management of technical vulnerabilities | [SECURITY.md](../../SECURITY.md), Dependabot, disclosure process |
| Logging / privacy in logs | Secure coding + privacy notice; no raw password logs |
| Supplier relationships (packages) | Dependency rules + Dependabot |
| Cloud data access | Firestore/Storage owner-only rules; [firebase-console-hardening.md](../security/firebase-console-hardening.md) |

### B. Privacy (27701 themes)

| Theme | Repository implementation |
| --- | --- |
| Privacy notice / transparency | [privacy.md](../privacy.md) |
| Data minimization | Local preview by default; cloud sync only for signed-in owners |
| Purpose limitation | Features doc + threat model |
| Breach / vulnerability communication | Security disclosure channels (not public Issues) |

### C. Vulnerability disclosure & handling (29147 / 30111)

| Stage | Implementation |
| --- | --- |
| Receive | Private Vulnerability Reporting / `security@inject.group` |
| Acknowledge | Target ≤ 3 business days |
| Validate / triage | Target ≤ 7 business days |
| Remediate | Severity-based; tracked in private channels |
| Disclose | Coordinated advisory / release notes |

### D. Life cycle (12207 themes)

| Process | Artifacts |
| --- | --- |
| Stakeholder / requirements | [features.md](../features.md) |
| Architecture / design | [architecture.md](../architecture.md), threat model |
| Implementation | `lib/` source |
| Verification | `flutter analyze`, `flutter test`, PR checks |
| Operation / maintenance | SUPPORT, SECURITY, CONTRIBUTING |
| Documentation | `docs/` + community health files |

### E. Product quality (25010 characteristics)

| Characteristic | Evidence |
| --- | --- |
| Functional suitability | features.md vs implementation |
| Performance efficiency | Lightweight local Cubit state |
| Compatibility | Flutter multi-platform targets |
| Usability | Material navigation + clear primary actions |
| Reliability | Analyzer/test gates |
| Security | Security policy set + coding requirements |
| Maintainability | Feature modules + contribution rules |
| Portability | iOS/Android/web/desktop folders |

---

## Gaps and intentional limitations (honest inventory)

| Gap | Status | Planned direction |
| --- | --- | --- |
| Formal org-wide ISMS certification evidence | Outside this repo | Maintain org documents separately |
| Enforced GitHub branch protection / required reviewers | Configured on primary public remote when admin available | Keep checklist current; mirror on injectGroup if org admin |
| Automated SAST beyond analyze + gitleaks | Partial (Security CI) | Expand when ready |
| App Check / API key restrictions in Console | Operator checklist | Enforce in Firebase/GCP Console |
| Formal ISO certification claim | Not claimed | Alignment only |

---

## Review checklist (annual)

- [ ] Security contacts still valid
- [ ] Supported versions table updated
- [ ] Threat model matches architecture
- [ ] Privacy notice matches actual data flows
- [ ] Contribution and PR templates still accurate
- [ ] Dependency policy still followed

---

## References (external)

- [GitHub Docs — Adding a security policy](https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository)
- [GitHub Docs — Community health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file)
- [Contributor Covenant](https://www.contributor-covenant.org/)
- ISO/IEC standards texts (official ISO store / organizational licenses)
