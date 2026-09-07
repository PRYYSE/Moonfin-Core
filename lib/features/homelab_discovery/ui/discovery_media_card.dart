import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../ui/navigation/destinations.dart';
import '../../../ui/widgets/media_card.dart';

class HomeLabDiscoveryMediaCard extends StatelessWidget {
  static const _tmdbPosterBase = 'https://image.tmdb.org/t/p/w342';

  final SeerrDiscoverItem item;
  final double width;
  final VoidCallback? onFocus;
  final VoidCallback? onTap;
  final bool? externalIsFocused;

  const HomeLabDiscoveryMediaCard({
    super.key,
    required this.item,
    required this.width,
    this.onFocus,
    this.onTap,
    this.externalIsFocused,
  });

  @override
  Widget build(BuildContext context) {
    return MediaCard(
      title: item.displayTitle,
      subtitle: _subtitleFor(item),
      imageUrl: _posterUrl(item.posterPath),
      width: width,
      aspectRatio: 2 / 3,
      seerrMediaType: item.mediaType,
      seerrStatus: item.mediaInfo?.status,
      onFocus: onFocus,
      externalIsFocused: externalIsFocused,
      onTap: onTap ?? () => openHomeLabDiscoveryItem(context, item),
    );
  }

  String? _posterUrl(String? path) {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '$_tmdbPosterBase$trimmed';
  }

  String? _subtitleFor(SeerrDiscoverItem item) {
    final parts = <String>[];
    final date = item.releaseDate ?? item.firstAirDate;
    if (date != null && date.length >= 4) parts.add(date.substring(0, 4));
    final rating = item.voteAverage;
    if (rating != null && rating > 0) {
      parts.add(rating.toStringAsFixed(1));
    }
    final status = item.mediaInfo?.status;
    if (status == 4 || status == 5) {
      parts.add('Available');
    } else if (status == 2 || status == 3) {
      parts.add('Requested');
    }
    return parts.isEmpty ? null : parts.join('  ');
  }
}

void openHomeLabDiscoveryItem(
  BuildContext context,
  SeerrDiscoverItem item,
) {
  final mediaType = item.mediaType == 'tv' ? 'tv' : 'movie';
  context.push(
    Destinations.seerrMedia(item.id.toString(), mediaType: mediaType),
  );
}
