import 'dart:math' as math;

import 'seerr_discovery_schema.dart';

/// Reduces a large Discovery catalogue tab to a stable, useful session.
///
/// Anchors remain predictable. Optional sections are selected deterministically
/// from weighted pools using the user/session seed and refresh nonce, so a page
/// does not reshuffle while the user navigates it but can materially change on
/// a later session or explicit refresh.
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

    for (final anchor in anchors) {
      add(anchor);
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

    // Strict pass: honour both cooldowns and per-pool budgets.
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
