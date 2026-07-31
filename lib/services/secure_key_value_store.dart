import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key-value store that prefers [FlutterSecureStorage] and latches to a
/// [SharedPreferences] fallback when the secure-storage platform plugin is
/// unavailable (e.g. stale web registrant → MissingPluginException).
class SecureKeyValueStore {
  SecureKeyValueStore({
    FlutterSecureStorage? storage,
    SharedPreferences? preferences,
  }) : this._(
          storage ??
              const FlutterSecureStorage(
                // ignore: deprecated_member_use
                aOptions: AndroidOptions(encryptedSharedPreferences: true),
              ),
          preferences,
        );

  SecureKeyValueStore._(this._storage, this._preferences);

  static const String fallbackKeyPrefix = 'secure_fallback.';

  final FlutterSecureStorage _storage;
  SharedPreferences? _preferences;

  /// Once true, all subsequent ops go to SharedPreferences without retrying
  /// the missing secure-storage channel.
  bool _degraded = false;

  bool get isDegraded => _degraded;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  String _fallbackKey(String key) => '$fallbackKeyPrefix$key';

  bool _isPluginFailure(Object error) {
    return error is MissingPluginException ||
        error is PlatformException ||
        error is UnsupportedError;
  }

  Future<void> _latchDegraded(Object error) async {
    if (_degraded) return;
    _degraded = true;
    debugPrint(
      'SecureKeyValueStore: secure storage unavailable, '
      'falling back to SharedPreferences: $error',
    );
  }

  Future<String?> read(String key) async {
    if (_degraded) {
      return (await _prefs()).getString(_fallbackKey(key));
    }
    try {
      return await _storage.read(key: key);
    } catch (e) {
      if (!_isPluginFailure(e)) rethrow;
      await _latchDegraded(e);
      return (await _prefs()).getString(_fallbackKey(key));
    }
  }

  Future<void> write(String key, String value) async {
    if (_degraded) {
      await (await _prefs()).setString(_fallbackKey(key), value);
      return;
    }
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      if (!_isPluginFailure(e)) rethrow;
      await _latchDegraded(e);
      await (await _prefs()).setString(_fallbackKey(key), value);
    }
  }

  Future<void> delete(String key) async {
    if (_degraded) {
      await (await _prefs()).remove(_fallbackKey(key));
      return;
    }
    try {
      await _storage.delete(key: key);
    } catch (e) {
      if (!_isPluginFailure(e)) rethrow;
      await _latchDegraded(e);
      await (await _prefs()).remove(_fallbackKey(key));
    }
  }

  Future<Map<String, String>> readAll() async {
    if (_degraded) {
      return _readAllFallback();
    }
    try {
      return await _storage.readAll();
    } catch (e) {
      if (!_isPluginFailure(e)) rethrow;
      await _latchDegraded(e);
      return _readAllFallback();
    }
  }

  Future<Map<String, String>> _readAllFallback() async {
    final prefs = await _prefs();
    final result = <String, String>{};
    for (final entry in prefs.getKeys()) {
      if (!entry.startsWith(fallbackKeyPrefix)) continue;
      final value = prefs.getString(entry);
      if (value == null) continue;
      result[entry.substring(fallbackKeyPrefix.length)] = value;
    }
    return result;
  }
}
