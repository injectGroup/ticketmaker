import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_user.dart';

/// Local demo auth. Passwords are salted + base64-encoded (not production crypto).
class AuthRepository {
  AuthRepository({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _usersKey = 'auth.users.v1';
  static const _sessionEmailKey = 'auth.sessionEmail.v1';

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async =>
      _prefs ??= (_prefsOverride ?? await SharedPreferences.getInstance());

  Future<AppUser?> loadSession() async {
    final prefs = await _store;
    final email = prefs.getString(_sessionEmailKey);
    if (email == null || email.isEmpty) return null;
    final users = await _readUsers();
    final record = users[email.toLowerCase()];
    if (record == null) return null;
    return AppUser.fromJson(Map<String, dynamic>.from(record['user'] as Map));
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final users = await _readUsers();
    final record = users[normalized];
    if (record == null) {
      throw AuthException('No account found for that email.');
    }
    final salt = record['salt'] as String;
    final hash = record['passwordHash'] as String;
    if (_hash(password, salt) != hash) {
      throw AuthException('Incorrect password.');
    }
    final user = AppUser.fromJson(
      Map<String, dynamic>.from(record['user'] as Map),
    );
    final prefs = await _store;
    await prefs.setString(_sessionEmailKey, normalized);
    return user;
  }

  Future<AppUser> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required DateTime dateOfBirth,
    required bool marketingOptIn,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw AuthException('Enter a valid email address.');
    }
    if (password.trim().length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }
    final users = await _readUsers();
    if (users.containsKey(normalized)) {
      throw AuthException('An account already exists for that email.');
    }

    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final user = AppUser(
      id: 'user-$salt',
      email: normalized,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: phone.trim(),
      dateOfBirth: dateOfBirth,
      marketingOptIn: marketingOptIn,
    );

    users[normalized] = {
      'salt': salt,
      'passwordHash': _hash(password, salt),
      'user': user.toJson(),
    };
    await _writeUsers(users);
    final prefs = await _store;
    await prefs.setString(_sessionEmailKey, normalized);
    return user;
  }

  Future<AppUser> updateProfile(AppUser user) async {
    final users = await _readUsers();
    final key = user.email.toLowerCase();
    final record = users[key];
    if (record == null) {
      throw AuthException('Session expired. Please sign in again.');
    }
    record['user'] = user.toJson();
    users[key] = record;
    await _writeUsers(users);
    return user;
  }

  Future<void> signOut() async {
    final prefs = await _store;
    await prefs.remove(_sessionEmailKey);
  }

  Future<Map<String, Map<String, dynamic>>> _readUsers() async {
    final prefs = await _store;
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
    );
  }

  Future<void> _writeUsers(Map<String, Map<String, dynamic>> users) async {
    final prefs = await _store;
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  static String _hash(String password, String salt) {
    return base64Encode(utf8.encode('$salt::$password'));
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
