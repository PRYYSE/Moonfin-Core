import '../../../data/services/seerr/seerr_api_models.dart';
import '../catalogue/discovery_catalogue.dart';

/// Presentation-only diversity for personalised landing-page previews.
///
/// Stock Moonfin's recommendation engine remains authoritative for ranking.
/// See All deliberately bypasses this policy so the complete ranking remains
/// reachable.
abstract final class HomeLabDiscoveryPersonalPresentation {
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

  static String displayTitle(
    HomeLabDiscoverySection section,
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
