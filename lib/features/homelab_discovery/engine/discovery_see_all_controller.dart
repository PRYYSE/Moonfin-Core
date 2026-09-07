import '../../../data/services/seerr/seerr_api_models.dart';
import '../catalogue/discovery_catalogue.dart';
import '../data/discovery_lane_loader.dart';

typedef HomeLabDiscoveryDeepPageLoader =
    Future<HomeLabDiscoveryPageLoadResult> Function(
      HomeLabDiscoverySection section, {
      required int page,
      required bool forceRefresh,
    });

class HomeLabDiscoverySeeAllState {
  final HomeLabDiscoverySection section;
  final String title;
  final List<SeerrDiscoverItem> items;
  final int throughPage;
  final int totalPages;
  final int sourceTotalResults;
  final Object? error;

  const HomeLabDiscoverySeeAllState({
    required this.section,
    required this.title,
    this.items = const [],
    this.throughPage = 0,
    this.totalPages = 1,
    this.sourceTotalResults = 0,
    this.error,
  });

  bool get hasError => error != null;
  bool get hasMore => throughPage == 0 || throughPage < totalPages;
}

/// Deep-browse state for one Discovery section.
///
/// Unlike landing previews, this deliberately does not apply cross-row session
/// novelty, family caps or title diversification. It only deduplicates exact
/// media identities across source pages and keeps paging forward through a few
/// membership-filtered empty pages so restrictive availability modes do not
/// create false empty states.
class HomeLabDiscoverySeeAllController {
  final HomeLabDiscoverySection section;
  final HomeLabDiscoveryDeepPageLoader loadPage;
  final int maxEmptyPageReadAhead;

  final List<SeerrDiscoverItem> _items = <SeerrDiscoverItem>[];
  final Set<String> _seen = <String>{};
  String _title;
  int _throughPage = 0;
  int _totalPages = 1;
  int _sourceTotalResults = 0;
  Object? _error;
  bool _loading = false;

  HomeLabDiscoverySeeAllController({
    required this.section,
    required this.loadPage,
    this.maxEmptyPageReadAhead = 4,
  }) : _title = section.title;

  HomeLabDiscoverySeeAllState get state => HomeLabDiscoverySeeAllState(
    section: section,
    title: _title,
    items: List.unmodifiable(_items),
    throughPage: _throughPage,
    totalPages: _totalPages,
    sourceTotalResults: _sourceTotalResults,
    error: _error,
  );

  Future<HomeLabDiscoverySeeAllState> loadInitial() async {
    _resetData();
    return _advance(forceRefresh: false);
  }

  Future<HomeLabDiscoverySeeAllState> refresh() async {
    _resetData();
    return _advance(forceRefresh: true);
  }

  Future<HomeLabDiscoverySeeAllState> loadMore() => _advance();

  Future<HomeLabDiscoverySeeAllState> retry() => _advance();

  void reset() => _resetData();

  Future<HomeLabDiscoverySeeAllState> _advance({
    bool forceRefresh = false,
  }) async {
    if (_loading || (!state.hasMore && _throughPage > 0)) return state;
    _loading = true;
    _error = null;
    final before = _items.length;
    var scanned = 0;

    try {
      do {
        final requestedPage = _throughPage + 1;
        final loaded = await loadPage(
          section,
          page: requestedPage,
          forceRefresh: forceRefresh && requestedPage == 1,
        );
        _title = loaded.displayTitle;
        _throughPage = loaded.page < requestedPage
            ? requestedPage
            : loaded.page;
        _totalPages = loaded.totalPages;
        _sourceTotalResults = loaded.totalResults;
        for (final item in loaded.items) {
          if (_seen.add(_identity(item))) _items.add(item);
        }
        scanned++;
      } while (_items.length == before &&
          state.hasMore &&
          scanned < maxEmptyPageReadAhead);
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
    }

    return state;
  }

  String _identity(SeerrDiscoverItem item) =>
      '${item.mediaType ?? section.query.mediaType}:${item.id}';

  void _resetData() {
    _items.clear();
    _seen.clear();
    _title = section.title;
    _throughPage = 0;
    _totalPages = 1;
    _sourceTotalResults = 0;
    _error = null;
  }
}
