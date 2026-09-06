import '../../../data/services/seerr/seerr_api_models.dart';
import '../bridge/moonfin_discovery_bridge.dart';
import '../catalogue/discovery_catalogue.dart';

typedef HomeLabDiscoveryItemPredicate = bool Function(SeerrDiscoverItem item);

class HomeLabDiscoveryPageWindow {
  final List<SeerrDiscoverItem> items;
  final int fromPage;
  final int throughPage;
  final int totalPages;

  const HomeLabDiscoveryPageWindow({
    required this.items,
    required this.fromPage,
    required this.throughPage,
    required this.totalPages,
  });
}

class HomeLabDiscoveryPaginator {
  final HomeLabDiscoveryQuery query;
  final HomeLabDiscoveryPageFetcher fetchPage;
  final HomeLabDiscoveryItemPredicate? include;
  final int minimumMatchesPerLoad;
  final int maxPagesPerScan;

  int _currentPage = 0;
  int _totalPages = 1;
  bool _started = false;
  final Set<String> _seen = {};

  HomeLabDiscoveryPaginator({
    required this.query,
    required this.fetchPage,
    this.include,
    this.minimumMatchesPerLoad = 12,
    this.maxPagesPerScan = 6,
  }) : assert(minimumMatchesPerLoad > 0),
       assert(maxPagesPerScan > 0);

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get canLoadMore => !_started || _currentPage < _totalPages;
  int get uniqueItemCount => _seen.length;

  Future<HomeLabDiscoveryPageWindow> loadNext() async {
    if (_started && !canLoadMore) {
      return HomeLabDiscoveryPageWindow(
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

    return HomeLabDiscoveryPageWindow(
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
