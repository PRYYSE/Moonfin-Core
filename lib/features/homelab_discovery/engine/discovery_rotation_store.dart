import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'discovery_rotation_history.dart';

/// Persists only Discovery lane-selection cooldown state per server/user scope.
class HomeLabDiscoveryRotationStore {
  static const _keyPrefix = 'moonfin.homelab.discovery.rotation.v2.';

  Future<void> _saveTail = Future<void>.value();

  Future<Map<String, HomeLabDiscoveryRotationHistory>> load(
    String scope,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final key = _key(scope);
      final raw = preferences.getString(key);
      if (raw == null || raw.isEmpty) return {};

      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['tabs'] is! Map) {
        await preferences.remove(key);
        return {};
      }
      final tabs = decoded['tabs'] as Map;
      return {
        for (final entry in tabs.entries)
          if (entry.key.toString().trim().isNotEmpty && entry.value is Map)
            entry.key.toString(): HomeLabDiscoveryRotationHistory.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            ),
      };
    } catch (_) {
      // Corrupt/broken novelty persistence must never break Discovery itself.
      return {};
    }
  }

  Future<void> save(
    String scope,
    Map<String, HomeLabDiscoveryRotationHistory> histories,
  ) {
    final payload = jsonEncode({
      'tabs': <String, dynamic>{
        for (final entry in histories.entries)
          if (entry.key.trim().isNotEmpty) entry.key: entry.value.toJson(),
      },
    });
    final previous = _saveTail;
    final operation = () async {
      try {
        await previous;
      } catch (_) {
        // A previous persistence failure does not block the latest snapshot.
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_key(scope), payload);
    }();
    _saveTail = operation;
    return operation;
  }

  Future<void> clear(String scope) async {
    try {
      await _saveTail;
    } catch (_) {
      // Clear should still proceed after a failed earlier save.
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(scope));
  }

  String _key(String scope) {
    final normalised = scope.trim().isEmpty ? 'default' : scope.trim();
    final encoded = base64UrlEncode(
      utf8.encode(normalised),
    ).replaceAll('=', '');
    return '$_keyPrefix$encoded';
  }
}
