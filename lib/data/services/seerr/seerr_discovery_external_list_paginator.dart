import '../custom_external_lists_service.dart';

typedef SeerrDiscoveryExternalListLoader =
    Future<List<ImdbExternalListItem>> Function({bool forceRefresh});

class SeerrDiscoveryExternalListWindow {
  final List<ImdbExternalListItem> items;
  final int startIndex;
  final int totalItems;
  final bool hasMore;

  const SeerrDiscoveryExternalListWindow({
    required this.items,
    required this.startIndex,
    required this.totalItems,
    required this.hasMore,
  });
}

/// Adds deterministic windowing/deduplication around Moonfin's existing
/// server-proxied external-list service.
///
/// The current CustomExternalListsService returns a complete normalised list.
/// This adapter prevents expanded Discovery grids from mounting that whole list
/// at once. A later Moonbase endpoint can move the same paging contract server
/// side without changing the consumer behaviour.
class SeerrDiscoveryExternalListPaginator {
  final SeerrDiscoveryExternalListLoader loadItems;
  final int pageSize;
  final String mediaType;

  List<ImdbExternalListItem>? _items;
  int _offset = 0;

  SeerrDiscoveryExternalListPaginator({
    required this.loadItems,
    this.pageSize = 40,
    this.mediaType = 'all',
  }) : assert(pageSize > 0);

  int get offset => _offset;
  int get totalItems => _items?.length ?? 0;
  bool get canLoadMore => _items == null || _offset < _items!.length;

  Future<SeerrDiscoveryExternalListWindow> loadNext({
    bool forceRefresh = false,
  }) async {
    if (_items == null || forceRefresh) {
      final loaded = await loadItems(forceRefresh: forceRefresh);
      _items = _normalise(loaded);
      _offset = 0;
    }

    final items = _items!;
    final start = _offset;
    final end = (start + pageSize).clamp(0, items.length).toInt();
    final window = items.sublist(start, end);
    _offset = end;
    return SeerrDiscoveryExternalListWindow(
      items: window,
      startIndex: start,
      totalItems: items.length,
      hasMore: _offset < items.length,
    );
  }

  void reset() => _offset = 0;

  void clearCache() {
    _items = null;
    _offset = 0;
  }

  List<ImdbExternalListItem> _normalise(List<ImdbExternalListItem> input) {
    final output = <ImdbExternalListItem>[];
    final seen = <String>{};
    for (final item in input) {
      if (!_matchesMediaType(item)) continue;
      final identity = item.tmdbId.isNotEmpty
          ? 'tmdb:${item.type.toLowerCase()}:${item.tmdbId}'
          : 'imdb:${item.imdbId}';
      if (identity.endsWith(':') || !seen.add(identity)) continue;
      output.add(item);
    }
    return output;
  }

  bool _matchesMediaType(ImdbExternalListItem item) {
    if (mediaType == 'all' || mediaType.isEmpty) return true;
    final type = item.type.toLowerCase();
    return switch (mediaType) {
      'movie' => type == 'movie',
      'tv' => type == 'series' || type == 'tv' || type == 'show',
      _ => true,
    };
  }
}
