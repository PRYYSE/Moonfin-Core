import '../../../data/models/aggregated_item.dart';
import '../../../data/models/home_row.dart';
import '../../../data/services/row_data_source.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../catalogue/discovery_catalogue.dart';
import 'discovery_personal_policy.dart';

typedef HomeLabDiscoveryPersonalRowLoader =
    Future<HomeRow> Function(String serverId, int rowIndex);

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

/// Feature-local adapter over stock Moonfin's `Since You Watched` engine.
///
/// A personalised catalogue label is executable only when
/// [homeLabDiscoveryPersonalPolicy] can prove that the current upstream row,
/// plus explicit result filtering, represents that label truthfully. There is
/// deliberately no hash/slot fallback for unknown or source-specific labels.
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

  bool supports(HomeLabDiscoverySection section) =>
      homeLabDiscoveryPersonalPolicy(section) != null;

  Future<HomeLabDiscoveryPersonalPage> load(
    HomeLabDiscoverySection section, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final policy = homeLabDiscoveryPersonalPolicy(section);
    if (policy == null) {
      throw UnsupportedError(
        'Discovery personal strategy ${section.query.seedStrategy ?? section.id} '
        'has no truthful source in the current Flutter client',
      );
    }

    final safePage = page < 1 ? 1 : page;
    if (forceRefresh) _rows.remove(section.id);

    var row = _rows[section.id];
    if (row == null) {
      row = await _loadRow(serverId, policy.rowIndex);
      row = await _expandScoredRow(row);
      _rows[section.id] = row;
    }

    final filtered = row.items
        .where((item) => _matches(policy, item))
        .toList(growable: false);
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
      // Keep the authored label. The upstream row title may describe whichever
      // seed source the user configured and must not silently redefine the
      // semantics of this Discovery lane.
      title: section.title,
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

  bool _matches(
    HomeLabDiscoveryPersonalPolicy policy,
    AggregatedItem item,
  ) {
    final wanted = policy.mediaType.toLowerCase();
    if (wanted == 'movie' && item.type != 'Movie') return false;
    if (wanted == 'tv' && item.type != 'Series') return false;
    if (wanted != 'movie' &&
        wanted != 'tv' &&
        wanted != 'all' &&
        wanted != 'any') {
      return false;
    }
    if (item.type != 'Movie' && item.type != 'Series') return false;

    if (policy.animeOnly && !_looksLikeAnime(item)) return false;

    if (policy.requiredGenreFragments.isNotEmpty) {
      final genres = item.genres.map((value) => value.toLowerCase()).toList();
      final matchesGenre = policy.requiredGenreFragments.any(
        (fragment) => genres.any((genre) => genre.contains(fragment)),
      );
      if (!matchesGenre) return false;
    }

    final minimumRating = policy.minRating;
    if (minimumRating != null) {
      final rating = item.communityRating;
      if (rating == null || rating < minimumRating) return false;
    }

    if (policy.unseenOnly && item.isPlayed) return false;

    final maxRuntimeMinutes = policy.maxRuntimeMinutes;
    if (maxRuntimeMinutes != null) {
      final runtime = item.runtime;
      if (runtime != null && runtime.inMinutes > maxRuntimeMinutes) return false;
    }

    final year = item.productionYear;
    final currentYear = DateTime.now().year;
    final olderThanYears = policy.olderThanYears;
    if (olderThanYears != null &&
        year != null &&
        year > currentYear - olderThanYears) {
      return false;
    }
    final newerThanYears = policy.newerThanYears;
    if (newerThanYears != null &&
        year != null &&
        year < currentYear - newerThanYears) {
      return false;
    }

    return true;
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
    final japanese =
        language == 'ja' || language == 'jpn' || language == 'japanese';
    return isAnimated && (japanese || fromJapan);
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
    final external = item.serverId == 'seerr';
    final status = raw['IsBlacklisted'] == true
        ? 6
        : external
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
              jellyfinMediaId: external ? null : item.id,
            ),
    );
  }
}
