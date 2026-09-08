import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/data/services/seerr/seerr_api_models.dart';
import 'package:moonfin/features/homelab_discovery/catalogue/discovery_catalogue.dart';
import 'package:moonfin/features/homelab_discovery/data/discovery_lane_loader.dart';
import 'package:moonfin/features/homelab_discovery/engine/discovery_tab_controller.dart';

HomeLabDiscoverySection section(String id) => HomeLabDiscoverySection(
  id: id,
  title: id,
  minItems: 1,
  previewLimit: 4,
  priority: HomeLabDiscoveryPriority.anchor,
  query: const HomeLabDiscoveryQuery(
    source: HomeLabDiscoverySource.discoverMovies,
    mediaType: 'movie',
  ),
);

void main() {
  test('ineligible sections never enter composition or lane I/O', () async {
    final allowed = section('allowed');
    final blocked = section('blocked');
    final loadedIds = <String>[];
    final controller = HomeLabDiscoveryTabController(
      tab: HomeLabDiscoveryTab(
        id: 'test',
        title: 'Test',
        sections: [blocked, allowed],
        initialLaneBudget: 2,
        minimumLaneCount: 1,
      ),
      sessionSeed: 'server:user',
      isSectionEligible: (candidate) => candidate.id != blocked.id,
      loadLane: (candidate) async {
        loadedIds.add(candidate.id);
        return HomeLabDiscoveryLaneLoadResult(
          section: candidate,
          items: const [
            SeerrDiscoverItem(id: 1, mediaType: 'movie', title: 'One'),
          ],
          throughPage: 1,
          totalPages: 1,
        );
      },
    );

    final result = await controller.load();

    expect(result.selectedSections.map((value) => value.id), ['allowed']);
    expect(loadedIds, ['allowed']);
    expect(result.usableLanes.map((value) => value.section.id), ['allowed']);
    expect(result.failedLanes, isEmpty);
  });
}
