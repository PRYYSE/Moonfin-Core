import 'seerr_api_models.dart';
import 'seerr_discovery_schema.dart';

/// Presentation-only policy for personalised Discovery previews.
///
/// The accepted Home recommendation engine remains authoritative for ranking.
/// This layer only makes the small landing-page preview easier to browse by:
/// - replacing generic duplicate row labels with stable neutral labels;
/// - preferring title-family variety within a row;
/// - preferring title families not already used by earlier For You rows;
/// - gracefully backfilling when diversity would make the row too small.
///
/// Expanded `See All` collections deliberately bypass this policy so the user
/// can still inspect the complete ranked recommendation set.
abstract final class SeerrDiscoveryPersonalPresentation {
  static const _genericGeneratedTitles = <String>{
    'for you',
    'recommended for you',
    'recommendations for you',
    'top picks for you',
    'more picks for you',
  };

  static const _fallbackByStrategy = <String, String>{
    'recent-history': 'Top Picks For You',
    'favourites': 'More Picks For You',
    'watchlist': 'Picks Worth a Look',
    'high-ratings': 'Strong Matches',
    'likes': 'More To Explore',
    'mixed-positive': 'Based on Your Taste',
    'highly-rated-unseen': 'Highly Rated Picks',
    'novelty': 'Something Different',
    'movie-affinity': 'Hidden Matches',
    'series-affinity': 'Worth Discovering',
    'anime-affinity': 'More You Might Like',
    'short-runtime-affinity': 'Quick Picks',
    'older-affinity': 'Older Gems',
    'recent-affinity': 'Recent Picks',
    'rewatch': 'Worth Revisiting',
    'recent-discovery-context': 'Keep Exploring',
  };

  static const _stopWords = <String>{'a', 'an', 'and', 'of', 'the'};

  /// Returns a truthful display title without allowing adjacent personalised
  /// slots to collapse to the same generic Home label.
  static String displayTitle(
    SeerrDiscoverySection section,
    String generated, {
    required Set<String> usedTitles,
  }) {
    final trimmed = generated.trim();
    final normalised = _normaliseTitle(trimmed);
    if (trimmed.isNotEmpty &&
        !_genericGeneratedTitles.contains(normalised) &&
        !usedTitles.contains(normalised)) {
      usedTitles.add(normalised);
      return trimmed;
    }

    final strategy = section.query.seedStrategy ?? '';
    final preferred = _fallbackByStrategy[strategy] ?? section.title.trim();
    final candidates = <String>[
      preferred.isEmpty ? 'More Picks For You' : preferred,
      section.title.trim(),
      'More Picks For You',
      'More To Explore',
      'Worth Discovering',
      'Hidden Matches',
      'Keep Exploring',
    ];

    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final key = _normaliseTitle(candidate);
      if (usedTitles.add(key)) return candidate;
    }

    var suffix = 2;
    while (true) {
      final candidate = '$preferred $suffix';
      if (usedTitles.add(_normaliseTitle(candidate))) return candidate;
      suffix++;
    }
  }

  /// Reorders/shortens only the landing-page preview. The original ranking is
  /// preserved within each preference tier and deferred items are backfilled
  /// only until [minimumRetained] is satisfied.
  static List<SeerrDiscoverItem> diversifyPreview(
    Iterable<SeerrDiscoverItem> items, {
    required int minimumRetained,
    Set<String>? previouslySurfacedFamilies,
    int maxPerFamily = 2,
  }) {
    final source = items.toList(growable: false);
    if (source.length <= 1 || maxPerFamily < 1) return source;

    final seenEarlier = previouslySurfacedFamilies ?? <String>{};
    final familyCounts = <String, int>{};
    final freshFamilies = <SeerrDiscoverItem>[];
    final repeatedFromEarlierRows = <SeerrDiscoverItem>[];
    final overFamilyCap = <SeerrDiscoverItem>[];

    for (final item in source) {
      final family = familyKey(item.displayTitle);
      if (family.isEmpty) {
        freshFamilies.add(item);
        continue;
      }

      final count = familyCounts[family] ?? 0;
      if (count >= maxPerFamily) {
        overFamilyCap.add(item);
        continue;
      }
      familyCounts[family] = count + 1;

      if (seenEarlier.contains(family)) {
        repeatedFromEarlierRows.add(item);
      } else {
        freshFamilies.add(item);
      }
    }

    final result = <SeerrDiscoverItem>[...freshFamilies];
    void backfill(Iterable<SeerrDiscoverItem> candidates) {
      for (final item in candidates) {
        if (result.length >= minimumRetained) break;
        result.add(item);
      }
    }

    backfill(repeatedFromEarlierRows);
    backfill(overFamilyCap);

    for (final item in result) {
      final family = familyKey(item.displayTitle);
      if (family.isNotEmpty) seenEarlier.add(family);
    }
    return result;
  }

  /// Conservative title-family heuristic used only when discovery cards do not
  /// carry TMDb collection IDs. Two meaningful leading words are enough to
  /// catch obvious clusters such as Demon Slayer and Mortal Kombat while the
  /// soft/backfill behaviour prevents false positives becoming exclusions.
  static String familyKey(String title) {
    final words = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && !_stopWords.contains(word))
        .toList(growable: false);
    if (words.isEmpty) return '';
    return words.take(words.length == 1 ? 1 : 2).join(' ');
  }

  static String _normaliseTitle(String title) => title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
