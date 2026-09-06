import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'discovery_catalogue.dart';

typedef HomeLabDiscoveryFetcher = Future<String> Function(Uri uri);

enum HomeLabDiscoveryCatalogueSource { network, cache, unavailable }

class HomeLabDiscoveryLoadResult {
  final HomeLabDiscoveryCatalogue? catalogue;
  final HomeLabDiscoveryCatalogueSource source;
  final Object? networkError;
  final Object? cacheError;

  const HomeLabDiscoveryLoadResult({
    required this.catalogue,
    required this.source,
    this.networkError,
    this.cacheError,
  });

  bool get isAvailable => catalogue != null;
}

abstract interface class HomeLabDiscoveryCatalogueCache {
  Future<String?> read();
  Future<void> write(String rawJson);
}

class SharedPreferencesHomeLabDiscoveryCatalogueCache
    implements HomeLabDiscoveryCatalogueCache {
  final SharedPreferences preferences;
  final String key;

  const SharedPreferencesHomeLabDiscoveryCatalogueCache({
    required this.preferences,
    required this.key,
  });

  factory SharedPreferencesHomeLabDiscoveryCatalogueCache.forBaseUrl(
    SharedPreferences preferences,
    String baseUrl,
  ) {
    final encoded = base64Url.encode(utf8.encode(baseUrl));
    return SharedPreferencesHomeLabDiscoveryCatalogueCache(
      preferences: preferences,
      key: 'homelab_discovery_catalogue_v2_$encoded',
    );
  }

  @override
  Future<String?> read() async => preferences.getString(key);

  @override
  Future<void> write(String rawJson) async {
    final saved = await preferences.setString(key, rawJson);
    if (!saved) {
      throw StateError('Unable to save Discovery last-known-good catalogue');
    }
  }
}

class HomeLabDiscoveryCatalogueLoader {
  static const relativeCataloguePath =
      '/Moonfin/Web/homelab/discovery.catalogue.json';

  final String baseUrl;
  final HomeLabDiscoveryCatalogueCache cache;
  final HomeLabDiscoveryFetcher fetcher;

  const HomeLabDiscoveryCatalogueLoader({
    required this.baseUrl,
    required this.cache,
    required this.fetcher,
  });

  factory HomeLabDiscoveryCatalogueLoader.network({
    required String baseUrl,
    required HomeLabDiscoveryCatalogueCache cache,
    Duration timeout = const Duration(seconds: 6),
  }) {
    return HomeLabDiscoveryCatalogueLoader(
      baseUrl: baseUrl,
      cache: cache,
      fetcher: (uri) async {
        final response = await http.get(uri).timeout(timeout);
        if (response.statusCode != 200) {
          throw StateError(
            'Discovery catalogue HTTP ${response.statusCode} from $uri',
          );
        }
        return response.body;
      },
    );
  }

  Uri get catalogueUri {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalized$relativeCataloguePath');
  }

  Future<HomeLabDiscoveryLoadResult> load() async {
    Object? networkError;
    try {
      final raw = await fetcher(catalogueUri);
      final catalogue = _decodeAndValidate(raw);
      await cache.write(raw);
      return HomeLabDiscoveryLoadResult(
        catalogue: catalogue,
        source: HomeLabDiscoveryCatalogueSource.network,
      );
    } catch (error) {
      networkError = error;
    }

    Object? cacheError;
    try {
      final cached = await cache.read();
      if (cached != null && cached.trim().isNotEmpty) {
        final catalogue = _decodeAndValidate(cached);
        return HomeLabDiscoveryLoadResult(
          catalogue: catalogue,
          source: HomeLabDiscoveryCatalogueSource.cache,
          networkError: networkError,
        );
      }
    } catch (error) {
      cacheError = error;
    }

    return HomeLabDiscoveryLoadResult(
      catalogue: null,
      source: HomeLabDiscoveryCatalogueSource.unavailable,
      networkError: networkError,
      cacheError: cacheError,
    );
  }

  HomeLabDiscoveryCatalogue _decodeAndValidate(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Discovery catalogue root must be an object');
    }
    return HomeLabDiscoveryCatalogue.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }
}
