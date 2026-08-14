import 'seerr_discovery_filter_policy.dart';
import 'seerr_discovery_schema.dart';

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
      sortBy: SeerrDiscoveryRequestSort.normalise(parameters['sortBy']),
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

/// Mirrors the safe sort allow-list used by request-plan compilation without
/// making route decoding depend on HTTP implementation details.
abstract final class SeerrDiscoveryRequestSort {
  static const allowed = <String>{
    'popularity.asc',
    'popularity.desc',
    'vote_average.asc',
    'vote_average.desc',
    'primary_release_date.asc',
    'primary_release_date.desc',
    'first_air_date.asc',
    'first_air_date.desc',
    'title.asc',
    'title.desc',
    'name.asc',
    'name.desc',
    'original_title.asc',
    'original_title.desc',
    'revenue.asc',
    'revenue.desc',
  };

  static String normalise(String? value) {
    final sort = value?.trim();
    return sort != null && allowed.contains(sort) ? sort : 'popularity.desc';
  }
}
