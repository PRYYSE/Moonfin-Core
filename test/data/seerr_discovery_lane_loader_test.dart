import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_lane_loader.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_schema.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_session.dart';

SeerrDiscoverItem _item(int id) =>
    SeerrDiscoverItem(id: id, mediaType: 'movie', title: 'Item $id');

SeerrDiscoverySection _section({int minItems = 3, int previewLimit = 5}) =>
    SeerrDiscoverySection(
      id: 'lane',
      title: 'Lane',
      minItems: minItems,
      previewLimit: previewLimit,
      dedupGroup: 'movies-lane',
      query: const SeerrDiscoveryQuery(
        source: SeerrDiscoverySource.discoverMovies,
        mediaType: 'movie',
      ),
    );

void main() {
  test('reads ahead then caps a useful preview to previewLimit', () async {
    final loader = SeerrDiscoveryLaneLoader(
      fetchPage: (_, page) async => SeerrDiscoverPage(
        page: page,
        totalPages: 4,
        results: [_item(page * 10 + 1), _item(page * 10 + 2)],
      ),
    );

    final result = await loader.load(_section());
    expect(result.hasError, isFalse);
    expect(result.isUsable, isTrue);
    expect(result.items.length, 5);
    expect(result.throughPage, 3);
  });

  test(
    'shallow optional lane becomes hideable instead of failing tab',
    () async {
      final loader = SeerrDiscoveryLaneLoader(
        fetchPage: (_, page) async => SeerrDiscoverPage(
          page: page,
          totalPages: 1,
          results: [_item(1), _item(2)],
        ),
      );

      final result = await loader.load(_section(minItems: 3));
      expect(result.hasError, isFalse);
      expect(result.shouldHide, isTrue);
      expect(result.items.length, 2);
    },
  );

  test('one lane fetch error is returned as data rather than thrown', () async {
    final loader = SeerrDiscoveryLaneLoader(
      fetchPage: (_, __) async => throw StateError('Seerr lane failed'),
    );

    final result = await loader.load(_section());
    expect(result.hasError, isTrue);
    expect(result.error, isA<StateError>());
    expect(result.items, isEmpty);
  });

  test('session dedup prefers unseen items across lane pools', () async {
    final session = SeerrDiscoverySession();
    session.markSeen('previous', [
      'movie:1',
      'movie:2',
    ], sharedGroup: 'tab:movies');
    final loader = SeerrDiscoveryLaneLoader(
      session: session,
      sharedDedupGroup: 'tab:movies',
      fetchPage: (_, page) async => SeerrDiscoverPage(
        page: page,
        totalPages: 1,
        results: [_item(1), _item(2), _item(3), _item(4), _item(5)],
      ),
    );

    final result = await loader.load(_section(minItems: 3, previewLimit: 5));
    expect(result.items.take(3).map((item) => item.id), [3, 4, 5]);
    expect(result.isUsable, isTrue);
  });

  test('section membership predicate can be lane specific', () async {
    final loader = SeerrDiscoveryLaneLoader(
      include: (_, item) => item.id.isEven,
      fetchPage: (_, page) async => SeerrDiscoverPage(
        page: page,
        totalPages: 2,
        results: [
          _item(page * 10 + 1),
          _item(page * 10 + 2),
          _item(page * 10 + 3),
          _item(page * 10 + 4),
        ],
      ),
    );

    final result = await loader.load(_section(minItems: 3, previewLimit: 4));
    expect(result.items.map((item) => item.id), [12, 14, 22, 24]);
    expect(result.isUsable, isTrue);
  });
}
