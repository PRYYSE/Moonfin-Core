/// Tracks content surfaced during one deep-discovery session.
///
/// Discovery rows may legitimately overlap, but repeatedly showing the same
/// blockbusters in adjacent rows makes an "endless" browser feel shallow.
/// This helper keeps the policy independent of widgets so every platform can
/// apply the same behaviour.
class SeerrDiscoverySession {
  final Map<String, Set<String>> _seenByGroup = {};

  /// Returns only IDs not already surfaced in [group], then records them.
  ///
  /// [minimumRetained] prevents aggressive deduplication from emptying a row.
  /// If too few unseen IDs remain, the original ordering is retained and only
  /// the unseen prefix is preferred. This allows intentional overlap without
  /// turning discovery into blank shelves.
  List<T> filterFresh<T>({
    required String group,
    required Iterable<T> items,
    required String Function(T item) identity,
    int minimumRetained = 6,
    bool record = true,
  }) {
    final list = items.toList(growable: false);
    if (list.isEmpty) return const [];

    final seen = _seenByGroup.putIfAbsent(group, () => <String>{});
    final fresh = <T>[];
    final repeats = <T>[];

    for (final item in list) {
      final id = identity(item);
      if (id.isEmpty || !seen.contains(id)) {
        fresh.add(item);
      } else {
        repeats.add(item);
      }
    }

    final result = <T>[...fresh];
    if (result.length < minimumRetained) {
      result.addAll(repeats.take(minimumRetained - result.length));
    }

    if (record) {
      for (final item in result) {
        final id = identity(item);
        if (id.isNotEmpty) seen.add(id);
      }
    }
    return result;
  }

  bool hasSeen(String group, String identity) =>
      _seenByGroup[group]?.contains(identity) ?? false;

  void markSeen(String group, Iterable<String> identities) {
    final seen = _seenByGroup.putIfAbsent(group, () => <String>{});
    seen.addAll(identities.where((value) => value.isNotEmpty));
  }

  void resetGroup(String group) => _seenByGroup.remove(group);

  void reset() => _seenByGroup.clear();

  Map<String, int> get counts => {
        for (final entry in _seenByGroup.entries) entry.key: entry.value.length,
      };
}
