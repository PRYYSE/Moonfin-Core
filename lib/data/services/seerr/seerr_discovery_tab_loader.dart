import '../../utils/bounded_concurrency.dart';
import 'seerr_discovery_lane_loader.dart';
import 'seerr_discovery_schema.dart';

class SeerrDiscoveryTabLoadResult {
  /// Usable lanes plus failed anchors, in catalogue/session order.
  /// Failed anchors remain renderable so the UI can offer a compact retry.
  final List<SeerrDiscoveryLaneLoadResult> rendered;

  /// Failed optional lanes are isolated and normally omitted from the landing
  /// page rather than turning the whole tab into an error state.
  final List<SeerrDiscoveryLaneLoadResult> failedOptional;

  /// Successful but too-shallow optional lanes.
  final List<SeerrDiscoveryLaneLoadResult> hiddenShallow;

  const SeerrDiscoveryTabLoadResult({
    required this.rendered,
    required this.failedOptional,
    required this.hiddenShallow,
  });

  bool get hasAnchorFailure =>
      rendered.any((result) => result.section.isAnchor && result.hasError);
  int get usableLaneCount => rendered.where((result) => result.isUsable).length;
}

/// Loads one composed landing tab with bounded upstream concurrency.
class SeerrDiscoveryTabLoader {
  final SeerrDiscoveryLaneLoader laneLoader;
  final int concurrency;

  const SeerrDiscoveryTabLoader({
    required this.laneLoader,
    this.concurrency = 3,
  }) : assert(concurrency > 0);

  Future<SeerrDiscoveryTabLoadResult> load(
    List<SeerrDiscoverySection> sections,
  ) async {
    if (sections.isEmpty) {
      return const SeerrDiscoveryTabLoadResult(
        rendered: [],
        failedOptional: [],
        hiddenShallow: [],
      );
    }

    final results =
        await mapBounded<SeerrDiscoverySection, SeerrDiscoveryLaneLoadResult>(
          sections,
          concurrency,
          laneLoader.load,
        );

    final rendered = <SeerrDiscoveryLaneLoadResult>[];
    final failedOptional = <SeerrDiscoveryLaneLoadResult>[];
    final hiddenShallow = <SeerrDiscoveryLaneLoadResult>[];

    for (final result in results) {
      if (result == null) continue;
      if (result.hasError) {
        if (result.section.isAnchor) {
          rendered.add(result);
        } else {
          failedOptional.add(result);
        }
      } else if (result.isUsable) {
        rendered.add(result);
      } else {
        hiddenShallow.add(result);
      }
    }

    return SeerrDiscoveryTabLoadResult(
      rendered: rendered,
      failedOptional: failedOptional,
      hiddenShallow: hiddenShallow,
    );
  }
}
