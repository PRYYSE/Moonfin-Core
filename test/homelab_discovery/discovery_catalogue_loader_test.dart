import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue_loader.dart';

class MemoryCache implements HomeLabDiscoveryCatalogueCache {
  String? value;
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<String?> read() async {
    if (failRead) throw StateError('read failed');
    return value;
  }

  @override
  Future<void> write(String rawJson) async {
    if (failWrite) throw StateError('write failed');
    value = rawJson;
  }
}

String validRaw({int schema = 2}) => jsonEncode({
  'schemaVersion': schema,
  'tabs': [
    {
      'id': 'movies',
      'title': 'Movies',
      'sections': [
        {
          'id': 'popular',
          'title': 'Popular',
          'query': {'source': 'discoverMovies', 'mediaType': 'movie'},
        },
      ],
    },
  ],
});

void main() {
  test('network catalogue wins and becomes last-known-good', () async {
    final cache = MemoryCache();
    final loader = HomeLabDiscoveryCatalogueLoader(
      baseUrl: 'http://192.168.50.12:8096/',
      cache: cache,
      fetcher: (_) async => validRaw(),
    );

    final result = await loader.load();

    expect(result.source, HomeLabDiscoveryCatalogueSource.network);
    expect(result.catalogue?.tabs.single.id, 'movies');
    expect(cache.value, isNotNull);
    expect(
      loader.catalogueUri.toString(),
      'http://192.168.50.12:8096/Moonfin/Web/homelab/discovery.catalogue.json',
    );
  });

  test('temporary network failure falls back to validated cache', () async {
    final cache = MemoryCache()..value = validRaw();
    final loader = HomeLabDiscoveryCatalogueLoader(
      baseUrl: 'http://server:8096',
      cache: cache,
      fetcher: (_) async => throw StateError('offline'),
    );

    final result = await loader.load();

    expect(result.source, HomeLabDiscoveryCatalogueSource.cache);
    expect(result.catalogue, isNotNull);
    expect(result.networkError, isA<StateError>());
  });

  test(
    'invalid network response does not replace valid cached catalogue',
    () async {
      final cached = validRaw();
      final cache = MemoryCache()..value = cached;
      final loader = HomeLabDiscoveryCatalogueLoader(
        baseUrl: 'http://server:8096',
        cache: cache,
        fetcher: (_) async => '{"schemaVersion":99,"tabs":[]}',
      );

      final result = await loader.load();

      expect(result.source, HomeLabDiscoveryCatalogueSource.cache);
      expect(cache.value, cached);
    },
  );

  test('network and cache failures fail closed without throwing', () async {
    final cache = MemoryCache()..failRead = true;
    final loader = HomeLabDiscoveryCatalogueLoader(
      baseUrl: 'http://server:8096',
      cache: cache,
      fetcher: (_) async => throw StateError('offline'),
    );

    final result = await loader.load();

    expect(result.source, HomeLabDiscoveryCatalogueSource.unavailable);
    expect(result.catalogue, isNull);
    expect(result.networkError, isA<StateError>());
    expect(result.cacheError, isA<StateError>());
  });

  test('cache write failure fails closed to existing cache path', () async {
    final cache = MemoryCache()
      ..value = validRaw()
      ..failWrite = true;
    final loader = HomeLabDiscoveryCatalogueLoader(
      baseUrl: 'http://server:8096',
      cache: cache,
      fetcher: (_) async => validRaw(),
    );

    final result = await loader.load();

    expect(result.source, HomeLabDiscoveryCatalogueSource.cache);
    expect(result.catalogue, isNotNull);
  });
}
