import '../catalogue/discovery_catalogue.dart';

/// Explicit contract for personalised Discovery rows that can be represented
/// truthfully by the current upstream `Since You Watched` recommendation row.
///
/// The row index only selects a deterministic recommendation seed from the
/// user's configured positive source. It never defines the advertised meaning
/// of a Discovery lane. Meaning comes from explicit result filters below.
/// Source-specific labels such as `recent-history`, `favourites`, `watchlist`,
/// `likes` and `high-ratings` deliberately return no policy until Home Lab has
/// a source adapter that can prove that provenance.
class HomeLabDiscoveryPersonalPolicy {
  final int rowIndex;
  final String mediaType;
  final bool animeOnly;
  final double? minRating;
  final bool unseenOnly;
  final int? maxRuntimeMinutes;
  final int? olderThanYears;
  final int? newerThanYears;
  final List<String> requiredGenreFragments;

  const HomeLabDiscoveryPersonalPolicy({
    required this.rowIndex,
    required this.mediaType,
    this.animeOnly = false,
    this.minRating,
    this.unseenOnly = false,
    this.maxRuntimeMinutes,
    this.olderThanYears,
    this.newerThanYears,
    this.requiredGenreFragments = const [],
  });
}

HomeLabDiscoveryPersonalPolicy? homeLabDiscoveryPersonalPolicy(
  HomeLabDiscoverySection section,
) {
  if (section.query.source != HomeLabDiscoverySource.personalised) return null;

  final strategy = (section.query.seedStrategy ?? '').trim().toLowerCase();
  final requestedMediaType = section.query.mediaType;
  final sectionAnime =
      section.tags.any((tag) => tag.toLowerCase() == 'anime') ||
      strategy.startsWith('anime-') ||
      section.id.toLowerCase().startsWith('anime-');

  HomeLabDiscoveryPersonalPolicy policy({
    required int rowIndex,
    String? mediaType,
    bool animeOnly = false,
    double? minRating,
    bool unseenOnly = false,
    int? maxRuntimeMinutes,
    int? olderThanYears,
    int? newerThanYears,
    List<String> requiredGenreFragments = const [],
  }) => HomeLabDiscoveryPersonalPolicy(
    rowIndex: rowIndex,
    mediaType: mediaType ?? requestedMediaType,
    animeOnly: animeOnly || sectionAnime,
    minRating: minRating,
    unseenOnly: unseenOnly,
    maxRuntimeMinutes: maxRuntimeMinutes,
    olderThanYears: olderThanYears,
    newerThanYears: newerThanYears,
    requiredGenreFragments: requiredGenreFragments,
  );

  return switch (strategy) {
    // Generic affinity lanes are truthful with the current upstream engine:
    // the source is intentionally broad, while the result type/filter below
    // provides the advertised shape.
    'movie-affinity' => policy(rowIndex: 9, mediaType: 'movie'),
    'series-affinity' => policy(rowIndex: 10, mediaType: 'tv'),
    'anime-affinity' => policy(rowIndex: 11, animeOnly: true),
    'short-runtime-affinity' => policy(
      rowIndex: 12,
      maxRuntimeMinutes: 60,
    ),
    'older-affinity' => policy(rowIndex: 13, olderThanYears: 10),
    'recent-affinity' => policy(rowIndex: 14, newerThanYears: 5),
    'highly-rated-unseen' => policy(
      rowIndex: 7,
      minRating: 7,
      unseenOnly: true,
    ),

    // Anime affinity variants remain broad taste recommendations but add a
    // concrete, testable result constraint. They do not claim a seed source
    // that the upstream row cannot prove.
    'anime-action-affinity' => policy(
      rowIndex: 11,
      animeOnly: true,
      requiredGenreFragments: const ['action'],
    ),
    'anime-fantasy-affinity' => policy(
      rowIndex: 11,
      animeOnly: true,
      requiredGenreFragments: const ['fantasy'],
    ),
    'anime-romance-drama-affinity' => policy(
      rowIndex: 11,
      animeOnly: true,
      requiredGenreFragments: const ['romance', 'drama'],
    ),
    'anime-highly-rated-unseen' => policy(
      rowIndex: 7,
      animeOnly: true,
      minRating: 7,
      unseenOnly: true,
    ),
    'anime-recent-affinity' => policy(
      rowIndex: 14,
      animeOnly: true,
      newerThanYears: 5,
    ),
    'anime-older-affinity' => policy(
      rowIndex: 13,
      animeOnly: true,
      olderThanYears: 10,
    ),
    'anime-movie-affinity' => policy(
      rowIndex: 9,
      mediaType: 'movie',
      animeOnly: true,
    ),
    'anime-short-affinity' => policy(
      rowIndex: 12,
      animeOnly: true,
      maxRuntimeMinutes: 60,
    ),

    // Everything else fails closed. In particular these currently include
    // source-provenance rows (history/favourites/watchlist/ratings/likes),
    // random/novelty rows, direct recently-added/trending rows, rewatch rows,
    // and structural series/anime labels such as one-season/completed/binge.
    _ => null,
  };
}
