import '../../../data/services/seerr/seerr_api_models.dart';
import '../bridge/moonfin_discovery_bridge.dart';
import '../catalogue/discovery_catalogue.dart';
import '../engine/discovery_personalisation.dart';
import 'discovery_paginator.dart';

typedef HomeLabDiscoveryLanePredicate =
    bool Function(HomeLabDiscoverySection section, SeerrDiscoverItem item);

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

/// Fetches one Discovery lane without mutating cross-row presentation state.
///
/// Lane loads may run concurrently. Session novelty, shared deduplication and
/// personalised title/family presentation therefore belong to the deterministic
/// post-fetch tab presentation stage, not here.
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

  Future<HomeLabDiscoveryLaneLoadResult> _loadPersonalised(
    HomeLabDiscoverySection section,
  ) async {
    final service = personalisation;
    if (service == null) {
      throw StateError('Personalised Discovery service is unavailable');
    }

    final loaded = await service.load(section);
    final items = loaded.page.results
        .where((item) => include?.call(section, item) ?? true)
        .take(section.previewLimit)
        .toList(growable: false);

    return HomeLabDiscoveryLaneLoadResult(
      section: section,
      displayTitle: loaded.title,
      items: items,
      throughPage: loaded.page.page,
      totalPages: loaded.page.totalPages,
    );
  }
}
