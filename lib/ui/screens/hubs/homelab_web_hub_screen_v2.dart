import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:moonfin_design/moonfin_design.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/models/aggregated_library.dart';
import '../../../data/models/home_row.dart';
import '../../../data/repositories/seerr_repository.dart';
import '../../../data/repositories/user_views_repository.dart';
import '../../../data/services/custom_external_lists_service.dart';
import '../../../data/services/row_data_source.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../data/utils/bounded_concurrency.dart';
import '../../../data/viewmodels/seerr_discover_view_model.dart';
import '../../../preference/home_section_config.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../navigation/homelab_hub_routes.dart';
import '../../widgets/bounded_network_image.dart';
import '../../widgets/library_row.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/top_toolbar.dart';

/// Home Lab web-desktop destination system.
///
/// Moonbase remains authoritative for integrations, synced preferences,
/// ownership/request state and custom editorial rows. This screen owns the
/// cinematic destination composition for Movies, TV and Anime only. Every
/// network shelf is fault-isolated: one failed Seerr/TMDB call can remove that
/// shelf, but cannot take down the destination.
class HomelabWebHubScreenV2 extends StatefulWidget {
  final String kind;

  const HomelabWebHubScreenV2({super.key, required this.kind});

  @override
  State<HomelabWebHubScreenV2> createState() => _HomelabWebHubScreenV2State();
}

enum _HubKind { movies, tv, anime }

extension _HubKindX on _HubKind {
  String get title => switch (this) {
    _HubKind.movies => 'Movies',
    _HubKind.tv => 'TV',
    _HubKind.anime => 'Anime',
  };

  String get kicker => switch (this) {
    _HubKind.movies => 'HOME LAB CINEMA',
    _HubKind.tv => 'HOME LAB SERIES',
    _HubKind.anime => 'HOME LAB ANIME',
  };

  String get intro => switch (this) {
    _HubKind.movies =>
      'New releases, acclaimed films, curated picks and your own collection.',
    _HubKind.tv =>
      'Series worth starting, seasons worth returning to and what is trending now.',
    _HubKind.anime =>
      'A focused anime destination for series, films and seasonal discovery.',
  };

  String get route => switch (this) {
    _HubKind.movies => HomelabHubRoutes.movies,
    _HubKind.tv => HomelabHubRoutes.tv,
    _HubKind.anime => HomelabHubRoutes.anime,
  };
}

class _HomelabWebHubScreenV2State extends State<HomelabWebHubScreenV2> {
  late final UserPreferences _prefs;
  late final MediaServerClient _client;
  late final UserViewsRepository _viewsRepo;
  late final RowDataSource _rowDataSource;
  late final CustomExternalListsService _customLists;

  Future<_HubData>? _dataFuture;

  _HubKind get _kind => switch (widget.kind.toLowerCase()) {
    'movies' => _HubKind.movies,
    'tv' => _HubKind.tv,
    _ => _HubKind.anime,
  };

  @override
  void initState() {
    super.initState();
    _prefs = GetIt.instance<UserPreferences>();
    _client = GetIt.instance<MediaServerClient>();
    _viewsRepo = GetIt.instance<UserViewsRepository>();
    _rowDataSource = RowDataSource(_client);
    _customLists = CustomExternalListsService();
    _dataFuture = _loadData();
  }

  @override
  void didUpdateWidget(covariant HomelabWebHubScreenV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _dataFuture = _loadData();
    }
  }

  Future<void> _refresh() async {
    final next = _loadData(forceRefresh: true);
    setState(() => _dataFuture = next);
    await next;
  }

  Future<_HubData> _loadData({bool forceRefresh = false}) async {
    final librariesFuture = _safeLibraries();
    final repoFuture = _seerrRepo();

    final libraries = await librariesFuture;
    final matchingLibraries = _matchingLibraries(libraries);
    final localFuture = _loadLocalRows(matchingLibraries);

    final repo = await repoFuture;
    final editorialFuture = _loadMoonbaseEditorialRows(
      repo,
      forceRefresh: forceRefresh,
    );
    final discoveryFuture = repo == null
        ? Future.value(const _DiscoveryLoad(shelves: []))
        : _loadDiscovery(repo);

    final localRows = await localFuture;
    final editorialRows = await editorialFuture;
    final discovery = await discoveryFuture;

    final shelves = <_HubShelf>[];
    final discoveryShelves = discovery.shelves;
    if (discoveryShelves.isNotEmpty) {
      // Immediate intent first, then editorial, then deeper exploration.
      shelves.add(discoveryShelves.first);
      if (discoveryShelves.length > 1 &&
          discoveryShelves[1].title == 'Your Watchlist') {
        shelves.add(discoveryShelves[1]);
      }
      shelves.addAll(editorialRows);
      final skip = shelves.length >= 2 &&
              discoveryShelves.length > 1 &&
              discoveryShelves[1].title == 'Your Watchlist'
          ? 2
          : 1;
      shelves.addAll(discoveryShelves.skip(skip));
    } else {
      shelves.addAll(editorialRows);
    }

    final cleanedShelves = _dedupeShelves(shelves);
    final heroItems = _heroCandidates(cleanedShelves);

    return _HubData(
      heroItems: heroItems,
      shelves: cleanedShelves,
      localRows: localRows,
      discoveryNotice: discovery.notice,
    );
  }

  Future<List<AggregatedLibrary>> _safeLibraries() async {
    try {
      return await _viewsRepo.getUserViews();
    } catch (_) {
      return const [];
    }
  }

  Future<SeerrRepository?> _seerrRepo() async {
    try {
      final repo = await GetIt.instance.getAsync<SeerrRepository>();
      await repo.ensureInitialized();
      return repo.isAvailable ? repo : null;
    } catch (_) {
      return null;
    }
  }

  List<AggregatedLibrary> _matchingLibraries(
    List<AggregatedLibrary> libraries,
  ) {
    final wanted = switch (_kind) {
      _HubKind.movies => const {'movies'},
      _HubKind.tv => const {'tv'},
      _HubKind.anime => const {'anime', 'anime movies'},
    };
    return libraries
        .where((library) => wanted.contains(library.name.trim().toLowerCase()))
        .toList(growable: false);
  }

  Future<List<_LocalRow>> _loadLocalRows(
    List<AggregatedLibrary> libraries,
  ) async {
    final rows = await Future.wait(
      libraries.map((library) async {
        try {
          final row = await _rowDataSource.loadLatestMedia(
            library.id,
            library.name,
            library.serverId,
            library.collectionType,
          );
          final filteredItems = _kind == _HubKind.anime
              ? row.items.where(_safeLocalAnime).toList(growable: false)
              : row.items;
          if (filteredItems.isEmpty) return null;
          return _LocalRow(
            library: library,
            row: row.copyWith(items: filteredItems),
          );
        } catch (_) {
          return null;
        }
      }),
    );
    return rows.whereType<_LocalRow>().toList(growable: false);
  }

  Future<List<_HubShelf>> _loadMoonbaseEditorialRows(
    SeerrRepository? repo, {
    required bool forceRefresh,
  }) async {
    final configs = _prefs.activeHomeSectionConfigs
        .where(
          (config) =>
              config.enabled &&
              config.isPluginDynamic &&
              config.pluginSource == HomeSectionPluginSource.custom,
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (configs.isEmpty) return const [];

    final resolved = await Future.wait(
      configs.map((config) async {
        try {
          final raw = await _customLists.fetchCustomRow(
            config,
            forceRefresh: forceRefresh,
          );
          if (_kind == _HubKind.anime) {
            // External lists do not carry enough language/adult metadata to be
            // admitted directly. Resolve them through Seerr and the same strict
            // anime verifier used for ordinary discovery.
            if (repo == null) return null;
            final verified = await _resolveSafeAnimeExternal(repo, raw);
            if (verified.isEmpty) return null;
            return _HubShelf(
              title: _editorialTitle(config),
              items: verified.take(20).toList(growable: false),
            );
          }

          final items = raw
              .where(_externalItemMatchesDestination)
              .map(_HubItem.fromExternal)
              .whereType<_HubItem>()
              .take(20)
              .toList(growable: false);
          if (items.isEmpty) return null;
          return _HubShelf(
            title: _editorialTitle(config),
            items: _dedupeHubItems(items),
          );
        } catch (_) {
          return null;
        }
      }),
    );

    return resolved.whereType<_HubShelf>().toList(growable: false);
  }

  String _editorialTitle(HomeSectionConfig config) {
    final raw = (config.pluginDisplayText ?? config.pluginSection ?? '').trim();
    return raw.isEmpty ? 'Curated for You' : raw;
  }

  bool _externalItemMatchesDestination(ImdbExternalListItem item) {
    final type = item.type.trim().toLowerCase();
    return switch (_kind) {
      _HubKind.movies => type == 'movie',
      _HubKind.tv => type == 'series' || type == 'tv',
      _HubKind.anime => false,
    };
  }

  Future<List<_HubItem>> _resolveSafeAnimeExternal(
    SeerrRepository repo,
    List<ImdbExternalListItem> raw,
  ) async {
    final candidates = raw.take(28).toList(growable: false);
    final resolved = await mapBounded<ImdbExternalListItem, _HubItem>(
      candidates,
      4,
      (item) async {
        final tmdbId = int.tryParse(item.tmdbId);
        if (tmdbId == null) return null;
        final type = item.type.trim().toLowerCase();
        final mediaType = type == 'series' || type == 'tv' ? 'tv' : 'movie';
        try {
          final search = await repo.search(item.title, mediaType: mediaType);
          final discover = search.results.firstWhere(
            (candidate) => candidate.id == tmdbId,
            orElse: () => search.results.isEmpty
                ? SeerrDiscoverItem(id: -1)
                : search.results.first,
          );
          if (discover.id != tmdbId || !_basicAnimeCandidate(discover)) {
            return null;
          }
          final verified = await _verifyAnimeCandidate(repo, discover);
          return verified == null
              ? null
              : _HubItem.fromSeerr(verified, mediaType);
        } catch (_) {
          return null;
        }
      },
    );
    return _dedupeHubItems(resolved.whereType<_HubItem>());
  }

  Future<_DiscoveryLoad> _loadDiscovery(SeerrRepository repo) {
    return switch (_kind) {
      _HubKind.movies => _loadMovieDiscovery(repo),
      _HubKind.tv => _loadTvDiscovery(repo),
      _HubKind.anime => _loadAnimeDiscovery(repo),
    };
  }

  Future<_DiscoveryLoad> _loadMovieDiscovery(SeerrRepository repo) async {
    final futures = <Future<_HubShelf?>>[
      _safeShelf(
        'Trending Movies',
        () => repo.getTrendingMovies(limit: 30),
        'movie',
      ),
      _safeShelf(
        'Your Watchlist',
        () => repo.getWatchlist(page: 1),
        'movie',
        mediaTypeFilter: 'movie',
      ),
      _safeShelf(
        'Critically Acclaimed',
        () => repo.getTopMovies(limit: 30),
        'movie',
      ),
      _safeShelf(
        'New & Upcoming',
        () => repo.getUpcomingMovies(page: 1),
        'movie',
      ),
      _safeShelf(
        'Action',
        () => repo.discoverMovies(
          page: 1,
          sortBy: 'popularity.desc',
          genre: 28,
        ),
        'movie',
      ),
      _safeShelf(
        'Science Fiction',
        () => repo.discoverMovies(
          page: 1,
          sortBy: 'popularity.desc',
          genre: 878,
        ),
        'movie',
      ),
      _safeShelf(
        'Fantasy',
        () => repo.discoverMovies(
          page: 1,
          sortBy: 'popularity.desc',
          genre: 14,
        ),
        'movie',
      ),
      _safeShelf(
        'Thrillers',
        () => repo.discoverMovies(
          page: 1,
          sortBy: 'popularity.desc',
          genre: 53,
        ),
        'movie',
      ),
      _safeShelf(
        'Comedy',
        () => repo.discoverMovies(
          page: 1,
          sortBy: 'popularity.desc',
          genre: 35,
        ),
        'movie',
      ),
      _safeShelf(
        'Horror',
        () => repo.discoverMovies(
          page: 1,
          sortBy: 'popularity.desc',
          genre: 27,
        ),
        'movie',
      ),
      _safeMergedShelf(
        'Studio Spotlight',
        [
          () => repo.discoverMovies(
            page: 1,
            sortBy: 'popularity.desc',
            studio: 41077,
          ),
          () => repo.discoverMovies(
            page: 1,
            sortBy: 'popularity.desc',
            studio: 420,
          ),
          () => repo.discoverMovies(
            page: 1,
            sortBy: 'popularity.desc',
            studio: 174,
          ),
        ],
        'movie',
      ),
    ];

    final shelves = (await Future.wait(futures))
        .whereType<_HubShelf>()
        .toList(growable: false);
    return _DiscoveryLoad(
      shelves: shelves,
      notice: shelves.isEmpty
          ? 'Movie discovery is temporarily unavailable.'
          : null,
    );
  }

  Future<_DiscoveryLoad> _loadTvDiscovery(SeerrRepository repo) async {
    final futures = <Future<_HubShelf?>>[
      _safeShelf(
        'Trending Series',
        () => repo.getTrendingTv(limit: 30),
        'tv',
      ),
      _safeShelf(
        'Your Watchlist',
        () => repo.getWatchlist(page: 1),
        'tv',
        mediaTypeFilter: 'tv',
      ),
      _safeShelf(
        'Critically Acclaimed',
        () => repo.getTopTv(limit: 30),
        'tv',
      ),
      _safeShelf(
        'New & Upcoming',
        () => repo.getUpcomingTv(page: 1),
        'tv',
      ),
      _safeShelf(
        'Drama',
        () => repo.discoverTv(
          page: 1,
          sortBy: 'popularity.desc',
          genre: 18,
        ),
        'tv',
      ),
      _safeShelf(
        'Comedy',
        () => repo.discoverTv(
          page: 1,
          sortBy: 'popularity.desc',
          genre: 35,
        ),
        'tv',
      ),
      _safeShelf(
        'Crime',
        () => repo.discoverTv(
          page: 1,
          sortBy: 'popularity.desc',
          genre: 80,
        ),
        'tv',
      ),
      _safeShelf(
        'Mystery & Suspense',
        () => repo.discoverTv(
          page: 1,
          sortBy: 'popularity.desc',
          genre: 9648,
        ),
        'tv',
      ),
      _safeShelf(
        'Sci-Fi & Fantasy',
        () => repo.discoverTv(
          page: 1,
          sortBy: 'popularity.desc',
          genre: 10765,
        ),
        'tv',
      ),
      _safeMergedShelf(
        'Network Spotlight',
        [
          () => repo.discoverTv(
            page: 1,
            sortBy: 'popularity.desc',
            network: 49,
          ),
          () => repo.discoverTv(
            page: 1,
            sortBy: 'popularity.desc',
            network: 2552,
          ),
          () => repo.discoverTv(
            page: 1,
            sortBy: 'popularity.desc',
            network: 213,
          ),
        ],
        'tv',
      ),
    ];

    final shelves = (await Future.wait(futures))
        .whereType<_HubShelf>()
        .toList(growable: false);
    return _DiscoveryLoad(
      shelves: shelves,
      notice: shelves.isEmpty ? 'TV discovery is temporarily unavailable.' : null,
    );
  }

  Future<_DiscoveryLoad> _loadAnimeDiscovery(SeerrRepository repo) async {
    final futures = <Future<_HubShelf?>>[
      _safeAnimeShelf(
        repo,
        'Popular Anime',
        [
          () => repo.discoverTv(
            page: 1,
            sortBy: 'popularity.desc',
            genre: 16,
          ),
          () => repo.discoverTv(
            page: 2,
            sortBy: 'popularity.desc',
            genre: 16,
          ),
        ],
        'tv',
      ),
      _safeAnimeShelf(
        repo,
        'Your Anime Watchlist',
        [() => repo.getWatchlist(page: 1)],
        'tv',
      ),
      _safeAnimeShelf(
        repo,
        'Top Rated Anime',
        [
          () => repo.discoverTv(
            page: 1,
            sortBy: 'vote_average.desc',
            genre: 16,
          ),
          () => repo.discoverTv(
            page: 2,
            sortBy: 'vote_average.desc',
            genre: 16,
          ),
        ],
        'tv',
      ),
      _safeAnimeShelf(
        repo,
        'New This Season',
        [
          () => repo.discoverTv(
            page: 1,
            sortBy: 'first_air_date.desc',
            genre: 16,
          ),
          () => repo.getUpcomingTv(page: 1),
        ],
        'tv',
      ),
      _safeAnimeShelf(
        repo,
        'Anime Movies',
        [
          () => repo.discoverMovies(
            page: 1,
            sortBy: 'popularity.desc',
            genre: 16,
          ),
          () => repo.discoverMovies(
            page: 2,
            sortBy: 'vote_average.desc',
            genre: 16,
          ),
        ],
        'movie',
      ),
      _safeAnimeShelf(
        repo,
        'Action & Adventure',
        [
          () => repo.discoverTv(
            page: 1,
            sortBy: 'popularity.desc',
            genre: 10759,
          ),
          () => repo.discoverTv(
            page: 2,
            sortBy: 'popularity.desc',
            genre: 10759,
          ),
        ],
        'tv',
        secondaryGenre: 10759,
      ),
      _safeAnimeShelf(
        repo,
        'Sci-Fi & Fantasy',
        [
          () => repo.discoverTv(
            page: 1,
            sortBy: 'popularity.desc',
            genre: 10765,
          ),
          () => repo.discoverTv(
            page: 2,
            sortBy: 'popularity.desc',
            genre: 10765,
          ),
        ],
        'tv',
        secondaryGenre: 10765,
      ),
      _safeAnimeShelf(
        repo,
        'Comedy',
        [
          () => repo.discoverTv(
            page: 1,
            sortBy: 'popularity.desc',
            genre: 35,
          ),
          () => repo.discoverTv(
            page: 2,
            sortBy: 'popularity.desc',
            genre: 35,
          ),
        ],
        'tv',
        secondaryGenre: 35,
      ),
      _safeAnimeShelf(
        repo,
        'Drama',
        [
          () => repo.discoverTv(
            page: 1,
            sortBy: 'popularity.desc',
            genre: 18,
          ),
          () => repo.discoverTv(
            page: 2,
            sortBy: 'popularity.desc',
            genre: 18,
          ),
        ],
        'tv',
        secondaryGenre: 18,
      ),
      _safeAnimeShelf(
        repo,
        'Mystery & Suspense',
        [
          () => repo.discoverTv(
            page: 1,
            sortBy: 'popularity.desc',
            genre: 9648,
          ),
          () => repo.discoverTv(
            page: 2,
            sortBy: 'popularity.desc',
            genre: 9648,
          ),
        ],
        'tv',
        secondaryGenre: 9648,
      ),
    ];

    final shelves = (await Future.wait(futures))
        .whereType<_HubShelf>()
        .toList(growable: false);
    return _DiscoveryLoad(
      shelves: shelves,
      notice: shelves.isEmpty
          ? 'Anime discovery is temporarily unavailable.'
          : null,
    );
  }

  Future<_HubShelf?> _safeShelf(
    String title,
    Future<SeerrDiscoverPage> Function() load,
    String fallbackMediaType, {
    String? mediaTypeFilter,
  }) async {
    try {
      final page = await load();
      final items = page.results
          .where(_safeDiscover)
          .where(
            (item) =>
                mediaTypeFilter == null ||
                (item.mediaType ?? fallbackMediaType) == mediaTypeFilter,
          )
          .map((item) => _HubItem.fromSeerr(item, fallbackMediaType))
          .take(30)
          .toList(growable: false);
      final deduped = _dedupeHubItems(items);
      return deduped.isEmpty ? null : _HubShelf(title: title, items: deduped);
    } catch (_) {
      return null;
    }
  }

  Future<_HubShelf?> _safeMergedShelf(
    String title,
    List<Future<SeerrDiscoverPage> Function()> loaders,
    String fallbackMediaType,
  ) async {
    final pages = await Future.wait(
      loaders.map((load) async {
        try {
          return await load();
        } catch (_) {
          return null;
        }
      }),
    );
    final items = pages
        .whereType<SeerrDiscoverPage>()
        .expand((page) => page.results)
        .where(_safeDiscover)
        .map((item) => _HubItem.fromSeerr(item, fallbackMediaType));
    final deduped = _dedupeHubItems(items).take(30).toList(growable: false);
    return deduped.isEmpty ? null : _HubShelf(title: title, items: deduped);
  }

  Future<_HubShelf?> _safeAnimeShelf(
    SeerrRepository repo,
    String title,
    List<Future<SeerrDiscoverPage> Function()> loaders,
    String fallbackMediaType, {
    int? secondaryGenre,
  }) async {
    final pages = await Future.wait(
      loaders.map((load) async {
        try {
          return await load();
        } catch (_) {
          return null;
        }
      }),
    );
    final seen = <String>{};
    final candidates = pages
        .whereType<SeerrDiscoverPage>()
        .expand((page) => page.results)
        .where((item) {
          final type = item.mediaType ?? fallbackMediaType;
          final key = '$type:${item.id}';
          return seen.add(key) &&
              _basicAnimeCandidate(item) &&
              (secondaryGenre == null || item.genreIds.contains(secondaryGenre));
        })
        .take(42)
        .toList(growable: false);

    final verified = await mapBounded<SeerrDiscoverItem, SeerrDiscoverItem>(
      candidates,
      5,
      (item) => _verifyAnimeCandidate(repo, item),
    );
    final items = verified
        .whereType<SeerrDiscoverItem>()
        .map((item) => _HubItem.fromSeerr(item, fallbackMediaType));
    final deduped = _dedupeHubItems(items).take(30).toList(growable: false);
    return deduped.isEmpty ? null : _HubShelf(title: title, items: deduped);
  }

  bool _basicAnimeCandidate(SeerrDiscoverItem item) {
    final mediaType = item.mediaType ?? 'tv';
    final isTv = mediaType == 'tv';
    final isMovie = mediaType == 'movie';
    if (!isTv && !isMovie) return false;
    return _safeDiscover(item) &&
        item.originalLanguage?.toLowerCase() == 'ja' &&
        item.genreIds.contains(16) &&
        !_looksExplicit('${item.displayTitle} ${item.overview ?? ''}');
  }

  Future<SeerrDiscoverItem?> _verifyAnimeCandidate(
    SeerrRepository repo,
    SeerrDiscoverItem item,
  ) async {
    if (!_basicAnimeCandidate(item)) return null;
    try {
      final mediaType = item.mediaType ?? 'tv';
      if (mediaType == 'movie') {
        final detail = await repo.getMovieDetails(item.id);
        if (detail.mediaInfo?.status == 6) return null;
        final text = [
          item.displayTitle,
          item.overview ?? '',
          detail.title,
          detail.tagline ?? '',
          detail.overview ?? '',
          ...detail.genres.map((genre) => genre.name),
          ...detail.keywords.map((keyword) => keyword.name),
        ].join(' ');
        return _looksExplicit(text) ? null : item;
      }
      final detail = await repo.getTvDetails(item.id);
      if (detail.mediaInfo?.status == 6) return null;
      final text = [
        item.displayTitle,
        item.overview ?? '',
        detail.displayTitle,
        detail.tagline ?? '',
        detail.overview ?? '',
        ...detail.genres.map((genre) => genre.name),
        ...detail.keywords.map((keyword) => keyword.name),
      ].join(' ');
      return _looksExplicit(text) ? null : item;
    } catch (_) {
      // Do not admit an unverified candidate to ordinary Anime discovery.
      return null;
    }
  }

  bool _safeDiscover(SeerrDiscoverItem item) {
    return !item.adult &&
        !item.isBlacklisted &&
        item.displayTitle.trim().isNotEmpty;
  }

  static final List<RegExp> _animeExplicitPatterns = [
    ...SeerrDiscoverViewModel.nsfwPatterns,
    RegExp(r'\bhentai\b', caseSensitive: false),
    RegExp(r'\bpornographic\b', caseSensitive: false),
    RegExp(r'\bsexually explicit\b', caseSensitive: false),
    RegExp(r'\badult animation\b', caseSensitive: false),
    RegExp(r'\beroge\b', caseSensitive: false),
    RegExp(r'\bfutanari\b', caseSensitive: false),
    RegExp(r'\bnetorare\b', caseSensitive: false),
    RegExp(r'\btentacle sex\b', caseSensitive: false),
    RegExp(r'\bincest\b', caseSensitive: false),
    RegExp(r'\brape\b', caseSensitive: false),
  ];

  bool _looksExplicit(String text) =>
      _animeExplicitPatterns.any((pattern) => pattern.hasMatch(text));

  bool _safeLocalAnime(AggregatedItem item) {
    final tags = (item.rawData['Tags'] as List?)
            ?.map((entry) => entry?.toString() ?? '')
            .join(' ') ??
        '';
    final text = '${item.name} ${item.overview ?? ''} '
        '${item.genres.join(' ')} $tags';
    return !_looksExplicit(text);
  }

  List<_HubShelf> _dedupeShelves(List<_HubShelf> shelves) {
    final result = <_HubShelf>[];
    final titleSeen = <String>{};
    for (final shelf in shelves) {
      final titleKey = shelf.title.trim().toLowerCase();
      if (!titleSeen.add(titleKey)) continue;
      final items = _dedupeHubItems(shelf.items);
      if (items.isEmpty) continue;
      result.add(_HubShelf(title: shelf.title, items: items));
    }
    return result;
  }

  List<_HubItem> _dedupeHubItems(Iterable<_HubItem> items) {
    final seen = <String>{};
    return items.where((item) => seen.add(item.stableKey)).toList(growable: false);
  }

  List<_HubItem> _heroCandidates(List<_HubShelf> shelves) {
    final seen = <String>{};
    final result = <_HubItem>[];
    for (final shelf in shelves) {
      for (final item in shelf.items) {
        if (item.backdropUrl == null || !seen.add(item.stableKey)) continue;
        result.add(item);
        if (result.length >= 8) return result;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final navbarPosition = _prefs.get(UserPreferences.navbarPosition);
    final safeTop = MediaQuery.paddingOf(context).top;
    final toolbarInset = navbarPosition == NavbarPosition.top
        ? safeTop + TopToolbar.baseHeightFor(context)
        : safeTop;
    final hasLeftRail =
        navbarPosition == NavbarPosition.left &&
        (PlatformDetection.isDesktop ||
            (PlatformDetection.isWeb && !PlatformDetection.useMobileUi));
    final rowLeftInset = hasLeftRail ? 78.0 : 0.0;
    final heroLeftInset = hasLeftRail ? 126.0 : 54.0;

    return Scaffold(
      backgroundColor: AppColorScheme.background,
      body: NavigationLayout(
        activeRoute: _kind.route,
        pinTopToolbar: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _HomeLabAmbientBackdrop(),
            FutureBuilder<_HubData>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return _HubLoading(
                    title: _kind.title,
                    topInset: toolbarInset,
                    leftInset: rowLeftInset,
                  );
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return _HubError(onRetry: _refresh);
                }
                final data = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _HomeLabHero(
                        kind: _kind,
                        items: data.heroItems,
                        topInset: toolbarInset + 16,
                        leftInset: heroLeftInset,
                      ),
                      const SizedBox(height: 2),
                      for (var i = 0; i < data.shelves.length; i++)
                        Padding(
                          padding: EdgeInsets.only(left: rowLeftInset),
                          child: _buildDiscoveryShelf(
                            data.shelves[i],
                            prominent: i < 3,
                          ),
                        ),
                      if (data.localRows.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            rowLeftInset + 34,
                            30,
                            28,
                            6,
                          ),
                          child: const _SectionEyebrow(
                            kicker: 'YOUR COLLECTION',
                            title: 'From Your Library',
                          ),
                        ),
                        for (final local in data.localRows)
                          Padding(
                            padding: EdgeInsets.only(left: rowLeftInset),
                            child: _buildLocalRow(local),
                          ),
                      ],
                      if (data.discoveryNotice != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            rowLeftInset + 34,
                            24,
                            28,
                            12,
                          ),
                          child: Text(
                            data.discoveryNotice!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColorScheme.onSurface.withValues(
                                    alpha: 0.58,
                                  ),
                                ),
                          ),
                        ),
                      const SizedBox(height: 64),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryShelf(_HubShelf shelf, {required bool prominent}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 10, 28, 2),
            child: Text(
              shelf.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                  ),
            ),
          ),
          LibraryRow(
            title: '',
            rowHeight: prominent ? 272 : 258,
            children: shelf.items
                .map((item) => _buildDiscoveryCard(item, prominent: prominent))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryCard(_HubItem item, {required bool prominent}) {
    final metadata = <String>[
      if (item.year != null) item.year!,
      if (item.rating != null && item.rating! > 0)
        '★ ${item.rating!.toStringAsFixed(1)}',
    ];
    return MediaCard(
      title: item.title,
      subtitle: metadata.isEmpty ? null : metadata.join('  •  '),
      imageUrl: item.posterUrl,
      width: prominent ? 158 : 148,
      aspectRatio: 2 / 3,
      seerrMediaType: item.mediaType,
      seerrStatus: item.seerrStatus,
      onTap: () => _openDiscoveryItem(item),
    );
  }

  void _openDiscoveryItem(_HubItem item) {
    context.push(
      Destinations.seerrMedia(
        item.tmdbId.toString(),
        mediaType: item.mediaType,
        title: item.title,
      ),
    );
  }

  Widget _buildLocalRow(_LocalRow local) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(34, 8, 28, 2),
          child: Text(
            local.row.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
          ),
        ),
        LibraryRow(
          title: '',
          rowHeight: 258,
          onSeeAll: () {
            context.push(
              Destinations.library(
                local.library.id,
                serverId: local.library.serverId,
              ),
            );
          },
          children: local.row.items.map(_buildLocalCard).toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildLocalCard(AggregatedItem item) {
    final aspectRatio = MediaCard.aspectRatioForType(item.type);
    return MediaCard(
      title: item.name,
      subtitle: item.subtitle,
      imageUrl: _localPosterUrl(item),
      width: aspectRatio == 16 / 9 ? 242 : 148,
      aspectRatio: aspectRatio,
      itemType: item.type,
      isFavorite: item.isFavorite,
      isPlayed: item.isPlayed,
      unplayedCount: item.unplayedItemCount,
      playedPercentage: item.playedPercentage,
      onTap: () => context.push(
        Destinations.itemOrPhoto(
          item.id,
          serverId: item.serverId,
          type: item.type,
        ),
      ),
    );
  }

  String? _localPosterUrl(AggregatedItem item) {
    try {
      if (item.type == 'Episode' &&
          item.seriesId != null &&
          item.seriesPrimaryImageTag != null) {
        return _client.imageApi.getPrimaryImageUrl(
          item.seriesId!,
          maxWidth: 420,
          tag: item.seriesPrimaryImageTag,
        );
      }
      return _client.imageApi.getPrimaryImageUrl(
        item.id,
        maxWidth: 420,
        tag: item.primaryImageTag ?? item.primaryImageTagField,
      );
    } catch (_) {
      return null;
    }
  }
}

class _HomeLabAmbientBackdrop extends StatelessWidget {
  const _HomeLabAmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorScheme.accent.withValues(alpha: 0.055),
              AppColorScheme.background,
              ThemeRegistry.active.semantic.mediaTypeBadgeShow.withValues(
                alpha: 0.035,
              ),
              AppColorScheme.background,
            ],
            stops: const [0.0, 0.28, 0.66, 1.0],
          ),
        ),
      ),
    );
  }
}

class _HomeLabHero extends StatefulWidget {
  final _HubKind kind;
  final List<_HubItem> items;
  final double topInset;
  final double leftInset;

  const _HomeLabHero({
    required this.kind,
    required this.items,
    required this.topInset,
    required this.leftInset,
  });

  @override
  State<_HomeLabHero> createState() => _HomeLabHeroState();
}

class _HomeLabHeroState extends State<_HomeLabHero> {
  Timer? _timer;
  int _index = 0;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _configureTimer();
  }

  @override
  void didUpdateWidget(covariant _HomeLabHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFirst = oldWidget.items.isEmpty ? null : oldWidget.items.first.stableKey;
    final newFirst = widget.items.isEmpty ? null : widget.items.first.stableKey;
    if (oldFirst != newFirst || oldWidget.items.length != widget.items.length) {
      _index = 0;
      _configureTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _configureTimer() {
    _timer?.cancel();
    if (widget.items.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted || _hovered || widget.items.length <= 1) return;
      setState(() => _index = (_index + 1) % widget.items.length);
    });
  }

  void _move(int delta) {
    if (widget.items.isEmpty) return;
    setState(() {
      _index = (_index + delta) % widget.items.length;
      if (_index < 0) _index += widget.items.length;
    });
    _configureTimer();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final heroHeight = (size.height * 0.57).clamp(450.0, 650.0).toDouble();
    if (widget.items.isEmpty) {
      return _HeroFallback(
        kind: widget.kind,
        height: heroHeight,
        topInset: widget.topInset,
        leftInset: widget.leftInset,
      );
    }

    if (_index >= widget.items.length) _index = 0;
    final item = widget.items[_index];

    return MouseRegion(
      onEnter: (_) => _hovered = true,
      onExit: (_) => _hovered = false,
      child: SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              child: item.backdropUrl == null
                  ? const SizedBox.expand()
                  : SizedBox.expand(
                      key: ValueKey('home_lab_hero_${item.stableKey}'),
                      child: BoundedNetworkImage(
                        imageUrl: item.backdropUrl!,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        fadeInDuration: const Duration(milliseconds: 240),
                        maxWidth: 1920,
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColorScheme.scrim.withValues(alpha: 0.18),
                      Colors.transparent,
                      AppColorScheme.background.withValues(alpha: 0.72),
                      AppColorScheme.background,
                    ],
                    stops: const [0.0, 0.36, 0.78, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColorScheme.scrim.withValues(alpha: 0.92),
                      AppColorScheme.scrim.withValues(alpha: 0.66),
                      AppColorScheme.scrim.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.32, 0.62, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: widget.leftInset,
              right: 108,
              top: widget.topInset,
              bottom: 48,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: ConstrainedBox(
                    key: ValueKey('home_lab_hero_copy_${item.stableKey}'),
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.kind.kicker,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColorScheme.accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.35,
                              ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppColorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                                height: 0.98,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (item.year != null) _HeroPill(label: item.year!),
                            if (item.rating != null && item.rating! > 0)
                              _HeroPill(
                                label: '★ ${item.rating!.toStringAsFixed(1)}',
                              ),
                            if (item.isAvailable)
                              const _HeroPill(label: 'In Library'),
                          ],
                        ),
                        if (item.overview != null && item.overview!.trim().isNotEmpty) ...[
                          const SizedBox(height: 13),
                          Text(
                            item.overview!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColorScheme.onSurface.withValues(alpha: 0.86),
                                  height: 1.38,
                                ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () => context.push(
                            Destinations.seerrMedia(
                              item.tmdbId.toString(),
                              mediaType: item.mediaType,
                              title: item.title,
                            ),
                          ),
                          icon: Icon(
                            item.isAvailable
                                ? Icons.play_arrow_rounded
                                : Icons.add_rounded,
                          ),
                          label: Text(item.isAvailable ? 'Open' : 'View & Request'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.items.length > 1) ...[
              Positioned(
                right: 22,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _HeroArrow(
                    icon: Icons.chevron_right_rounded,
                    onPressed: () => _move(1),
                  ),
                ),
              ),
              Positioned(
                right: 54,
                bottom: 22,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.items.length, (index) {
                    final selected = index == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: selected ? 22 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColorScheme.accent
                            : AppColorScheme.onSurface.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  final _HubKind kind;
  final double height;
  final double topInset;
  final double leftInset;

  const _HeroFallback({
    required this.kind,
    required this.height,
    required this.topInset,
    required this.leftInset,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorScheme.accent.withValues(alpha: 0.10),
              Theme.of(context).colorScheme.surface,
              AppColorScheme.background,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(leftInset, topInset + 70, 56, 62),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind.kicker,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColorScheme.accent,
                          letterSpacing: 2.35,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    kind.title,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.1,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    kind.intro,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColorScheme.onSurface.withValues(alpha: 0.70),
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  final String kicker;
  final String title;

  const _SectionEyebrow({required this.kicker, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColorScheme.accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColorScheme.onSurface,
                fontWeight: FontWeight.w850,
                letterSpacing: -0.4,
              ),
        ),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ThemeRegistry.active.colors.surface.withValues(alpha: 0.72),
        borderRadius: ThemeRegistry.active.borders.chipRadius,
        border: Border.all(
          color: ThemeRegistry.active.borders.chipBorder.color,
          width: ThemeRegistry.active.borders.chipBorder.width,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _HeroArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HeroArrow({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: ThemeRegistry.active.colors.surface.withValues(alpha: 0.72),
        foregroundColor: AppColorScheme.onSurface,
        side: ThemeRegistry.active.borders.chipBorder,
      ),
    );
  }
}

class _HubLoading extends StatelessWidget {
  final String title;
  final double topInset;
  final double leftInset;

  const _HubLoading({
    required this.title,
    required this.topInset,
    required this.leftInset,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 390 + topInset,
          child: Padding(
            padding: EdgeInsets.fromLTRB(leftInset + 34, topInset + 110, 56, 40),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColorScheme.accent.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: width.clamp(320, 640) * 0.58,
                    height: 42,
                    decoration: BoxDecoration(
                      color: ThemeRegistry.active.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading $title…',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColorScheme.onSurface.withValues(alpha: 0.48),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (var row = 0; row < 3; row++)
          Padding(
            padding: EdgeInsets.fromLTRB(leftInset + 34, 8, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180,
                  height: 18,
                  decoration: BoxDecoration(
                    color: ThemeRegistry.active.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 185,
                  child: Row(
                    children: List.generate(
                      7,
                      (index) => Container(
                        width: 118,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: ThemeRegistry.active.colors.card,
                          borderRadius: ThemeRegistry.active.borders.cardRadius,
                          border: Border.all(
                            color: ThemeRegistry.active.borders.cardBorder.color,
                            width: ThemeRegistry.active.borders.cardBorder.width,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HubError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _HubError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 34,
            color: AppColorScheme.onSurface.withValues(alpha: 0.58),
          ),
          const SizedBox(height: 12),
          Text(
            'This destination could not be loaded.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => onRetry(), child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _HubData {
  final List<_HubItem> heroItems;
  final List<_HubShelf> shelves;
  final List<_LocalRow> localRows;
  final String? discoveryNotice;

  const _HubData({
    required this.heroItems,
    required this.shelves,
    required this.localRows,
    this.discoveryNotice,
  });
}

class _DiscoveryLoad {
  final List<_HubShelf> shelves;
  final String? notice;

  const _DiscoveryLoad({required this.shelves, this.notice});
}

class _HubShelf {
  final String title;
  final List<_HubItem> items;

  const _HubShelf({required this.title, required this.items});
}

class _LocalRow {
  final AggregatedLibrary library;
  final HomeRow row;

  const _LocalRow({required this.library, required this.row});
}

class _HubItem {
  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final String? overview;
  final String? year;
  final double? rating;
  final int? seerrStatus;

  const _HubItem({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.posterUrl,
    this.backdropUrl,
    this.overview,
    this.year,
    this.rating,
    this.seerrStatus,
  });

  String get stableKey => '$mediaType:$tmdbId';

  bool get isAvailable => seerrStatus == 4 || seerrStatus == 5;

  factory _HubItem.fromSeerr(
    SeerrDiscoverItem item,
    String fallbackMediaType,
  ) {
    final date = item.releaseDate ?? item.firstAirDate;
    return _HubItem(
      tmdbId: item.id,
      mediaType: item.mediaType ?? fallbackMediaType,
      title: item.displayTitle,
      posterUrl: _normaliseImage(item.posterPath, size: 'w500'),
      backdropUrl: _normaliseImage(item.backdropPath, size: 'w1280'),
      overview: item.overview,
      year: date != null && date.length >= 4 ? date.substring(0, 4) : null,
      rating: item.voteAverage,
      seerrStatus: item.mediaInfo?.status,
    );
  }

  static _HubItem? fromExternal(ImdbExternalListItem item) {
    final tmdbId = int.tryParse(item.tmdbId);
    if (tmdbId == null) return null;
    final rawType = item.type.trim().toLowerCase();
    final mediaType = rawType == 'series' || rawType == 'tv' ? 'tv' : 'movie';
    return _HubItem(
      tmdbId: tmdbId,
      mediaType: mediaType,
      title: item.title,
      posterUrl: _normaliseImage(item.posterUrl, size: 'w500'),
      backdropUrl: _normaliseImage(item.backdropUrl, size: 'w1280'),
      year: item.year?.toString(),
      rating: item.rating,
    );
  }
}

String? _normaliseImage(String? value, {required String size}) {
  if (value == null || value.trim().isEmpty) return null;
  final trimmed = value.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('//')) return 'https:$trimmed';
  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return 'https://image.tmdb.org/t/p/$size$path';
}
