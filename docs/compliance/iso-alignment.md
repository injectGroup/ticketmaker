# ISO alignment

## Purpose

Map Quick Ticket Maker repository practices to selected ISO/IEC standards used by Inject for software security, privacy, and life-cycle quality.

> **Important:** This mapping demonstrates **alignment of documentation and engineering practices**. It is **not** a claim that Inject or this product is formally ISO-certified.

---

## Document control

| Field | Value |
| --- | --- |
| Product | Quick Ticket Maker |
| Repository | injectGroup/ticketmaker |
| Last reviewed | 2026-07-16 |

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
| Access control / least privilege | Private repo; collaborator roles; SSH preferred ([getting-started.md](../getting-started.md)) |
| Secure development life cycle | PR reviews, analyzer/tests, [secure-coding.md](../security/secure-coding.md) |
| Management of technical vulnerabilities | [SECURITY.md](../../SECURITY.md), dependency review expectations |
| Logging / privacy in logs | Secure coding + privacy notice restrictions |
| Supplier relationships (packages) | Dependency rules in development + threat model |

### B. Privacy (27701 themes)

| Theme | Repository implementation |
| --- | --- |
| Privacy notice / transparency | [privacy.md](../privacy.md) |
| Data minimization | In-memory preview state; no account system |
| Purpose limitation | Features doc states preview-only purpose |
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
| Enforced GitHub branch protection / required reviewers | Configuration dependent | Enable on `main` for all writes |
| Automated SAST/DAST in CI | Not yet configured | Add CI workflow when ready |
| Persistent data encryption controls | N/A (no persistence) | Define before adding storage |
| Production telemetry governance | N/A | Update privacy + threat model before enabling |

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
