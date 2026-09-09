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
  Future<HomeLabDiscoverySeeAllState>? _activeAdvance;
  bool _resetAfterActive = false;

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

  Future<HomeLabDiscoverySeeAllState> loadInitial() =>
      _replaceAfterCurrent(forceRefresh: false);

  Future<HomeLabDiscoverySeeAllState> refresh() =>
      _replaceAfterCurrent(forceRefresh: true);

  Future<HomeLabDiscoverySeeAllState> loadMore() => _advanceOrJoin();

  Future<HomeLabDiscoverySeeAllState> retry() => _advanceOrJoin();

  /// Synchronous callers may request a reset while paging is still in flight.
  /// Defer the destructive clear until that operation has settled so its
  /// response can never repopulate a freshly reset collection with stale data.
  void reset() {
    if (_activeAdvance != null) {
      _resetAfterActive = true;
      return;
    }
    _resetData();
  }

  Future<HomeLabDiscoverySeeAllState> _replaceAfterCurrent({
    required bool forceRefresh,
  }) async {
    while (_activeAdvance != null) {
      await _activeAdvance;
    }
    _resetData();
    return _startAdvance(forceRefresh: forceRefresh);
  }

  Future<HomeLabDiscoverySeeAllState> _advanceOrJoin() {
    final active = _activeAdvance;
    if (active != null) return active;
    if (!state.hasMore && _throughPage > 0) return Future.value(state);
    return _startAdvance();
  }

  Future<HomeLabDiscoverySeeAllState> _startAdvance({
    bool forceRefresh = false,
  }) {
    late final Future<HomeLabDiscoverySeeAllState> future;
    future = _advance(forceRefresh: forceRefresh).whenComplete(() {
      if (!identical(_activeAdvance, future)) return;
      _activeAdvance = null;
      if (_resetAfterActive) {
        _resetAfterActive = false;
        _resetData();
      }
    });
    _activeAdvance = future;
    return future;
  }

  Future<HomeLabDiscoverySeeAllState> _advance({
    bool forceRefresh = false,
  }) async {
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
