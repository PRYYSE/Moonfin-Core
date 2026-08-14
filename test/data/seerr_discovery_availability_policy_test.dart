import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_availability_policy.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';

SeerrDiscoverItem _item(int status) => SeerrDiscoverItem(
      id: status,
      title: 'Item $status',
      mediaInfo: SeerrMediaInfo(status: status),
    );

void main() {
  test('general discovery keeps available/requested/requestable media', () {
    expect(
      SeerrDiscoveryAvailabilityPolicy.include(
        _item(5),
        SeerrDiscoveryAvailabilityMode.all,
      ),
      isTrue,
    );
    expect(
      SeerrDiscoveryAvailabilityPolicy.include(
        _item(2),
        SeerrDiscoveryAvailabilityMode.all,
      ),
      isTrue,
    );
    expect(
      SeerrDiscoveryAvailabilityPolicy.include(
        _item(1),
        SeerrDiscoveryAvailabilityMode.all,
      ),
      isTrue,
    );
  });

  test('requestable excludes requested and available media', () {
    expect(
      SeerrDiscoveryAvailabilityPolicy.include(
        _item(1),
        SeerrDiscoveryAvailabilityMode.requestable,
      ),
      isTrue,
    );
    expect(
      SeerrDiscoveryAvailabilityPolicy.include(
        _item(2),
        SeerrDiscoveryAvailabilityMode.requestable,
      ),
      isFalse,
    );
    expect(
      SeerrDiscoveryAvailabilityPolicy.include(
        _item(5),
        SeerrDiscoveryAvailabilityMode.requestable,
      ),
      isFalse,
    );
  });

  test('local Jellyfin ownership augments Seerr availability', () {
    expect(
      SeerrDiscoveryAvailabilityPolicy.include(
        _item(1),
        SeerrDiscoveryAvailabilityMode.available,
        isOwnedLocally: true,
      ),
      isTrue,
    );
    expect(
      SeerrDiscoveryAvailabilityPolicy.include(
        _item(1),
        SeerrDiscoveryAvailabilityMode.notOwned,
        isOwnedLocally: true,
      ),
      isFalse,
    );
  });

  test('unwatched uses Jellyfin watch state without hiding unknown media', () {
    expect(
      SeerrDiscoveryAvailabilityPolicy.include(
        _item(1),
        SeerrDiscoveryAvailabilityMode.unwatched,
        isWatched: true,
      ),
      isFalse,
    );
    expect(
      SeerrDiscoveryAvailabilityPolicy.include(
        _item(1),
        SeerrDiscoveryAvailabilityMode.unwatched,
        isWatched: false,
      ),
      isTrue,
    );
    expect(
      SeerrDiscoveryAvailabilityPolicy.include(
        _item(1),
        SeerrDiscoveryAvailabilityMode.unwatched,
      ),
      isTrue,
    );
  });

  test('blocklist wins over every lane mode', () {
    final blocked = _item(6);
    for (final mode in SeerrDiscoveryAvailabilityMode.values) {
      expect(
        SeerrDiscoveryAvailabilityPolicy.include(blocked, mode),
        isFalse,
      );
    }
  });
}
