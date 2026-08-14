/// Tracks content surfaced during one deep-discovery session.
///
/// Discovery rows may legitimately overlap, but repeatedly showing the same
/// blockbusters in adjacent rows makes an "endless" browser feel shallow.
/// This helper keeps the policy independent of widgets so every platform can
/// apply the same behaviour.
class SeerrDiscoverySession {
  final Map<String, Set<String>> _seenByGroup = {};

  /// Prefers IDs not already surfaced in [group] or optional [sharedGroup],
  /// then records the retained IDs into both scopes.
  ///
  /// A lane can therefore use a specific group such as `movies-genres` and a
  /// shared tab scope such as `tab:movies`. Expanded full-result screens should
  /// omit [sharedGroup] so landing-page novelty never hides valid catalogue
  /// results.
  ///
  /// [minimumRetained] prevents aggressive deduplication from emptying a row.
  /// If too few unseen IDs remain, prior items are reintroduced in original
  /// order after the fresh items.
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

    final seen = _seenByGroup.putIfAbsent(group, () => <String>{});
    final sharedSeen = sharedGroup == null || sharedGroup == group
        ? null
        : _seenByGroup.putIfAbsent(sharedGroup, () => <String>{});
    final fresh = <T>[];
    final repeats = <T>[];

    for (final item in list) {
      final id = identity(item);
      final hasSeen =
          id.isNotEmpty &&
          (seen.contains(id) || (sharedSeen?.contains(id) ?? false));
      if (!hasSeen) {
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
    final seen = _seenByGroup.putIfAbsent(group, () => <String>{});
    seen.addAll(clean);
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
