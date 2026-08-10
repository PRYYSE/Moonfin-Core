import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../../../data/services/row_data_source.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../navigation/homelab_hub_routes.dart';
import 'homelab_web_hub_screen_v2_candidate.dart';
import '../../widgets/library_row.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/top_toolbar.dart';

/// The three dedicated discovery destinations being prototyped for the Home
/// Lab fork. They deliberately remain separate from Jellyfin library types:
/// the hub is a landing/discovery page, while the library is only one source
/// of rows inside it.
enum HomelabHubKind { movies, tv, anime }

extension HomelabHubKindX on HomelabHubKind {
  String get title => switch (this) {
    HomelabHubKind.movies => 'Movies',
    HomelabHubKind.tv => 'TV',
    HomelabHubKind.anime => 'Anime',
  };

  String get route => switch (this) {
    HomelabHubKind.movies => HomelabHubRoutes.movies,
    HomelabHubKind.tv => HomelabHubRoutes.tv,
    HomelabHubKind.anime => HomelabHubRoutes.anime,
  };
}

class HomelabHubScreen extends StatefulWidget {
  final HomelabHubKind kind;

  const HomelabHubScreen({super.key, required this.kind});

  @override
  State<HomelabHubScreen> createState() => _HomelabHubScreenState();
}

class _HomelabHubScreenState extends State<HomelabHubScreen> {
  late final UserPreferences _prefs;
  late final MediaServerClient _client;
  late final UserViewsRepository _viewsRepo;
  late final RowDataSource _rowDataSource;

  Future<_HubData>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _prefs = GetIt.instance<UserPreferences>();
    _client = GetIt.instance<MediaServerClient>();
    _viewsRepo = GetIt.instance<UserViewsRepository>();
    _rowDataSource = RowDataSource(_client);
    _dataFuture = _loadData();
  }

  Future<void> _refresh() async {
    final next = _loadData();
    setState(() => _dataFuture = next);
    await next;
  }

  Future<_HubData> _loadData() async {
    final libraries = await _viewsRepo.getUserViews();
    final matchingLibraries = _matchingLibraries(libraries);

    final localRows = <_LocalHubRow>[];
    for (final library in matchingLibraries) {
      try {
        final row = await _rowDataSource.loadLatestMedia(
          library.id,
          library.name,
          library.serverId,
          library.collectionType,
        );
        if (row.items.isNotEmpty) {
          localRows.add(_LocalHubRow(library: library, row: row));
        }
      } catch (_) {
        // A missing local row must not take the discovery destination down.
      }
    }

    final discoveryRows = <_DiscoverHubRow>[];
    String? discoveryNotice;
    try {
      final repo = await GetIt.instance.getAsync<SeerrRepository>();
      await repo.ensureInitialized();
      if (repo.isAvailable) {
        discoveryRows.addAll(await _loadDiscoveryRows(repo));
      } else {
        discoveryNotice = 'Discovery is unavailable for this user.';
      }
    } catch (_) {
      discoveryNotice = 'Discovery rows could not be loaded.';
    }

    return _HubData(
      localRows: localRows,
      discoveryRows: discoveryRows,
      discoveryNotice: discoveryNotice,
    );
  }

  List<AggregatedLibrary> _matchingLibraries(
    List<AggregatedLibrary> libraries,
  ) {
    // Exact library names are intentional for the prototype. Using only
    // collectionType would merge Anime Movies into Movies and Anime into TV,
    // which is precisely the leakage these hubs are meant to prevent.
    final wanted = switch (widget.kind) {
      HomelabHubKind.movies => const {'movies'},
      HomelabHubKind.tv => const {'tv'},
      HomelabHubKind.anime => const {'anime', 'anime movies'},
    };

    return libraries
        .where((library) => wanted.contains(library.name.trim().toLowerCase()))
        .toList(growable: false);
  }

  Future<List<_DiscoverHubRow>> _loadDiscoveryRows(SeerrRepository repo) async {
    if (widget.kind == HomelabHubKind.movies) {
      // Use the generic Seerr discover endpoints here. They are available on
      // the same Moonbase proxy path already proven by the Anime hub and avoid
      // one unsupported convenience endpoint taking the whole page down.
      final pages = await Future.wait([
        repo.discoverMovies(page: 1, sortBy: 'popularity.desc'),
        repo.discoverMovies(page: 1, sortBy: 'vote_average.desc'),
      ]);
      return [
        _DiscoverHubRow(
          title: 'Popular Movies',
          mediaType: 'movie',
          items: pages[0].results,
        ),
        _DiscoverHubRow(
          title: 'Top Rated Movies',
          mediaType: 'movie',
          items: pages[1].results,
        ),
      ];
    }

    if (widget.kind == HomelabHubKind.tv) {
      final pages = await Future.wait([
        repo.discoverTv(page: 1, sortBy: 'popularity.desc'),
        repo.discoverTv(page: 1, sortBy: 'vote_average.desc'),
      ]);
      return [
        _DiscoverHubRow(
          title: 'Popular TV',
          mediaType: 'tv',
          items: pages[0].results,
        ),
        _DiscoverHubRow(
          title: 'Top Rated TV',
          mediaType: 'tv',
          items: pages[1].results,
        ),
      ];
    }

    // Prototype anime classifier: TMDb Animation (genre 16) constrained to
    // Japanese original-language titles. This is intentionally stricter than
    // generic animation and prevents normal Western TV/movies appearing in the
    // Anime hub. The next design pass can replace/augment these rows with the
    // MDBList/AniList-style curated sources already supported by Moonbase.
    final pages = await Future.wait([
      repo.discoverTv(page: 1, sortBy: 'popularity.desc', genre: 16),
      repo.discoverTv(page: 1, sortBy: 'vote_average.desc', genre: 16),
      repo.discoverMovies(page: 1, sortBy: 'popularity.desc', genre: 16),
    ]);

    List<SeerrDiscoverItem> animeOnly(SeerrDiscoverPage page) => page.results
        .where(
          (item) =>
              item.originalLanguage?.toLowerCase() == 'ja' &&
              item.genreIds.contains(16),
        )
        .take(20)
        .toList(growable: false);

    return [
      _DiscoverHubRow(
        title: 'Popular Anime Series',
        mediaType: 'tv',
        items: animeOnly(pages[0]),
      ),
      _DiscoverHubRow(
        title: 'Top Rated Anime Series',
        mediaType: 'tv',
        items: animeOnly(pages[1]),
      ),
      _DiscoverHubRow(
        title: 'Popular Anime Movies',
        mediaType: 'movie',
        items: animeOnly(pages[2]),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && !PlatformDetection.useMobileUi) {
      return HomelabWebHubScreenV2Candidate(kind: widget.kind.name);
    }

    final navbarPosition = _prefs.get(UserPreferences.navbarPosition);
    final safeTopInset = PlatformDetection.useMobileUi
        ? MediaQuery.paddingOf(context).top
        : 0.0;
    final topInset = navbarPosition == NavbarPosition.top
        ? safeTopInset + TopToolbar.baseHeightFor(context) + 12
        : safeTopInset + 20.0;
    final hasPersistentLeftRail =
        navbarPosition == NavbarPosition.left &&
        (PlatformDetection.isTV ||
            PlatformDetection.isDesktop ||
            (PlatformDetection.isWeb && !PlatformDetection.useMobileUi));
    final leftInset = hasPersistentLeftRail ? 92.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColorScheme.background,
      body: NavigationLayout(
        activeRoute: widget.kind.route,
        pinTopToolbar: true,
        child: FutureBuilder<_HubData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return _HubError(onRetry: _refresh);
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(leftInset, topInset, 20, 40),
                children: [
                  _HubHeader(kind: widget.kind),
                  const SizedBox(height: 18),
                  ...data.discoveryRows
                      .where((row) => row.items.isNotEmpty)
                      .map(_buildDiscoveryRow),
                  if (data.discoveryNotice != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Text(
                        data.discoveryNotice!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                    ),
                  if (data.localRows.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 2),
                      child: Text(
                        'From Your Library',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    ...data.localRows.map(_buildLocalRow),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocalRow(_LocalHubRow localRow) {
    final row = localRow.row;
    return LibraryRow(
      title: row.title,
      rowHeight: 246,
      onSeeAll: () {
        context.push(
          Destinations.library(
            localRow.library.id,
            serverId: localRow.library.serverId,
          ),
        );
      },
      children: row.items.map(_buildLocalCard).toList(growable: false),
    );
  }

  Widget _buildLocalCard(AggregatedItem item) {
    final aspectRatio = MediaCard.aspectRatioForType(item.type);
    return MediaCard(
      title: item.name,
      subtitle: item.subtitle,
      imageUrl: _localPosterUrl(item),
      width: aspectRatio == 16 / 9 ? 245 : 150,
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
          maxWidth: 360,
          tag: item.seriesPrimaryImageTag,
        );
      }
      return _client.imageApi.getPrimaryImageUrl(
        item.id,
        maxWidth: 360,
        tag: item.primaryImageTag ?? item.primaryImageTagField,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildDiscoveryRow(_DiscoverHubRow row) {
    return LibraryRow(
      title: row.title,
      rowHeight: 246,
      children: row.items
          .map((item) => _buildDiscoveryCard(item, row.mediaType))
          .toList(growable: false),
    );
  }

  Widget _buildDiscoveryCard(SeerrDiscoverItem item, String fallbackMediaType) {
    final yearSource = item.releaseDate ?? item.firstAirDate;
    final year = yearSource != null && yearSource.length >= 4
        ? yearSource.substring(0, 4)
        : null;
    final rating = item.voteAverage != null && item.voteAverage! > 0
        ? '★ ${item.voteAverage!.toStringAsFixed(1)}'
        : null;
    final subtitle = [
      if (year != null) year,
      if (rating != null) rating,
    ].join('  ');
    final mediaType = item.mediaType ?? fallbackMediaType;

    return MediaCard(
      title: item.displayTitle,
      subtitle: subtitle.isEmpty ? null : subtitle,
      imageUrl: item.posterPath == null
          ? null
          : 'https://image.tmdb.org/t/p/w342${item.posterPath}',
      width: 150,
      aspectRatio: 2 / 3,
      seerrMediaType: mediaType,
      seerrStatus: item.mediaInfo?.status,
      onTap: () => context.push(
        Destinations.seerrMedia(
          item.id.toString(),
          mediaType: mediaType,
          title: item.displayTitle,
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  final HomelabHubKind kind;

  const _HubHeader({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HubNavButton(
                label: 'Home',
                selected: false,
                onPressed: () => context.go(Destinations.home),
              ),
              for (final destination in HomelabHubKind.values)
                _HubNavButton(
                  label: destination.title,
                  selected: destination == kind,
                  onPressed: () {
                    if (destination != kind) context.go(destination.route);
                  },
                ),
            ],
          ),
          if (kind == HomelabHubKind.anime) ...[
            const SizedBox(height: 12),
            Text(
              'Prototype discovery filter: Japanese-language Animation. '
              'MDBList-backed seasonal and curated rows come next.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColorScheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HubNavButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _HubNavButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label));
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
          const Text('The hub could not be loaded.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => onRetry(), child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _HubData {
  final List<_LocalHubRow> localRows;
  final List<_DiscoverHubRow> discoveryRows;
  final String? discoveryNotice;

  const _HubData({
    required this.localRows,
    required this.discoveryRows,
    this.discoveryNotice,
  });
}

class _LocalHubRow {
  final AggregatedLibrary library;
  final HomeRow row;

  const _LocalHubRow({required this.library, required this.row});
}

class _DiscoverHubRow {
  final String title;
  final String mediaType;
  final List<SeerrDiscoverItem> items;

  const _DiscoverHubRow({
    required this.title,
    required this.mediaType,
    required this.items,
  });
}
