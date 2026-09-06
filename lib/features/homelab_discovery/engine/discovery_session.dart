/// Tracks content surfaced during one Home Lab Discovery session.
///
/// Deduplication is intentionally presentation-only. Expanded full-result
/// views do not use the shared landing-page group, so valid catalogue results
/// remain reachable through See All.
class HomeLabDiscoverySession {
  final Map<String, Set<String>> _seenByGroup = {};

  List<T> filterFresh<T>({
    required String group,
    String? sharedGroup,
    required Iterable<T> items,
    required String Function(T item) identity,
    int minimumRetained = 6,
    bool record = true,
  }) {
    final list = items.toList(growable: false);
    if (list.isEmpty) return const [];

    final seen = record
        ? _seenByGroup.putIfAbsent(group, () => <String>{})
        : (_seenByGroup[group] ?? const <String>{});
    final sharedSeen = sharedGroup == null || sharedGroup == group
        ? null
        : record
        ? _seenByGroup.putIfAbsent(sharedGroup, () => <String>{})
        : (_seenByGroup[sharedGroup] ?? const <String>{});
    final fresh = <T>[];
    final repeats = <T>[];

    for (final item in list) {
      final id = identity(item);
      final hasSeen =
          id.isNotEmpty &&
          (seen.contains(id) || (sharedSeen?.contains(id) ?? false));
      if (hasSeen) {
        repeats.add(item);
      } else {
        fresh.add(item);
      }
    }

    final result = <T>[...fresh];
    if (result.length < minimumRetained) {
      result.addAll(repeats.take(minimumRetained - result.length));
    }

    if (record) {
      for (final item in result) {
        final id = identity(item);
        if (id.isEmpty) continue;
        seen.add(id);
        sharedSeen?.add(id);
      }
    }
    return result;
  }

  bool hasSeen(String group, String identity) =>
      _seenByGroup[group]?.contains(identity) ?? false;

  void markSeen(
    String group,
    Iterable<String> identities, {
    String? sharedGroup,
  }) {
    final clean = identities.where((value) => value.isNotEmpty).toList();
    _seenByGroup.putIfAbsent(group, () => <String>{}).addAll(clean);
    if (sharedGroup != null && sharedGroup != group) {
      _seenByGroup.putIfAbsent(sharedGroup, () => <String>{}).addAll(clean);
    }
  }

  void resetGroup(String group) => _seenByGroup.remove(group);

  void reset() => _seenByGroup.clear();

  Map<String, int> get counts => {
    for (final entry in _seenByGroup.entries) entry.key: entry.value.length,
  };
}
