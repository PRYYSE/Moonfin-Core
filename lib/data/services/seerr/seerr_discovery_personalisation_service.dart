import '../../models/aggregated_item.dart';
import '../../models/home_row.dart';
import '../row_data_source.dart';
import 'seerr_api_models.dart';
import 'seerr_discovery_schema.dart';

typedef SeerrDiscoveryPersonalRowLoader =
    Future<HomeRow> Function(
      String serverId,
      int rowIndex, {
      List<String>? preferredItemTypes,
      bool animeOnly,
    });

typedef SeerrDiscoveryPersonalLoadMore =
    Future<(List<AggregatedItem>, int)> Function({
      required HomeRow row,
      required String serverId,
      int? offset,
    });

class SeerrDiscoveryPersonalPage {
  final String title;
  final SeerrDiscoverPage page;

  const SeerrDiscoveryPersonalPage({required this.title, required this.page});
}

/// Adapts the already accepted Home `Since You Watched` recommendation engine
/// to deep Discovery without reimplementing its taste-signal collection.
///
/// RowDataSource already combines recent play history, favourites, positive
/// ratings/likes, Seerr watchlist and recent/library cold-start seeds, then
/// scores up to 100 recommendations. Discovery gives each personalised section
/// a stable row slot and pages through that existing scored cache.
class SeerrDiscoveryPersonalisationService {
  static const int pageSize = 15;

  final String serverId;
  final SeerrDiscoveryPersonalRowLoader _loadRow;
  final SeerrDiscoveryPersonalLoadMore _loadMore;
  final Map<String, HomeRow> _rows = <String, HomeRow>{};

  SeerrDiscoveryPersonalisationService({
    required this.serverId,
    required RowDataSource rowDataSource,
  }) : _loadRow = rowDataSource.loadSinceYouWatchedRow,
       _loadMore = rowDataSource.loadMore;

  SeerrDiscoveryPersonalisationService.forTesting({
    required this.serverId,
    required SeerrDiscoveryPersonalRowLoader loadRow,
    required SeerrDiscoveryPersonalLoadMore loadMore,
  }) : _loadRow = loadRow,
       _loadMore = loadMore;

  Future<SeerrDiscoveryPersonalPage> load(
    SeerrDiscoverySection section, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final key = section.id;
    if (forceRefresh) _rows.remove(key);

    var row = _rows[key];
    if (row == null) {
      row = await _loadRow(
        serverId,
        _slotFor(section),
        preferredItemTypes: _preferredItemTypes(section),
        animeOnly: _animeOnly(section),
      );
      _rows[key] = row;
    }

    final total = row.totalCount > row.items.length
        ? row.totalCount
        : row.items.length;
    final totalPages = total == 0 ? 0 : (total + pageSize - 1) ~/ pageSize;
    final start = (safePage - 1) * pageSize;
    if (start >= total) {
      return SeerrDiscoveryPersonalPage(
        title: _effectiveTitle(section, row),
        page: SeerrDiscoverPage(
          page: safePage,
          totalPages: totalPages,
          totalResults: total,
          results: const [],
        ),
      );
    }

    List<AggregatedItem> available = row.items;
    if (start + pageSize > available.length && row.hasMore) {
      final (loaded, loadedTotal) = await _loadMore(
        row: row,
        serverId: serverId,
        offset: start,
      );
      available = loaded;
      final refreshedTotal = loadedTotal > total ? loadedTotal : total;
      row = row.copyWith(items: available, totalCount: refreshedTotal);
      _rows[key] = row;
    }

    final end = (start + pageSize).clamp(0, available.length).toInt();
    final items = start < available.length
        ? available.sublist(start, end)
        : const <AggregatedItem>[];
    final converted = items
        .map(_toSeerrItem)
        .whereType<SeerrDiscoverItem>()
        .toList(growable: false);
    final finalTotal = row.totalCount > row.items.length
        ? row.totalCount
        : row.items.length;
    final finalPages = finalTotal == 0
        ? 0
        : (finalTotal + pageSize - 1) ~/ pageSize;

    return SeerrDiscoveryPersonalPage(
      title: _effectiveTitle(section, row),
      page: SeerrDiscoverPage(
        page: safePage,
        totalPages: finalPages,
        totalResults: finalTotal,
        results: converted,
      ),
    );
  }

  void clearSection(String sectionId) => _rows.remove(sectionId);

  void clear() => _rows.clear();

  int _slotFor(SeerrDiscoverySection section) {
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

    // Anime-specific strategy names use the same stable 1..16 recommendation
    // slots but remain isolated by section cache key and Anime filtering.
    var hash = 0;
    for (final unit in '${section.id}|$strategy'.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return (hash % 16) + 1;
  }

  List<String>? _preferredItemTypes(SeerrDiscoverySection section) {
    if (_animeOnly(section)) return const ['Movie', 'Series'];
    return switch (section.query.mediaType) {
      'movie' => const ['Movie'],
      'tv' => const ['Series'],
      _ => null,
    };
  }

  bool _animeOnly(SeerrDiscoverySection section) {
    if (section.tags.any((tag) => tag.toLowerCase() == 'anime')) return true;
    final strategy = section.query.seedStrategy?.toLowerCase() ?? '';
    return strategy.startsWith('anime-') || section.id.startsWith('anime-');
  }

  String _effectiveTitle(SeerrDiscoverySection section, HomeRow row) {
    final generated = row.title.trim();
    if (generated.isNotEmpty && generated != 'Recommended For You') {
      return generated;
    }
    return section.title;
  }

  SeerrDiscoverItem? _toSeerrItem(AggregatedItem item) {
    final tmdb = int.tryParse(item.tmdbId ?? '') ?? int.tryParse(item.id);
    if (tmdb == null || tmdb <= 0) return null;

    final raw = item.rawData;
    final mediaType =
        item.seerrMediaType ??
        (item.type == 'Series'
            ? 'tv'
            : item.type == 'Movie'
            ? 'movie'
            : null);
    if (mediaType != 'movie' && mediaType != 'tv') return null;

    final year = item.productionYear;
    final date = year == null
        ? null
        : '${year.toString().padLeft(4, '0')}-01-01';
    final genreIds = (raw['GenreIds'] as List? ?? const [])
        .map((value) => value is int ? value : int.tryParse(value.toString()))
        .whereType<int>()
        .toList(growable: false);
    final status = raw['IsBlacklisted'] == true
        ? 6
        : item.serverId == 'seerr'
        ? item.seerrStatus
        : 5;

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
      mediaInfo: status == null
          ? null
          : SeerrMediaInfo(
              tmdbId: tmdb,
              status: status,
              jellyfinMediaId: item.serverId == 'seerr' ? null : item.id,
            ),
    );
  }
}
