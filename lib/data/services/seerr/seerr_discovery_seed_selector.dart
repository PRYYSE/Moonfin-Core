class SeerrDiscoveryTasteSeed {
  final String id;
  final String mediaType;
  final double affinity;
  final Set<int> genreIds;
  final String? franchiseKey;

  const SeerrDiscoveryTasteSeed({
    required this.id,
    required this.mediaType,
    this.affinity = 1.0,
    this.genreIds = const {},
    this.franchiseKey,
  });
}

/// Greedy, deterministic seed selection for personalised discovery.
///
/// Strong signals still lead, but the first pass rejects near-identical genre
/// clusters and duplicate franchise keys. Later passes relax diversity before
/// returning too few seeds, making diversity a preference rather than a hard
/// source of empty recommendation rows.
abstract final class SeerrDiscoverySeedSelector {
  static List<SeerrDiscoveryTasteSeed> select(
    Iterable<SeerrDiscoveryTasteSeed> candidates, {
    int limit = 5,
    int maxPerMediaType = 3,
    double maxGenreSimilarity = 0.75,
  }) {
    if (limit <= 0) return const [];

    final ordered = candidates.where((seed) => seed.id.isNotEmpty).toList()
      ..sort((a, b) {
        final byAffinity = b.affinity.compareTo(a.affinity);
        return byAffinity != 0 ? byAffinity : a.id.compareTo(b.id);
      });
    if (ordered.isEmpty) return const [];

    final selected = <SeerrDiscoveryTasteSeed>[];
    final selectedIds = <String>{};
    final franchises = <String>{};
    final mediaCounts = <String, int>{};

    bool franchiseAvailable(SeerrDiscoveryTasteSeed seed) {
      final key = seed.franchiseKey?.trim();
      return key == null || key.isEmpty || !franchises.contains(key);
    }

    bool mediaHasRoom(SeerrDiscoveryTasteSeed seed) =>
        (mediaCounts[seed.mediaType] ?? 0) < maxPerMediaType;

    bool genreDiverse(SeerrDiscoveryTasteSeed seed) => selected.every(
      (other) => _jaccard(seed.genreIds, other.genreIds) < maxGenreSimilarity,
    );

    void add(SeerrDiscoveryTasteSeed seed) {
      if (selected.length >= limit || !selectedIds.add(seed.id)) return;
      selected.add(seed);
      mediaCounts.update(
        seed.mediaType,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      final franchise = seed.franchiseKey?.trim();
      if (franchise != null && franchise.isNotEmpty) franchises.add(franchise);
    }

    // First pass: strong diversity across genre, media type and franchise.
    for (final seed in ordered) {
      if (selected.length >= limit) break;
      if (!franchiseAvailable(seed) ||
          !mediaHasRoom(seed) ||
          !genreDiverse(seed)) {
        continue;
      }
      add(seed);
    }

    // Second pass: relax genre overlap but retain franchise/media-type balance.
    if (selected.length < limit) {
      for (final seed in ordered) {
        if (selected.length >= limit) break;
        if (!franchiseAvailable(seed) || !mediaHasRoom(seed)) continue;
        add(seed);
      }
    }

    // Last resort: affinity order only, still no exact duplicate seed IDs.
    if (selected.length < limit) {
      for (final seed in ordered) {
        if (selected.length >= limit) break;
        add(seed);
      }
    }

    return selected;
  }

  static double _jaccard(Set<int> a, Set<int> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0 : intersection / union;
  }
}
