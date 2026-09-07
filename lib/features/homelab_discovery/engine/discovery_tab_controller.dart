import '../catalogue/discovery_catalogue.dart';
import '../data/discovery_lane_loader.dart';
import 'discovery_composer.dart';
import 'discovery_session.dart';
import 'discovery_tab_presentation.dart';

typedef HomeLabDiscoveryLaneLoad =
    Future<HomeLabDiscoveryLaneLoadResult> Function(
      HomeLabDiscoverySection section,
    );

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
/// Selection is deterministic. Lane I/O is concurrent, but every result is
/// keyed by section ID and all cross-row/session presentation is applied only
/// after the concurrent work completes, in selected catalogue order.
class HomeLabDiscoveryTabController {
  final HomeLabDiscoveryTab tab;
  final HomeLabDiscoveryLaneLoad loadLane;
  final String sessionSeed;
  final HomeLabDiscoveryComposer composer;
  final HomeLabDiscoverySession session;
  final String sharedDedupGroup;

  final Map<String, int> _sessionsSinceSeen = <String, int>{};
  int _refreshNonce = 0;

  HomeLabDiscoveryTabController({
    required this.tab,
    required this.loadLane,
    required this.sessionSeed,
    HomeLabDiscoveryComposer? composer,
    HomeLabDiscoverySession? session,
    String? sharedDedupGroup,
  }) : composer = composer ?? const HomeLabDiscoveryComposer(),
       session = session ?? HomeLabDiscoverySession(),
       sharedDedupGroup = sharedDedupGroup ?? 'tab:${tab.id}';

  int get refreshNonce => _refreshNonce;

  Future<HomeLabDiscoveryTabLoadResult> load({bool rotate = false}) async {
    if (rotate) _refreshNonce++;

    final selected = composer.compose(
      tab,
      sessionSeed: sessionSeed,
      refreshNonce: _refreshNonce,
      sessionsSinceSeen: Map.unmodifiable(_sessionsSinceSeen),
    );
    final resultsBySectionId = <String, HomeLabDiscoveryLaneLoadResult>{};

    await Future.wait(
      selected.map((section) async {
        try {
          resultsBySectionId[section.id] = await loadLane(section);
        } catch (error) {
          resultsBySectionId[section.id] = HomeLabDiscoveryLaneLoadResult(
            section: section,
            error: error,
          );
        }
      }),
    );

    final lanes = HomeLabDiscoveryTabPresentation.composeSections(
      selected,
      resultsBySectionId,
      session: session,
      sharedDedupGroup: sharedDedupGroup,
    );
    _advanceSelectionHistory(selected);

    return HomeLabDiscoveryTabLoadResult(
      selectedSections: List.unmodifiable(selected),
      lanes: lanes,
    );
  }

  Future<HomeLabDiscoveryTabLoadResult> refresh() => load(rotate: true);

  void resetSession() {
    _refreshNonce = 0;
    _sessionsSinceSeen.clear();
    session.reset();
  }

  void _advanceSelectionHistory(List<HomeLabDiscoverySection> selected) {
    for (final id in _sessionsSinceSeen.keys.toList(growable: false)) {
      _sessionsSinceSeen[id] = _sessionsSinceSeen[id]! + 1;
    }
    for (final section in selected) {
      _sessionsSinceSeen[section.id] = 0;
    }
  }
}
