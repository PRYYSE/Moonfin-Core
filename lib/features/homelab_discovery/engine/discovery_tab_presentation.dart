import '../catalogue/discovery_catalogue.dart';
import '../data/discovery_lane_loader.dart';
import 'discovery_personal_presentation.dart';

/// Applies cross-row presentation policy after all lane loads have completed.
///
/// Results are consumed in catalogue order, never completion/insertion order.
/// This keeps personalised row titles and family diversity deterministic even
/// when lane requests finish concurrently in a different order each session.
abstract final class HomeLabDiscoveryTabPresentation {
  static List<HomeLabDiscoveryLaneLoadResult> compose(
    HomeLabDiscoveryTab tab,
    Map<String, HomeLabDiscoveryLaneLoadResult> resultsBySectionId,
  ) {
    final usedPersonalTitles = <String>{};
    final surfacedPersonalFamilies = <String>{};
    final presented = <HomeLabDiscoveryLaneLoadResult>[];

    for (final section in tab.sections) {
      final result = resultsBySectionId[section.id];
      if (result == null) continue;

      if (section.query.source != HomeLabDiscoverySource.personalised ||
          result.hasError ||
          result.items.isEmpty) {
        presented.add(result);
        continue;
      }

      final title = HomeLabDiscoveryPersonalPresentation.displayTitle(
        section,
        result.displayTitle,
        usedTitles: usedPersonalTitles,
      );
      final items = HomeLabDiscoveryPersonalPresentation.diversifyPreview(
        result.items,
        minimumRetained: section.minItems,
        previouslySurfacedFamilies: surfacedPersonalFamilies,
      );

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
