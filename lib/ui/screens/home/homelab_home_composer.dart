import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../data/models/home_row.dart';
import '../../../preference/home_section_config.dart';
import '../../../preference/preference_constants.dart';
import '../../../util/platform_detection.dart';

/// Home Lab's opinionated web Home composition layer.
///
/// Moonbase and the normal Moonfin section system remain the source of truth
/// for data loading and saved settings. This layer only asks for a small set of
/// high-value sections that make the Home destination useful out of the box,
/// then arranges the rows for a premium streaming-style discovery flow.
///
/// It is deliberately web-desktop-only during the design phase so Android,
/// native mobile and TV keep their proven baseline until the responsive pass.
class HomelabHomeComposer {
  const HomelabHomeComposer._();

  static bool get enabled => kIsWeb && !PlatformDetection.useMobileUi;

  /// Sections required for the first coherent Home experience even when the
  /// current saved layout predates them or has them disabled. Existing entries
  /// keep their settings and identity; missing/disabled entries are replaced
  /// only for this in-memory web composition and are not written back to the
  /// user's Moonbase profile.
  static List<HomeSectionConfig> augmentConfigs(
    List<HomeSectionConfig> configured, {
    required bool mergeContinueWatchingNextUp,
  }) {
    if (!enabled) return configured;

    final byType = <HomeSectionType, HomeSectionConfig>{
      for (final cfg in configured)
        if (cfg.isBuiltin) cfg.type: cfg,
    };
    final dynamic = configured.where((cfg) => cfg.isPluginDynamic).toList();

    final required = <HomeSectionType>[
      HomeSectionType.resume,
      if (!mergeContinueWatchingNextUp) HomeSectionType.nextUp,
      HomeSectionType.sinceYouWatched1,
      HomeSectionType.sinceYouWatched2,
      HomeSectionType.rewatch,
      HomeSectionType.seerrWatchlist,
      HomeSectionType.seerrTrending,
      HomeSectionType.recentlyReleased,
      HomeSectionType.seerrRecentlyAdded,
      HomeSectionType.latestMedia,
      HomeSectionType.libraryTilesSmall,
    ];

    var syntheticOrder = configured.fold<int>(
          -1,
          (max, cfg) => cfg.order > max ? cfg.order : max,
        ) +
        1;

    final result = <HomeSectionConfig>[];
    for (final type in required) {
      final existing = byType[type];
      result.add(
        existing == null
            ? HomeSectionConfig(
                type: type,
                enabled: true,
                order: syntheticOrder++,
              )
            : existing.copyWith(enabled: true),
      );
    }

    // Keep every other user/Moonbase-configured row available. Composition
    // below decides where it belongs and suppresses only obvious duplicates.
    for (final cfg in configured) {
      if (cfg.isBuiltin && required.contains(cfg.type)) continue;
      if (!cfg.enabled) continue;
      result.add(cfg);
    }
    result.addAll(dynamic.where((d) => !result.contains(d)));

    return result;
  }

  static List<HomeRow> compose(List<HomeRow> input) {
    if (!enabled || input.isEmpty) return input;

    final seen = <String>{};
    final rows = <HomeRow>[];
    for (final row in input) {
      if (!seen.add(row.id)) continue;
      if (_isLowValueDuplicate(row, input)) continue;
      rows.add(_retitle(row));
    }

    final originalPosition = <String, int>{
      for (var i = 0; i < rows.length; i++) rows[i].id: i,
    };
    rows.sort((a, b) {
      final byPriority = _priority(a).compareTo(_priority(b));
      if (byPriority != 0) return byPriority;
      return (originalPosition[a.id] ?? 0).compareTo(
        originalPosition[b.id] ?? 0,
      );
    });
    return rows;
  }

  static bool _isLowValueDuplicate(HomeRow row, List<HomeRow> all) {
    final hasSeerrTrending = all.any((r) => r.id == 'seerr_trending');
    final hasRecentlyReleased = all.any(
      (r) => r.rowType == HomeRowType.recentlyReleased,
    );

    // One mixed trending signal is more useful on neutral Home than several
    // near-identical popularity charts. Movies/TV get their own richer charts
    // on their dedicated destinations later.
    if (hasSeerrTrending &&
        (row.id == 'tmdb_trending_all_weekly' ||
            row.id == 'imdb_most_popular_movies' ||
            row.id == 'imdb_most_popular_tv_shows')) {
      return true;
    }

    // Avoid showing the same "new" idea twice when the stronger local release
    // row is already present. Seerr Recently Added remains useful because it is
    // ownership-aware/request-aware, so it is not suppressed here.
    if (hasRecentlyReleased && row.id == 'tmdb_now_playing_movies') {
      return true;
    }
    return false;
  }

  static HomeRow _retitle(HomeRow row) {
    final title = switch (row.id) {
      'resume' => 'Continue Watching',
      'nextUp' => 'Next Up For You',
      'rewatch' => 'Worth Watching Again',
      'seerr_watchlist' => 'Your Watchlist',
      'seerr_trending' => 'Trending Now',
      'seerr_recently_added' => 'Recently Added',
      'libraryTiles' || 'libraryTilesSmall' => 'Browse Your Libraries',
      _ when row.rowType == HomeRowType.recentlyReleased => 'New & Noteworthy',
      _ => row.title,
    };
    return title == row.title ? row : row.copyWith(title: title);
  }

  static int _priority(HomeRow row) {
    if (row.id == 'resume') return 0;
    if (row.id == 'nextUp') return 5;

    // Personal relevance comes before global popularity.
    if (row.id.startsWith('sinceYouWatched')) return 15;
    if (row.id == 'rewatch') return 22;
    if (row.id == 'seerr_watchlist') return 28;

    // Curated custom rows are editorial infrastructure from Moonbase/MDBList.
    if (row.id.startsWith('pluginDynamic:custom:')) return 35;

    if (row.id == 'seerr_trending') return 42;
    if (row.rowType == HomeRowType.recentlyReleased) return 50;
    if (row.id == 'seerr_recently_added') return 56;

    // Remaining external discovery stays in the middle of Home.
    if (row.id.startsWith('seerr_') ||
        row.id.startsWith('tmdb_') ||
        row.id.startsWith('imdb_')) {
      return 62;
    }

    if (row.rowType == HomeRowType.collections ||
        row.rowType == HomeRowType.genres) {
      return 70;
    }

    // Raw local-catalogue surfaces intentionally trail discovery.
    if (row.rowType == HomeRowType.latestMedia) return 82;
    if (row.rowType == HomeRowType.libraryTiles ||
        row.rowType == HomeRowType.libraryTilesSmall) {
      return 100;
    }

    return 76;
  }
}
