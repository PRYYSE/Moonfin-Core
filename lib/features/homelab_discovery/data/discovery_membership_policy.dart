import '../../../data/services/seerr/seerr_api_models.dart';
import '../catalogue/discovery_catalogue.dart';

/// Applies section membership after a source has returned a candidate item.
///
/// Seerr request/availability state remains authoritative for remote media.
/// Local ownership/watch state can be supplied by callers when it has been
/// resolved. Unknown watch state is intentionally treated as not-known-watched,
/// matching the accepted v1 behaviour rather than hiding valid recommendations.
abstract final class HomeLabDiscoveryMembershipPolicy {
  static const _nsfwTerms = <String>[
    r'\bsex\b',
    'sexual',
    r'\bporn\b',
    'erotic',
    r'\bnude\b',
    'nudity',
    r'\bxxx\b',
    'adult film',
    'prostitute',
    'stripper',
    r'\bescort\b',
    'seduction',
    r'\baffair\b',
    'threesome',
    r'\borgy\b',
    'kinky',
    'fetish',
    r'\bbdsm\b',
    'dominatrix',
  ];

  static final _nsfwPatterns = _nsfwTerms
      .map((term) => RegExp(term, caseSensitive: false))
      .toList(growable: false);

  static bool include(
    SeerrDiscoverItem item,
    HomeLabDiscoveryAvailabilityMode mode, {
    required bool blockNsfw,
    bool? isOwnedLocally,
    bool? isWatched,
  }) {
    if (item.isBlacklisted) return false;
    if (blockNsfw && _isNsfw(item)) return false;

    final status = item.mediaInfo?.status;
    final requested = status == 2 || status == 3;
    final available = item.isAvailable || isOwnedLocally == true;

    return switch (mode) {
      HomeLabDiscoveryAvailabilityMode.all => true,
      HomeLabDiscoveryAvailabilityMode.requestable => !available && !requested,
      HomeLabDiscoveryAvailabilityMode.available => available,
      HomeLabDiscoveryAvailabilityMode.requested => requested,
      HomeLabDiscoveryAvailabilityMode.notOwned => !available,
      HomeLabDiscoveryAvailabilityMode.unwatched => isWatched != true,
    };
  }

  static bool _isNsfw(SeerrDiscoverItem item) {
    if (item.adult) return true;
    final text = '${item.displayTitle} ${item.overview ?? ''}';
    return _nsfwPatterns.any((pattern) => pattern.hasMatch(text));
  }
}
