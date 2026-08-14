import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'seerr_discovery_rotation_history.dart';

/// Persists only Discovery lane-selection cooldown state.
///
/// This deliberately stores no Jellyfin watch history, favourites, ratings,
/// Seerr credentials or media metadata. The accepted personalisation sources
/// remain authoritative; this store exists only so optional lanes do not reset
/// to the same selection every time the app process restarts.
class SeerrDiscoveryRotationStore {
  static const _keyPrefix = 'moonfin.discovery.rotation.v1.';

  Future<Map<String, SeerrDiscoveryRotationHistory>> load(String scope) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _key(scope);
    final raw = preferences.getString(key);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await preferences.remove(key);
        return {};
      }
      final tabs = decoded['tabs'];
      if (tabs is! Map) {
        await preferences.remove(key);
        return {};
      }
      return {
        for (final entry in tabs.entries)
          if (entry.key.toString().trim().isNotEmpty && entry.value is Map)
            entry.key.toString(): SeerrDiscoveryRotationHistory.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            ),
      };
    } catch (_) {
      // Corrupt local novelty state is never a reason to break Discovery.
      await preferences.remove(key);
      return {};
    }
  }

  Future<void> save(
    String scope,
    Map<String, SeerrDiscoveryRotationHistory> histories,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final tabs = <String, dynamic>{
      for (final entry in histories.entries)
        if (entry.key.trim().isNotEmpty) entry.key: entry.value.toJson(),
    };
    await preferences.setString(_key(scope), jsonEncode({'tabs': tabs}));
  }

  Future<void> clear(String scope) async {
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
