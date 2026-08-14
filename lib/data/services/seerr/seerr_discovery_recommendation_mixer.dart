import 'seerr_api_models.dart';

class SeerrDiscoverySeedResults {
  final String seedId;
  final double weight;
  final List<SeerrDiscoverItem> items;

  const SeerrDiscoverySeedResults({
    required this.seedId,
    required this.items,
    this.weight = 1.0,
  });
}

/// Interleaves recommendation/similar outputs from several taste seeds.
///
/// Appending one seed's entire page or globally sorting everything by
/// popularity causes a few franchises to dominate personalised Discovery.
/// Instead, stronger seeds get earlier turns while every viable seed gets a
/// chance to contribute before another round begins.
abstract final class SeerrDiscoveryRecommendationMixer {
  static List<SeerrDiscoverItem> mix({
    required Iterable<SeerrDiscoverySeedResults> seeds,
    int limit = 20,
    Set<String> recentlySurfaced = const {},
    String? mediaType,
  }) {
    if (limit <= 0) return const [];

    final ordered = seeds.where((seed) => seed.items.isNotEmpty).toList()
      ..sort((a, b) {
        final byWeight = b.weight.compareTo(a.weight);
        return byWeight != 0 ? byWeight : a.seedId.compareTo(b.seedId);
      });
    if (ordered.isEmpty) return const [];

    final queues = <String, List<SeerrDiscoverItem>>{
      for (final seed in ordered)
        seed.seedId: seed.items
            .where((item) => _matchesMediaType(item, mediaType))
            .toList(growable: false),
    };
    final positions = <String, int>{for (final seed in ordered) seed.seedId: 0};
    final chosen = <SeerrDiscoverItem>[];
    final chosenIds = <String>{};
    final deferredRecent = <SeerrDiscoverItem>[];
    final deferredIds = <String>{};

    var madeProgress = true;
    while (chosen.length < limit && madeProgress) {
      madeProgress = false;
      for (final seed in ordered) {
        final queue = queues[seed.seedId]!;
        var position = positions[seed.seedId]!;
        while (position < queue.length) {
          final item = queue[position++];
          positions[seed.seedId] = position;
          final identity = _identity(item, mediaType);
          if (!chosenIds.add(identity)) continue;

          madeProgress = true;
          if (recentlySurfaced.contains(identity)) {
            if (deferredIds.add(identity)) deferredRecent.add(item);
            // Keep the item eligible as a last-resort fallback but remove it
            // from the fresh chosen set for now.
            chosenIds.remove(identity);
            break;
          }

          chosen.add(item);
          break;
        }
        if (chosen.length >= limit) break;
      }
    }

    // Novelty is a preference, not a reason to return a sparse personalised
    // rail. Reintroduce recently surfaced candidates only after fresh results.
    for (final item in deferredRecent) {
      if (chosen.length >= limit) break;
      final identity = _identity(item, mediaType);
      if (chosenIds.add(identity)) chosen.add(item);
    }

    return chosen;
  }

  static bool _matchesMediaType(SeerrDiscoverItem item, String? wanted) {
    if (wanted == null || wanted.isEmpty || wanted == 'all') return true;
    final actual = item.mediaType;
    return actual == null || actual.isEmpty || actual == wanted;
  }

  static String _identity(SeerrDiscoverItem item, String? fallbackType) {
    final type = item.mediaType?.isNotEmpty == true
        ? item.mediaType!
        : (fallbackType ?? 'unknown');
    return '$type:${item.id}';
  }
}
