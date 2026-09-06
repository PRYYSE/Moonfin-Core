import '../../../data/services/seerr/seerr_api_models.dart';
import '../bridge/moonfin_discovery_bridge.dart';
import '../catalogue/discovery_catalogue.dart';
import '../engine/discovery_personal_presentation.dart';
import '../engine/discovery_personalisation.dart';
import '../engine/discovery_session.dart';
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

  const HomeLabDiscoveryLaneLoadResult({
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

class HomeLabDiscoveryLaneLoader {
  final HomeLabDiscoveryPageFetcher fetchPage;
  final HomeLabDiscoveryLanePredicate? include;
  final HomeLabDiscoverySession? session;
  final String? sharedDedupGroup;
  final HomeLabDiscoveryPersonalisation? personalisation;
  final Set<String>? personalUsedTitles;
  final Set<String>? personalSurfacedFamilies;
  final int maxPagesPerScan;

  const HomeLabDiscoveryLaneLoader({
    required this.fetchPage,
    this.include,
    this.session,
    this.sharedDedupGroup,
    this.personalisation,
    this.personalUsedTitles,
    this.personalSurfacedFamilies,
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
      var items = window.items
          .take(section.previewLimit)
          .toList(growable: false);
      items = _applySessionDedup(section, items);

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
    var items = loaded.page.results
        .where((item) => include?.call(section, item) ?? true)
        .take(section.previewLimit)
        .toList(growable: false);
    items = _applySessionDedup(section, items);

    final families = personalSurfacedFamilies;
    if (families != null && items.isNotEmpty) {
      items = HomeLabDiscoveryPersonalPresentation.diversifyPreview(
        items,
        minimumRetained: section.minItems,
        previouslySurfacedFamilies: families,
      );
    }

    final title = HomeLabDiscoveryPersonalPresentation.displayTitle(
      section,
      loaded.title,
      usedTitles: personalUsedTitles ?? <String>{},
    );

    return HomeLabDiscoveryLaneLoadResult(
      section: section,
      displayTitle: title,
      items: items,
      throughPage: loaded.page.page,
      totalPages: loaded.page.totalPages,
    );
  }

  List<SeerrDiscoverItem> _applySessionDedup(
    HomeLabDiscoverySection section,
    List<SeerrDiscoverItem> items,
  ) {
    if (!section.sessionDedup || session == null || items.isEmpty) return items;
    return session!.filterFresh<SeerrDiscoverItem>(
      group: section.dedupGroup,
      sharedGroup: sharedDedupGroup,
      items: items,
      identity: (item) =>
          '${item.mediaType ?? section.query.mediaType}:${item.id}',
      minimumRetained: section.minItems,
    );
  }
}
