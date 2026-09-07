import '../../../data/services/seerr/seerr_api_models.dart';
import '../catalogue/discovery_catalogue.dart';
import '../data/discovery_lane_loader.dart';
import 'discovery_personal_presentation.dart';
import 'discovery_session.dart';

/// Applies cross-row presentation policy after all lane loads have completed.
///
/// Results are consumed in catalogue order, never completion/insertion order.
/// Session novelty, shared deduplication, personalised titles and family
/// diversity all live here so concurrent fetch timing cannot change the page.
abstract final class HomeLabDiscoveryTabPresentation {
  static List<HomeLabDiscoveryLaneLoadResult> compose(
    HomeLabDiscoveryTab tab,
    Map<String, HomeLabDiscoveryLaneLoadResult> resultsBySectionId, {
    HomeLabDiscoverySession? session,
    String? sharedDedupGroup,
  }) => composeSections(
    tab.sections,
    resultsBySectionId,
    session: session,
    sharedDedupGroup: sharedDedupGroup,
  );

  static List<HomeLabDiscoveryLaneLoadResult> composeSections(
    Iterable<HomeLabDiscoverySection> sections,
    Map<String, HomeLabDiscoveryLaneLoadResult> resultsBySectionId, {
    HomeLabDiscoverySession? session,
    String? sharedDedupGroup,
  }) {
    final usedPersonalTitles = <String>{};
    final surfacedPersonalFamilies = <String>{};
    final presented = <HomeLabDiscoveryLaneLoadResult>[];

    for (final section in sections) {
      final result = resultsBySectionId[section.id];
      if (result == null) continue;
      if (result.hasError || result.items.isEmpty) {
        presented.add(result);
        continue;
      }

      var items = result.items;
      if (section.sessionDedup && session != null) {
        items = session.filterFresh<SeerrDiscoverItem>(
          group: section.dedupGroup,
          sharedGroup: sharedDedupGroup,
          items: items,
          identity: (item) =>
              '${item.mediaType ?? section.query.mediaType}:${item.id}',
          minimumRetained: section.minItems,
        );
      }

      var title = result.displayTitle;
      if (section.query.source == HomeLabDiscoverySource.personalised) {
        title = HomeLabDiscoveryPersonalPresentation.displayTitle(
          section,
          title,
          usedTitles: usedPersonalTitles,
        );
        items = HomeLabDiscoveryPersonalPresentation.diversifyPreview(
          items,
          minimumRetained: section.minItems,
          previouslySurfacedFamilies: surfacedPersonalFamilies,
        );
      }

      final changed = title != result.displayTitle ||
          !identical(items, result.items);
      if (!changed) {
        presented.add(result);
        continue;
      }

      presented.add(
        HomeLabDiscoveryLaneLoadResult(
          section: result.section,
          displayTitle: title,
          items: items,
          throughPage: result.throughPage,
          totalPages: result.totalPages,
          error: result.error,
        ),
      );
    }

    return List.unmodifiable(presented);
  }
}
