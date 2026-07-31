import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pins the published documentation against the behaviour that actually ships.
///
/// These are documents rather than logic, but the claims are load-bearing: the
/// privacy notice and threat model are compliance artefacts, and the features
/// spec calls itself "the source of truth for shipped behaviour".
String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  return file.readAsStringSync();
}

void _mustNotContain(String doc, String path, List<String> staleClaims) {
  for (final claim in staleClaims) {
    expect(
      doc,
      isNot(contains(claim)),
      reason: '$path still contains the stale claim: "$claim"',
    );
  }
}

void _mustContain(String doc, String path, List<String> facts) {
  for (final fact in facts) {
    expect(
      doc,
      contains(fact),
      reason: '$path should document: "$fact"',
    );
  }
}

void main() {
  group('docs/architecture.md', () {
    test('no longer denies the shipped backend, auth, or persistence', () {
      _mustNotContain(_read('docs/architecture.md'), 'docs/architecture.md', [
        'No first-party backend API',
        'No authentication service',
        'No persistent local database',
        'QR payloads are client-generated strings/URLs for preview only',
        'Future extension points (not implemented)',
        'TicketsPage (sample list)',
      ]);
    });

    test('describes the as-built system', () {
      _mustContain(_read('docs/architecture.md'), 'docs/architecture.md', [
        'Cloud Firestore',
        'Firebase Auth',
        '/verify/:id',
        'SecureKeyValueStore',
        'Storage is deliberately not used',
      ]);
    });
  });

  group('docs/features.md', () {
    test('no longer describes the preview-only demo', () {
      _mustNotContain(_read('docs/features.md'), 'docs/features.md', [
        'There is no authenticated end-user role in the current release.',
        'no backend is guaranteed to resolve it',
        'Displays two hardcoded sample tickets',
        '**Not implemented.** Tickets created on Generate are not saved',
        '| Discover | `/discover` |',
        'Circu Du Freak',
      ]);
    });

    test('documents the shipped journey', () {
      _mustContain(_read('docs/features.md'), 'docs/features.md', [
        'F-TKT-002',
        'F-VER-001',
        '/verify/:id',
        'single-use',
      ]);
    });
  });

  group('docs/privacy.md', () {
    test('no longer claims the app is local-only with no backend', () {
      _mustNotContain(_read('docs/privacy.md'), 'docs/privacy.md', [
        'Inject does **not** operate a first-party backend for this app.',
        'Ticket state lives in memory for the session (not persisted by the app).',
        'The app does **not** require account registration.',
      ]);
    });

    test('discloses Firebase and the world-readable ticket document', () {
      _mustContain(_read('docs/privacy.md'), 'docs/privacy.md', [
        'Firebase',
        'Cloud Firestore',
        'publicly readable',
        'guest name',
      ]);
    });
  });

  group('docs/security/threat-model.md', () {
    test('no longer calls QR payloads preview-only artifacts', () {
      _mustNotContain(
        _read('docs/security/threat-model.md'),
        'docs/security/threat-model.md',
        ['Generated QR content and ticket codes are **preview artifacts**'],
      );
    });

    test('covers the public verification trust boundary', () {
      _mustContain(
        _read('docs/security/threat-model.md'),
        'docs/security/threat-model.md',
        [
          'tickets/{guestCode}',
          'single-use',
          'unauthenticated',
        ],
      );
    });
  });

  group('CHANGELOG.md', () {
    test('records the V1 personal ticket share milestone', () {
      _mustContain(_read('CHANGELOG.md'), 'CHANGELOG.md', [
        'secure storage',
        '/verify/:id',
        '### Fixed',
        '### Security',
      ]);
    });
  });

  group('USER_RESEARCH_REPORT.md', () {
    test('documents the structural defects found in local simulation', () {
      _mustContain(
        _read('USER_RESEARCH_REPORT.md'),
        'USER_RESEARCH_REPORT.md',
        [
          'Structural defects',
          'MissingPluginException',
          'Noto',
          'compact',
        ],
      );
    });
  });

  group('QR host', () {
    test('the docs quote the host TicketPayload actually generates', () {
      final source = _read('lib/features/tickets/data/ticket_payload.dart');
      final host = RegExp(r"static const String host = '([^']+)'")
          .firstMatch(source)
          ?.group(1);
      expect(host, isNotNull, reason: 'TicketPayload.host not found');

      for (final path in const ['docs/features.md', 'docs/privacy.md']) {
        expect(
          _read(path),
          contains(host!),
          reason: '$path quotes a QR host other than the generated $host',
        );
      }
    });
  });

  group('README.md', () {
    test('does not list shipped features as out of scope', () {
      _mustNotContain(_read('README.md'), 'README.md', [
        '- User authentication and authorization',
        '- Persistent ticket storage / sync',
        '- QR scanning / door admission workflows',
        '- Export, share, or print pipelines',
        'browse a sample ticket list (placeholder until persistence is added)',
      ]);
    });
  });

  group('multi-format share', () {
    test('the docs no longer call PDF export out of scope', () {
      for (final path in const ['README.md', 'docs/features.md']) {
        _mustNotContain(_read(path), path, ['PDF export (PNG only)']);
      }
    });

    test('the shipped PDF path is documented', () {
      _mustContain(_read('docs/features.md'), 'docs/features.md', [
        'TicketPdfExport',
        'Share as PDF',
      ]);
      _mustContain(_read('README.md'), 'README.md', ['PDF']);
      _mustContain(_read('docs/privacy.md'), 'docs/privacy.md', ['PDF']);
    });
  });
}
