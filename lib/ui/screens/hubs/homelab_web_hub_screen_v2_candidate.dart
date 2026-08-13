import 'dart:async';
import 'dart:convert';

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

/// Corrected Home Lab web-desktop discovery destinations.
///
/// Data/integrations remain owned by Jellyfin, Moonbase and Seerr. This widget
/// owns the destination composition only. Each external shelf catches its own
/// failure so a single bad endpoint never takes down Movies, TV or Anime.
class HomelabWebHubScreenV2Candidate extends StatefulWidget {
  final String kind;

  const HomelabWebHubScreenV2Candidate({super.key, required this.kind});

  @override
  State<HomelabWebHubScreenV2Candidate> createState() =>
      _HomelabWebHubScreenV2CandidateState();
}

enum _DestinationKind { movies, tv, anime }

extension _DestinationKindX on _DestinationKind {
  String get title => switch (this) {
    _DestinationKind.movies => 'Movies',
    _DestinationKind.tv => 'TV',
    _DestinationKind.anime => 'Anime',
  };

  String get kicker => switch (this) {
    _DestinationKind.movies => 'HOME LAB CINEMA',
    _DestinationKind.tv => 'HOME LAB SERIES',
    _DestinationKind.anime => 'HOME LAB ANIME',
  };

  String get route => switch (this) {
    _DestinationKind.movies => HomelabHubRoutes.movies,
    _DestinationKind.tv => HomelabHubRoutes.tv,
    _DestinationKind.anime => HomelabHubRoutes.anime,
  };

  Set<String> get libraryNames => switch (this) {
    _DestinationKind.movies => const {'movies'},
    _DestinationKind.tv => const {'tv'},
    _DestinationKind.anime => const {'anime', 'anime movies'},
  };

  String get fallbackDescription => switch (this) {
    _DestinationKind.movies =>
      'New releases, acclaimed films, curated picks and your own collection.',
    _DestinationKind.tv =>
      'Series worth starting, seasons worth returning to and what is trending now.',
    _DestinationKind.anime =>
      'A focused anime destination for series, films and seasonal discovery.',
  };
}

class _HomelabWebHubScreenV2CandidateState
    extends State<HomelabWebHubScreenV2Candidate> {
  late final UserPreferences _prefs;
  late final MediaServerClient _client;
  late final UserViewsRepository _views;
  late final RowDataSource _rowDataSource;
  late final CustomExternalListsService _customLists;

  Future<_DestinationData>? _future;

  _DestinationKind get _kind => switch (widget.kind.toLowerCase()) {
    'movies' => _DestinationKind.movies,
    'tv' => _DestinationKind.tv,
    _ => _DestinationKind.anime,
  };

  @override
  void initState() {
    super.initState();
    _prefs = GetIt.instance<UserPreferences>();
    _client = GetIt.instance<MediaServerClient>();
    _views = GetIt.instance<UserViewsRepository>();
    _rowDataSource = RowDataSource(_client);
    _customLists = CustomExternalListsService();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant HomelabWebHubScreenV2Candidate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _future = _load();
    }
  }

  Future<void> _refresh() async {
    final next = _load(forceRefresh: true);
    setState(() => _future = next);
    await next;
  }

  Future<_DestinationData> _load({bool forceRefresh = false}) async {
    final repoFuture = _getSeerr();
    final librariesFuture = _getLibraries();

    final libraries = await librariesFuture;
    final localFuture = _loadLocalRows(libraries);
    final repo = await repoFuture;

    final discoveryFuture = repo == null
        ? Future.value(const <_Shelf>[])
        : _loadDiscovery(repo);
    final personalisedFuture = repo == null || libraries.isEmpty
        ? Future.value(const <_Shelf>[])
        : _loadPersonalised(repo, libraries.first.serverId);
    final editorialFuture = _loadEditorial(repo, forceRefresh: forceRefresh);

    final discovery = await discoveryFuture;
    final personalised = await personalisedFuture;
    final editorial = await editorialFuture;
    final local = await localFuture;

    final shelves = <_Shelf>[];
    if (discovery.isNotEmpty) {
      shelves.add(discovery.first);
      final watchlist = discovery.where((row) => row.isWatchlist).toList();
      shelves.addAll(watchlist);
      shelves.addAll(personalised);
      shelves.addAll(editorial);
      shelves.addAll(discovery.skip(1).where((row) => !row.isWatchlist));
    } else {
      shelves.addAll(personalised);
      shelves.addAll(editorial);
    }

    final cleaned = _dedupeShelves(shelves);
    return _DestinationData(
      shelves: cleaned,
      localRows: local,
      heroItems: _heroCandidates(cleaned),
      notice: repo == null && cleaned.isEmpty
          ? 'Discovery is temporarily unavailable. Your local library remains accessible below.'
          : null,
    );
  }

  Future<SeerrRepository?> _getSeerr() async {
    try {
      final repo = await GetIt.instance.getAsync<SeerrRepository>();
      await repo.ensureInitialized();
      return repo.isAvailable ? repo : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<AggregatedLibrary>> _getLibraries() async {
    try {
      final all = await _views.getUserViews();
      return all
          .where(
            (library) =>
                _kind.libraryNames.contains(library.name.trim().toLowerCase()),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<_LocalShelf>> _loadLocalRows(
    List<AggregatedLibrary> libraries,
  ) async {
    final rows = await Future.wait(
      libraries.map((library) async {
        try {
          final loaded = await _rowDataSource.loadLatestMedia(
            library.id,
            library.name,
            library.serverId,
            library.collectionType,
          );
          final items = _kind == _DestinationKind.anime
              ? loaded.items.where(_safeLocalAnime).toList(growable: false)
              : loaded.items;
          if (items.isEmpty) return null;
          return _LocalShelf(
            library: library,
            row: loaded.copyWith(items: items),
          );
        } catch (_) {
          return null;
        }
      }),
    );
    return rows.whereType<_LocalShelf>().toList(growable: false);
  }

  Future<List<_Shelf>> _loadEditorial(
    SeerrRepository? repo, {
    required bool forceRefresh,
  }) async {
    final configs =
        _prefs.homeSectionsConfig
            .where(
              (config) =>
                  config.isPluginDynamic &&
                  config.pluginSource == HomeSectionPluginSource.custom &&
                  (config.enabled || _isDestinationOnly(config)) &&
                  _supportsDestination(config),
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    final result = await Future.wait(
      configs.map((config) async {
        try {
          final raw = await _customLists.fetchCustomRow(
            config,
            forceRefresh: forceRefresh,
          );
          final title = (config.pluginDisplayText ?? config.pluginSection ?? '')
              .trim();
          final displayTitle = title.isEmpty ? 'Curated for You' : title;

          if (_kind == _DestinationKind.anime) {
            final metadata = _editorialMetadata(config);
            final managedTmdbAnime =
                metadata['source'] == 'tmdb_chart' &&
                metadata['homelab_destinations'] is List &&
                (metadata['homelab_destinations'] as List).contains('anime');
            final verified = managedTmdbAnime
                ? _dedupeItems(
                    raw
                        .where(
                          (item) =>
                              !_looksExplicit(item.title) &&
                              item.tmdbId.trim().isNotEmpty,
                        )
                        .map(_HubItem.fromExternal)
                        .whereType<_HubItem>(),
                  ).take(30).toList(growable: false)
                : repo == null
                ? const <_HubItem>[]
                : await _resolveEditorialAnime(repo, raw);
            return verified.isEmpty ? null : _Shelf(displayTitle, verified);
          }

          final expectedType = _kind == _DestinationKind.movies
              ? 'movie'
              : 'tv';
          final items = raw
              .where((item) {
                final type = item.type.toLowerCase();
                return expectedType == 'movie'
                    ? type == 'movie'
                    : type == 'series' || type == 'tv';
              })
              .map(_HubItem.fromExternal)
              .whereType<_HubItem>()
              .take(24)
              .toList(growable: false);
          return items.isEmpty ? null : _Shelf(displayTitle, items);
        } catch (_) {
          return null;
        }
      }),
    );
    return result.whereType<_Shelf>().toList(growable: false);
  }

  Map<String, dynamic> _editorialMetadata(HomeSectionConfig config) {
    try {
      final decoded = jsonDecode(config.pluginAdditionalData ?? '{}');
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  bool _isDestinationOnly(HomeSectionConfig config) =>
      _editorialMetadata(config)['homelab_destination_only'] == true;

  bool _supportsDestination(HomeSectionConfig config) {
    final raw = _editorialMetadata(config)['homelab_destinations'];
    if (raw is! List || raw.isEmpty) return true;
    return raw
        .map((entry) => entry.toString().trim().toLowerCase())
        .contains(_kind.name);
  }

  Future<List<_Shelf>> _loadPersonalised(
    SeerrRepository repo,
    String serverId,
  ) async {
    final rows = await Future.wait(
      List.generate(3, (index) async {
        try {
          return await _rowDataSource.loadSinceYouWatchedRow(
            serverId,
            index + 1,
            preferredItemTypes: switch (_kind) {
              _DestinationKind.movies => const ['Movie'],
              _DestinationKind.tv => const ['Series'],
              _DestinationKind.anime => const ['Movie', 'Series'],
            },
            animeOnly: _kind == _DestinationKind.anime,
          );
        } catch (_) {
          return null;
        }
      }),
    );

    final result = <_Shelf>[];
    for (final row in rows.whereType<HomeRow>()) {
      if (row.items.isEmpty) continue;
      if (_kind == _DestinationKind.anime) {
        final candidates = row.items
            .map(_HubItem.recommendationAsExternal)
            .whereType<ImdbExternalListItem>()
            .take(16)
            .toList(growable: false);
        final verified = await _resolveEditorialAnime(repo, candidates);
        if (verified.isNotEmpty) {
          result.add(_Shelf(row.title, verified, isPersonalised: true));
        }
        continue;
      }

      final expectedType = _kind == _DestinationKind.movies ? 'movie' : 'tv';
      final items = row.items
          .where((item) => !_recommendationLooksAnime(item))
          .map(_HubItem.fromRecommendation)
          .whereType<_HubItem>()
          .where((item) => item.mediaType == expectedType)
          .take(24)
          .toList(growable: false);
      if (items.isNotEmpty) {
        result.add(_Shelf(row.title, items, isPersonalised: true));
      }
    }
    return result;
  }

  bool _recommendationLooksAnime(AggregatedItem item) {
    final raw = item.rawData;
    final language = raw['OriginalLanguage']?.toString().toLowerCase();
    final genreIds = raw['GenreIds'];
    final genres = item.genres.map((genre) => genre.toLowerCase()).toSet();
    final animation =
        (genreIds is List && genreIds.any((id) => id.toString() == '16')) ||
        genres.contains('animation') ||
        genres.contains('anime');
    return genres.contains('anime') || (animation && language == 'ja');
  }

  Future<List<_HubItem>> _resolveEditorialAnime(
    SeerrRepository repo,
    List<ImdbExternalListItem> input,
  ) async {
    final candidates = input.take(24).toList(growable: false);
    final resolved = await mapBounded<ImdbExternalListItem, _HubItem>(
      candidates,
      4,
      (item) async {
        final tmdbId = int.tryParse(item.tmdbId);
        if (tmdbId == null) return null;
        final rawType = item.type.toLowerCase();
        final mediaType = rawType == 'movie' ? 'movie' : 'tv';
        try {
          final page = await repo.search(item.title, mediaType: mediaType);
          SeerrDiscoverItem? match;
          for (final candidate in page.results) {
            if (candidate.id == tmdbId) {
              match = candidate;
              break;
            }
          }
          if (match == null) return null;
          final verified = await _verifyAnime(repo, match);
          return verified == null
              ? null
              : _HubItem.fromSeerr(verified, mediaType);
        } catch (_) {
          return null;
        }
      },
    );
    return _dedupeItems(
      resolved.whereType<_HubItem>(),
    ).take(24).toList(growable: false);
  }

  Future<List<_Shelf>> _loadDiscovery(SeerrRepository repo) async {
    return switch (_kind) {
      _DestinationKind.movies => _loadMovies(repo),
      _DestinationKind.tv => _loadTv(repo),
      _DestinationKind.anime => _loadAnime(repo),
    };
  }

  Future<List<_Shelf>> _loadMovies(SeerrRepository repo) async {
    final tasks = <Future<_Shelf?>>[
      _loadShelf(
        'Trending Movies',
        'movie',
        () => repo.getTrendingMovies(limit: 30),
      ),
      _loadShelf(
        'Your Watchlist',
        'movie',
        () => repo.getWatchlist(page: 1),
        filterMediaType: 'movie',
        isWatchlist: true,
      ),
      _loadShelf(
        'Critically Acclaimed',
        'movie',
        () => repo.discoverMovies(page: 1, sortBy: 'vote_average.desc'),
      ),
      _loadShelf(
        'New & Upcoming',
        'movie',
        () => repo.getUpcomingMovies(page: 1),
      ),
      _loadShelf(
        'Action',
        'movie',
        () =>
            repo.discoverMovies(page: 1, sortBy: 'popularity.desc', genre: 28),
      ),
      _loadShelf(
        'Science Fiction',
        'movie',
        () =>
            repo.discoverMovies(page: 1, sortBy: 'popularity.desc', genre: 878),
      ),
      _loadShelf(
        'Thrillers',
        'movie',
        () =>
            repo.discoverMovies(page: 1, sortBy: 'popularity.desc', genre: 53),
      ),
      _loadShelf(
        'Comedy',
        'movie',
        () =>
            repo.discoverMovies(page: 1, sortBy: 'popularity.desc', genre: 35),
      ),
      _loadMergedShelf('Studio Spotlight', 'movie', [
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
      ]),
    ];
    return (await Future.wait(tasks)).whereType<_Shelf>().toList();
  }

  Future<List<_Shelf>> _loadTv(SeerrRepository repo) async {
    final tasks = <Future<_Shelf?>>[
      _loadShelf('Trending Series', 'tv', () => repo.getTrendingTv(limit: 30)),
      _loadShelf(
        'Your Watchlist',
        'tv',
        () => repo.getWatchlist(page: 1),
        filterMediaType: 'tv',
        isWatchlist: true,
      ),
      _loadShelf(
        'Critically Acclaimed',
        'tv',
        () => repo.discoverTv(page: 1, sortBy: 'vote_average.desc'),
      ),
      _loadShelf('New & Upcoming', 'tv', () => repo.getUpcomingTv(page: 1)),
      _loadShelf(
        'Drama',
        'tv',
        () => repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 18),
      ),
      _loadShelf(
        'Comedy',
        'tv',
        () => repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 35),
      ),
      _loadShelf(
        'Crime',
        'tv',
        () => repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 80),
      ),
      _loadShelf(
        'Sci-Fi & Fantasy',
        'tv',
        () => repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 10765),
      ),
      _loadMergedShelf('Network Spotlight', 'tv', [
        () => repo.discoverTv(page: 1, sortBy: 'popularity.desc', network: 49),
        () =>
            repo.discoverTv(page: 1, sortBy: 'popularity.desc', network: 2552),
        () => repo.discoverTv(page: 1, sortBy: 'popularity.desc', network: 213),
      ]),
    ];
    return (await Future.wait(tasks)).whereType<_Shelf>().toList();
  }

  Future<List<_Shelf>> _loadAnime(SeerrRepository repo) async {
    final tasks = <Future<_Shelf?>>[
      _loadAnimeShelf(repo, 'Trending Anime', 'tv', [
        () => repo.getTrending(limit: 60, offset: 0),
        () => repo.getTrending(limit: 60, offset: 60),
      ]),
      _loadAnimeShelf(repo, 'Popular Anime', 'tv', [
        () => repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 16),
        () => repo.discoverTv(page: 2, sortBy: 'popularity.desc', genre: 16),
        () => repo.discoverTv(page: 3, sortBy: 'popularity.desc', genre: 16),
      ]),
      _loadAnimeShelf(repo, 'Your Anime Watchlist', 'tv', [
        () => repo.getWatchlist(page: 1),
      ], isWatchlist: true),
      _loadAnimeShelf(repo, 'New This Season', 'tv', [
        () =>
            repo.discoverTv(page: 1, sortBy: 'first_air_date.desc', genre: 16),
        () =>
            repo.discoverTv(page: 2, sortBy: 'first_air_date.desc', genre: 16),
        () =>
            repo.discoverTv(page: 3, sortBy: 'first_air_date.desc', genre: 16),
      ]),
      _loadAnimeShelf(repo, 'Anime Movies', 'movie', [
        () =>
            repo.discoverMovies(page: 1, sortBy: 'popularity.desc', genre: 16),
        () =>
            repo.discoverMovies(page: 2, sortBy: 'popularity.desc', genre: 16),
        () =>
            repo.discoverMovies(page: 3, sortBy: 'popularity.desc', genre: 16),
      ]),
    ];
    return (await Future.wait(tasks)).whereType<_Shelf>().toList();
  }

  Future<_Shelf?> _loadShelf(
    String title,
    String fallbackMediaType,
    Future<SeerrDiscoverPage> Function() request, {
    String? filterMediaType,
    bool isWatchlist = false,
  }) async {
    try {
      final page = await request();
      final items = page.results
          .where(_safeDiscover)
          .where(
            (item) =>
                filterMediaType == null ||
                (item.mediaType ?? fallbackMediaType) == filterMediaType,
          )
          .map((item) => _HubItem.fromSeerr(item, fallbackMediaType));
      final cleaned = _dedupeItems(items).take(30).toList(growable: false);
      return cleaned.isEmpty
          ? null
          : _Shelf(title, cleaned, isWatchlist: isWatchlist);
    } catch (_) {
      return null;
    }
  }

  Future<_Shelf?> _loadMergedShelf(
    String title,
    String fallbackMediaType,
    List<Future<SeerrDiscoverPage> Function()> requests,
  ) async {
    final pages = await Future.wait(
      requests.map((request) async {
        try {
          return await request();
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
    final cleaned = _dedupeItems(items).take(30).toList(growable: false);
    return cleaned.isEmpty ? null : _Shelf(title, cleaned);
  }

  Future<_Shelf?> _loadAnimeShelf(
    SeerrRepository repo,
    String title,
    String fallbackMediaType,
    List<Future<SeerrDiscoverPage> Function()> requests, {
    int? secondaryGenre,
    bool isWatchlist = false,
  }) async {
    final pages = await Future.wait(
      requests.map((request) async {
        try {
          return await request();
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
          final mediaType = item.mediaType ?? fallbackMediaType;
          final key = '$mediaType:${item.id}';
          return seen.add(key) &&
              _basicAnimeCandidate(item) &&
              (secondaryGenre == null ||
                  item.genreIds.contains(secondaryGenre));
        })
        .take(40)
        .toList(growable: false);

    final verified = await mapBounded<SeerrDiscoverItem, SeerrDiscoverItem>(
      candidates,
      5,
      (item) => _verifyAnime(repo, item),
    );
    final items = verified.whereType<SeerrDiscoverItem>().map(
      (item) => _HubItem.fromSeerr(item, fallbackMediaType),
    );
    final cleaned = _dedupeItems(items).take(30).toList(growable: false);
    return cleaned.isEmpty
        ? null
        : _Shelf(title, cleaned, isWatchlist: isWatchlist);
  }

  bool _safeDiscover(SeerrDiscoverItem item) =>
      !item.adult && !item.isBlacklisted && item.displayTitle.trim().isNotEmpty;

  bool _basicAnimeCandidate(SeerrDiscoverItem item) {
    if (!_safeDiscover(item)) return false;
    final mediaType = item.mediaType ?? 'tv';
    if (mediaType != 'tv' && mediaType != 'movie') return false;
    return item.originalLanguage?.toLowerCase() == 'ja' &&
        item.genreIds.contains(16) &&
        !_looksExplicit('${item.displayTitle} ${item.overview ?? ''}');
  }

  Future<SeerrDiscoverItem?> _verifyAnime(
    SeerrRepository repo,
    SeerrDiscoverItem item,
  ) async {
    if (!_basicAnimeCandidate(item)) return null;
    try {
      final mediaType = item.mediaType ?? 'tv';
      if (mediaType == 'movie') {
        final detail = await repo.getMovieDetails(item.id);
        if (detail.mediaInfo?.status == 6) return null;
        final text = <String>[
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
      final text = <String>[
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
      // Basic candidate checks already exclude adult and blocklisted media.
      // Keep normal Japanese animation when optional detail metadata is down.
      return item;
    }
  }

  static final List<RegExp> _explicitAnimePatterns = <RegExp>[
    RegExp(r'\bhentai\b', caseSensitive: false),
    RegExp(r'\bporn(?:ographic|ography)?\b', caseSensitive: false),
    RegExp(r'\bxxx\b', caseSensitive: false),
    RegExp(r'\bsexually explicit\b', caseSensitive: false),
    RegExp(r'\badult animation\b', caseSensitive: false),
    RegExp(r'\beroge\b', caseSensitive: false),
    RegExp(r'\bfutanari\b', caseSensitive: false),
    RegExp(r'\btentacle sex\b', caseSensitive: false),
  ];

  bool _looksExplicit(String text) =>
      _explicitAnimePatterns.any((pattern) => pattern.hasMatch(text));

  bool _safeLocalAnime(AggregatedItem item) {
    final rawTags = item.rawData['Tags'];
    final tags = rawTags is List
        ? rawTags.map((entry) => entry?.toString() ?? '').join(' ')
        : '';
    final text =
        '${item.name} ${item.overview ?? ''} '
        '${item.genres.join(' ')} $tags';
    return !_looksExplicit(text);
  }

  List<_Shelf> _dedupeShelves(Iterable<_Shelf> input) {
    final titles = <String>{};
    final usedItems = <String>{};
    final result = <_Shelf>[];
    for (final shelf in input) {
      final key = shelf.title.trim().toLowerCase();
      if (!titles.add(key)) continue;
      final items = _dedupeItems(
        shelf.items.where((item) => !usedItems.contains(item.stableKey)),
      );
      final minimum = shelf.isWatchlist || shelf.isPersonalised ? 1 : 6;
      if (items.length < minimum) continue;
      usedItems.addAll(items.map((item) => item.stableKey));
      result.add(
        _Shelf(
          shelf.title,
          items,
          isWatchlist: shelf.isWatchlist,
          isPersonalised: shelf.isPersonalised,
        ),
      );
    }
    return result;
  }

  List<_HubItem> _dedupeItems(Iterable<_HubItem> input) {
    final seen = <String>{};
    return input.where((item) => seen.add(item.stableKey)).toList();
  }

  List<_HubItem> _heroCandidates(List<_Shelf> shelves) {
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
    final nav = _prefs.get(UserPreferences.navbarPosition);
    final safeTop = MediaQuery.paddingOf(context).top;
    final topInset = nav == NavbarPosition.top
        ? safeTop + TopToolbar.baseHeightFor(context)
        : safeTop;
    final leftRail =
        nav == NavbarPosition.left &&
        (PlatformDetection.isDesktop ||
            (PlatformDetection.isWeb && !PlatformDetection.useMobileUi));
    final rowInset = leftRail ? 78.0 : 0.0;
    final heroInset = leftRail ? 126.0 : 54.0;

    return Scaffold(
      backgroundColor: AppColorScheme.background,
      body: NavigationLayout(
        activeRoute: _kind.route,
        pinTopToolbar: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _AmbientBackdrop(),
            FutureBuilder<_DestinationData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return _DestinationLoading(
                    title: _kind.title,
                    topInset: topInset,
                    leftInset: rowInset,
                  );
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return _DestinationError(onRetry: _refresh);
                }

                final data = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _DestinationHero(
                        kind: _kind,
                        items: data.heroItems,
                        topInset: topInset + 16,
                        leftInset: heroInset,
                      ),
                      const SizedBox(height: 4),
                      for (final shelf in data.shelves)
                        Padding(
                          padding: EdgeInsets.only(left: rowInset),
                          child: _discoveryRow(shelf),
                        ),
                      if (data.localRows.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            rowInset + 34,
                            30,
                            28,
                            2,
                          ),
                          child: Text(
                            'FROM YOUR LIBRARY',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColorScheme.accent,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.8,
                                ),
                          ),
                        ),
                        for (final local in data.localRows)
                          Padding(
                            padding: EdgeInsets.only(left: rowInset),
                            child: _localRow(local),
                          ),
                      ],
                      if (data.notice != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            rowInset + 34,
                            20,
                            28,
                            8,
                          ),
                          child: Text(
                            data.notice!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
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

  Widget _discoveryRow(_Shelf shelf) {
    return LibraryRow(
      title: shelf.title,
      rowHeight: 258,
      children: shelf.items.map(_discoveryCard).toList(growable: false),
    );
  }

  Widget _discoveryCard(_HubItem item) {
    final metadata = <String>[
      if (item.year != null) item.year!,
      if (item.rating != null && item.rating! > 0)
        '★ ${item.rating!.toStringAsFixed(1)}',
    ];
    return MediaCard(
      title: item.title,
      subtitle: metadata.isEmpty ? null : metadata.join('  •  '),
      imageUrl: item.posterUrl,
      width: 150,
      aspectRatio: 2 / 3,
      seerrMediaType: item.mediaType,
      seerrStatus: item.seerrStatus,
      onTap: () => context.push(
        Destinations.seerrMedia(
          item.tmdbId.toString(),
          mediaType: item.mediaType,
          title: item.title,
        ),
      ),
    );
  }

  Widget _localRow(_LocalShelf local) {
    return LibraryRow(
      title: local.row.title,
      rowHeight: 258,
      onSeeAll: () => context.push(
        Destinations.library(
          local.library.id,
          serverId: local.library.serverId,
        ),
      ),
      children: local.row.items.map(_localCard).toList(growable: false),
    );
  }

  Widget _localCard(AggregatedItem item) {
    final aspect = MediaCard.aspectRatioForType(item.type);
    return MediaCard(
      title: item.name,
      subtitle: item.subtitle,
      imageUrl: _localImage(item),
      width: aspect == 16 / 9 ? 242 : 150,
      aspectRatio: aspect,
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

  String? _localImage(AggregatedItem item) {
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

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

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

class _DestinationHero extends StatefulWidget {
  final _DestinationKind kind;
  final List<_HubItem> items;
  final double topInset;
  final double leftInset;

  const _DestinationHero({
    required this.kind,
    required this.items,
    required this.topInset,
    required this.leftInset,
  });

  @override
  State<_DestinationHero> createState() => _DestinationHeroState();
}

class _DestinationHeroState extends State<_DestinationHero> {
  Timer? _timer;
  int _index = 0;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant _DestinationHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length ||
        (oldWidget.items.isNotEmpty &&
            widget.items.isNotEmpty &&
            oldWidget.items.first.stableKey != widget.items.first.stableKey)) {
      _index = 0;
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.items.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted || _hovered || widget.items.length <= 1) return;
      setState(() => _index = (_index + 1) % widget.items.length);
    });
  }

  void _next() {
    if (widget.items.isEmpty) return;
    setState(() => _index = (_index + 1) % widget.items.length);
    _restartTimer();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = (size.height * 0.57).clamp(450.0, 650.0).toDouble();
    if (widget.items.isEmpty) {
      return _HeroFallback(
        kind: widget.kind,
        height: height,
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
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              child: item.backdropUrl == null
                  ? const SizedBox.expand()
                  : SizedBox.expand(
                      key: ValueKey(item.stableKey),
                      child: BoundedNetworkImage(
                        imageUrl: item.backdropUrl!,
                        fit: BoxFit.cover,
                        maxWidth: 1920,
                        fadeInDuration: const Duration(milliseconds: 220),
                      ),
                    ),
            ),
            const _HeroScrim(),
            Positioned(
              left: widget.leftInset,
              right: 110,
              top: widget.topInset,
              bottom: 48,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: ConstrainedBox(
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
                          letterSpacing: 2.3,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
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
                          if (item.year != null) _HeroPill(item.year!),
                          if (item.rating != null && item.rating! > 0)
                            _HeroPill('★ ${item.rating!.toStringAsFixed(1)}'),
                          if (item.isAvailable) const _HeroPill('In Library'),
                        ],
                      ),
                      if (item.overview != null &&
                          item.overview!.trim().isNotEmpty) ...[
                        const SizedBox(height: 13),
                        Text(
                          item.overview!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColorScheme.onSurface.withValues(
                                  alpha: 0.86,
                                ),
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
                        label: Text(
                          item.isAvailable ? 'Open' : 'View & Request',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.items.length > 1)
              Positioned(
                right: 24,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton.filledTonal(
                    onPressed: _next,
                    icon: const Icon(Icons.chevron_right_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: ThemeRegistry.active.colors.surface
                          .withValues(alpha: 0.72),
                      foregroundColor: AppColorScheme.onSurface,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroScrim extends StatelessWidget {
  const _HeroScrim();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
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
        DecoratedBox(
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
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  final _DestinationKind kind;
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
              ThemeRegistry.active.colors.surface,
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
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.3,
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
                    kind.fallbackDescription,
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

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill(this.label);

  @override
  Widget build(BuildContext context) {
    final borders = ThemeRegistry.active.borders;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ThemeRegistry.active.colors.surface.withValues(alpha: 0.72),
        borderRadius: borders.chipRadius,
        border: Border.all(
          color: borders.chipBorder.color,
          width: borders.chipBorder.width,
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

class _DestinationLoading extends StatelessWidget {
  final String title;
  final double topInset;
  final double leftInset;

  const _DestinationLoading({
    required this.title,
    required this.topInset,
    required this.leftInset,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(
      context,
    ).width.clamp(320.0, 640.0).toDouble();
    final tokens = ThemeRegistry.active;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: topInset + 390,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              leftInset + 34,
              topInset + 110,
              56,
              40,
            ),
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
                    width: width * 0.58,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tokens.colors.surfaceVariant,
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
                    color: tokens.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 176,
                  child: Row(
                    children: List.generate(
                      7,
                      (index) => Container(
                        width: 112,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: tokens.colors.card,
                          borderRadius: tokens.borders.cardRadius,
                          border: Border.all(
                            color: tokens.borders.cardBorder.color,
                            width: tokens.borders.cardBorder.width,
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

class _DestinationError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _DestinationError({required this.onRetry});

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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => onRetry(), child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _DestinationData {
  final List<_Shelf> shelves;
  final List<_LocalShelf> localRows;
  final List<_HubItem> heroItems;
  final String? notice;

  const _DestinationData({
    required this.shelves,
    required this.localRows,
    required this.heroItems,
    this.notice,
  });
}

class _Shelf {
  final String title;
  final List<_HubItem> items;
  final bool isWatchlist;
  final bool isPersonalised;

  const _Shelf(
    this.title,
    this.items, {
    this.isWatchlist = false,
    this.isPersonalised = false,
  });
}

class _LocalShelf {
  final AggregatedLibrary library;
  final HomeRow row;

  const _LocalShelf({required this.library, required this.row});
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

  factory _HubItem.fromSeerr(SeerrDiscoverItem item, String fallbackMediaType) {
    final date = item.releaseDate ?? item.firstAirDate;
    return _HubItem(
      tmdbId: item.id,
      mediaType: item.mediaType ?? fallbackMediaType,
      title: item.displayTitle,
      posterUrl: _image(item.posterPath, 'w500'),
      backdropUrl: _image(item.backdropPath, 'w1280'),
      overview: item.overview,
      year: date != null && date.length >= 4 ? date.substring(0, 4) : null,
      rating: item.voteAverage,
      seerrStatus: item.mediaInfo?.status,
    );
  }

  static _HubItem? fromRecommendation(AggregatedItem item) {
    if (item.serverId != 'seerr') return null;
    final raw = item.rawData;
    final providers = raw['ProviderIds'];
    final providerId = providers is Map ? providers['Tmdb']?.toString() : null;
    final id = int.tryParse(providerId ?? item.tmdbId ?? item.id);
    if (id == null) return null;
    final rawType = (raw['SeerrMediaType'] ?? raw['Type'] ?? item.type)
        .toString()
        .toLowerCase();
    final type = rawType == 'series' || rawType == 'tv' ? 'tv' : 'movie';
    final ratingRaw = raw['CommunityRating'] ?? raw['VoteAverage'];
    return _HubItem(
      tmdbId: id,
      mediaType: type,
      title: item.name,
      posterUrl: _image(raw['PosterPath']?.toString(), 'w500'),
      backdropUrl: _image(raw['BackdropPath']?.toString(), 'w1280'),
      overview: item.overview,
      year: raw['ProductionYear']?.toString(),
      rating: ratingRaw is num ? ratingRaw.toDouble() : null,
    );
  }

  static ImdbExternalListItem? recommendationAsExternal(AggregatedItem item) {
    final mapped = fromRecommendation(item);
    if (mapped == null) return null;
    return ImdbExternalListItem(
      imdbId: '',
      tmdbId: mapped.tmdbId.toString(),
      title: mapped.title,
      posterUrl: mapped.posterUrl,
      backdropUrl: mapped.backdropUrl,
      year: int.tryParse(mapped.year ?? ''),
      type: mapped.mediaType == 'tv' ? 'Series' : 'Movie',
      rating: mapped.rating,
    );
  }

  static _HubItem? fromExternal(ImdbExternalListItem item) {
    final id = int.tryParse(item.tmdbId);
    if (id == null) return null;
    final type = item.type.toLowerCase();
    return _HubItem(
      tmdbId: id,
      mediaType: type == 'series' || type == 'tv' ? 'tv' : 'movie',
      title: item.title,
      posterUrl: _image(item.posterUrl, 'w500'),
      backdropUrl: _image(item.backdropUrl, 'w1280'),
      year: item.year?.toString(),
      rating: item.rating,
    );
  }
}

String? _image(String? raw, String size) {
  if (raw == null || raw.trim().isEmpty) return null;
  final value = raw.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  if (value.startsWith('//')) return 'https:$value';
  final path = value.startsWith('/') ? value : '/$value';
  return 'https://image.tmdb.org/t/p/$size$path';
}
