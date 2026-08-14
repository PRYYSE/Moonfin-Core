import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_lab_discovery_catalogue.dart';
import 'seerr_discovery_catalogue_loader.dart';

/// Fetches Moonbase's versioned Discovery catalogue and keeps a cross-platform
/// last-known-good copy using shared_preferences.
///
/// No Seerr/TMDb credentials are present here. The endpoint is authenticated
/// with the user's existing Jellyfin session just like Moonfin's other plugin
/// APIs.
class SeerrDiscoveryCatalogueService {
  static const _cacheKey = 'moonfin.discovery.catalogue.v2.lastKnownGood';

  final Dio _dio;

  SeerrDiscoveryCatalogueService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  Future<SeerrDiscoveryCatalogueLoadResult> load() async {
    final loader = SeerrDiscoveryCatalogueLoader(
      maxSupportedSchemaVersion: 2,
      fallback: homeLabDiscoveryCatalogue,
      fetchRemote: _fetchRemote,
      readCached: _readCached,
      writeCached: _writeCached,
    );
    return loader.load();
  }

  Future<Map<String, dynamic>?> _fetchRemote() async {
    final client = GetIt.instance.isRegistered<MediaServerClient>()
        ? GetIt.instance<MediaServerClient>()
        : null;
    if (client == null || client.accessToken == null) {
      throw StateError('No authenticated Jellyfin client for Discovery catalogue');
    }

    final response = await _dio.get(
      '${client.baseUrl}/Moonfin/Discovery/Catalogue',
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Authorization': buildServerAuthorizationHeader(
            scheme: 'MediaBrowser',
            deviceInfo: client.deviceInfo,
            accessToken: client.accessToken!,
          ),
        },
        validateStatus: (status) => status != null && status >= 200 && status < 500,
      ),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Discovery catalogue endpoint returned HTTP ${response.statusCode}',
      );
    }
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('Discovery catalogue endpoint returned invalid JSON');
  }

  Future<Map<String, dynamic>?> _readCached() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Cached Discovery catalogue is not an object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _writeCached(Map<String, dynamic> json) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cacheKey, jsonEncode(json));
  }

  Future<void> clearCachedCatalogue() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_cacheKey);
  }
}
