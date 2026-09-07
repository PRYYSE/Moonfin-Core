import '../../../data/utils/bounded_concurrency.dart';
import '../catalogue/discovery_catalogue.dart';
import '../data/discovery_lane_loader.dart';
import 'discovery_composer.dart';
import 'discovery_rotation_history.dart';
import 'discovery_session.dart';
import 'discovery_tab_presentation.dart';

typedef HomeLabDiscoveryLaneLoad =
    Future<HomeLabDiscoveryLaneLoadResult> Function(
      HomeLabDiscoverySection section,
    );

typedef HomeLabDiscoveryRotationPersist = Future<void> Function();

class HomeLabDiscoveryTabLoadResult {
  final List<HomeLabDiscoverySection> selectedSections;
  final List<HomeLabDiscoveryLaneLoadResult> lanes;

  const HomeLabDiscoveryTabLoadResult({
    required this.selectedSections,
    required this.lanes,
  });

  List<HomeLabDiscoveryLaneLoadResult> get usableLanes =>
      lanes.where((lane) => lane.isUsable).toList(growable: false);

  List<HomeLabDiscoveryLaneLoadResult> get failedLanes =>
      lanes.where((lane) => lane.hasError).toList(growable: false);

  List<HomeLabDiscoveryLaneLoadResult> get hiddenLanes =>
      lanes.where((lane) => lane.shouldHide).toList(growable: false);
}

/// Coordinates one Discovery tab without coupling data loading to Flutter UI.
///
/// Selection is deterministic. Lane I/O is bounded and concurrent, but every
/// result is keyed by section ID and all cross-row/session presentation is
/// applied only after the concurrent work completes, in selected catalogue
/// order. Rotation cooldown state is committed only for rows that actually
/// surfaced and may be persisted independently of content/session novelty.
class HomeLabDiscoveryTabController {
  final HomeLabDiscoveryTab tab;
  final HomeLabDiscoveryLaneLoad loadLane;
  final String sessionSeed;
  final HomeLabDiscoveryComposer composer;
  final HomeLabDiscoverySession session;
  final HomeLabDiscoveryRotationHistory rotationHistory;
  final HomeLabDiscoveryRotationPersist? persistRotationHistory;
  final String sharedDedupGroup;
  final int maxConcurrentLoads;

  int _refreshNonce = 0;

  HomeLabDiscoveryTabController({
    required this.tab,
    required this.loadLane,
    required this.sessionSeed,
    HomeLabDiscoveryComposer? composer,
    HomeLabDiscoverySession? session,
    HomeLabDiscoveryRotationHistory? rotationHistory,
    this.persistRotationHistory,
    String? sharedDedupGroup,
    int maxConcurrentLoads = 6,
  }) : composer = composer ?? const HomeLabDiscoveryComposer(),
       session = session ?? HomeLabDiscoverySession(),
       rotationHistory = rotationHistory ?? HomeLabDiscoveryRotationHistory(),
       sharedDedupGroup = sharedDedupGroup ?? 'tab:${tab.id}',
       maxConcurrentLoads = maxConcurrentLoads < 1 ? 1 : maxConcurrentLoads;

  int get refreshNonce => _refreshNonce;

  Future<HomeLabDiscoveryTabLoadResult> load({bool rotate = false}) async {
    if (rotate) _refreshNonce++;

    final selected = composer.compose(
      tab,
      sessionSeed: sessionSeed,
      refreshNonce: _refreshNonce,
      sessionsSinceSeen: rotationHistory.sessionsSinceSeen,
    );
    final resultsBySectionId = <String, HomeLabDiscoveryLaneLoadResult>{};

    await mapBounded<HomeLabDiscoverySection, bool>(
      selected,
      maxConcurrentLoads,
      (section) async {
        try {
          resultsBySectionId[section.id] = await loadLane(section);
        } catch (error) {
          resultsBySectionId[section.id] = HomeLabDiscoveryLaneLoadResult(
            section: section,
            error: error,
          );
        }
        return true;
      },
    );

    final lanes = HomeLabDiscoveryTabPresentation.composeSections(
      selected,
      resultsBySectionId,
      session: session,
      sharedDedupGroup: sharedDedupGroup,
    );
    rotationHistory.commitSession(
      lanes.where((lane) => lane.isUsable).map((lane) => lane.section.id),
    );
    await _persistRotationHistory();

    return HomeLabDiscoveryTabLoadResult(
      selectedSections: List.unmodifiable(selected),
      lanes: lanes,
    );
  }

  Future<HomeLabDiscoveryTabLoadResult> refresh() => load(rotate: true);

  void resetSession() {
    _refreshNonce = 0;
    rotationHistory.clear();
    session.reset();
  }

  Future<void> _persistRotationHistory() async {
    final persist = persistRotationHistory;
    if (persist == null) return;
    try {
      await persist();
    } catch (_) {
      // Optional novelty persistence must never fail the Discovery tab load.
    }
  }
}
