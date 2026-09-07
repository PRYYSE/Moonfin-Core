import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_membership_policy.dart';

SeerrDiscoverItem item({
  int? status,
  bool adult = false,
  String title = 'Example',
  String? overview,
}) => SeerrDiscoverItem(
  id: 1,
  mediaType: 'movie',
  title: title,
  adult: adult,
  overview: overview,
  mediaInfo: status == null ? null : SeerrMediaInfo(status: status),
);

bool include(
  SeerrDiscoverItem candidate,
  HomeLabDiscoveryAvailabilityMode mode, {
  bool blockNsfw = false,
  bool? isOwnedLocally,
  bool? isWatched,
}) => HomeLabDiscoveryMembershipPolicy.include(
  candidate,
  mode,
  blockNsfw: blockNsfw,
  isOwnedLocally: isOwnedLocally,
  isWatched: isWatched,
);

void main() {
  test('blacklisted media is rejected in every availability mode', () {
    expect(
      include(item(status: 6), HomeLabDiscoveryAvailabilityMode.all),
      isFalse,
    );
  });

  test('requestable excludes requested and available media', () {
    expect(
      include(item(), HomeLabDiscoveryAvailabilityMode.requestable),
      isTrue,
    );
    expect(
      include(item(status: 2), HomeLabDiscoveryAvailabilityMode.requestable),
      isFalse,
    );
    expect(
      include(item(status: 5), HomeLabDiscoveryAvailabilityMode.requestable),
      isFalse,
    );
  });

  test('available accepts Seerr or resolved local ownership', () {
    expect(
      include(item(status: 4), HomeLabDiscoveryAvailabilityMode.available),
      isTrue,
    );
    expect(
      include(
        item(),
        HomeLabDiscoveryAvailabilityMode.available,
        isOwnedLocally: true,
      ),
      isTrue,
    );
    expect(
      include(item(), HomeLabDiscoveryAvailabilityMode.available),
      isFalse,
    );
  });

  test('requested recognises pending and approved request states', () {
    expect(
      include(item(status: 2), HomeLabDiscoveryAvailabilityMode.requested),
      isTrue,
    );
    expect(
      include(item(status: 3), HomeLabDiscoveryAvailabilityMode.requested),
      isTrue,
    );
    expect(
      include(item(status: 5), HomeLabDiscoveryAvailabilityMode.requested),
      isFalse,
    );
  });

  test('notOwned and unwatched honour optional local state', () {
    expect(
      include(item(status: 2), HomeLabDiscoveryAvailabilityMode.notOwned),
      isTrue,
    );
    expect(
      include(
        item(),
        HomeLabDiscoveryAvailabilityMode.notOwned,
        isOwnedLocally: true,
      ),
      isFalse,
    );
    expect(
      include(
        item(),
        HomeLabDiscoveryAvailabilityMode.unwatched,
        isWatched: true,
      ),
      isFalse,
    );
    expect(
      include(item(), HomeLabDiscoveryAvailabilityMode.unwatched),
      isTrue,
    );
  });

  test('NSFW preference blocks adult flags and accepted v1 text patterns', () {
    expect(
      include(
        item(adult: true),
        HomeLabDiscoveryAvailabilityMode.all,
        blockNsfw: true,
      ),
      isFalse,
    );
    expect(
      include(
        item(title: 'An Erotic Thriller'),
        HomeLabDiscoveryAvailabilityMode.all,
        blockNsfw: true,
      ),
      isFalse,
    );
    expect(
      include(
        item(title: 'An Erotic Thriller'),
        HomeLabDiscoveryAvailabilityMode.all,
      ),
      isTrue,
    );
  });
}
