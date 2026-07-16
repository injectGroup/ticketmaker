# Changelog

All notable changes to Quick Ticket Maker are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Full GitHub community health documentation set (README, SECURITY, CONTRIBUTING, CODE_OF_CONDUCT, SUPPORT, LICENSE)
- Product docs under `docs/` (architecture, features, getting started, development, privacy)
- Security pack (information security policy, threat model, secure coding)
- ISO alignment mapping (`docs/compliance/iso-alignment.md`)
- GitHub Issue/PR templates and Dependabot configuration
- Hardened `.gitignore` for secrets and credential files

## [1.0.0] - 2026-07-16

### Added

- Initial Flutter rewrite of Quick Ticket Maker (Generate + Tickets tabs)
- QR customization (colors, shape), ticket code generation, background gradients, image refresh
- Cubit state management, go_router shell navigation
- TaskManager local backup under `.taskmanager/`

[Unreleased]: https://github.com/injectGroup/ticketmaker/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/injectGroup/ticketmaker/releases/tag/v1.0.0
