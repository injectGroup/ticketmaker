import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/entities/app_user.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Contract for auth backends (Firebase production, in-memory tests).
abstract class AuthRepository {
  Future<AppUser?> loadSession();

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithApple();

  Future<AppUser> updateProfile(AppUser user);

  Future<void> signOut();
}

/// Firebase Auth + Firestore `users/{uid}` profiles.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// iOS OAuth client from GoogleService-Info.plist `CLIENT_ID`.
  static const _googleIosClientId =
      '107781542059-s9csu7kamfsavn0n0c30eda68ikrgma6.apps.googleusercontent.com';

  /// Web OAuth client from google-services.json (client_type 3) — used as
  /// `serverClientId` so Google returns an ID token for Firebase Auth.
  static const _googleWebClientId =
      '107781542059-j20t5d1kggv1lkfek3s6nti1lduojoo3.apps.googleusercontent.com';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    try {
      // iOS client from GoogleService-Info.plist; web client as serverClientId
      // so Android/iOS can obtain an ID token for Firebase Auth.
      await _googleSignIn.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS
            ? _googleIosClientId
            : null,
        serverClientId: _googleWebClientId,
      );
      _googleInitialized = true;
    } catch (e) {
      throw AuthException(
        'Google Sign-In is not configured. Enable Google in Firebase Console '
        'and add OAuth client IDs to the app.',
      );
    }
  }

  @override
  Future<AppUser?> loadSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _userFromFirebase(firebaseUser);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw AuthException('Enter a valid email address.');
    }
    if (password.isEmpty) {
      throw AuthException('Enter your password.');
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AuthException('Could not sign in. Try again.');
      }
      return _userFromFirebase(user);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (_) {
      throw AuthException('Could not sign in. Try again.');
    }
  }

  @override
  Future<AppUser> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isEmpty || last.isEmpty) {
      throw AuthException('Enter your first and last name.');
    }
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw AuthException('Enter a valid email address.');
    }
    if (password.trim().length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AuthException('Could not create account. Try again.');
      }
      final appUser = AppUser(
        id: firebaseUser.uid,
        email: normalized,
        firstName: first,
        lastName: last,
      );
      // Don't block Save Ticket / sheet dismiss on profile sync.
      final displayName = '$first $last'.trim();
      unawaited(
        firebaseUser.updateDisplayName(displayName).catchError((_) {}),
      );
      _persistUserInBackground(appUser, isNew: true);
      return appUser;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (_) {
      throw AuthException('Could not create account. Try again.');
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthException(
          'Google Sign-In did not return an ID token. Check OAuth client setup.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AuthException('Google Sign-In failed. Try again.');
      }
      return _finalizeSocialUser(
        firebaseUser,
        displayName: account.displayName,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
      );
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Google Sign-In was cancelled.');
      }
      throw AuthException(
        'Google Sign-In is unavailable. Enable Google in Firebase Console.',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (_) {
      throw AuthException(
        'Google Sign-In failed. Ensure Google provider and OAuth clients are set up.',
      );
    }
  }

  @override
  Future<AppUser> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthException('Apple Sign-In did not return an identity token.');
      }
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
      );
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AuthException('Apple Sign-In failed. Try again.');
      }
      final given = appleCredential.givenName?.trim() ?? '';
      final family = appleCredential.familyName?.trim() ?? '';
      final appleDisplay = [given, family].where((s) => s.isNotEmpty).join(' ');
      return _finalizeSocialUser(
        firebaseUser,
        displayName: appleDisplay.isEmpty ? null : appleDisplay,
        firstNameHint: given.isEmpty ? null : given,
        lastNameHint: family.isEmpty ? null : family,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
      );
    } on AuthException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException('Apple Sign-In was cancelled.');
      }
      throw AuthException(
        'Apple Sign-In is unavailable. Enable Apple in Firebase Console '
        'and the Sign in with Apple capability.',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (_) {
      throw AuthException(
        'Apple Sign-In failed. Enable the Apple provider in Firebase Console.',
      );
    }
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    final current = _auth.currentUser;
    if (current == null || current.uid != user.id) {
      throw AuthException('Session expired. Please sign in again.');
    }
    await _upsertUserDoc(user, isNew: false);
    return user;
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Google may be unconfigured; still sign out of Firebase.
    }
    await _auth.signOut();
  }

  Future<AppUser> _finalizeSocialUser(
    User firebaseUser, {
    String? displayName,
    String? firstNameHint,
    String? lastNameHint,
    required bool isNewUser,
  }) async {
    final existing = await _fetchUserDoc(firebaseUser.uid);
    if (existing != null) {
      return existing;
    }
    final parsed = _splitDisplayName(
      displayName ?? firebaseUser.displayName ?? '',
    );
    final appUser = AppUser(
      id: firebaseUser.uid,
      email: (firebaseUser.email ?? '').toLowerCase(),
      firstName: firstNameHint?.isNotEmpty == true
          ? firstNameHint!
          : parsed.$1,
      lastName: lastNameHint?.isNotEmpty == true ? lastNameHint! : parsed.$2,
    );
    _persistUserInBackground(
      appUser,
      isNew: isNewUser || existing == null,
    );
    return appUser;
  }

  Future<AppUser> _userFromFirebase(User firebaseUser) async {
    final existing = await _fetchUserDoc(firebaseUser.uid);
    if (existing != null) return existing;
    final parsed = _splitDisplayName(firebaseUser.displayName ?? '');
    final appUser = AppUser(
      id: firebaseUser.uid,
      email: (firebaseUser.email ?? '').toLowerCase(),
      firstName: parsed.$1,
      lastName: parsed.$2,
    );
    _persistUserInBackground(appUser, isNew: true);
    return appUser;
  }

  Future<AppUser?> _fetchUserDoc(String uid) async {
    try {
      final snap = await _users.doc(uid).get();
      if (!snap.exists || snap.data() == null) return null;
      final data = Map<String, dynamic>.from(snap.data()!);
      data['id'] = uid;
      return AppUser.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  void _persistUserInBackground(AppUser user, {required bool isNew}) {
    unawaited(_upsertUserDoc(user, isNew: isNew).catchError((_) {}));
  }

  Future<void> _upsertUserDoc(AppUser user, {required bool isNew}) async {
    final payload = <String, dynamic>{
      ...user.toJson(),
      'uid': user.id,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isNew) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    await _users.doc(user.id).set(payload, SetOptions(merge: true));
  }

  static (String, String) _splitDisplayName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  static String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Console.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Authentication failed. Try again.';
    }
  }
}

/// In-memory auth for widget/unit tests (no Firebase).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser}) : _session = initialUser;

  AppUser? _session;
  final Map<String, ({AppUser user, String password})> _accounts = {};

  @override
  Future<AppUser?> loadSession() async => _session;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    final record = _accounts[key];
    if (record == null) {
      throw AuthException('No account found for that email.');
    }
    if (record.password != password) {
      throw AuthException('Incorrect password.');
    }
    _session = record.user;
    return record.user;
  }

  @override
  Future<AppUser> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw AuthException('An account already exists for that email.');
    }
    if (password.trim().length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }
    final user = AppUser(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      email: key,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    );
    _accounts[key] = (user: user, password: password);
    _session = user;
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final user = AppUser(
      id: 'google-user',
      email: 'google@example.com',
      firstName: 'Google',
      lastName: 'User',
    );
    _session = user;
    return user;
  }

  @override
  Future<AppUser> signInWithApple() async {
    final user = AppUser(
      id: 'apple-user',
      email: 'apple@example.com',
      firstName: 'Apple',
      lastName: 'User',
    );
    _session = user;
    return user;
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    if (_session == null || _session!.id != user.id) {
      throw AuthException('Session expired. Please sign in again.');
    }
    _session = user;
    final key = user.email.toLowerCase();
    final existing = _accounts[key];
    if (existing != null) {
      _accounts[key] = (user: user, password: existing.password);
    }
    return user;
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }
}
