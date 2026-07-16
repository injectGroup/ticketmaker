# Development standards

Engineering standards for Quick Ticket Maker. These support ISO/IEC 25010 maintainability/reliability and ISO/IEC 27002 secure development expectations.

---

## 1. Language and framework

- Dart null safety is mandatory.
- Prefer Flutter 3.x Material 3 patterns already used in `AppTheme`.
- Do not reintroduce FlutterFlow runtime dependencies.

---

## 2. Code organization

- Put feature code under `lib/features/<feature>/`.
- Put shared theme/router/widgets under `lib/core/`.
- Keep widgets focused; extract sections when files become hard to review.
- Prefer immutable models with `copyWith` for state entities.

---

## 3. State management

- Use Cubit/Bloc for feature state.
- Keep side effects (snackbars, navigation) in listeners or UI callbacks, not deep in domain entities.
- Avoid global mutable singletons for feature state.

---

## 4. Style and static analysis

- `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`.
- Merge requirement: `flutter analyze` is clean.
- Do not disable linter rules broadly to silence issues; fix or scope with justification.

---

## 5. Testing

Minimum expectations:

| Type | Expectation |
| --- | --- |
| Widget/smoke | Cover primary Generate screen identity and critical controls |
| Unit | Required for non-trivial Cubit/business logic changes |
| Golden / integration | Optional; add when UI regressions are costly |

Run:

```bash
flutter test
```

---

## 6. Dependency management

1. Add dependencies only when necessary.
2. Prefer well-maintained packages with clear licenses compatible with Inject’s proprietary distribution model.
3. Commit `pubspec.lock`.
4. Review changelogs and advisories on upgrades.
5. Remove unused dependencies in the same PR when replacing libraries.

---

## 7. Secrets and configuration

Forbidden in git:

- API keys, OAuth tokens, private keys
- Production keystore passwords
- Customer personal data dumps
- `.env` files containing live credentials

Allowed:

- Example env templates with empty/placeholder values (if introduced later)
- Public URLs that are intentionally part of demo content

If a secret is committed accidentally:

1. Rotate the secret immediately.
2. Remove it from git history if required by Inject security process.
3. Report via [SECURITY.md](../SECURITY.md).

---

## 8. Pull request hygiene

- One concern per PR when practical.
- Update docs with behaviour changes.
- Call out security/privacy impact.
- Include screenshots for UI changes.
- Do not force-push `main`.

---

## 9. Accessibility and UX

- Keep text contrast readable on gradients.
- Provide fallbacks for failed network images.
- Avoid conveying information by color alone when adding new status indicators.
- Test on a small phone width and a tablet/desktop target when changing layout.

---

## 10. Definition of done

A change is done when:

1. Code is merged to `main` (or accepted by maintainer process).
2. Analyzer and tests pass.
3. Docs and TaskManager status reflect reality.
4. No known medium+ security issues introduced without an approved exception.
