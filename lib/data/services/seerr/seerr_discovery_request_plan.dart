import 'seerr_discovery_filter_policy.dart';
import 'seerr_discovery_schema.dart';

/// A validated HTTP-agnostic request description for the existing Seerr proxy.
///
/// Keeping endpoint/query compilation separate from Dio makes the large
/// server-delivered catalogue testable without adding another auth/network
/// stack. The existing SeerrHttpClient can execute these plans through its
/// normal Jellyfin-authenticated proxy path.
class SeerrDiscoveryRequestPlan {
  final String path;
  final Map<String, dynamic> queryParameters;

  const SeerrDiscoveryRequestPlan({
    required this.path,
    required this.queryParameters,
  });

  static const _allowedSorts = <String>{
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

  static String safeSort(String sortBy) =>
      _allowedSorts.contains(sortBy) ? sortBy : 'popularity.desc';

  static SeerrDiscoveryRequestPlan? fromQuery(
    SeerrDiscoveryQuery query, {
    int page = 1,
    DateTime? now,
  }) {
    // Semantic names exist only in authoring catalogues. Running them without
    // compilation would silently drop the intended keyword/provider constraint
    // and return a misleadingly broad result set, so fail closed.
    if (query.keywordNames.isNotEmpty ||
        query.excludeKeywordNames.isNotEmpty ||
        query.providerNames.isNotEmpty) {
      return null;
    }

    final safePage = page < 1 ? 1 : page;
    final filters = SeerrDiscoveryFilterPolicy.sanitise(
      query.filters,
      now: now,
    );

    SeerrDiscoveryRequestPlan discover(String path) =>
        SeerrDiscoveryRequestPlan(
          path: path,
          queryParameters: {
            'page': safePage,
            'sortBy': safeSort(query.sortBy),
            ...filters,
          },
        );

    return switch (query.source) {
      SeerrDiscoverySource.discoverMovies => discover('discover/movies'),
      SeerrDiscoverySource.discoverTv => discover('discover/tv'),
      SeerrDiscoverySource.trending => SeerrDiscoveryRequestPlan(
          path: 'discover/trending',
          queryParameters: {'page': safePage},
        ),
      SeerrDiscoverySource.upcomingMovies => SeerrDiscoveryRequestPlan(
          path: 'discover/movies/upcoming',
          queryParameters: {'page': safePage},
        ),
      SeerrDiscoverySource.upcomingTv => SeerrDiscoveryRequestPlan(
          path: 'discover/tv/upcoming',
          queryParameters: {'page': safePage},
        ),
      SeerrDiscoverySource.watchlist => SeerrDiscoveryRequestPlan(
          path: 'discover/watchlist',
          queryParameters: {'page': safePage},
        ),
      // These are composed through user context/server list services rather
      // than a single raw Seerr discovery endpoint.
      SeerrDiscoverySource.personalised ||
      SeerrDiscoverySource.externalList => null,
    };
  }
}
