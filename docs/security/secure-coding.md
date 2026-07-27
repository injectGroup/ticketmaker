# Secure coding requirements

Mandatory engineering controls for contributors to Quick Ticket Maker.

Aligned with ISO/IEC 27002 secure coding themes and GitHub secure development guidance.

---

## 1. Input handling

1. Treat all external data as untrusted (network responses, future form fields, deep links, clipboard, QR scan results).
2. Validate and constrain types, lengths, and formats before use.
3. Prefer allowlists over denylists for URLs and schemes (`https` only unless justified).
4. Never construct executable code from strings based on user input.

---

## 2. Secrets

1. Do not hard-code credentials, webhooks, or service-account JSON.
2. Do not commit keystores with production passwords.
3. Use CI secret stores for automation credentials.
4. Redact secrets in logs, screenshots, and crash reports.
5. Rotate immediately on exposure.
6. Firebase **client** API keys in `lib/firebase_options.dart` are public-by-design for mobile/web SDKs — never treat them as server secrets; enforce Console API key restrictions and App Check ([firebase-console-hardening.md](firebase-console-hardening.md)).
7. Auth debug logs may record password emptiness only — never raw passwords.

---

## 3. Cryptography

1. Do not invent crypto protocols for ticket authenticity.
2. Use platform TLS; do not disable certificate validation.
3. If adding token storage, use OS-provided secure storage — not plaintext SharedPreferences for secrets.

---

## 4. Data minimization

1. Collect only data needed for a defined purpose (see [privacy.md](../privacy.md)).
2. Avoid embedding personal data in QR payloads unless required and disclosed.
3. Prefer synthetic demo data in screenshots and docs.

---

## 5. Dependencies

1. Justify each new package in the PR description.
2. Check licenses for proprietary-distribution compatibility.
3. Prefer packages with active maintenance.
4. After upgrades, run analyzer and tests; smoke-test Generate and Tickets flows.

---

## 6. UI / webviews / links

1. If opening URLs, use vetted APIs (`url_launcher` with scheme checks) when introduced.
2. Do not enable arbitrary JavaScript bridges without a security review.
3. Sanitize any future HTML rendering surfaces.

---

## 7. Error handling

1. Fail closed for security decisions (deny by default).
2. Show user-friendly errors without leaking internals.
3. Log enough for debugging in development; avoid sensitive detail in production logs.

---

## 8. Testing for security-relevant changes

For auth, storage, networking, or parsing changes, include tests for:

- Rejecting invalid input
- Handling missing network / timeouts
- Ensuring secrets are not serialized into unexpected outputs

---

## 9. Pull request security checklist

Contributors must answer in the PR template:

- [ ] Does this change introduce network calls, storage, or auth?
- [ ] Are new dependencies justified and reviewed?
- [ ] Are secrets absent from the diff?
- [ ] Were docs/threat model updated if trust boundaries changed?

---

## 10. Prohibited patterns

- Committing `.env` with live values
- `http://` cleartext endpoints for new features (except local dev with documentation)
- Copy-pasting unknown code from untrusted sources without review
- Disabling analyzer/linter rules to hide security defects
- Publishing proprietary source to a **new** public remote without maintainer approval, LICENSE intact, and compensating GitHub/Firebase controls ([github-hardening-checklist.md](github-hardening-checklist.md))
