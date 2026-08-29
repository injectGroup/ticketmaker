import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web Google Sign-In uses Firebase popup; native keeps GoogleSignIn', () {
    final source = File(
      'lib/features/auth/data/auth_repository.dart',
    ).readAsStringSync();

    expect(source, contains('kIsWeb'));
    expect(source, contains('GoogleAuthProvider()'));
    expect(source, contains('signInWithPopup'));
    expect(
      source,
      contains('authenticate()'),
      reason: 'iOS/Android must still use GoogleSignIn.authenticate',
    );
    expect(
      source,
      contains('e.toString()'),
      reason: 'Google Sign-In errors must print e.toString() for the console',
    );
  });
}
