import '../../../data/models/aggregated_item.dart';
import '../../../data/models/home_row.dart';
import '../../../data/services/row_data_source.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../catalogue/discovery_catalogue.dart';
import 'discovery_personal_policy.dart';
import 'discovery_personal_sources.dart';

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

/// Feature-local personalisation adapter for Home Lab Discovery.
///
/// Generic affinity rows use [homeLabDiscoveryPersonalPolicy]. Provenance-
/// specific rows use [HomeLabDiscoveryPersonalSources]. Unknown, structural or
/// contextual strategies have no fallback and therefore fail closed.
class HomeLabDiscoveryPersonalisation {
  static const pageSize = 15;
  static const _maxExpansionPasses = 8;

  final String serverId;
  final HomeLabDiscoveryPersonalRowLoader _loadRow;
  final HomeLabDiscoveryPersonalLoadMore _loadMore;
  final HomeLabDiscoveryPersonalSources? _personalSources;
  final Map<String, HomeRow> _rows = <String, HomeRow>{};

  HomeLabDiscoveryPersonalisation({
    required this.serverId,
    required RowDataSource rowDataSource,
    HomeLabDiscoveryPersonalSources? personalSources,
  }) : _loadRow = rowDataSource.loadSinceYouWatchedRow,
       _loadMore = rowDataSource.loadMore,
       _personalSources = personalSources;

  HomeLabDiscoveryPersonalisation.forTesting({
    required this.serverId,
    required HomeLabDiscoveryPersonalRowLoader loadRow,
    required HomeLabDiscoveryPersonalLoadMore loadMore,
    HomeLabDiscoveryPersonalSources? personalSources,
  }) : _loadRow = loadRow,
       _loadMore = loadMore,
       _personalSources = personalSources;

  bool supports(HomeLabDiscoverySection section) =>
      homeLabDiscoveryPersonalPolicy(section) != null ||
      (_personalSources?.supports(section) ?? false);

  Future<HomeLabDiscoveryPersonalPage> load(
    HomeLabDiscoverySection section, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final policy = homeLabDiscoveryPersonalPolicy(section);
    if (policy != null) {
      return _loadGenericAffinity(
        section,
        policy,
        page: page,
        forceRefresh: forceRefresh,
      );
    }

    final sources = _personalSources;
    if (sources == null || !sources.supports(section)) {
      throw UnsupportedError(
        'Discovery personal strategy ${section.query.seedStrategy ?? section.id} '
        'has no truthful source in the current Flutter client',
      );
    }

    final loaded = await sources.load(
      section,
      page: page,
      forceRefresh: forceRefresh,
    );
    final converted = loaded.items
        .map(_toSeerrItem)
        .whereType<SeerrDiscoverItem>()
        .toList(growable: false);

    return HomeLabDiscoveryPersonalPage(
      title: _sourceDisplayTitle(section),
      page: SeerrDiscoverPage(
        page: loaded.page,
        totalPages: loaded.totalPages,
        totalResults: loaded.totalResults,
        results: converted,
      ),
    );
  }

  Future<HomeLabDiscoveryPersonalPage> _loadGenericAffinity(
    HomeLabDiscoverySection section,
    HomeLabDiscoveryPersonalPolicy policy, {
    required int page,
    required bool forceRefresh,
  }) async {
    final safePage = page < 1 ? 1 : page;
    if (forceRefresh) _rows.remove(section.id);

    var row = _rows[section.id];
    if (row == null) {
      row = await _loadRow(serverId, policy.rowIndex);
      row = await _expandScoredRow(row);
      _rows[section.id] = row;
    }

    // Convert before counting/paging so malformed or identity-less upstream
    // candidates cannot inflate the advertised total or create empty pages.
    final eligible = row.items
        .where((item) => _matches(policy, item))
        .map(_toSeerrItem)
        .whereType<SeerrDiscoverItem>()
        .toList(growable: false);
    final total = eligible.length;
    final totalPages = total == 0 ? 0 : (total + pageSize - 1) ~/ pageSize;
    final start = (safePage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, total).toInt();
    final converted = start < total
        ? eligible.sublist(start, end)
        : const <SeerrDiscoverItem>[];

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

  void clearSection(String sectionId) {
    _rows.remove(sectionId);
  }

  void clear() {
    _rows.clear();
    _personalSources?.clear();
  }

  static String _sourceDisplayTitle(HomeLabDiscoverySection section) {
    final strategy = (section.query.seedStrategy ?? '').trim().toLowerCase();
    if (strategy == 'anime-novelty' ||
        strategy == 'anime-something-different') {
      return 'Something Different in Anime';
    }
    return section.title;
  }

  bool _matches(HomeLabDiscoveryPersonalPolicy policy, AggregatedItem item) {
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
      if (runtime != null && runtime.inMinutes > maxRuntimeMinutes) {
        return false;
      }
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
    // A local Jellyfin id is never a TMDB id. External Seerr/TMDB adapters are
    // the only safe place where a numeric AggregatedItem.id itself is TMDB.
    final tmdb = int.tryParse(
      item.tmdbId ?? (item.serverId == 'seerr' ? item.id : ''),
    );
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
    final explicitJellyfinId = raw['JellyfinMediaId']?.toString().trim();
    final jellyfinId = external
        ? (explicitJellyfinId == null || explicitJellyfinId.isEmpty
              ? null
              : explicitJellyfinId)
        : item.id;

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
              jellyfinMediaId: jellyfinId,
            ),
    );
  }
}
