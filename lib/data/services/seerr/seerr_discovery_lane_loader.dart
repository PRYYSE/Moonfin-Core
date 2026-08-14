import 'seerr_api_models.dart';
import 'seerr_discovery_paginator.dart';
import 'seerr_discovery_schema.dart';
import 'seerr_discovery_session.dart';

typedef SeerrDiscoveryLanePredicate =
    bool Function(SeerrDiscoverySection section, SeerrDiscoverItem item);

class SeerrDiscoveryLaneLoadResult {
  final SeerrDiscoverySection section;
  final List<SeerrDiscoverItem> items;
  final int throughPage;
  final int totalPages;
  final Object? error;

  const SeerrDiscoveryLaneLoadResult({
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

/// Loads one landing-page lane without allowing it to affect its neighbours.
///
/// Source filtering happens first. Session novelty is then applied as a
/// preference, with [SeerrDiscoverySession] allowed to reintroduce repeats when
/// needed to retain a useful row. Expanded views intentionally bypass this
/// loader's session-dedup step and use [SeerrDiscoveryPaginator] directly.
class SeerrDiscoveryLaneLoader {
  final SeerrDiscoveryPageFetcher fetchPage;
  final SeerrDiscoveryLanePredicate? include;
  final SeerrDiscoverySession? session;
  final String? sharedDedupGroup;
  final int maxPagesPerScan;

  const SeerrDiscoveryLaneLoader({
    required this.fetchPage,
    this.include,
    this.session,
    this.sharedDedupGroup,
    this.maxPagesPerScan = 6,
  });

  Future<SeerrDiscoveryLaneLoadResult> load(
    SeerrDiscoverySection section,
  ) async {
    try {
      final paginator = SeerrDiscoveryPaginator(
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

      return SeerrDiscoveryLaneLoadResult(
        section: section,
        items: items,
        throughPage: window.throughPage,
        totalPages: window.totalPages,
      );
    } catch (error) {
      return SeerrDiscoveryLaneLoadResult(section: section, error: error);
    }
  }
}
