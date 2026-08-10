import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/auth/data/auth_repository.dart';

void main() {
  group('mapFirebaseAuthError — Google web popup', () {
    test('popup-closed-by-user is informative, not silent', () {
      final message = mapFirebaseAuthError(
        FirebaseAuthException(code: 'popup-closed-by-user'),
      );
      expect(message.toLowerCase(), contains('closed'));
      expect(message.toLowerCase(), anyOf(contains('google'), contains('sign')));
    });

    test('popup-blocked tells the user to allow popups', () {
      final message = mapFirebaseAuthError(
        FirebaseAuthException(code: 'popup-blocked'),
      );
      expect(message.toLowerCase(), contains('popup'));
      expect(message.toLowerCase(), contains('allow'));
    });

    test('cancelled-popup-request asks the user to try again', () {
      final message = mapFirebaseAuthError(
        FirebaseAuthException(code: 'cancelled-popup-request'),
      );
      expect(message.toLowerCase(), contains('try again'));
    });

    test('existing email/password codes stay unchanged', () {
      expect(
        mapFirebaseAuthError(FirebaseAuthException(code: 'wrong-password')),
        'Incorrect email or password.',
      );
      expect(
        mapFirebaseAuthError(
          FirebaseAuthException(code: 'operation-not-allowed'),
        ),
        'This sign-in method is not enabled in Firebase Console.',
      );
    });
  });
}
