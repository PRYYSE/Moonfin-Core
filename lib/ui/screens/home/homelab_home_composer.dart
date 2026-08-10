import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../data/models/home_row.dart';
import '../../../preference/home_section_config.dart';
import '../../../util/platform_detection.dart';

/// Home Lab's web-desktop presentation layer for Home.
///
/// Moonbase/user settings are authoritative for which sections exist and their
/// order. This composer deliberately does not force-enable, suppress or reorder
/// configured sections. It only applies Home Lab presentation names and folds
/// the several per-library recently-released rows into one coherent shelf.
class HomelabHomeComposer {
  const HomelabHomeComposer._();

  static bool get enabled => kIsWeb && !PlatformDetection.useMobileUi;

  /// Keep the saved Moonbase/user layout exactly as configured.
  static List<HomeSectionConfig> augmentConfigs(
    List<HomeSectionConfig> configured, {
    required bool mergeContinueWatchingNextUp,
  }) {
    return configured;
  }

  static List<HomeRow> compose(List<HomeRow> input) {
    if (!enabled || input.isEmpty) return input;

    final seenIds = <String>{};
    final output = <HomeRow>[];
    final recentRows = <HomeRow>[];
    int? recentInsertIndex;

    for (final row in input) {
      if (!seenIds.add(row.id)) continue;
      if (row.rowType == HomeRowType.recentlyReleased) {
        recentInsertIndex ??= output.length;
        recentRows.add(row);
        continue;
      }
      output.add(_retitle(row));
    }

    final mergedRecent = _mergeRecentlyReleased(recentRows);
    if (mergedRecent != null) {
      final index = (recentInsertIndex ?? output.length).clamp(0, output.length);
      output.insert(index, mergedRecent);
    }

    return output;
  }

  static HomeRow? _mergeRecentlyReleased(List<HomeRow> rows) {
    if (rows.isEmpty) return null;

    final seen = <String>{};
    final items = [
      for (final row in rows)
        for (final item in row.items)
          if (seen.add('${item.serverId}:${item.id}')) item,
    ];

    items.sort((a, b) {
      DateTime? dateFor(dynamic item) {
        final premiere = item.premiereDate as DateTime?;
        if (premiere != null) return premiere;
        final year = item.productionYear as int?;
        return year == null ? null : DateTime(year);
      }

      final aDate = dateFor(a);
      final bDate = dateFor(b);
      if (aDate != null && bDate != null) return bDate.compareTo(aDate);
      if (aDate != null) return -1;
      if (bDate != null) return 1;
      return 0;
    });

    if (items.isEmpty && !rows.any((row) => row.isLoading)) return null;

    final visibleItems = items.take(20).toList(growable: false);
    return HomeRow(
      id: 'homelab_new_noteworthy',
      title: 'New & Noteworthy',
      items: visibleItems,
      rowType: HomeRowType.recentlyReleased,
      isLoading: visibleItems.isEmpty && rows.any((row) => row.isLoading),
      totalCount: visibleItems.length,
    );
  }

  static HomeRow _retitle(HomeRow row) {
    final title = switch (row.id) {
      'resume' => 'Continue Watching',
      'nextUp' => 'Next Up',
      'sinceYouWatched3' => 'Recommended For You',
      'rewatch' => 'Worth Watching Again',
      'seerr_watchlist' => 'Your Watchlist',
      'seerr_trending' => 'Trending Now',
      'seerr_recently_added' => 'Recently Added to Your Library',
      'libraryTiles' || 'libraryTilesSmall' => 'Browse Your Libraries',
      _ => row.title,
    };
    return title == row.title ? row : row.copyWith(title: title);
  }
}
