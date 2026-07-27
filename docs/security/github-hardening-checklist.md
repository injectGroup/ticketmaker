# GitHub hardening checklist (public repository)

Operator checklist for Quick Ticket Maker remotes. Visibility stays **public**; compensating controls below protect secrets and supply chain. Proprietary [LICENSE](../../LICENSE) restricts commercial use but does **not** hide source.

**Primary remote:** `ejike-art/ticketmaker-gen-and-tickets-only`  
**Upstream (optional mirror):** `injectGroup/ticketmaker` — apply only with org admin rights.

Last reviewed: 2026-07-27

---

## 1. Code security (Settings → Code security)

- [ ] **Secret scanning** enabled
- [ ] **Push protection** enabled (blocks commits containing known secret patterns)
- [ ] **Dependabot alerts** enabled
- [ ] **Dependabot security updates** enabled when available
- [ ] **Private vulnerability reporting** enabled (Security → Advisories)

## 2. Branch protection

Protect default branch (`gen-and-tickets-only` and/or `main`):

- [ ] Require a pull request before merging
- [ ] Dismiss stale pull request approvals when new commits are pushed
- [ ] Do not allow force pushes
- [ ] Do not allow deletions
- [ ] Require status checks to pass: `Flutter analyze and test`, `Gitleaks secret scan` (after [security-ci.yml](../../.github/workflows/security-ci.yml) runs)

## 3. Actions secrets

- [ ] `GOOGLE_CHAT_WEBHOOK_URL` set as a repository secret only (never committed)
- [ ] No production service-account JSON in Actions logs or artifacts

## 4. Client Firebase keys

[`lib/firebase_options.dart`](../../lib/firebase_options.dart) contains **public client** API keys (normal for Firebase SDKs). They are not server secrets. Compensating controls:

- [ ] Restrict API keys in Google Cloud Console (HTTP referrers / app package / bundle ID)
- [ ] Enable App Check for Auth, Firestore, and Storage — see [firebase-console-hardening.md](firebase-console-hardening.md)

## 5. Verify via CLI

```bash
gh api repos/ejike-art/ticketmaker-gen-and-tickets-only --jq '{private,visibility,default_branch:.default_branch}'
gh api repos/ejike-art/ticketmaker-gen-and-tickets-only/vulnerability-alerts -X GET
# Branch protection (rulesets or classic):
gh api repos/ejike-art/ticketmaker-gen-and-tickets-only/branches/gen-and-tickets-only/protection
```

## 6. Related docs

- [information-security-policy.md](information-security-policy.md)
- [threat-model.md](threat-model.md)
- [../../SECURITY.md](../../SECURITY.md)
