import 'dart:math' as math;

import 'seerr_discovery_schema.dart';

/// Reduces a large Discovery catalogue tab to a stable, useful session.
///
/// Small tabs keep their anchors fully predictable. Larger catalogue tabs keep
/// a short predictable lead section, then interleave secondary anchors with a
/// deterministic sample of distinct deep-discovery pools before filling the
/// remaining budget. This prevents a long block of generic/current rows from
/// hiding the richer catalogue while preserving stable session composition.
class SeerrDiscoveryComposer {
  const SeerrDiscoveryComposer();

  List<SeerrDiscoverySection> compose(
    SeerrDiscoveryTab tab, {
    required String sessionSeed,
    int refreshNonce = 0,
    Map<String, int> sessionsSinceSeen = const {},
    bool Function(SeerrDiscoverySection section)? isEligible,
  }) {
    if (tab.sections.isEmpty) return const [];

    final budget = tab.initialLaneBudget.clamp(1, tab.sections.length).toInt();
    final eligible = tab.sections
        .where((section) => isEligible?.call(section) ?? true)
        .toList(growable: false);
    if (eligible.isEmpty) return const [];

    final anchors = eligible.where((section) => section.isAnchor).toList();
    final optional = eligible.where((section) => !section.isAnchor).toList();

    final selected = <SeerrDiscoverySection>[];
    final selectedIds = <String>{};
    final poolCounts = <String, int>{};

    void add(SeerrDiscoverySection section) {
      if (selected.length >= budget || !selectedIds.add(section.id)) return;
      selected.add(section);
      poolCounts.update(section.pool, (count) => count + 1, ifAbsent: () => 1);
    }

    bool poolHasRoom(SeerrDiscoverySection section) {
      final limit = tab.poolBudgets[section.pool];
      if (limit == null) return true;
      return (poolCounts[section.pool] ?? 0) < limit;
    }

    bool coolingDown(SeerrDiscoverySection section) {
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

    // Compact tabs remain exactly anchor-first. Large catalogue tabs only pin
    // three lead anchors, so Trending/Popular/current context stays familiar
    // without consuming the whole first screen.
    final leadAnchorCount = anchors.length > 6 ? 3 : anchors.length;
    final leadAnchors = anchors.take(leadAnchorCount);
    final secondaryAnchors = anchors.skip(leadAnchorCount).toList();
    for (final anchor in leadAnchors) {
      add(anchor);
    }

    if (secondaryAnchors.isNotEmpty && optional.isNotEmpty) {
      // Pick the strongest currently-eligible candidate from each optional
      // pool. Pool order follows catalogue authoring order, while the lane
      // within each pool remains session-weighted and deterministic.
      final poolOrder = <String>[];
      final seenPools = <String>{};
      for (final section in optional) {
        if (seenPools.add(section.pool)) poolOrder.add(section.pool);
      }

      final poolSeeds = <SeerrDiscoverySection>[];
      for (final pool in poolOrder) {
        for (final section in ranked) {
          if (section.pool != pool || coolingDown(section)) continue;
          poolSeeds.add(section);
          break;
        }
      }

      // Build a mixed front window. The first few rows remain familiar, then
      // the page starts exposing discovery/runtimes/eras/genres/themes/etc.
      // Secondary anchors are woven between those deeper lanes instead of
      // appearing as one long generic block.
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

      // Preserve every anchor that still fits the configured landing budget.
      for (; anchorIndex < secondaryAnchors.length; anchorIndex++) {
        add(secondaryAnchors[anchorIndex]);
      }

      // Any remaining pool seeds get first chance before the generic weighted
      // fill, further improving category breadth on larger sessions.
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

    // Strict fill: honour both cooldowns and per-pool budgets.
    for (final section in ranked) {
      if (selected.length >= budget) break;
      if (coolingDown(section) || !poolHasRoom(section)) continue;
      add(section);
    }

    // A sparse catalogue/session should still be usable. First relax cooldowns
    // while retaining pool balance.
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

    // Last-resort fill ignores pool caps rather than returning an almost-empty
    // landing page. This is intentionally a fallback, not normal composition.
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
    SeerrDiscoverySection section, {
    required String sessionSeed,
    required int refreshNonce,
  }) {
    final hash = _fnv1a32('$sessionSeed|$refreshNonce|${section.id}');
    // Convert to an open (0,1) interval. Exponential-race ranking gives each
    // item a weighted chance without needing mutable RNG state.
    final unit = (hash + 1) / 4294967297.0;
    final priorityMultiplier = switch (section.priority) {
      SeerrDiscoveryPriority.anchor => 1000.0,
      SeerrDiscoveryPriority.high => 2.0,
      SeerrDiscoveryPriority.normal => 1.0,
      SeerrDiscoveryPriority.low => 0.5,
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
