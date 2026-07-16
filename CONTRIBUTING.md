# Contributing to Quick Ticket Maker

Thank you for contributing to **Quick Ticket Maker**. This guide explains how authorized collaborators propose changes safely and consistently.

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md) and the [Security Policy](SECURITY.md).

---

## Who can contribute

This is a **private Inject repository**. Contributions are limited to:

- Inject employees and contractors with repository access
- External collaborators explicitly granted write/triage permissions

If you lack access, request it from an Inject maintainer. Do not fork publicly with proprietary code.

---

## Before you start

1. Read [docs/getting-started.md](docs/getting-started.md) and [docs/architecture.md](docs/architecture.md).
2. Search existing Issues and Pull Requests to avoid duplicates.
3. For security-sensitive work, read [docs/security/secure-coding.md](docs/security/secure-coding.md).
4. Open an Issue (or link a TaskManager task) describing the change **before** large implementations.

---

## Development workflow

### 1. Clone and branch

```bash
git clone git@github.com:injectGroup/ticketmaker.git
cd ticketmaker
flutter pub get
git checkout -b feature/<short-description>
# or: fix/<short-description> | docs/<short-description> | security/<short-description>
```

Branch from `main`. Keep branches short-lived.

### 2. Implement

- Prefer small, focused commits.
- Match existing architecture (`core/` vs `features/`).
- Do not introduce unrelated refactors outside the PR scope.
- Do not commit secrets, credentials, or personal data.

### 3. Verify locally (required quality gates)

```bash
flutter pub get
flutter analyze
flutter test
```

Optional platform checks:

```bash
flutter build apk --debug
flutter build ios --debug --no-codesign
flutter build web
```

### 4. Commit messages

Use clear, imperative summaries:

```text
Add ticket export stub for PDF preview

Explain why the change is needed in the body when non-obvious.
```

Include TaskManager / Issue IDs when applicable:

```text
Fix QR shape toggle not updating preview

Refs: task-1784203205908
```

### 5. Open a pull request

- Use the PR template in `.github/PULL_REQUEST_TEMPLATE.md`.
- Link related Issues.
- Describe security impact (even if “none”).
- Request review from at least one maintainer.
- Do not force-push shared branches after review starts unless agreed.

---

## Pull request requirements

A PR is ready for merge when:

- [ ] Scope is clear and limited to the stated goal
- [ ] `flutter analyze` reports no issues
- [ ] `flutter test` passes
- [ ] Docs updated if behaviour or public APIs changed
- [ ] No secrets or credential files included
- [ ] Security implications noted
- [ ] Code of Conduct and license terms respected

Maintainers may request additional tests, threat-model notes, or accessibility checks for UI changes.

---

## Issue guidelines

### Bug reports

Use the Bug Report template. Include:

- Platform and OS version
- App version / commit
- Steps to reproduce
- Expected vs actual results
- Screenshots or logs (redact secrets)

### Feature requests

Use the Feature Request template. Include:

- Problem statement
- Proposed solution
- Alternatives considered
- Security / privacy impact

### Security vulnerabilities

**Do not** file public Issues. Follow [SECURITY.md](SECURITY.md).

---

## Coding standards

See [docs/development.md](docs/development.md) for:

- Dart/Flutter style
- Feature module layout
- State management conventions
- Testing expectations
- Accessibility and internationalization notes

---

## Documentation contributions

Documentation lives primarily under `docs/` and root community health files.

When changing behaviour:

1. Update the relevant `docs/*.md` file in the same PR.
2. Keep README feature lists accurate (no aspirational features presented as shipped).
3. Update ISO/security docs only when controls or processes actually change.

---

## Task tracking

Inject uses TaskManager for delivery tracking. When working on tracked work:

1. Mark the task **in-progress** when starting.
2. Mark **done** when merged / verified.
3. Keep `.taskmanager/tasks.json` consistent with reality (local backup).

---

## License

Contributions are submitted under the repository [LICENSE](LICENSE). You confirm you have the right to submit the contribution and that it does not include unauthorized third-party proprietary code.

---

## Questions

See [SUPPORT.md](SUPPORT.md).
