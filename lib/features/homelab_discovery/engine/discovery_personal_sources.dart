import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/repositories/seerr_repository.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../catalogue/discovery_catalogue.dart';

enum HomeLabDiscoveryPersonalSourceKind {
  recentHistory,
  favourites,
  watchlist,
  highRatings,
  likes,
  mixedPositive,
  recentlyAdded,
  trendingAnime,
}

enum HomeLabDiscoveryPersonalSourceMode { recommendations, direct }

class HomeLabDiscoveryPersonalSourcePolicy {
  final HomeLabDiscoveryPersonalSourceKind kind;
  final HomeLabDiscoveryPersonalSourceMode mode;
  final bool animeOnly;

  const HomeLabDiscoveryPersonalSourcePolicy({
    required this.kind,
    required this.mode,
    this.animeOnly = false,
  });
}

HomeLabDiscoveryPersonalSourcePolicy? homeLabDiscoveryPersonalSourcePolicy(
  HomeLabDiscoverySection section,
) {
  if (section.query.source != HomeLabDiscoverySource.personalised) return null;
  final strategy = (section.query.seedStrategy ?? '').trim().toLowerCase();

  const recommendations = HomeLabDiscoveryPersonalSourceMode.recommendations;
  const direct = HomeLabDiscoveryPersonalSourceMode.direct;

  return switch (strategy) {
    'recent-history' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.recentHistory,
      mode: recommendations,
    ),
    'favourites' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.favourites,
      mode: recommendations,
    ),
    'watchlist' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.watchlist,
      mode: recommendations,
    ),
    'high-ratings' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.highRatings,
      mode: recommendations,
    ),
    'likes' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.likes,
      mode: recommendations,
    ),
    'mixed-positive' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.mixedPositive,
      mode: recommendations,
    ),
    'anime-recent-history' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.recentHistory,
      mode: recommendations,
      animeOnly: true,
    ),
    'anime-favourites' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.favourites,
      mode: recommendations,
      animeOnly: true,
    ),
    'anime-watchlist' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.watchlist,
      mode: recommendations,
      animeOnly: true,
    ),
    'anime-high-ratings' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.highRatings,
      mode: recommendations,
      animeOnly: true,
    ),
    'recently-added' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.recentlyAdded,
      mode: direct,
    ),
    'trending-anime' => const HomeLabDiscoveryPersonalSourcePolicy(
      kind: HomeLabDiscoveryPersonalSourceKind.trendingAnime,
      mode: direct,
      animeOnly: true,
    ),
    _ => null,
  };
}

class HomeLabDiscoveryPersonalSourcePage {
  final int page;
  final int totalPages;
  final int totalResults;
  final List<AggregatedItem> items;

  const HomeLabDiscoveryPersonalSourcePage({
    required this.page,
    required this.totalPages,
    required this.totalResults,
    this.items = const [],
  });
}

typedef HomeLabDiscoveryPersonalSourcePoolLoader =
    Future<List<AggregatedItem>> Function(
      HomeLabDiscoveryPersonalSourceKind kind,
    );
typedef HomeLabDiscoveryPersonalRecommendationLoader =
    Future<List<AggregatedItem>> Function(AggregatedItem seed);

/// Truthful source-specific personalisation for Home Lab Discovery.
///
/// Source provenance is fixed by [homeLabDiscoveryPersonalSourcePolicy]. A
/// deterministic hash may choose a seed *within that already-correct source*,
/// but can never choose the semantic meaning of a lane. Source snapshots and
/// per-seed recommendations are cached so concurrent landing rows share work.
/// Every snapshot is deliberately bounded; its reported total describes that
/// bounded snapshot rather than pretending to be an unbounded server total.
class HomeLabDiscoveryPersonalSources {
  static const int pageSize = 15;
  static const int _maxRecommendationSeeds = 2;
  static const int _maxSnapshotItems = 60;
  static const int _maxRatedCandidates = 100;
  static const int _maxWatchlistPages = 2;

  static const String _sourceFields =
      'DateCreated,Type,UserData,Overview,Genres,CommunityRating,'
      'OfficialRating,RunTimeTicks,ProductionYear,ImageTags,BackdropImageTags,'
      'ProviderIds,Tags,People,Studios,SeriesId';

  final String serverId;
  final MediaServerClient? _client;
  final SeerrRepository? _repository;
  final Set<String> _blockedParentalRatings;
  final HomeLabDiscoveryPersonalSourcePoolLoader? _poolLoaderOverride;
  final HomeLabDiscoveryPersonalRecommendationLoader?
  _recommendationLoaderOverride;

  final Map<HomeLabDiscoveryPersonalSourceKind, Future<List<AggregatedItem>>>
  _poolFutures = {};
  final Map<String, Future<List<AggregatedItem>>> _recommendationFutures = {};
  final Map<String, Future<List<AggregatedItem>>> _sectionFutures = {};
  Future<List<AggregatedItem>>? _ratedPoolFuture;

  HomeLabDiscoveryPersonalSources.production({
    required this.serverId,
    required MediaServerClient client,
    required SeerrRepository repository,
    Set<String> blockedParentalRatings = const {},
  }) : _client = client,
       _repository = repository,
       _blockedParentalRatings = blockedParentalRatings,
       _poolLoaderOverride = null,
       _recommendationLoaderOverride = null;

  HomeLabDiscoveryPersonalSources.forTesting({
    required this.serverId,
    required HomeLabDiscoveryPersonalSourcePoolLoader loadPool,
    required HomeLabDiscoveryPersonalRecommendationLoader loadRecommendations,
  }) : _client = null,
       _repository = null,
       _blockedParentalRatings = const {},
       _poolLoaderOverride = loadPool,
       _recommendationLoaderOverride = loadRecommendations;

  bool supports(HomeLabDiscoverySection section) =>
      homeLabDiscoveryPersonalSourcePolicy(section) != null;

  Future<HomeLabDiscoveryPersonalSourcePage> load(
    HomeLabDiscoverySection section, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final policy = homeLabDiscoveryPersonalSourcePolicy(section);
    if (policy == null) {
      throw UnsupportedError(
        'Discovery personal strategy ${section.query.seedStrategy ?? section.id} '
        'has no truthful source adapter',
      );
    }
    if (forceRefresh) clear();

    final safePage = page < 1 ? 1 : page;
    final snapshot = await _sectionFutures.putIfAbsent(
      section.id,
      () => _buildSectionSnapshot(section, policy),
    );
    final total = snapshot.length;
    final totalPages = total == 0 ? 0 : (total + pageSize - 1) ~/ pageSize;
    final start = (safePage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, total).toInt();
    final items = start < total
        ? snapshot.sublist(start, end)
        : const <AggregatedItem>[];

    return HomeLabDiscoveryPersonalSourcePage(
      page: safePage,
      totalPages: totalPages,
      totalResults: total,
      items: items,
    );
  }

  void clear() {
    _poolFutures.clear();
    _recommendationFutures.clear();
    _sectionFutures.clear();
    _ratedPoolFuture = null;
  }

  Future<List<AggregatedItem>> _buildSectionSnapshot(
    HomeLabDiscoverySection section,
    HomeLabDiscoveryPersonalSourcePolicy policy,
  ) async {
    final sourcePool = _dedupe(
      (await _pool(policy.kind))
          .where((item) => _matchesSection(item, section, policy.animeOnly))
          .where(_hasUsableTmdbIdentity)
          .toList(growable: false),
    );
    if (sourcePool.isEmpty) return const [];

    if (policy.mode == HomeLabDiscoveryPersonalSourceMode.direct) {
      return sourcePool.take(_maxSnapshotItems).toList(growable: false);
    }

    final selectedSeeds = _selectSeeds(section, sourcePool);
    if (selectedSeeds.isEmpty) return const [];
    final recommendationLists = await Future.wait(
      selectedSeeds.map(_recommendationsFor),
    );
    final sourceKeys = sourcePool.map(_identityKey).toSet();
    final merged = <AggregatedItem>[];
    final seen = <String>{};
    final maxLength = recommendationLists.fold<int>(
      0,
      (value, items) => items.length > value ? items.length : value,
    );

    for (var index = 0; index < maxLength; index++) {
      for (final recommendations in recommendationLists) {
        if (index >= recommendations.length) continue;
        final item = recommendations[index];
        if (!_matchesSection(item, section, policy.animeOnly)) continue;
        if (!_hasUsableTmdbIdentity(item)) continue;
        final key = _identityKey(item);
        if (sourceKeys.contains(key) || !seen.add(key)) continue;
        merged.add(item);
        if (merged.length >= _maxSnapshotItems) {
          return List.unmodifiable(merged);
        }
      }
    }
    return List.unmodifiable(merged);
  }

  Future<List<AggregatedItem>> _pool(HomeLabDiscoveryPersonalSourceKind kind) =>
      _poolFutures.putIfAbsent(kind, () => _loadPool(kind));

  Future<List<AggregatedItem>> _loadPool(
    HomeLabDiscoveryPersonalSourceKind kind,
  ) async {
    final override = _poolLoaderOverride;
    if (override != null) return override(kind);
    return _loadProductionPool(kind);
  }

  Future<List<AggregatedItem>> _loadProductionPool(
    HomeLabDiscoveryPersonalSourceKind kind,
  ) async {
    switch (kind) {
      case HomeLabDiscoveryPersonalSourceKind.recentHistory:
        return _loadRecentHistory();
      case HomeLabDiscoveryPersonalSourceKind.favourites:
        return _queryLocal(
          includeItemTypes: const ['Movie', 'Series'],
          isFavorite: true,
          sortBy: 'SortName',
          sortOrder: 'Ascending',
          limit: _maxSnapshotItems,
        );
      case HomeLabDiscoveryPersonalSourceKind.watchlist:
        return _loadWatchlist();
      case HomeLabDiscoveryPersonalSourceKind.highRatings:
        return (await _ratedPool())
            .where((item) => (item.personalRating ?? 0) >= 8.0)
            .toList(growable: false);
      case HomeLabDiscoveryPersonalSourceKind.likes:
        return (await _ratedPool())
            .where((item) => item.personalRatingLikes == true)
            .toList(growable: false);
      case HomeLabDiscoveryPersonalSourceKind.mixedPositive:
        final pools = await Future.wait([
          _pool(HomeLabDiscoveryPersonalSourceKind.favourites),
          _pool(HomeLabDiscoveryPersonalSourceKind.highRatings),
          _pool(HomeLabDiscoveryPersonalSourceKind.likes),
          _pool(HomeLabDiscoveryPersonalSourceKind.watchlist),
        ]);
        return _dedupe(
          pools.expand((items) => items).toList(growable: false),
        ).take(_maxSnapshotItems).toList(growable: false);
      case HomeLabDiscoveryPersonalSourceKind.recentlyAdded:
        return _queryLocal(
          includeItemTypes: const ['Movie', 'Series'],
          sortBy: 'DateCreated',
          sortOrder: 'Descending',
          limit: _maxSnapshotItems,
        );
      case HomeLabDiscoveryPersonalSourceKind.trendingAnime:
        return _loadTrendingAnime();
    }
  }

  Future<List<AggregatedItem>> _ratedPool() => _ratedPoolFuture ??= _queryLocal(
    includeItemTypes: const ['Movie', 'Series'],
    filters: const ['IsPlayed'],
    sortBy: 'DatePlayed',
    sortOrder: 'Descending',
    limit: _maxRatedCandidates,
  );

  Future<List<AggregatedItem>> _loadRecentHistory() async {
    final raw = await _queryLocal(
      includeItemTypes: const ['Movie', 'Episode'],
      filters: const ['IsPlayed'],
      sortBy: 'DatePlayed',
      sortOrder: 'Descending',
      limit: _maxSnapshotItems,
    );
    final seriesIds = <String>[];
    final seenSeries = <String>{};
    for (final item in raw) {
      if (item.type != 'Episode') continue;
      final seriesId = item.seriesId;
      if (seriesId != null && seriesId.isNotEmpty && seenSeries.add(seriesId)) {
        seriesIds.add(seriesId);
      }
    }
    if (seriesIds.isEmpty) {
      return raw.where((item) => item.type == 'Movie').toList(growable: false);
    }

    final client = _client!;
    final response = await client.itemsApi.getItems(
      ids: seriesIds,
      fields: _sourceFields,
    );
    final series = _parseLocal(response);
    final byId = {for (final item in series) item.id: item};
    final result = <AggregatedItem>[];
    final added = <String>{};
    for (final item in raw) {
      if (item.type == 'Movie') {
        final key = _identityKey(item);
        if (added.add(key)) result.add(item);
        continue;
      }
      final seriesId = item.seriesId;
      final resolved = seriesId == null ? null : byId[seriesId];
      if (resolved == null) continue;
      final key = _identityKey(resolved);
      if (added.add(key)) result.add(resolved);
    }
    return result.take(_maxSnapshotItems).toList(growable: false);
  }

  Future<List<AggregatedItem>> _loadWatchlist() async {
    final repository = _repository!;
    await repository.ensureInitialized();
    if (!repository.isAvailable) return const [];

    final items = <AggregatedItem>[];
    for (var page = 1; page <= _maxWatchlistPages; page++) {
      final response = await repository.getWatchlist(page: page);
      for (final item in response.results) {
        final converted = _fromSeerr(item);
        if (converted != null && !item.isBlacklisted) items.add(converted);
      }
      if (response.totalPages <= page) break;
    }
    return _dedupe(items).take(_maxSnapshotItems).toList(growable: false);
  }

  Future<List<AggregatedItem>> _loadTrendingAnime() async {
    final repository = _repository!;
    await repository.ensureInitialized();
    if (!repository.isAvailable) return const [];
    final response = await repository.getTrending(limit: _maxSnapshotItems);
    final converted = response.results
        .where((item) => !item.isBlacklisted)
        .map(_fromSeerr)
        .whereType<AggregatedItem>()
        .where(_looksLikeAnime)
        .toList(growable: false);
    return _dedupe(converted);
  }

  Future<List<AggregatedItem>> _queryLocal({
    required List<String> includeItemTypes,
    List<String>? filters,
    String? sortBy,
    String? sortOrder,
    bool? isFavorite,
    required int limit,
  }) async {
    final response = await _client!.itemsApi.getItems(
      includeItemTypes: includeItemTypes,
      filters: filters,
      sortBy: sortBy,
      sortOrder: sortOrder,
      isFavorite: isFavorite,
      recursive: true,
      limit: limit,
      fields: _sourceFields,
    );
    return _parseLocal(response);
  }

  List<AggregatedItem> _parseLocal(Map<String, dynamic> response) {
    final rawItems = response['Items'] as List? ?? const [];
    return rawItems
        .whereType<Map>()
        .map((raw) {
          final data = raw.cast<String, dynamic>();
          return AggregatedItem(
            id: data['Id']?.toString() ?? '',
            serverId: serverId,
            rawData: data,
          );
        })
        .where((item) {
          if (item.id.isEmpty) return false;
          final rating = item.officialRating?.trim().toUpperCase();
          return rating == null ||
              rating.isEmpty ||
              !_blockedParentalRatings.contains(rating);
        })
        .toList(growable: false);
  }

  Future<List<AggregatedItem>> _recommendationsFor(AggregatedItem seed) {
    final key = _identityKey(seed);
    return _recommendationFutures.putIfAbsent(key, () async {
      final override = _recommendationLoaderOverride;
      if (override != null) return override(seed);
      return _loadProductionRecommendations(seed);
    });
  }

  Future<List<AggregatedItem>> _loadProductionRecommendations(
    AggregatedItem seed,
  ) async {
    final repository = _repository!;
    await repository.ensureInitialized();
    if (!repository.isAvailable) return const [];
    final tmdbId = _tmdbId(seed);
    if (tmdbId == null) return const [];

    final SeerrDiscoverPage page;
    if (seed.type == 'Series') {
      page = await repository.getTvRecommendations(tmdbId);
    } else if (seed.type == 'Movie') {
      page = await repository.getMovieRecommendations(tmdbId);
    } else {
      return const [];
    }

    return page.results
        .where((item) => !item.isBlacklisted)
        .map(_fromSeerr)
        .whereType<AggregatedItem>()
        .take(_maxSnapshotItems)
        .toList(growable: false);
  }

  AggregatedItem? _fromSeerr(SeerrDiscoverItem item) {
    if (item.id <= 0) return null;
    final type = switch (item.mediaType) {
      'movie' => 'Movie',
      'tv' => 'Series',
      _ => null,
    };
    if (type == null) return null;
    final mediaInfo = item.mediaInfo;
    final year = _year(item.releaseDate ?? item.firstAirDate);
    return AggregatedItem(
      id: item.id.toString(),
      serverId: 'seerr',
      rawData: {
        'Name': item.displayTitle,
        'Type': type,
        'ProviderIds': {'Tmdb': item.id.toString()},
        'PosterPath': item.posterPath,
        'BackdropPath': item.backdropPath,
        'Overview': item.overview,
        'ProductionYear': year,
        'OriginalLanguage': item.originalLanguage,
        'GenreIds': item.genreIds,
        'CommunityRating': item.voteAverage,
        'Adult': item.adult,
        'SeerrMediaType': item.mediaType,
        if (mediaInfo?.status != null) 'SeerrStatus': mediaInfo!.status,
        if (mediaInfo?.jellyfinMediaId != null &&
            mediaInfo!.jellyfinMediaId!.trim().isNotEmpty)
          'JellyfinMediaId': mediaInfo.jellyfinMediaId,
      },
    );
  }

  List<AggregatedItem> _selectSeeds(
    HomeLabDiscoverySection section,
    List<AggregatedItem> sourcePool,
  ) {
    if (sourcePool.isEmpty) return const [];
    final count = sourcePool.length < _maxRecommendationSeeds
        ? sourcePool.length
        : _maxRecommendationSeeds;
    final strategy = section.query.seedStrategy ?? '';
    final start = _stableOffset('${section.id}|$strategy', sourcePool.length);
    return [
      for (var index = 0; index < count; index++)
        sourcePool[(start + index) % sourcePool.length],
    ];
  }

  static int _stableOffset(String value, int length) {
    if (length <= 1) return 0;
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash % length;
  }

  bool _matchesSection(
    AggregatedItem item,
    HomeLabDiscoverySection section,
    bool animeOnly,
  ) {
    final typeMatches = switch (section.query.mediaType) {
      'movie' => item.type == 'Movie',
      'tv' => item.type == 'Series',
      _ => item.type == 'Movie' || item.type == 'Series',
    };
    if (!typeMatches) return false;
    return !animeOnly || _looksLikeAnime(item);
  }

  static bool _looksLikeAnime(AggregatedItem item) {
    final tags = (item.rawData['Tags'] as List? ?? const []).map(
      (value) => value.toString().toLowerCase(),
    );
    final genres = item.genres.map((value) => value.toLowerCase());
    if (tags.any((value) => value.contains('anime')) ||
        genres.any((value) => value.contains('anime'))) {
      return true;
    }

    if (item.serverId != 'seerr') return false;
    final genreIds = (item.rawData['GenreIds'] as List? ?? const [])
        .map((value) => value is int ? value : int.tryParse(value.toString()))
        .whereType<int>();
    final language = item.rawData['OriginalLanguage']?.toString().toLowerCase();
    return genreIds.contains(16) && language == 'ja';
  }

  static List<AggregatedItem> _dedupe(List<AggregatedItem> items) {
    final seen = <String>{};
    return items
        .where((item) => seen.add(_identityKey(item)))
        .toList(growable: false);
  }

  static String _identityKey(AggregatedItem item) {
    final tmdb = _tmdbId(item);
    final type = item.type ?? '';
    if (tmdb != null) return 'tmdb:$type:$tmdb';
    return '${item.serverId}:$type:${item.id}';
  }

  static bool _hasUsableTmdbIdentity(AggregatedItem item) =>
      _tmdbId(item) != null;

  static int? _tmdbId(AggregatedItem item) {
    final providerId = int.tryParse(item.tmdbId ?? '');
    if (providerId != null && providerId > 0) return providerId;
    if (item.serverId != 'seerr') return null;
    final externalId = int.tryParse(item.id);
    return externalId != null && externalId > 0 ? externalId : null;
  }

  static int? _year(String? value) {
    if (value == null || value.length < 4) return null;
    return int.tryParse(value.substring(0, 4));
  }
}
