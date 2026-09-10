import '../data/discovery_lane_loader.dart';
import 'discovery_tab_controller.dart';

class HomeLabDiscoveryLaneQualitySummary {
  final String sectionId;
  final int itemCount;
  final int previewLimit;
  final bool underfilled;
  final int missingPosterCards;
  final int missingIdentityCards;
  final int repeatedFromEarlierLanes;

  const HomeLabDiscoveryLaneQualitySummary({
    required this.sectionId,
    required this.itemCount,
    required this.previewLimit,
    required this.underfilled,
    required this.missingPosterCards,
    required this.missingIdentityCards,
    required this.repeatedFromEarlierLanes,
  });

  Map<String, Object> toJson() => {
    'sectionId': sectionId,
    'itemCount': itemCount,
    'previewLimit': previewLimit,
    'underfilled': underfilled,
    'missingPosterCards': missingPosterCards,
    'missingIdentityCards': missingIdentityCards,
    'repeatedFromEarlierLanes': repeatedFromEarlierLanes,
  };
}

class HomeLabDiscoveryQualityReport {
  final int laneCount;
  final int totalCards;
  final int uniqueCards;
  final int repeatedCards;
  final int duplicateDistinctItems;
  final double duplicateRatio;
  final int missingIdentityCards;
  final int missingPosterCards;
  final double missingPosterRatio;
  final int missingBackdropCards;
  final int ownedCards;
  final double ownedRatio;
  final int underfilledLaneCount;
  final int hiddenLaneCount;
  final int failedLaneCount;
  final bool refreshFailure;
  final List<HomeLabDiscoveryLaneQualitySummary> laneSummaries;

  const HomeLabDiscoveryQualityReport({
    required this.laneCount,
    required this.totalCards,
    required this.uniqueCards,
    required this.repeatedCards,
    required this.duplicateDistinctItems,
    required this.duplicateRatio,
    required this.missingIdentityCards,
    required this.missingPosterCards,
    required this.missingPosterRatio,
    required this.missingBackdropCards,
    required this.ownedCards,
    required this.ownedRatio,
    required this.underfilledLaneCount,
    required this.hiddenLaneCount,
    required this.failedLaneCount,
    required this.refreshFailure,
    required this.laneSummaries,
  });

  /// Privacy-safe aggregate output. Media titles and Jellyfin/TMDB identities
  /// are intentionally never included.
  Map<String, Object> toJson() => {
    'laneCount': laneCount,
    'totalCards': totalCards,
    'uniqueCards': uniqueCards,
    'repeatedCards': repeatedCards,
    'duplicateDistinctItems': duplicateDistinctItems,
    'duplicateRatio': duplicateRatio,
    'missingIdentityCards': missingIdentityCards,
    'missingPosterCards': missingPosterCards,
    'missingPosterRatio': missingPosterRatio,
    'missingBackdropCards': missingBackdropCards,
    'ownedCards': ownedCards,
    'ownedRatio': ownedRatio,
    'underfilledLaneCount': underfilledLaneCount,
    'hiddenLaneCount': hiddenLaneCount,
    'failedLaneCount': failedLaneCount,
    'refreshFailure': refreshFailure,
    'laneSummaries': laneSummaries.map((summary) => summary.toJson()).toList(),
  };
}

/// Aggregate recommendation-quality diagnostics shared by Web, Android mobile/
/// tablet and Android TV. This deliberately observes presentation output only;
/// it does not alter source selection or recommendation ranking.
abstract final class HomeLabDiscoveryQuality {
  static HomeLabDiscoveryQualityReport analyse(
    HomeLabDiscoveryTabLoadResult result,
  ) {
    final occurrences = <String, int>{};
    final laneSummaries = <HomeLabDiscoveryLaneQualitySummary>[];
    var totalCards = 0;
    var missingIdentityCards = 0;
    var missingPosterCards = 0;
    var missingBackdropCards = 0;
    var ownedCards = 0;
    var repeatedCards = 0;
    var underfilledLaneCount = 0;

    for (final lane in result.usableLanes) {
      final items = lane.items;
      final previewLimit = lane.section.previewLimit;
      var laneMissingPoster = 0;
      var laneMissingIdentity = 0;
      var laneRepeatedCards = 0;
      final underfilled = previewLimit > 0 && items.length < previewLimit;
      if (underfilled) underfilledLaneCount++;

      for (final item in items) {
        totalCards++;
        final identity = _identity(lane, item.id, item.mediaType);
        if (identity == null) {
          missingIdentityCards++;
          laneMissingIdentity++;
        } else {
          final previous = occurrences[identity] ?? 0;
          if (previous > 0) {
            repeatedCards++;
            laneRepeatedCards++;
          }
          occurrences[identity] = previous + 1;
        }

        if (item.posterPath?.trim().isNotEmpty != true) {
          missingPosterCards++;
          laneMissingPoster++;
        }
        if (item.backdropPath?.trim().isNotEmpty != true) {
          missingBackdropCards++;
        }
        if (item.mediaInfo?.jellyfinMediaId?.trim().isNotEmpty == true) {
          ownedCards++;
        }
      }

      laneSummaries.add(
        HomeLabDiscoveryLaneQualitySummary(
          sectionId: lane.section.id,
          itemCount: items.length,
          previewLimit: previewLimit,
          underfilled: underfilled,
          missingPosterCards: laneMissingPoster,
          missingIdentityCards: laneMissingIdentity,
          repeatedFromEarlierLanes: laneRepeatedCards,
        ),
      );
    }

    final duplicateDistinctItems = occurrences.values
        .where((count) => count > 1)
        .length;

    return HomeLabDiscoveryQualityReport(
      laneCount: result.usableLanes.length,
      totalCards: totalCards,
      uniqueCards: occurrences.length,
      repeatedCards: repeatedCards,
      duplicateDistinctItems: duplicateDistinctItems,
      duplicateRatio: _ratio(repeatedCards, totalCards),
      missingIdentityCards: missingIdentityCards,
      missingPosterCards: missingPosterCards,
      missingPosterRatio: _ratio(missingPosterCards, totalCards),
      missingBackdropCards: missingBackdropCards,
      ownedCards: ownedCards,
      ownedRatio: _ratio(ownedCards, totalCards),
      underfilledLaneCount: underfilledLaneCount,
      hiddenLaneCount: result.hiddenLanes.length,
      failedLaneCount: result.failedLanes.length,
      refreshFailure: result.refreshFailure != null,
      laneSummaries: List.unmodifiable(laneSummaries),
    );
  }

  static String? _identity(
    HomeLabDiscoveryLaneLoadResult lane,
    int id,
    String? itemMediaType,
  ) {
    if (id <= 0) return null;
    final mediaType = (itemMediaType?.trim().isNotEmpty ?? false)
        ? itemMediaType!.trim()
        : lane.section.query.mediaType.trim();
    if (mediaType.isEmpty) return null;
    return '$mediaType:$id';
  }

  static double _ratio(int part, int whole) {
    if (whole <= 0) return 0;
    return ((part / whole) * 1000).round() / 1000;
  }
}
