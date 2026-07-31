import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Play Console package name for the internal testing track.
const _packageId = 'com.agathakakalogical.quickticketmaker';

const _gradlePath = 'android/app/build.gradle.kts';
const _manifestPath = 'android/app/src/main/AndroidManifest.xml';
const _mainActivityPath =
    'android/app/src/main/kotlin/com/agathakakalogical/quickticketmaker/'
    'MainActivity.kt';
const _legacyMainActivityPath =
    'android/app/src/main/kotlin/com/injectgroup/ticket_maker/MainActivity.kt';

String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  return file.readAsStringSync();
}

void main() {
  group('release signing', () {
    test('does not fall back to the debug keystore', () {
      // A debug-signed bundle is rejected by every Play Console track.
      expect(
        _read(_gradlePath),
        isNot(contains('signingConfigs.getByName("debug")')),
      );
    });

    test('declares and uses a dedicated release config', () {
      final gradle = _read(_gradlePath);

      expect(gradle, contains('create("release")'));
      expect(gradle, contains('signingConfigs.getByName("release")'));
    });

    test('sources credentials from key.properties rather than the repo', () {
      final gradle = _read(_gradlePath);

      expect(gradle, contains('key.properties'));
      expect(gradle, contains('storeFile'));
      expect(gradle, contains('storePassword'));
      expect(gradle, contains('keyAlias'));
      expect(gradle, contains('keyPassword'));
    });
  });

  group('application identity', () {
    test('applicationId and namespace both use the Play package name', () {
      final gradle = _read(_gradlePath);

      expect(gradle, contains('applicationId = "$_packageId"'));
      expect(gradle, contains('namespace = "$_packageId"'));
    });

    test('targetSdk follows the Flutter toolchain instead of a pinned level',
        () {
      // Play raises its required target API level annually; pinning a number
      // silently freezes the app below the threshold.
      expect(_read(_gradlePath), contains('targetSdk = flutter.targetSdkVersion'));
    });

    test('the launcher shows the product name', () {
      expect(
        _read(_manifestPath),
        contains('android:label="Quick Ticket Maker"'),
      );
    });
  });

  group('MainActivity package path', () {
    test('matches the namespace', () {
      expect(_read(_mainActivityPath), contains('package $_packageId'));
    });

    test('leaves no copy behind under the old package', () {
      expect(
        File(_legacyMainActivityPath).existsSync(),
        isFalse,
        reason: 'stale MainActivity under the injectgroup package',
      );
    });
  });

  group('signing material stays out of git', () {
    test('.gitignore excludes the keystore and its passwords', () {
      final ignore = _read('.gitignore');

      expect(ignore, contains('key.properties'));
      expect(ignore, contains('*.jks'));
      expect(ignore, contains('*.keystore'));
    });
  });

  group('product name across platforms', () {
    test('iOS CFBundleDisplayName matches the product name', () {
      expect(
        _read('ios/Runner/Info.plist'),
        contains('<string>Quick Ticket Maker</string>'),
      );
    });

    test('web manifest uses the product name', () {
      final manifest = _read('web/manifest.json');
      expect(manifest, contains('"name": "Quick Ticket Maker"'));
      expect(manifest, contains('"short_name": "Quick Ticket"'));
    });
  });
}
