import '../../../data/services/seerr/seerr_api_models.dart';
import '../bridge/moonfin_discovery_bridge.dart';
import '../catalogue/discovery_catalogue.dart';
import '../engine/discovery_personalisation.dart';
import 'discovery_paginator.dart';

typedef HomeLabDiscoveryLanePredicate =
    bool Function(HomeLabDiscoverySection section, SeerrDiscoverItem item);

class HomeLabDiscoveryPageLoadResult {
  final HomeLabDiscoverySection section;
  final String displayTitle;
  final List<SeerrDiscoverItem> items;
  final int page;
  final int totalPages;
  final int totalResults;

  HomeLabDiscoveryPageLoadResult({
    required this.section,
    String? displayTitle,
    this.items = const [],
    this.page = 1,
    this.totalPages = 0,
    this.totalResults = 0,
  }) : displayTitle = displayTitle ?? section.title;
}

class HomeLabDiscoveryLaneLoadResult {
  final HomeLabDiscoverySection section;
  final String displayTitle;
  final List<SeerrDiscoverItem> items;
  final int throughPage;
  final int totalPages;
  final Object? error;

  HomeLabDiscoveryLaneLoadResult({
    required this.section,
    String? displayTitle,
    this.items = const [],
    this.throughPage = 0,
    this.totalPages = 0,
    this.error,
  }) : displayTitle = displayTitle ?? section.title;

  bool get hasError => error != null;
  bool get isUsable => !hasError && items.length >= section.minItems;
  bool get shouldHide => !hasError && !isUsable;
}

/// Fetches Discovery data without mutating cross-row presentation state.
///
/// Landing lane loads may run concurrently. Session novelty, shared
/// deduplication and personalised title/family presentation therefore belong to
/// the deterministic post-fetch tab presentation stage, not here. [loadPage]
/// exposes membership-filtered source pages for deep browsing without applying
/// preview-only cross-row presentation.
class HomeLabDiscoveryLaneLoader {
  final HomeLabDiscoveryPageFetcher fetchPage;
  final HomeLabDiscoveryLanePredicate? include;
  final HomeLabDiscoveryPersonalisation? personalisation;
  final int maxPagesPerScan;

  const HomeLabDiscoveryLaneLoader({
    required this.fetchPage,
    this.include,
    this.personalisation,
    this.maxPagesPerScan = 6,
  });

  Future<HomeLabDiscoveryLaneLoadResult> load(
    HomeLabDiscoverySection section,
  ) async {
    try {
      if (section.query.source == HomeLabDiscoverySource.personalised) {
        final service = personalisation;
        // Unsupported semantic labels are catalogue capability gaps, not
        // transport failures. Hide them cleanly instead of surfacing an error
        // or substituting unrelated recommendation data.
        if (service != null && !service.supports(section)) {
          return HomeLabDiscoveryLaneLoadResult(section: section);
        }
        return _loadPersonalised(section);
      }

      final paginator = HomeLabDiscoveryPaginator(
        query: section.query,
        fetchPage: fetchPage,
        minimumMatchesPerLoad: section.previewLimit,
        maxPagesPerScan: maxPagesPerScan,
        include: include == null ? null : (item) => include!(section, item),
      );
      final window = await paginator.loadNext();
      final items = window.items
          .take(section.previewLimit)
          .toList(growable: false);

      return HomeLabDiscoveryLaneLoadResult(
        section: section,
        items: items,
        throughPage: window.throughPage,
        totalPages: window.totalPages,
      );
    } catch (error) {
      return HomeLabDiscoveryLaneLoadResult(section: section, error: error);
    }
  }

  Future<HomeLabDiscoveryPageLoadResult> loadPage(
    HomeLabDiscoverySection section, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final safePage = page < 1 ? 1 : page;
    late final SeerrDiscoverPage loadedPage;
    var displayTitle = section.title;

    if (section.query.source == HomeLabDiscoverySource.personalised) {
      final service = personalisation;
      if (service == null) {
        throw StateError('Personalised Discovery service is unavailable');
      }
      if (!service.supports(section)) {
        throw UnsupportedError(
          'Discovery personal strategy ${section.query.seedStrategy ?? section.id} '
          'is not executable by this client',
        );
      }
      final loaded = await service.load(
        section,
        page: safePage,
        forceRefresh: forceRefresh,
      );
      loadedPage = loaded.page;
      displayTitle = loaded.title;
    } else {
      loadedPage = await fetchPage(section.query, safePage);
    }

    final items = loadedPage.results
        .where((item) => include?.call(section, item) ?? true)
        .toList(growable: false);
    return HomeLabDiscoveryPageLoadResult(
      section: section,
      displayTitle: displayTitle,
      items: items,
      page: loadedPage.page,
      totalPages: loadedPage.totalPages,
      totalResults: loadedPage.totalResults,
    );
  }

  Future<HomeLabDiscoveryLaneLoadResult> _loadPersonalised(
    HomeLabDiscoverySection section,
  ) async {
    final loaded = await loadPage(section);
    final items = loaded.items
        .take(section.previewLimit)
        .toList(growable: false);

    return HomeLabDiscoveryLaneLoadResult(
      section: section,
      displayTitle: loaded.displayTitle,
      items: items,
      throughPage: loaded.page,
      totalPages: loaded.totalPages,
    );
  }
}
