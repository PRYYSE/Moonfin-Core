import 'seerr_discovery_filter_policy.dart';
import 'seerr_discovery_schema.dart';

/// Merges user-selected browse refinements into an immutable base lane query.
///
/// Refinements may narrow a lane but should never silently turn `Hidden Gems`
/// into a generic browse by replacing its rating/vote constraints.
abstract final class SeerrDiscoveryRefinementPolicy {
  static const _numericLowerBounds = <String>{
    'withRuntimeGte',
    'voteAverageGte',
    'voteCountGte',
  };
  static const _numericUpperBounds = <String>{
    'withRuntimeLte',
    'voteAverageLte',
    'voteCountLte',
  };
  static const _dateLowerBounds = <String>{
    'primaryReleaseDateGte',
    'firstAirDateGte',
  };
  static const _dateUpperBounds = <String>{
    'primaryReleaseDateLte',
    'firstAirDateLte',
  };

  static SeerrDiscoveryQuery merge(
    SeerrDiscoveryQuery base,
    Map<String, String> refinements, {
    DateTime? now,
  }) {
    final safeBase = SeerrDiscoveryFilterPolicy.sanitise(base.filters, now: now);
    final safeRefinements =
        SeerrDiscoveryFilterPolicy.sanitise(refinements, now: now);
    final merged = Map<String, String>.from(safeBase);

    for (final entry in safeRefinements.entries) {
      final key = entry.key;
      final candidate = entry.value;
      final existing = merged[key];
      if (existing == null) {
        merged[key] = candidate;
        continue;
      }

      if (key == 'genre') {
        merged[key] = _mergeGenres(existing, candidate);
      } else if (_numericLowerBounds.contains(key)) {
        merged[key] = _stricterNumeric(existing, candidate, lowerBound: true);
      } else if (_numericUpperBounds.contains(key)) {
        merged[key] = _stricterNumeric(existing, candidate, lowerBound: false);
      } else if (_dateLowerBounds.contains(key)) {
        merged[key] = existing.compareTo(candidate) >= 0 ? existing : candidate;
      } else if (_dateUpperBounds.contains(key)) {
        merged[key] = existing.compareTo(candidate) <= 0 ? existing : candidate;
      }
      // Exact identity constraints such as studio/network/language/provider and
      // base keywords remain locked when already supplied by the base lane.
    }

    return SeerrDiscoveryQuery(
      source: base.source,
      mediaType: base.mediaType,
      sortBy: base.sortBy,
      filters: merged,
      keywordNames: base.keywordNames,
      excludeKeywordNames: base.excludeKeywordNames,
      providerNames: base.providerNames,
      seedStrategy: base.seedStrategy,
      listProvider: base.listProvider,
      listId: base.listId,
    );
  }

  static String _mergeGenres(String base, String refinement) {
    final values = <String>[];
    final seen = <String>{};
    for (final value in [...base.split(','), ...refinement.split(',')]) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed)) values.add(trimmed);
    }
    return values.join(',');
  }

  static String _stricterNumeric(
    String existing,
    String candidate, {
    required bool lowerBound,
  }) {
    final a = double.tryParse(existing);
    final b = double.tryParse(candidate);
    if (a == null || b == null) return existing;
    final chosen = lowerBound
        ? (a >= b ? existing : candidate)
        : (a <= b ? existing : candidate);
    return chosen;
  }
}
