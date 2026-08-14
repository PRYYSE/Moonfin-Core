import 'seerr_discovery_filter_policy.dart';
import 'seerr_discovery_schema.dart';
import 'seerr_discovery_sort_policy.dart';

class SeerrDiscoveryRouteState {
  final String? title;
  final SeerrDiscoveryQuery query;

  const SeerrDiscoveryRouteState({required this.query, this.title});
}

/// Encodes/decodes the single query identity used by both a preview lane and
/// its expanded collection.
abstract final class SeerrDiscoveryRouteCodec {
  static Map<String, String> encode(
    SeerrDiscoveryQuery query, {
    String? title,
  }) => query.toRouteParameters(title: title);

  static SeerrDiscoveryRouteState decode(
    Map<String, String> parameters, {
    DateTime? now,
  }) {
    final sourceName = parameters['source'] ?? 'discoverMovies';
    final source = SeerrDiscoverySource.values.firstWhere(
      (value) => value.name == sourceName,
      orElse: () => SeerrDiscoverySource.discoverMovies,
    );
    final mediaType = parameters['mediaType'] ??
        switch (source) {
          SeerrDiscoverySource.discoverTv ||
          SeerrDiscoverySource.upcomingTv => 'tv',
          SeerrDiscoverySource.discoverMovies ||
          SeerrDiscoverySource.upcomingMovies => 'movie',
          _ => 'all',
        };

    final query = SeerrDiscoveryQuery(
      source: source,
      mediaType: mediaType,
      sortBy: SeerrDiscoverySortPolicy.normalise(parameters['sortBy']),
      filters: SeerrDiscoveryFilterPolicy.fromRouteParameters(
        parameters,
        now: now,
      ),
      seedStrategy: _trimmed(parameters['seedStrategy']),
      listProvider: _trimmed(parameters['listProvider']),
      listId: _trimmed(parameters['listId']),
    );
    return SeerrDiscoveryRouteState(
      query: query,
      title: _trimmed(parameters['filterName']),
    );
  }

  static String? _trimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
