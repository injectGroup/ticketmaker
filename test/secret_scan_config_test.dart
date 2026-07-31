import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Gitleaks allowlist.
///
/// Firebase client API keys in `lib/firebase_options.dart` are public by design
/// — FlutterFire generates that file to be committed, and the threat model
/// classifies the keys as low sensitivity. Gitleaks still flags them as
/// `gcp-api-key`, so they are allowlisted.
///
/// The risk is that someone later widens this into a blanket bypass, so these
/// tests pin the allowlist narrow: default rules stay on, and only Google
/// API-key-shaped strings in that one generated file are exempt.
String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  return file.readAsStringSync();
}

void main() {
  group('gitleaks.toml', () {
    test('keeps the default rule set enabled', () {
      final config = _read('gitleaks.toml');
      expect(
        config,
        contains('useDefault = true'),
        reason: 'the allowlist must extend the default rules, not replace them',
      );
    });

    test('exempts only the generated Firebase options file', () {
      final config = _read('gitleaks.toml');

      expect(config, contains('firebase_options'));
      expect(
        config,
        contains('gcp-api-key'),
        reason: 'the exemption should name the rule it answers',
      );

      final paths = RegExp(r'''paths\s*=\s*\[([^\]]*)\]''', dotAll: true)
          .firstMatch(config)
          ?.group(1);
      expect(paths, isNotNull, reason: 'no allowlist paths found');
      expect(
        RegExp(r'''['"]{1,3}''').allMatches(paths!).length ~/ 2,
        1,
        reason: 'exactly one path may be allowlisted, found: $paths',
      );
    });

    test('is scoped to Google API key shapes, not the whole file', () {
      final config = _read('gitleaks.toml');
      expect(
        config,
        contains('AIza'),
        reason: 'restrict the exemption to Google API key shaped values so '
            'other secret types in that file are still caught',
      );
    });

    test('does not disable scanning wholesale', () {
      final config = _read('gitleaks.toml');
      for (final banned in const [
        'paths = [\'\'\'.*\'\'\']',
        'stopwords',
        'useDefault = false',
      ]) {
        expect(
          config,
          isNot(contains(banned)),
          reason: 'gitleaks.toml must not neuter the scan ($banned)',
        );
      }
    });
  });

  group('security-ci.yml', () {
    test('points Gitleaks at the committed config', () {
      final workflow = _read('.github/workflows/security-ci.yml');
      expect(
        workflow,
        contains('GITLEAKS_CONFIG'),
        reason: 'the action ignores gitleaks.toml unless GITLEAKS_CONFIG is set',
      );
      expect(workflow, contains('gitleaks.toml'));
    });

    test('still runs the scan on pull requests to main', () {
      final workflow = _read('.github/workflows/security-ci.yml');
      expect(workflow, contains('gitleaks/gitleaks-action'));
      expect(workflow, contains('pull_request'));
    });
  });
}
