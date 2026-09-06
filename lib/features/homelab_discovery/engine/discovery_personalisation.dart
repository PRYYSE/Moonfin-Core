import '../../../data/models/aggregated_item.dart';
import '../../../data/models/home_row.dart';
import '../../../data/services/row_data_source.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../catalogue/discovery_catalogue.dart';

typedef HomeLabDiscoveryPersonalRowLoader = Future<HomeRow> Function(
  String serverId,
  int rowIndex,
);

typedef HomeLabDiscoveryPersonalLoadMore =
    Future<(List<AggregatedItem>, int)> Function({
      required HomeRow row,
      required String serverId,
      int? offset,
    });

class HomeLabDiscoveryPersonalPage {
  final String title;
  final SeerrDiscoverPage page;

  const HomeLabDiscoveryPersonalPage({required this.title, required this.page});
}

/// Adapts stock Moonfin's accepted `Since You Watched` recommendation engine
/// to Home Lab Discovery without changing Home or RowDataSource.
///
/// Stock RowDataSource already builds/scored-caches up to 100 recommendations.
/// Discovery expands that cache, then applies section-specific media/anime
/// filtering locally. This keeps the recommendation engine upstream-owned.
class HomeLabDiscoveryPersonalisation {
  static const pageSize = 15;
  static const _maxExpansionPasses = 8;

  final String serverId;
  final HomeLabDiscoveryPersonalRowLoader _loadRow;
  final HomeLabDiscoveryPersonalLoadMore _loadMore;
  final Map<String, HomeRow> _rows = <String, HomeRow>{};

  HomeLabDiscoveryPersonalisation({
    required this.serverId,
    required RowDataSource rowDataSource,
  }) : _loadRow = rowDataSource.loadSinceYouWatchedRow,
       _loadMore = rowDataSource.loadMore;

  HomeLabDiscoveryPersonalisation.forTesting({
    required this.serverId,
    required HomeLabDiscoveryPersonalRowLoader loadRow,
    required HomeLabDiscoveryPersonalLoadMore loadMore,
  }) : _loadRow = loadRow,
       _loadMore = loadMore;

  Future<HomeLabDiscoveryPersonalPage> load(
    HomeLabDiscoverySection section, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final safePage = page < 1 ? 1 : page;
    if (forceRefresh) _rows.remove(section.id);

    var row = _rows[section.id];
    if (row == null) {
      row = await _loadRow(serverId, _slotFor(section));
      row = await _expandScoredRow(row);
      _rows[section.id] = row;
    }

    final filtered = row.items.where((item) => _matches(section, item)).toList();
    final total = filtered.length;
    final totalPages = total == 0 ? 0 : (total + pageSize - 1) ~/ pageSize;
    final start = (safePage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, total).toInt();
    final pageItems = start < total
        ? filtered.sublist(start, end)
        : const <AggregatedItem>[];
    final converted = pageItems
        .map(_toSeerrItem)
        .whereType<SeerrDiscoverItem>()
        .toList(growable: false);

    return HomeLabDiscoveryPersonalPage(
      title: _effectiveTitle(section, row),
      page: SeerrDiscoverPage(
        page: safePage,
        totalPages: totalPages,
        totalResults: total,
        results: converted,
      ),
    );
  }

  Future<HomeRow> _expandScoredRow(HomeRow initial) async {
    var row = initial;
    var pass = 0;
    while (row.hasMore && pass < _maxExpansionPasses) {
      pass++;
      final before = row.items.length;
      final (loaded, total) = await _loadMore(
        row: row,
        serverId: serverId,
        offset: before,
      );
      if (loaded.length <= before) break;
      row = row.copyWith(items: loaded, totalCount: total);
    }
    return row;
  }

  void clearSection(String sectionId) => _rows.remove(sectionId);

  void clear() => _rows.clear();

  int _slotFor(HomeLabDiscoverySection section) {
    const slots = <String, int>{
      'recent-history': 1,
      'favourites': 2,
      'watchlist': 3,
      'high-ratings': 4,
      'likes': 5,
      'mixed-positive': 6,
      'highly-rated-unseen': 7,
      'novelty': 8,
      'movie-affinity': 9,
      'series-affinity': 10,
      'anime-affinity': 11,
      'short-runtime-affinity': 12,
      'older-affinity': 13,
      'recent-affinity': 14,
      'rewatch': 15,
      'recent-discovery-context': 16,
    };
    final strategy = section.query.seedStrategy ?? '';
    final direct = slots[strategy];
    if (direct != null) return direct;

    // Anime/specialised strategy names deterministically share one of the same
    // sixteen upstream recommendation slots, then section filtering diverges.
    var hash = 0;
    for (final unit in '${section.id}|$strategy'.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return (hash % 16) + 1;
  }

  bool _matches(HomeLabDiscoverySection section, AggregatedItem item) {
    final wanted = section.query.mediaType;
    if (wanted == 'movie' && item.type != 'Movie') return false;
    if (wanted == 'tv' && item.type != 'Series') return false;
    if (_animeOnly(section) && !_looksLikeAnime(item)) return false;
    return item.type == 'Movie' || item.type == 'Series';
  }

  bool _animeOnly(HomeLabDiscoverySection section) {
    if (section.tags.any((tag) => tag.toLowerCase() == 'anime')) return true;
    final strategy = section.query.seedStrategy?.toLowerCase() ?? '';
    return strategy.startsWith('anime-') || section.id.startsWith('anime-');
  }

  bool _looksLikeAnime(AggregatedItem item) {
    final tags = (item.rawData['Tags'] as List? ?? const [])
        .map((value) => value.toString().toLowerCase())
        .toSet();
    final genres = item.genres.map((value) => value.toLowerCase()).toSet();
    if (tags.contains('anime') || genres.contains('anime')) return true;

    final isAnimated = genres.contains('animation');
    final language = item.rawData['OriginalLanguage']?.toString().toLowerCase();
    final fromJapan = item.productionLocations.any(
      (value) => value.toLowerCase() == 'japan',
    );
    final japanese = language == 'ja' || language == 'jpn' || language == 'japanese';
    return isAnimated && (japanese || fromJapan);
  }

  String _effectiveTitle(HomeLabDiscoverySection section, HomeRow row) {
    final generated = row.title.trim();
    if (generated.isNotEmpty && generated != 'Recommended For You') {
      return generated;
    }
    return section.title;
  }

  SeerrDiscoverItem? _toSeerrItem(AggregatedItem item) {
    final tmdb = int.tryParse(item.tmdbId ?? '');
    if (tmdb == null || tmdb <= 0) return null;

    final mediaType = switch (item.type) {
      'Movie' => 'movie',
      'Series' => 'tv',
      _ => null,
    };
    if (mediaType == null) return null;

    final raw = item.rawData;
    final year = item.productionYear;
    final date = year == null
        ? null
        : '${year.toString().padLeft(4, '0')}-01-01';
    final genreIds = (raw['GenreIds'] as List? ?? const [])
        .map((value) => value is int ? value : int.tryParse(value.toString()))
        .whereType<int>()
        .toList(growable: false);
    final status = raw['IsBlacklisted'] == true ? 6 : 5;

    return SeerrDiscoverItem(
      id: tmdb,
      mediaType: mediaType,
      title: mediaType == 'movie' ? item.name : null,
      name: mediaType == 'tv' ? item.name : null,
      posterPath: raw['PosterPath']?.toString(),
      backdropPath: raw['BackdropPath']?.toString(),
      overview: item.overview,
      releaseDate: mediaType == 'movie' ? date : null,
      firstAirDate: mediaType == 'tv' ? date : null,
      originalLanguage: raw['OriginalLanguage']?.toString(),
      genreIds: genreIds,
      voteAverage: item.communityRating,
      adult: raw['Adult'] == true,
      mediaInfo: SeerrMediaInfo(
        tmdbId: tmdb,
        status: status,
        jellyfinMediaId: item.id,
      ),
    );
  }
}
