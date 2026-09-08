import '../../../ui/navigation/destinations.dart';
import '../catalogue/discovery_catalogue.dart';
import '../engine/discovery_see_all_controller.dart';

abstract final class HomeLabDiscoveryRoutes {
  static const sectionQueryParameter = 'section';

  static String section(String sectionId) {
    return Uri(
      path: Destinations.seerrDiscover,
      queryParameters: {sectionQueryParameter: sectionId},
    ).toString();
  }

  static String? sectionId(Uri? uri) {
    if (uri == null || uri.path != Destinations.seerrDiscover) return null;
    final value = uri.queryParameters[sectionQueryParameter]?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}

class HomeLabDiscoverySeeAllRoutePayload {
  final String sectionId;
  final HomeLabDiscoveryCatalogue catalogue;
  final HomeLabDiscoverySeeAllController controller;

  const HomeLabDiscoverySeeAllRoutePayload({
    required this.sectionId,
    required this.catalogue,
    required this.controller,
  });

  bool matches(String? candidateSectionId) =>
      candidateSectionId != null && candidateSectionId == sectionId;
}
