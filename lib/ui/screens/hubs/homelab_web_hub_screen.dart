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

/// Premium web-desktop discovery destinations for the Home Lab fork.
///
/// The server remains authoritative for integrations, ownership/request state,
/// parental blocking and Moonbase custom rows. This screen owns presentation
/// and destination-specific composition so Home, Movies, TV and Anime can feel
/// like one coherent streaming product without changing the proven mobile/TV
/// layouts during the web-first design pass.
class HomelabWebHubScreen extends StatefulWidget {
  final String kind;

  const HomelabWebHubScreen({super.key, required this.kind});

  @override
  State<HomelabWebHubScreen> createState() => _HomelabWebHubScreenState();
}

enum _PremiumHubKind { movies, tv, anime }

extension _PremiumHubKindX on _PremiumHubKind {
  String get title => switch (this) {
    _PremiumHubKind.movies => 'Movies',
    _PremiumHubKind.tv => 'TV',
    _PremiumHubKind.anime => 'Anime',
  };

  String get kicker => switch (this) {
    _PremiumHubKind.movies => 'CINEMA',
    _PremiumHubKind.tv => 'SERIES',
    _PremiumHubKind.anime => 'ANIME',
  };

  String get intro => switch (this) {
    _PremiumHubKind.movies =>
      'Big releases, acclaimed films and curated picks in one place.',
    _PremiumHubKind.tv =>
      'What is trending, what is next and series worth settling into.',
    _PremiumHubKind.anime =>
      'Japanese animation discovery with ordinary adult content filtered out.',
  };

  String get route => switch (this) {
    _PremiumHubKind.movies => HomelabHubRoutes.movies,
    _PremiumHubKind.tv => HomelabHubRoutes.tv,
    _PremiumHubKind.anime => HomelabHubRoutes.anime,
  };
}

class _HomelabWebHubScreenState extends State<HomelabWebHubScreen> {
  late final UserPreferences _prefs;
  late final MediaServerClient _client;
  late final UserViewsRepository _viewsRepo;
  late final RowDataSource _rowDataSource;
  late final CustomExternalListsService _customLists;

  Future<_WebHubData>? _dataFuture;

  _PremiumHubKind get _kind => switch (widget.kind.toLowerCase()) {
    'movies' => _PremiumHubKind.movies,
    'tv' => _PremiumHubKind.tv,
    _ => _PremiumHubKind.anime,
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
  void didUpdateWidget(covariant HomelabWebHubScreen oldWidget) {
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

  Future<_WebHubData> _loadData({bool forceRefresh = false}) async {
    final libraries = await _viewsRepo.getUserViews();
    final matchingLibraries = _matchingLibraries(libraries);

    // Start all independent sources together. The page only swaps from its
    // compact loading state when the first coherent composition is ready.
    final localFuture = _loadLocalRows(matchingLibraries);
    final editorialFuture = _loadMoonbaseEditorialRows(
      forceRefresh: forceRefresh,
    );
    final discoveryFuture = _loadDiscoveryRows();

    final localRows = await localFuture;
    final editorialRows = await editorialFuture;
    final discovery = await discoveryFuture;

    final shelves = <_WebHubShelf>[];
    if (discovery.shelves.isNotEmpty) {
      // Lead with a live discovery signal, then give Moonbase/MDBList editorial
      // rows premium placement before the deeper generic charts.
      shelves.add(discovery.shelves.first);
      shelves.addAll(editorialRows);
      shelves.addAll(discovery.shelves.skip(1));
    } else {
      shelves.addAll(editorialRows);
    }

    final heroItems = _heroCandidates(discovery.shelves, editorialRows);

    return _WebHubData(
      heroItems: heroItems,
      shelves: shelves.where((row) => row.items.isNotEmpty).toList(),
      localRows: localRows,
      discoveryNotice: discovery.notice,
    );
  }

  List<AggregatedLibrary> _matchingLibraries(
    List<AggregatedLibrary> libraries,
  ) {
    final wanted = switch (_kind) {
      _PremiumHubKind.movies => const {'movies'},
      _PremiumHubKind.tv => const {'tv'},
      _PremiumHubKind.anime => const {'anime', 'anime movies'},
    };

    return libraries
        .where((library) => wanted.contains(library.name.trim().toLowerCase()))
        .toList(growable: false);
  }

  Future<List<_WebLocalRow>> _loadLocalRows(
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
          if (row.items.isEmpty) return null;
          return _WebLocalRow(library: library, row: row);
        } catch (_) {
          return null;
        }
      }),
    );
    return rows.whereType<_WebLocalRow>().toList(growable: false);
  }

  Future<List<_WebHubShelf>> _loadMoonbaseEditorialRows({
    required bool forceRefresh,
  }) async {
    // Anime remains deliberately strict until a curated row is able to carry
    // authoritative anime/adult metadata. Seerr's adult + server blocklist
    // signals are reliable, while a generic external list item is not.
    if (_kind == _PremiumHubKind.anime) return const [];

    final configs =
        _prefs.activeHomeSectionConfigs
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
          final items = raw
              .where(_externalItemMatchesDestination)
              .map(_WebHubItem.fromExternal)
              .whereType<_WebHubItem>()
              .take(20)
              .toList(growable: false);
          if (items.isEmpty) return null;
          final title = (config.pluginDisplayText ?? config.pluginSection ?? '')
              .trim();
          return _WebHubShelf(
            title: title.isEmpty ? 'Curated for You' : title,
            items: _dedupeHubItems(items),
          );
        } catch (_) {
          return null;
        }
      }),
    );

    return resolved.whereType<_WebHubShelf>().toList(growable: false);
  }

  bool _externalItemMatchesDestination(ImdbExternalListItem item) {
    final type = item.type.trim().toLowerCase();
    return switch (_kind) {
      _PremiumHubKind.movies => type == 'movie',
      _PremiumHubKind.tv => type == 'series' || type == 'tv',
      _PremiumHubKind.anime => false,
    };
  }

  Future<_DiscoveryLoad> _loadDiscoveryRows() async {
    try {
      final repo = await GetIt.instance.getAsync<SeerrRepository>();
      await repo.ensureInitialized();
      if (!repo.isAvailable) {
        return const _DiscoveryLoad(
          shelves: [],
          notice: 'Discovery is unavailable for this user.',
        );
      }

      return switch (_kind) {
        _PremiumHubKind.movies => _loadMovieDiscovery(repo),
        _PremiumHubKind.tv => _loadTvDiscovery(repo),
        _PremiumHubKind.anime => _loadAnimeDiscovery(repo),
      };
    } catch (_) {
      return const _DiscoveryLoad(
        shelves: [],
        notice: 'Discovery rows could not be loaded.',
      );
    }
  }

  Future<_DiscoveryLoad> _loadMovieDiscovery(SeerrRepository repo) async {
    final pages = await Future.wait<SeerrDiscoverPage>([
      repo.getTrendingMovies(limit: 20),
      repo.getTopMovies(limit: 20),
      repo.getUpcomingMovies(page: 1),
      repo.discoverMovies(page: 1, sortBy: 'popularity.desc', genre: 28),
      repo.discoverMovies(page: 1, sortBy: 'popularity.desc', genre: 878),
      repo.discoverMovies(page: 1, sortBy: 'popularity.desc', genre: 14),
      repo.discoverMovies(page: 1, sortBy: 'popularity.desc', genre: 53),
    ]);

    return _DiscoveryLoad(
      shelves: [
        _shelf('Trending Now', _itemsFromPage(pages[0], 'movie')),
        _shelf('Critically Acclaimed', _itemsFromPage(pages[1], 'movie')),
        _shelf('Coming Soon', _itemsFromPage(pages[2], 'movie')),
        _shelf('Action', _itemsFromPage(pages[3], 'movie')),
        _shelf(
          'Sci-Fi & Fantasy',
          _itemsFromPages([pages[4], pages[5]], 'movie'),
        ),
        _shelf('Thrillers', _itemsFromPage(pages[6], 'movie')),
      ],
    );
  }

  Future<_DiscoveryLoad> _loadTvDiscovery(SeerrRepository repo) async {
    final pages = await Future.wait<SeerrDiscoverPage>([
      repo.getTrendingTv(limit: 20),
      repo.getTopTv(limit: 20),
      repo.getUpcomingTv(page: 1),
      repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 18),
      repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 35),
      repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 10765),
      repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 80),
      repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 9648),
    ]);

    return _DiscoveryLoad(
      shelves: [
        _shelf('Trending Now', _itemsFromPage(pages[0], 'tv')),
        _shelf('Critically Acclaimed', _itemsFromPage(pages[1], 'tv')),
        _shelf('Coming Soon', _itemsFromPage(pages[2], 'tv')),
        _shelf('Drama', _itemsFromPage(pages[3], 'tv')),
        _shelf('Comedy', _itemsFromPage(pages[4], 'tv')),
        _shelf('Sci-Fi & Fantasy', _itemsFromPage(pages[5], 'tv')),
        _shelf('Crime & Mystery', _itemsFromPages([pages[6], pages[7]], 'tv')),
      ],
    );
  }

  Future<_DiscoveryLoad> _loadAnimeDiscovery(SeerrRepository repo) async {
    final pages = await Future.wait<SeerrDiscoverPage>([
      repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 16),
      repo.discoverTv(page: 2, sortBy: 'popularity.desc', genre: 16),
      repo.discoverTv(page: 1, sortBy: 'vote_average.desc', genre: 16),
      repo.getUpcomingTv(page: 1),
      repo.discoverMovies(page: 1, sortBy: 'popularity.desc', genre: 16),
      repo.discoverMovies(page: 1, sortBy: 'vote_average.desc', genre: 16),
    ]);

    final popular = _animeOnly([...pages[0].results, ...pages[1].results]);
    final topRated = _animeOnly(pages[2].results);
    final upcoming = _animeOnly(pages[3].results);
    final animeMovies = _animeOnly([...pages[4].results, ...pages[5].results]);

    List<SeerrDiscoverItem> byGenre(int genre) =>
        popular.where((item) => item.genreIds.contains(genre)).toList();

    return _DiscoveryLoad(
      shelves: [
        _shelf('Popular Anime', _toHubItems(popular, 'tv')),
        _shelf('Top Rated Anime', _toHubItems(topRated, 'tv')),
        _shelf('Upcoming Anime', _toHubItems(upcoming, 'tv')),
        _shelf('Anime Movies', _toHubItems(animeMovies, 'movie')),
        _shelf('Action & Adventure', _toHubItems(byGenre(10759), 'tv')),
        _shelf('Fantasy & Sci-Fi', _toHubItems(byGenre(10765), 'tv')),
        _shelf('Comedy', _toHubItems(byGenre(35), 'tv')),
        _shelf('Drama', _toHubItems(byGenre(18), 'tv')),
      ],
    );
  }

  List<SeerrDiscoverItem> _animeOnly(Iterable<SeerrDiscoverItem> input) {
    final seen = <String>{};
    return input
        .where((item) {
          final mediaType = item.mediaType ?? 'tv';
          final key = '$mediaType:${item.id}';
          return _safeDiscover(item) &&
              item.originalLanguage?.toLowerCase() == 'ja' &&
              item.genreIds.contains(16) &&
              seen.add(key);
        })
        .take(30)
        .toList(growable: false);
  }

  bool _safeDiscover(SeerrDiscoverItem item) {
    return !item.adult &&
        !item.isBlacklisted &&
        item.displayTitle.trim().isNotEmpty;
  }

  _WebHubShelf _shelf(String title, List<_WebHubItem> items) {
    return _WebHubShelf(title: title, items: _dedupeHubItems(items));
  }

  List<_WebHubItem> _itemsFromPage(
    SeerrDiscoverPage page,
    String fallbackMediaType,
  ) => _toHubItems(page.results, fallbackMediaType);

  List<_WebHubItem> _itemsFromPages(
    List<SeerrDiscoverPage> pages,
    String fallbackMediaType,
  ) => _toHubItems(pages.expand((page) => page.results), fallbackMediaType);

  List<_WebHubItem> _toHubItems(
    Iterable<SeerrDiscoverItem> items,
    String fallbackMediaType,
  ) {
    return items
        .where(_safeDiscover)
        .map((item) => _WebHubItem.fromSeerr(item, fallbackMediaType))
        .take(30)
        .toList(growable: false);
  }

  List<_WebHubItem> _dedupeHubItems(Iterable<_WebHubItem> items) {
    final seen = <String>{};
    return [
      for (final item in items)
        if (seen.add(item.stableKey)) item,
    ].take(20).toList(growable: false);
  }

  List<_WebHubItem> _heroCandidates(
    List<_WebHubShelf> discovery,
    List<_WebHubShelf> editorial,
  ) {
    final seen = <String>{};
    final candidates = <_WebHubItem>[];
    for (final shelf in [...discovery, ...editorial]) {
      for (final item in shelf.items) {
        if (item.backdropUrl == null || item.backdropUrl!.isEmpty) continue;
        if (!seen.add(item.stableKey)) continue;
        candidates.add(item);
        if (candidates.length >= 10) return candidates;
      }
    }
    return candidates;
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
    final rowLeftInset = hasLeftRail ? 88.0 : 0.0;
    final heroLeftInset = hasLeftRail ? 132.0 : 56.0;

    return Scaffold(
      backgroundColor: AppColorScheme.background,
      body: NavigationLayout(
        activeRoute: _kind.route,
        pinTopToolbar: true,
        child: FutureBuilder<_WebHubData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _WebHubLoading(title: _kind.title, topInset: toolbarInset);
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _WebHubError(onRetry: _refresh);
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _PremiumHero(
                    kind: _kind,
                    items: data.heroItems,
                    topInset: toolbarInset + 22,
                    leftInset: heroLeftInset,
                  ),
                  const SizedBox(height: 6),
                  for (final shelf in data.shelves)
                    Padding(
                      padding: EdgeInsets.only(left: rowLeftInset),
                      child: _buildDiscoveryShelf(shelf),
                    ),
                  if (data.localRows.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        rowLeftInset + 36,
                        28,
                        24,
                        2,
                      ),
                      child: Text(
                        'From Your Library',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
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
                        rowLeftInset + 36,
                        20,
                        28,
                        8,
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
                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDiscoveryShelf(_WebHubShelf shelf) {
    return LibraryRow(
      title: shelf.title,
      rowHeight: 286,
      children: shelf.items.map(_buildDiscoveryCard).toList(growable: false),
    );
  }

  Widget _buildDiscoveryCard(_WebHubItem item) {
    final metadata = <String>[
      if (item.year != null) item.year!,
      if (item.rating != null && item.rating! > 0)
        '★ ${item.rating!.toStringAsFixed(1)}',
    ];
    return MediaCard(
      title: item.title,
      subtitle: metadata.isEmpty ? null : metadata.join('  •  '),
      imageUrl: item.posterUrl,
      width: 164,
      aspectRatio: 2 / 3,
      seerrMediaType: item.mediaType,
      seerrStatus: item.seerrStatus,
      onTap: () => _openDiscoveryItem(item),
    );
  }

  void _openDiscoveryItem(_WebHubItem item) {
    context.push(
      Destinations.seerrMedia(
        item.tmdbId.toString(),
        mediaType: item.mediaType,
        title: item.title,
      ),
    );
  }

  Widget _buildLocalRow(_WebLocalRow local) {
    return LibraryRow(
      title: local.row.title,
      rowHeight: 286,
      onSeeAll: () {
        context.push(
          Destinations.library(
            local.library.id,
            serverId: local.library.serverId,
          ),
        );
      },
      children: local.row.items.map(_buildLocalCard).toList(growable: false),
    );
  }

  Widget _buildLocalCard(AggregatedItem item) {
    final aspectRatio = MediaCard.aspectRatioForType(item.type);
    return MediaCard(
      title: item.name,
      subtitle: item.subtitle,
      imageUrl: _localPosterUrl(item),
      width: aspectRatio == 16 / 9 ? 258 : 164,
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

class _PremiumHero extends StatefulWidget {
  final _PremiumHubKind kind;
  final List<_WebHubItem> items;
  final double topInset;
  final double leftInset;

  const _PremiumHero({
    required this.kind,
    required this.items,
    required this.topInset,
    required this.leftInset,
  });

  @override
  State<_PremiumHero> createState() => _PremiumHeroState();
}

class _PremiumHeroState extends State<_PremiumHero> {
  Timer? _timer;
  int _index = 0;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _configureTimer();
  }

  @override
  void didUpdateWidget(covariant _PremiumHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFirst = oldWidget.items.isEmpty
        ? null
        : oldWidget.items.first.stableKey;
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
    final heroHeight = (size.height * 0.68).clamp(520.0, 760.0).toDouble();
    if (widget.items.isEmpty) {
      return _PremiumHeroFallback(
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
                      key: ValueKey('premium_hero_${item.stableKey}'),
                      child: BoundedNetworkImage(
                        imageUrl: item.backdropUrl!,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        fadeInDuration: const Duration(milliseconds: 220),
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
                      AppColorScheme.scrim.withValues(alpha: 0.03),
                      AppColorScheme.background.withValues(alpha: 0.64),
                      AppColorScheme.background,
                    ],
                    stops: const [0.0, 0.42, 0.82, 1.0],
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
                      AppColorScheme.scrim.withValues(alpha: 0.84),
                      AppColorScheme.scrim.withValues(alpha: 0.52),
                      AppColorScheme.scrim.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.34, 0.66, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: widget.leftInset,
              right: 110,
              top: widget.topInset,
              bottom: 58,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 340),
                  child: ConstrainedBox(
                    key: ValueKey('premium_hero_copy_${item.stableKey}'),
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.kind.kicker,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColorScheme.accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.2,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: AppColorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                                height: 0.98,
                                shadows: [
                                  Shadow(
                                    blurRadius: 14,
                                    color: AppColorScheme.scrim.withValues(
                                      alpha: 0.72,
                                    ),
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 14),
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
                        if (item.overview != null &&
                            item.overview!.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            item.overview!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColorScheme.onSurface.withValues(
                                    alpha: 0.9,
                                  ),
                                  height: 1.35,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 8,
                                      color: AppColorScheme.scrim.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ],
                        const SizedBox(height: 20),
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
            ),
            if (widget.items.length > 1) ...[
              Positioned(
                left: 18,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _HeroArrow(
                    icon: Icons.chevron_left_rounded,
                    onPressed: () => _move(-1),
                  ),
                ),
              ),
              Positioned(
                right: 18,
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
                right: 56,
                bottom: 26,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.items.length, (index) {
                    final selected = index == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: selected ? 22 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColorScheme.accent
                            : AppColorScheme.onSurface.withValues(alpha: 0.42),
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

class _PremiumHeroFallback extends StatelessWidget {
  final _PremiumHubKind kind;
  final double height;
  final double topInset;
  final double leftInset;

  const _PremiumHeroFallback({
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
              Theme.of(context).colorScheme.surface,
              AppColorScheme.background,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(leftInset, topInset + 80, 56, 72),
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
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    kind.title,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    kind.intro,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColorScheme.onSurface.withValues(alpha: 0.72),
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

  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColorScheme.scrim.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColorScheme.onSurface.withValues(alpha: 0.16),
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
        backgroundColor: AppColorScheme.scrim.withValues(alpha: 0.42),
        foregroundColor: AppColorScheme.onSurface,
      ),
    );
  }
}

class _WebHubLoading extends StatelessWidget {
  final String title;
  final double topInset;

  const _WebHubLoading({required this.title, required this.topInset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading $title…',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebHubError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _WebHubError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

class _WebHubData {
  final List<_WebHubItem> heroItems;
  final List<_WebHubShelf> shelves;
  final List<_WebLocalRow> localRows;
  final String? discoveryNotice;

  const _WebHubData({
    required this.heroItems,
    required this.shelves,
    required this.localRows,
    this.discoveryNotice,
  });
}

class _DiscoveryLoad {
  final List<_WebHubShelf> shelves;
  final String? notice;

  const _DiscoveryLoad({required this.shelves, this.notice});
}

class _WebHubShelf {
  final String title;
  final List<_WebHubItem> items;

  const _WebHubShelf({required this.title, required this.items});
}

class _WebLocalRow {
  final AggregatedLibrary library;
  final HomeRow row;

  const _WebLocalRow({required this.library, required this.row});
}

class _WebHubItem {
  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final String? overview;
  final String? year;
  final double? rating;
  final int? seerrStatus;

  const _WebHubItem({
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

  factory _WebHubItem.fromSeerr(
    SeerrDiscoverItem item,
    String fallbackMediaType,
  ) {
    final date = item.releaseDate ?? item.firstAirDate;
    return _WebHubItem(
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

  static _WebHubItem? fromExternal(ImdbExternalListItem item) {
    final tmdbId = int.tryParse(item.tmdbId);
    if (tmdbId == null) return null;
    final rawType = item.type.trim().toLowerCase();
    final mediaType = rawType == 'series' || rawType == 'tv' ? 'tv' : 'movie';
    return _WebHubItem(
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
