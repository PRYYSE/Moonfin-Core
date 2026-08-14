import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/custom_external_lists_service.dart';
import 'package:moonfin/data/services/seerr/seerr_discovery_external_list_paginator.dart';

ImdbExternalListItem _item(
  int id, {
  String type = 'Movie',
  String? tmdbId,
}) =>
    ImdbExternalListItem(
      imdbId: 'tt${id.toString().padLeft(7, '0')}',
      tmdbId: tmdbId ?? '$id',
      title: 'Item $id',
      type: type,
    );

void main() {
  test('windows a large list instead of returning every card at once', () async {
    final paginator = SeerrDiscoveryExternalListPaginator(
      pageSize: 40,
      loadItems: ({bool forceRefresh = false}) async =>
          List.generate(95, (index) => _item(index + 1)),
    );

    final first = await paginator.loadNext();
    final second = await paginator.loadNext();
    final third = await paginator.loadNext();

    expect(first.items.length, 40);
    expect(first.startIndex, 0);
    expect(first.totalItems, 95);
    expect(first.hasMore, isTrue);
    expect(second.items.length, 40);
    expect(second.startIndex, 40);
    expect(third.items.length, 15);
    expect(third.startIndex, 80);
    expect(third.hasMore, isFalse);
  });

  test('deduplicates list IDs while preserving first source order', () async {
    final paginator = SeerrDiscoveryExternalListPaginator(
      pageSize: 10,
      loadItems: ({bool forceRefresh = false}) async => [
        _item(1),
        _item(2),
        _item(99, tmdbId: '1'),
        _item(3),
      ],
    );

    final window = await paginator.loadNext();
    expect(window.items.map((item) => item.tmdbId), ['1', '2', '3']);
  });

  test('media type constraint filters mixed lists before paging', () async {
    final paginator = SeerrDiscoveryExternalListPaginator(
      mediaType: 'tv',
      pageSize: 10,
      loadItems: ({bool forceRefresh = false}) async => [
        _item(1),
        _item(2, type: 'Series'),
        _item(3, type: 'TV'),
        _item(4, type: 'Show'),
      ],
    );

    final window = await paginator.loadNext();
    expect(window.items.map((item) => item.tmdbId), ['2', '3', '4']);
  });

  test('normal reset reuses cached list while force refresh reloads it', () async {
    var loads = 0;
    final paginator = SeerrDiscoveryExternalListPaginator(
      pageSize: 2,
      loadItems: ({bool forceRefresh = false}) async {
        loads++;
        return forceRefresh
            ? [_item(10), _item(11), _item(12)]
            : [_item(1), _item(2), _item(3)];
      },
    );

    await paginator.loadNext();
    paginator.reset();
    final cached = await paginator.loadNext();
    expect(loads, 1);
    expect(cached.items.map((item) => item.tmdbId), ['1', '2']);

    final refreshed = await paginator.loadNext(forceRefresh: true);
    expect(loads, 2);
    expect(refreshed.items.map((item) => item.tmdbId), ['10', '11']);
  });
}
