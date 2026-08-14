import 'seerr_api_models.dart';
import 'seerr_discovery_schema.dart';

/// Applies the membership rule declared by a Discovery lane.
///
/// Seerr status remains useful for request/availability state, while callers
/// can overlay Jellyfin-local ownership/watch state when it has been resolved.
/// Blocklisted items are always rejected here and stay authoritative.
class SeerrDiscoveryAvailabilityPolicy {
  const SeerrDiscoveryAvailabilityPolicy._();

  static bool include(
    SeerrDiscoverItem item,
    SeerrDiscoveryAvailabilityMode mode, {
    bool? isOwnedLocally,
    bool? isWatched,
  }) {
    if (item.isBlacklisted) return false;

    final status = item.mediaInfo?.status;
    final requested = status == 2 || status == 3;
    final available = item.isAvailable || isOwnedLocally == true;

    return switch (mode) {
      SeerrDiscoveryAvailabilityMode.all => true,
      SeerrDiscoveryAvailabilityMode.requestable => !available && !requested,
      SeerrDiscoveryAvailabilityMode.available => available,
      SeerrDiscoveryAvailabilityMode.requested => requested,
      SeerrDiscoveryAvailabilityMode.notOwned => !available,
      SeerrDiscoveryAvailabilityMode.unwatched => isWatched != true,
    };
  }
}
