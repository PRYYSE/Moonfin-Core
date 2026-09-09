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
typedef HomeLabDiscoverySectionEligibility =
    bool Function(HomeLabDiscoverySection section);

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
  final HomeLabDiscoverySectionEligibility? isSectionEligible;
  final String sharedDedupGroup;
  final int maxConcurrentLoads;

  int _refreshNonce = 0;
  HomeLabDiscoveryTabLoadResult? _cachedResult;
  Future<HomeLabDiscoveryTabLoadResult>? _inFlightLoad;

  HomeLabDiscoveryTabController({
    required this.tab,
    required this.loadLane,
    required this.sessionSeed,
    HomeLabDiscoveryComposer? composer,
    HomeLabDiscoverySession? session,
    HomeLabDiscoveryRotationHistory? rotationHistory,
    this.persistRotationHistory,
    this.isSectionEligible,
    String? sharedDedupGroup,
    int maxConcurrentLoads = 6,
  }) : composer = composer ?? const HomeLabDiscoveryComposer(),
       session = session ?? HomeLabDiscoverySession(),
       rotationHistory = rotationHistory ?? HomeLabDiscoveryRotationHistory(),
       sharedDedupGroup = sharedDedupGroup ?? 'tab:${tab.id}',
       maxConcurrentLoads = maxConcurrentLoads < 1 ? 1 : maxConcurrentLoads;

  int get refreshNonce => _refreshNonce;

  /// Returns retained tab data on ordinary rebuilds/resume instead of turning
  /// widget recycling into another recommendation load. Concurrent callers
  /// share the same in-flight work. Explicit refresh still rotates the lane
  /// selection; failed results are deliberately not cached so Retry can heal.
  Future<HomeLabDiscoveryTabLoadResult> load({bool rotate = false}) {
    if (rotate) {
      final active = _inFlightLoad;
      if (active != null) {
        return active.then((_) => load(rotate: true));
      }
      _refreshNonce++;
      _cachedResult = null;
      return _loadFresh();
    }

    final cached = _cachedResult;
    if (cached != null) return Future.value(cached);
    return _loadFresh();
  }

  Future<HomeLabDiscoveryTabLoadResult> _loadFresh() {
    final active = _inFlightLoad;
    if (active != null) return active;

    late final Future<HomeLabDiscoveryTabLoadResult> future;
    future = _performLoad()
        .then((result) {
          if (result.failedLanes.isEmpty) _cachedResult = result;
          return result;
        })
        .whenComplete(() {
          if (identical(_inFlightLoad, future)) _inFlightLoad = null;
        });
    _inFlightLoad = future;
    return future;
  }

  Future<HomeLabDiscoveryTabLoadResult> _performLoad() async {
    final selected = composer.compose(
      tab,
      sessionSeed: sessionSeed,
      refreshNonce: _refreshNonce,
      sessionsSinceSeen: rotationHistory.sessionsSinceSeen,
      isEligible: isSectionEligible,
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

  Future<void> resetSession() async {
    final active = _inFlightLoad;
    if (active != null) {
      try {
        await active;
      } catch (_) {
        // A failed in-flight load must not prevent an explicit session reset.
      }
    }
    _refreshNonce = 0;
    _cachedResult = null;
    rotationHistory.clear();
    session.reset();
    await _persistRotationHistory();
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
