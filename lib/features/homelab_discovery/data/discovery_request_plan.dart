import '../catalogue/discovery_catalogue.dart';
import 'discovery_filter_policy.dart';
import 'discovery_sort_policy.dart';

class HomeLabDiscoveryRequestPlan {
  final String path;
  final Map<String, dynamic> queryParameters;

  const HomeLabDiscoveryRequestPlan({
    required this.path,
    required this.queryParameters,
  });

  static HomeLabDiscoveryRequestPlan? fromQuery(
    HomeLabDiscoveryQuery query, {
    int page = 1,
    DateTime? now,
  }) {
    // Semantic names are authoring-only. The server compiler must resolve them
    // to concrete IDs before a client executes a lane.
    if (query.keywordNames.isNotEmpty ||
        query.excludeKeywordNames.isNotEmpty ||
        query.providerNames.isNotEmpty) {
      return null;
    }

    final safePage = page < 1 ? 1 : page;
    final filters = HomeLabDiscoveryFilterPolicy.sanitise(
      query.filters,
      now: now,
    );

    HomeLabDiscoveryRequestPlan discover(String path) =>
        HomeLabDiscoveryRequestPlan(
          path: path,
          queryParameters: {
            'page': safePage,
            'sortBy': HomeLabDiscoverySortPolicy.normalise(query.sortBy),
            ...filters,
          },
        );

    return switch (query.source) {
      HomeLabDiscoverySource.discoverMovies => discover('discover/movies'),
      HomeLabDiscoverySource.discoverTv => discover('discover/tv'),
      HomeLabDiscoverySource.trending => HomeLabDiscoveryRequestPlan(
        path: 'discover/trending',
        queryParameters: {'page': safePage},
      ),
      HomeLabDiscoverySource.upcomingMovies => HomeLabDiscoveryRequestPlan(
        path: 'discover/movies/upcoming',
        queryParameters: {'page': safePage},
      ),
      HomeLabDiscoverySource.upcomingTv => HomeLabDiscoveryRequestPlan(
        path: 'discover/tv/upcoming',
        queryParameters: {'page': safePage},
      ),
      HomeLabDiscoverySource.watchlist => HomeLabDiscoveryRequestPlan(
        path: 'discover/watchlist',
        queryParameters: {'page': safePage},
      ),
      HomeLabDiscoverySource.personalised ||
      HomeLabDiscoverySource.externalList => null,
    };
  }
}
