import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards decision D3: this release ships as `v1.0.0`.
///
/// The version is asserted in three places that are easy to let drift apart —
/// `pubspec.yaml`, the Android build script, and the changelog — because Play
/// rejects a reused `versionCode` and a changelog that disagrees with the tag is
/// worse than no changelog.
String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  return file.readAsStringSync();
}

void main() {
  const version = '1.0.0';
  const buildNumber = '1';
  const releaseDate = '2026-07-31';

  test('pubspec declares $version+$buildNumber', () {
    expect(
      _read('pubspec.yaml'),
      contains('\nversion: $version+$buildNumber\n'),
      reason: 'pubspec version must match the release tag v$version',
    );
  });

  test('Android version comes from the Flutter toolchain, not hardcoded', () {
    final gradle = _read('android/app/build.gradle.kts');
    expect(
      gradle,
      contains('flutter.versionCode'),
      reason: 'versionCode must follow pubspec so Play never sees a reuse',
    );
    expect(gradle, contains('flutter.versionName'));
  });

  group('CHANGELOG.md', () {
    test('has a single dated $version section, not an open Unreleased one', () {
      final changelog = _read('CHANGELOG.md');

      expect(
        changelog,
        contains('## [$version] - $releaseDate'),
        reason: 'the release section must be dated for the tag',
      );

      final headings = RegExp(
        r'^## \[' + version + r'\]',
        multiLine: true,
      ).allMatches(changelog);
      expect(
        headings.length,
        1,
        reason: 'found ${headings.length} "[$version]" headings; '
            'the V1 work and the baseline must live in one $version release',
      );
    });

    test('the V1 milestone sits under the $version heading', () {
      final changelog = _read('CHANGELOG.md');
      final releaseAt = changelog.indexOf('## [$version]');
      expect(releaseAt, greaterThan(-1));

      for (final entry in const [
        '/verify/:id',
        'secure storage',
        '### Security',
      ]) {
        final at = changelog.indexOf(entry);
        expect(at, greaterThan(-1), reason: 'missing changelog entry: $entry');
        expect(
          at,
          greaterThan(releaseAt),
          reason: '"$entry" is above the $version heading, so it reads as '
              'unreleased work',
        );
      }
    });

    test('links the v$version tag', () {
      expect(
        _read('CHANGELOG.md'),
        contains('[$version]: https://github.com/injectGroup/ticketmaker/'
            'releases/tag/v$version'),
      );
    });
  });
}
