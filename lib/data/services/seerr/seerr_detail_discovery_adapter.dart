import '../../models/aggregated_item.dart';
import '../../models/tmdb_item_ref.dart';
import '../../viewmodels/seerr_media_detail_view_model.dart';
import 'seerr_api_models.dart';
import 'seerr_discovery_recommendation_mixer.dart';

/// Converts Seerr's already-fetched Similar + Recommendations payloads into
/// the same [AggregatedItem] shape used by Moonfin's existing detail carousel.
///
/// No new network path or media-detail type is introduced. Selecting one of
/// these synthetic TMDb items goes through the existing detail route, which
/// resolves back to a local Jellyfin item first when the title is owned.
abstract final class SeerrDetailDiscoveryAdapter {
  static List<AggregatedItem> mergeIntoExisting({
    required List<AggregatedItem> existing,
    required SeerrMediaDetailState state,
    required bool blockNsfw,
    int limit = 40,
  }) {
    if (limit <= 0 || state.tmdbId == 0) return existing;

    final fallbackType = state.isTv ? 'tv' : 'movie';
    final mixed = SeerrDiscoveryRecommendationMixer.mix(
      limit: limit * 2,
      mediaType: fallbackType,
      seeds: [
        SeerrDiscoverySeedResults(
          seedId: 'recommendations',
          weight: 1.2,
          items: state.recommendations,
        ),
        SeerrDiscoverySeedResults(
          seedId: 'similar',
          items: state.similar,
        ),
      ],
    );

    final output = <AggregatedItem>[];
    final seen = <String>{};

    void addExisting(AggregatedItem item) {
      final tmdb = item.tmdbId;
      final identity = tmdb != null && tmdb.isNotEmpty
          ? '${_mediaTypeForAggregated(item)}:$tmdb'
          : 'jellyfin:${item.serverId}:${item.id}';
      if (seen.add(identity)) output.add(item);
    }

    for (final item in existing) {
      if (output.length >= limit) break;
      addExisting(item);
    }

    for (final item in mixed) {
      if (output.length >= limit) break;
      if (item.isBlacklisted || (blockNsfw && item.adult)) continue;
      if (item.id == state.tmdbId &&
          (item.mediaType == null || item.mediaType == fallbackType)) {
        continue;
      }
      final mediaType = _normaliseMediaType(item.mediaType, fallbackType);
      if (mediaType == null || item.displayTitle.trim().isEmpty) continue;
      final identity = '$mediaType:${item.id}';
      if (!seen.add(identity)) continue;
      output.add(_toAggregated(item, mediaType));
    }

    return List.unmodifiable(output);
  }

  static AggregatedItem _toAggregated(
    SeerrDiscoverItem item,
    String mediaType,
  ) {
    final kind = mediaType == 'tv' ? TmdbItemKind.tv : TmdbItemKind.movie;
    final date = item.releaseDate ?? item.firstAirDate;
    final year = date != null && date.length >= 4
        ? int.tryParse(date.substring(0, 4))
        : null;
    return AggregatedItem(
      id: TmdbItemRef(kind, '${item.id}').itemId,
      serverId: 'seerr',
      rawData: {
        'Name': item.displayTitle,
        'Overview': item.overview,
        'Type': mediaType == 'tv' ? 'Series' : 'Movie',
        'ProviderIds': {'Tmdb': '${item.id}'},
        'PosterPath': item.posterPath,
        'BackdropPath': item.backdropPath,
        if (year != null) 'ProductionYear': year,
        'PremiereDate': date,
        'CommunityRating': item.voteAverage,
        'GenreIds': item.genreIds,
        'SeerrMediaType': mediaType,
        'SeerrStatus': item.mediaInfo?.status,
        'UserData': const {'Played': false, 'IsFavorite': false},
        'MediaSources': const [],
        'MediaStreams': const [],
        'CanDelete': false,
      },
    );
  }

  static String? _normaliseMediaType(String? value, String fallback) {
    final normalised = value?.trim().toLowerCase();
    if (normalised == 'movie' || normalised == 'tv') return normalised;
    if (normalised == null || normalised.isEmpty) return fallback;
    return null;
  }

  static String _mediaTypeForAggregated(AggregatedItem item) {
    final raw = item.rawData['SeerrMediaType']?.toString().toLowerCase();
    if (raw == 'movie' || raw == 'tv') return raw!;
    return item.type == 'Series' ? 'tv' : 'movie';
  }
}
