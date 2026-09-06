import 'dart:math' as math;

import '../catalogue/discovery_catalogue.dart';

/// Reduces a large server-delivered Discovery tab to a stable useful session.
///
/// A short predictable anchor block stays at the front, then distinct deep
/// pools are interleaved before the remaining budget is filled. Selection is
/// deterministic for a session seed and refresh nonce.
class HomeLabDiscoveryComposer {
  const HomeLabDiscoveryComposer();

  List<HomeLabDiscoverySection> compose(
    HomeLabDiscoveryTab tab, {
    required String sessionSeed,
    int refreshNonce = 0,
    Map<String, int> sessionsSinceSeen = const {},
    bool Function(HomeLabDiscoverySection section)? isEligible,
  }) {
    if (tab.sections.isEmpty) return const [];

    final budget = tab.initialLaneBudget.clamp(1, tab.sections.length).toInt();
    final eligible = tab.sections
        .where((section) => isEligible?.call(section) ?? true)
        .toList(growable: false);
    if (eligible.isEmpty) return const [];

    final anchors = eligible.where((section) => section.isAnchor).toList();
    final optional = eligible.where((section) => !section.isAnchor).toList();

    final selected = <HomeLabDiscoverySection>[];
    final selectedIds = <String>{};
    final poolCounts = <String, int>{};

    void add(HomeLabDiscoverySection section) {
      if (selected.length >= budget || !selectedIds.add(section.id)) return;
      selected.add(section);
      poolCounts.update(section.pool, (count) => count + 1, ifAbsent: () => 1);
    }

    bool poolHasRoom(HomeLabDiscoverySection section) {
      final limit = tab.poolBudgets[section.pool];
      if (limit == null) return true;
      return (poolCounts[section.pool] ?? 0) < limit;
    }

    bool coolingDown(HomeLabDiscoverySection section) {
      if (section.cooldownSessions <= 0) return false;
      final age = sessionsSinceSeen[section.id];
      return age != null && age < section.cooldownSessions;
    }

    final ranked = [...optional]
      ..sort((a, b) {
        final aScore = _rank(
          a,
          sessionSeed: sessionSeed,
          refreshNonce: refreshNonce,
        );
        final bScore = _rank(
          b,
          sessionSeed: sessionSeed,
          refreshNonce: refreshNonce,
        );
        final byScore = aScore.compareTo(bScore);
        return byScore != 0 ? byScore : a.id.compareTo(b.id);
      });

    final leadAnchorCount = anchors.length > 6 ? 3 : anchors.length;
    final leadAnchors = anchors.take(leadAnchorCount);
    final secondaryAnchors = anchors.skip(leadAnchorCount).toList();
    for (final anchor in leadAnchors) {
      add(anchor);
    }

    if (secondaryAnchors.isNotEmpty && optional.isNotEmpty) {
      final poolOrder = <String>[];
      final seenPools = <String>{};
      for (final section in optional) {
        if (seenPools.add(section.pool)) poolOrder.add(section.pool);
      }

      final poolSeeds = <HomeLabDiscoverySection>[];
      for (final pool in poolOrder) {
        for (final section in ranked) {
          if (section.pool != pool || coolingDown(section)) continue;
          poolSeeds.add(section);
          break;
        }
      }

      final frontWindow = math.min(12, budget);
      var seedIndex = 0;
      var anchorIndex = 0;
      while (selected.length < frontWindow &&
          (seedIndex < poolSeeds.length ||
              anchorIndex < secondaryAnchors.length)) {
        if (seedIndex < poolSeeds.length) {
          final seed = poolSeeds[seedIndex++];
          if (!selectedIds.contains(seed.id) && poolHasRoom(seed)) add(seed);
        }
        if (selected.length >= frontWindow) break;
        if (anchorIndex < secondaryAnchors.length) {
          add(secondaryAnchors[anchorIndex++]);
        }
      }

      for (; anchorIndex < secondaryAnchors.length; anchorIndex++) {
        add(secondaryAnchors[anchorIndex]);
      }

      for (; seedIndex < poolSeeds.length; seedIndex++) {
        final seed = poolSeeds[seedIndex];
        if (coolingDown(seed) || !poolHasRoom(seed)) continue;
        add(seed);
      }
    } else {
      for (final anchor in secondaryAnchors) {
        add(anchor);
      }
    }

    for (final section in ranked) {
      if (selected.length >= budget) break;
      if (coolingDown(section) || !poolHasRoom(section)) continue;
      add(section);
    }

    if (selected.length < tab.minimumLaneCount) {
      for (final section in ranked) {
        if (selected.length >= budget ||
            selected.length >= tab.minimumLaneCount) {
          break;
        }
        if (!poolHasRoom(section)) continue;
        add(section);
      }
    }

    if (selected.length < tab.minimumLaneCount) {
      for (final section in ranked) {
        if (selected.length >= budget ||
            selected.length >= tab.minimumLaneCount) {
          break;
        }
        add(section);
      }
    }

    return selected;
  }

  double _rank(
    HomeLabDiscoverySection section, {
    required String sessionSeed,
    required int refreshNonce,
  }) {
    final hash = _fnv1a32('$sessionSeed|$refreshNonce|${section.id}');
    final unit = (hash + 1) / 4294967297.0;
    final priorityMultiplier = switch (section.priority) {
      HomeLabDiscoveryPriority.anchor => 1000.0,
      HomeLabDiscoveryPriority.high => 2.0,
      HomeLabDiscoveryPriority.normal => 1.0,
      HomeLabDiscoveryPriority.low => 0.5,
    };
    final effectiveWeight = section.weight * priorityMultiplier;
    return -math.log(unit) / effectiveWeight;
  }

  int _fnv1a32(String input) {
    var hash = 0x811C9DC5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
