import 'seerr_discovery_schema.dart';

enum SeerrDiscoveryCatalogueSource { remote, cached, builtInFallback }

class SeerrDiscoveryCatalogueLoadResult {
  final SeerrDiscoveryCatalogue catalogue;
  final SeerrDiscoveryCatalogueSource source;
  final Object? remoteError;
  final Object? cacheError;

  const SeerrDiscoveryCatalogueLoadResult({
    required this.catalogue,
    required this.source,
    this.remoteError,
    this.cacheError,
  });
}

typedef SeerrDiscoveryCatalogueReader =
    Future<Map<String, dynamic>?> Function();
typedef SeerrDiscoveryCatalogueWriter =
    Future<void> Function(Map<String, dynamic> json);

/// Loads the versioned server catalogue without making Discovery depend on it.
///
/// Order:
/// 1. validated remote/server catalogue;
/// 2. validated last-known-good cached catalogue;
/// 3. validated built-in recovery catalogue.
///
/// Network/storage details are injected so Web, Android and TV clients can use
/// their existing persistence/network layers without this service owning auth.
class SeerrDiscoveryCatalogueLoader {
  final int maxSupportedSchemaVersion;
  final SeerrDiscoveryCatalogue fallback;
  final SeerrDiscoveryCatalogueReader fetchRemote;
  final SeerrDiscoveryCatalogueReader readCached;
  final SeerrDiscoveryCatalogueWriter writeCached;

  const SeerrDiscoveryCatalogueLoader({
    this.maxSupportedSchemaVersion = 2,
    required this.fallback,
    required this.fetchRemote,
    required this.readCached,
    required this.writeCached,
  });

  Future<SeerrDiscoveryCatalogueLoadResult> load() async {
    Object? remoteError;
    Object? cacheError;

    try {
      final remoteJson = await fetchRemote();
      if (remoteJson != null) {
        final remote = _parse(remoteJson);
        try {
          await writeCached(remote.toJson());
        } catch (_) {
          // A valid live catalogue is still usable if local persistence fails.
        }
        return SeerrDiscoveryCatalogueLoadResult(
          catalogue: remote,
          source: SeerrDiscoveryCatalogueSource.remote,
        );
      }
    } catch (error) {
      remoteError = error;
    }

    try {
      final cachedJson = await readCached();
      if (cachedJson != null) {
        final cached = _parse(cachedJson);
        return SeerrDiscoveryCatalogueLoadResult(
          catalogue: cached,
          source: SeerrDiscoveryCatalogueSource.cached,
          remoteError: remoteError,
        );
      }
    } catch (error) {
      cacheError = error;
    }

    fallback.validate();
    if (fallback.schemaVersion > maxSupportedSchemaVersion) {
      throw StateError(
        'Built-in discovery schema ${fallback.schemaVersion} is newer than '
        'supported schema $maxSupportedSchemaVersion',
      );
    }
    return SeerrDiscoveryCatalogueLoadResult(
      catalogue: fallback,
      source: SeerrDiscoveryCatalogueSource.builtInFallback,
      remoteError: remoteError,
      cacheError: cacheError,
    );
  }

  SeerrDiscoveryCatalogue _parse(Map<String, dynamic> json) {
    final catalogue = SeerrDiscoveryCatalogue.fromJson(json);
    catalogue.validate();
    if (catalogue.schemaVersion > maxSupportedSchemaVersion) {
      throw UnsupportedError(
        'Discovery schema ${catalogue.schemaVersion} is newer than '
        'supported schema $maxSupportedSchemaVersion',
      );
    }
    return catalogue;
  }
}
