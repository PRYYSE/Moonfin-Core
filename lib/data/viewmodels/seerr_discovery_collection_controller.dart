import 'package:flutter/foundation.dart';

import '../services/seerr/seerr_api_models.dart';
import '../services/seerr/seerr_discovery_paginator.dart';
import '../services/seerr/seerr_discovery_refinement_policy.dart';
import '../services/seerr/seerr_discovery_schema.dart';
import '../services/seerr/seerr_discovery_sort_policy.dart';

class SeerrDiscoveryCollectionState {
  final SeerrDiscoveryQuery query;
  final List<SeerrDiscoverItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;

  const SeerrDiscoveryCollectionState({
    required this.query,
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 0,
    this.totalPages = 1,
  });

  bool get canLoadMore => !isLoading &&
      !isLoadingMore &&
      currentPage < totalPages;

  SeerrDiscoveryCollectionState copyWith({
    SeerrDiscoveryQuery? query,
    List<SeerrDiscoverItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    int? currentPage,
    int? totalPages,
  }) =>
      SeerrDiscoveryCollectionState(
        query: query ?? this.query,
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : (error ?? this.error),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
      );
}

/// Generic controller for an expanded Discovery lane.
///
/// The old SeerrBrowseViewModel is filter-type-specific. This controller takes
/// the exact base [SeerrDiscoveryQuery], preserves it through user refinements,
/// and owns deep page loading independently of the presentation widget.
class SeerrDiscoveryCollectionController extends ChangeNotifier {
  final SeerrDiscoveryQuery baseQuery;
  final SeerrDiscoveryPageFetcher fetchPage;
  final SeerrDiscoveryItemPredicate? include;
  final int minimumMatchesPerLoad;
  final int maxPagesPerScan;

  Map<String, String> _refinements = const {};
  String? _sortOverride;
  late SeerrDiscoveryPaginator _paginator;
  int _generation = 0;

  late SeerrDiscoveryCollectionState _state;
  SeerrDiscoveryCollectionState get state => _state;

  SeerrDiscoveryCollectionController({
    required this.baseQuery,
    required this.fetchPage,
    this.include,
    this.minimumMatchesPerLoad = 20,
    this.maxPagesPerScan = 6,
  }) {
    final query = _effectiveQuery();
    _state = SeerrDiscoveryCollectionState(query: query);
    _paginator = _createPaginator(query);
  }

  Future<void> load() async {
    final generation = ++_generation;
    final query = _effectiveQuery();
    _paginator = _createPaginator(query);
    _state = SeerrDiscoveryCollectionState(
      query: query,
      isLoading: true,
    );
    notifyListeners();

    try {
      final window = await _paginator.loadNext();
      if (generation != _generation) return;
      _state = _state.copyWith(
        items: window.items,
        isLoading: false,
        currentPage: window.throughPage,
        totalPages: window.totalPages,
        clearError: true,
      );
    } catch (error) {
      if (generation != _generation) return;
      _state = _state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_state.isLoading || _state.isLoadingMore || !_paginator.canLoadMore) {
      return;
    }
    final generation = _generation;
    _state = _state.copyWith(isLoadingMore: true, clearError: true);
    notifyListeners();

    try {
      final window = await _paginator.loadNext();
      if (generation != _generation) return;
      _state = _state.copyWith(
        items: [..._state.items, ...window.items],
        isLoadingMore: false,
        currentPage: window.throughPage,
        totalPages: window.totalPages,
        clearError: true,
      );
    } catch (error) {
      if (generation != _generation) return;
      _state = _state.copyWith(
        isLoadingMore: false,
        error: error.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> setRefinements(Map<String, String> refinements) async {
    if (mapEquals(_refinements, refinements)) return;
    _refinements = Map<String, String>.from(refinements);
    await load();
  }

  Future<void> clearRefinements() => setRefinements(const {});

  Future<void> setSort(String sortBy) async {
    final safe = SeerrDiscoverySortPolicy.normalise(sortBy);
    if (_sortOverride == safe ||
        (_sortOverride == null && safe == baseQuery.sortBy)) {
      return;
    }
    _sortOverride = safe;
    await load();
  }

  Future<void> resetSort() async {
    if (_sortOverride == null) return;
    _sortOverride = null;
    await load();
  }

  SeerrDiscoveryQuery _effectiveQuery() {
    final refined = SeerrDiscoveryRefinementPolicy.merge(
      baseQuery,
      _refinements,
    );
    final sort = _sortOverride ?? refined.sortBy;
    return SeerrDiscoveryQuery(
      source: refined.source,
      mediaType: refined.mediaType,
      sortBy: SeerrDiscoverySortPolicy.normalise(sort),
      filters: refined.filters,
      keywordNames: refined.keywordNames,
      excludeKeywordNames: refined.excludeKeywordNames,
      providerNames: refined.providerNames,
      seedStrategy: refined.seedStrategy,
      listProvider: refined.listProvider,
      listId: refined.listId,
    );
  }

  SeerrDiscoveryPaginator _createPaginator(SeerrDiscoveryQuery query) =>
      SeerrDiscoveryPaginator(
        query: query,
        fetchPage: fetchPage,
        include: include,
        minimumMatchesPerLoad: minimumMatchesPerLoad,
        maxPagesPerScan: maxPagesPerScan,
      );

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
