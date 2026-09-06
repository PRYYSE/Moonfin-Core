import '../../../data/services/seerr/seerr_api_models.dart';
import '../bridge/moonfin_discovery_bridge.dart';
import '../catalogue/discovery_catalogue.dart';
import '../engine/discovery_session.dart';
import 'discovery_paginator.dart';

typedef HomeLabDiscoveryLanePredicate =
    bool Function(HomeLabDiscoverySection section, SeerrDiscoverItem item);

class HomeLabDiscoveryLaneLoadResult {
  final HomeLabDiscoverySection section;
  final List<SeerrDiscoverItem> items;
  final int throughPage;
  final int totalPages;
  final Object? error;

  const HomeLabDiscoveryLaneLoadResult({
    required this.section,
    this.items = const [],
    this.throughPage = 0,
    this.totalPages = 0,
    this.error,
  });

  bool get hasError => error != null;
  bool get isUsable => !hasError && items.length >= section.minItems;
  bool get shouldHide => !hasError && !isUsable;
}

class HomeLabDiscoveryLaneLoader {
  final HomeLabDiscoveryPageFetcher fetchPage;
  final HomeLabDiscoveryLanePredicate? include;
  final HomeLabDiscoverySession? session;
  final String? sharedDedupGroup;
  final int maxPagesPerScan;

  const HomeLabDiscoveryLaneLoader({
    required this.fetchPage,
    this.include,
    this.session,
    this.sharedDedupGroup,
    this.maxPagesPerScan = 6,
  });

  Future<HomeLabDiscoveryLaneLoadResult> load(
    HomeLabDiscoverySection section,
  ) async {
    try {
      final paginator = HomeLabDiscoveryPaginator(
        query: section.query,
        fetchPage: fetchPage,
        minimumMatchesPerLoad: section.previewLimit,
        maxPagesPerScan: maxPagesPerScan,
        include: include == null ? null : (item) => include!(section, item),
      );
      final window = await paginator.loadNext();
      var items = window.items
          .take(section.previewLimit)
          .toList(growable: false);

      if (section.sessionDedup && session != null && items.isNotEmpty) {
        items = session!.filterFresh<SeerrDiscoverItem>(
          group: section.dedupGroup,
          sharedGroup: sharedDedupGroup,
          items: items,
          identity: (item) =>
              '${item.mediaType ?? section.query.mediaType}:${item.id}',
          minimumRetained: section.minItems,
        );
      }

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
}
