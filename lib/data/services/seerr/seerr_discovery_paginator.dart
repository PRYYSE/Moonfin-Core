import 'seerr_api_models.dart';
import 'seerr_discovery_schema.dart';

typedef SeerrDiscoveryPageFetcher = Future<SeerrDiscoverPage> Function(
  SeerrDiscoveryQuery query,
  int page,
);

typedef SeerrDiscoveryItemPredicate = bool Function(SeerrDiscoverItem item);

class SeerrDiscoveryPageWindow {
  final List<SeerrDiscoverItem> items;
  final int fromPage;
  final int throughPage;
  final int totalPages;

  const SeerrDiscoveryPageWindow({
    required this.items,
    required this.fromPage,
    required this.throughPage,
    required this.totalPages,
  });
}

/// Stateful bounded paginator shared by preview and expanded discovery flows.
///
/// A single Seerr/TMDb page can become sparse after media-type, blocklist,
/// availability or user refinements are applied. Rather than showing a nearly
/// empty lane/grid, each load may read ahead a bounded number of source pages
/// until it has a useful result window. Exact media IDs are suppressed across
/// page boundaries for the lifetime of this paginator.
class SeerrDiscoveryPaginator {
  final SeerrDiscoveryQuery query;
  final SeerrDiscoveryPageFetcher fetchPage;
  final SeerrDiscoveryItemPredicate? include;
  final int minimumMatchesPerLoad;
  final int maxPagesPerScan;

  int _currentPage = 0;
  int _totalPages = 1;
  bool _started = false;
  final Set<String> _seen = {};

  SeerrDiscoveryPaginator({
    required this.query,
    required this.fetchPage,
    this.include,
    this.minimumMatchesPerLoad = 12,
    this.maxPagesPerScan = 6,
  })  : assert(minimumMatchesPerLoad > 0),
        assert(maxPagesPerScan > 0);

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get canLoadMore => !_started || _currentPage < _totalPages;
  int get uniqueItemCount => _seen.length;

  Future<SeerrDiscoveryPageWindow> loadNext() async {
    if (_started && !canLoadMore) {
      return SeerrDiscoveryPageWindow(
        items: const [],
        fromPage: _currentPage,
        throughPage: _currentPage,
        totalPages: _totalPages,
      );
    }

    final fromPage = _currentPage + 1;
    var requestedPage = fromPage;
    var pagesRead = 0;
    final output = <SeerrDiscoverItem>[];

    while (pagesRead < maxPagesPerScan) {
      final page = await fetchPage(query, requestedPage);
      _started = true;
      pagesRead++;

      final reportedPage = page.page > 0 ? page.page : requestedPage;
      _currentPage = reportedPage;
      _totalPages = page.totalPages > 0 ? page.totalPages : reportedPage;

      for (final item in page.results) {
        if (!_matchesQueryMediaType(item)) continue;
        if (include != null && !include!(item)) continue;
        final identity = _identity(item);
        if (!_seen.add(identity)) continue;
        output.add(item);
      }

      if (output.length >= minimumMatchesPerLoad ||
          _currentPage >= _totalPages ||
          page.results.isEmpty) {
        break;
      }
      requestedPage = _currentPage + 1;
    }

    return SeerrDiscoveryPageWindow(
      items: output,
      fromPage: fromPage,
      throughPage: _currentPage,
      totalPages: _totalPages,
    );
  }

  void reset() {
    _currentPage = 0;
    _totalPages = 1;
    _started = false;
    _seen.clear();
  }

  bool _matchesQueryMediaType(SeerrDiscoverItem item) {
    final wanted = query.mediaType;
    if (wanted == 'all' || wanted.isEmpty) return true;
    final actual = item.mediaType;
    // Many Movie/TV-specific endpoints omit mediaType because it is implicit.
    if (actual == null || actual.isEmpty) return true;
    return actual == wanted;
  }

  String _identity(SeerrDiscoverItem item) {
    final mediaType = item.mediaType?.isNotEmpty == true
        ? item.mediaType!
        : query.mediaType;
    return '$mediaType:${item.id}';
  }
}
