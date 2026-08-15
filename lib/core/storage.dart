import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Namespaced, crash-safe wrapper over SharedPreferences.
///
/// SharedPreferences backs onto the platform's own key-value store —
/// SharedPreferences on Android and HarmonyOS, NSUserDefaults on iOS,
/// localStorage on web — so persistence works identically everywhere without
/// any platform code of ours.
class Store {
  Store._(this._prefs);

  static const _prefix = 'getteksi:';
  static Store? _instance;

  final SharedPreferences _prefs;

  static Store get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('Store.init() must be awaited before use');
    }
    return i;
  }

  static Future<void> init() async {
    _instance = Store._(await SharedPreferences.getInstance());
  }

  T readJson<T>(String key, T fallback, T Function(Object json) decode) {
    try {
      final raw = _prefs.getString(_prefix + key);
      if (raw == null) return fallback;
      return decode(jsonDecode(raw) as Object);
    } catch (_) {
      // Corrupt or schema-drifted payload — fall back rather than crash.
      return fallback;
    }
  }

  Future<void> writeJson(String key, Object? value) async {
    try {
      await _prefs.setString(_prefix + key, jsonEncode(value));
    } catch (_) {
      // Quota or platform failure: the app stays usable in memory.
    }
  }

  Future<void> remove(String key) async {
    try {
      await _prefs.remove(_prefix + key);
    } catch (_) {
      /* ignore */
    }
  }

  Future<void> clearAll() async {
    try {
      for (final key in _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
        await _prefs.remove(key);
      }
    } catch (_) {
      /* ignore */
    }
  }
}

final _rng = Random();
const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

String uid([String prefix = '']) {
  final body = List.generate(12, (_) => _alphabet[_rng.nextInt(_alphabet.length)]).join();
  return prefix.isEmpty ? body : '${prefix}_$body';
}
