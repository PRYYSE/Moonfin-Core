import 'package:flutter/foundation.dart';

import '../../preference/seerr_preferences.dart';
import '../repositories/seerr_repository.dart';
import '../services/seerr/seerr_api_models.dart';
import '../services/seerr/seerr_discovery_availability_policy.dart';
import '../services/seerr/seerr_discovery_catalogue_loader.dart';
import '../services/seerr/seerr_discovery_catalogue_service.dart';
import '../services/seerr/seerr_discovery_composer.dart';
import '../services/seerr/seerr_discovery_configured_lists_service.dart';
import '../services/seerr/seerr_discovery_lane_loader.dart';
import '../services/seerr/seerr_discovery_personalisation_service.dart';
import '../services/seerr/seerr_discovery_rotation_history.dart';
import '../services/seerr/seerr_discovery_schema.dart';
import '../services/seerr/seerr_discovery_session.dart';
import '../utils/bounded_concurrency.dart';

typedef SeerrDeepCatalogueLoader =
    Future<SeerrDiscoveryCatalogueLoadResult> Function();
typedef SeerrDeepPageFetcher =
    Future<SeerrDiscoverPage> Function(SeerrDiscoveryQuery query, int page);
typedef SeerrDeepPersonalFetcher =
    Future<SeerrDiscoveryPersonalPage> Function(
      SeerrDiscoverySection section,
      int page, {
      bool forceRefresh,
    });
typedef SeerrDeepSeedLoader = Future<String> Function();
typedef SeerrDeepBlockNsfw = bool Function();
typedef SeerrDeepCatalogueMerger =
    SeerrDiscoveryCatalogue Function(SeerrDiscoveryCatalogue catalogue);
typedef SeerrDeepExternalFetcher =
    Future<SeerrDiscoverPage> Function(
      SeerrDiscoverySection section,
      int page, {
      bool forceRefresh,
    });
typedef SeerrDeepExternalClearer = void Function();

class SeerrDeepDiscoveryRow {
  final SeerrDiscoverySection section;
  final String title;
  final List<SeerrDiscoverItem> items;
  final bool isLoading;
  final String? error;
  final int page;
  final int totalPages;

  const SeerrDeepDiscoveryRow({
    required this.section,
    required this.title,
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.totalPages = 1,
  });

  bool get hasMore => page < totalPages;
  bool get isPersonalised =>
      section.query.source == SeerrDiscoverySource.personalised;
  bool get canExpand =>
      section.expandable &&
      section.query.source != SeerrDiscoverySource.externalList;

  SeerrDeepDiscoveryRow copyWith({
    String? title,
    List<SeerrDiscoverItem>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? page,
    int? totalPages,
  }) => SeerrDeepDiscoveryRow(
    section: section,
    title: title ?? this.title,
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
  );
}

/// Shared deep-Discovery product state for Web, Android phone/tablet and
/// Android TV. Platform widgets remain responsible for layout/focus only.
class SeerrDeepDiscoveryViewModel extends ChangeNotifier {
  static const int _laneConcurrency = 3;

  static const _nsfwKeywords = <String>[
    r'\bsex\b',
    'sexual',
    r'\bporn\b',
    'erotic',
    r'\bnude\b',
    'nudity',
    r'\bxxx\b',
    'adult film',
    'prostitute',
    'stripper',
    r'\bescort\b',
    'seduction',
    r'\baffair\b',
    'threesome',
    r'\borgy\b',
    'kinky',
    'fetish',
    r'\bbdsm\b',
    'dominatrix',
  ];
  static final _nsfwPatterns = _nsfwKeywords
      .map((keyword) => RegExp(keyword, caseSensitive: false))
      .toList(growable: false);

  final SeerrDeepCatalogueLoader _loadCatalogue;
  final SeerrDeepPageFetcher _fetchPage;
  final SeerrDeepPersonalFetcher _fetchPersonal;
  final SeerrDeepSeedLoader _loadSessionSeed;
  final SeerrDeepBlockNsfw _blockNsfw;
  final SeerrDeepCatalogueMerger _mergeCatalogue;
  final SeerrDeepExternalFetcher _fetchExternal;
  final SeerrDeepExternalClearer _clearExternal;
  final SeerrDiscoveryComposer _composer;

  SeerrDiscoveryCatalogue? _catalogue;
  SeerrDiscoveryCatalogue? get catalogue => _catalogue;
  SeerrDiscoveryCatalogueSource? _catalogueSource;
  SeerrDiscoveryCatalogueSource? get catalogueSource => _catalogueSource;

  String? _activeTabId;
  String? get activeTabId => _activeTabId;
  List<SeerrDiscoveryTab> get tabs => _catalogue?.tabs ?? const [];
  SeerrDiscoveryTab? get activeTab {
    final id = _activeTabId;
    if (id == null) return null;
    for (final tab in tabs) {
      if (tab.id == id) return tab;
    }
    return null;
  }

  List<SeerrDeepDiscoveryRow> _rows = const [];
  List<SeerrDeepDiscoveryRow> get rows => _rows;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  String _sessionSeed = 'moonfin-discovery';
  int _refreshNonce = 0;
  int _generation = 0;
  final Map<String, SeerrDiscoverySession> _sessions = {};
  final Map<String, SeerrDiscoveryRotationHistory> _rotationHistory = {};

  SeerrDeepDiscoveryViewModel({
    required SeerrDiscoveryCatalogueService catalogueService,
    required SeerrRepository repository,
    required SeerrDiscoveryPersonalisationService personalisation,
    required SeerrDiscoveryConfiguredListsService configuredLists,
    required SeerrPreferences preferences,
    required String serverId,
    SeerrDiscoveryComposer composer = const SeerrDiscoveryComposer(),
  }) : _loadCatalogue = catalogueService.load,
       _fetchPage = ((query, page) =>
           repository.executeDiscoveryQuery(query, page: page)),
       _fetchPersonal = ((section, page, {forceRefresh = false}) =>
           personalisation.load(
             section,
             page: page,
             forceRefresh: forceRefresh,
           )),
       _loadSessionSeed = (() async {
         try {
           final user = await repository.getCurrentUser();
           return '$serverId|seerr:${user.id}';
         } catch (_) {
           return serverId;
         }
       }),
       _blockNsfw = (() => preferences.blockNsfw),
       _mergeCatalogue = configuredLists.mergeIntoCatalogue,
       _fetchExternal = ((section, page, {forceRefresh = false}) =>
           configuredLists.load(
             section,
             page: page,
             forceRefresh: forceRefresh,
           )),
       _clearExternal = configuredLists.clear,
       _composer = composer;

  SeerrDeepDiscoveryViewModel.forTesting({
    required SeerrDeepCatalogueLoader loadCatalogue,
    required SeerrDeepPageFetcher fetchPage,
    required SeerrDeepPersonalFetcher fetchPersonal,
    required SeerrDeepSeedLoader loadSessionSeed,
    SeerrDeepBlockNsfw blockNsfw = _neverBlockNsfw,
    SeerrDeepCatalogueMerger mergeCatalogue = _identityCatalogue,
    SeerrDeepExternalFetcher fetchExternal = _unsupportedExternal,
    SeerrDeepExternalClearer clearExternal = _noopExternalClear,
    SeerrDiscoveryComposer composer = const SeerrDiscoveryComposer(),
  }) : _loadCatalogue = loadCatalogue,
       _fetchPage = fetchPage,
       _fetchPersonal = fetchPersonal,
       _loadSessionSeed = loadSessionSeed,
       _blockNsfw = blockNsfw,
       _mergeCatalogue = mergeCatalogue,
       _fetchExternal = fetchExternal,
       _clearExternal = clearExternal,
       _composer = composer;

  static bool _neverBlockNsfw() => false;

  static SeerrDiscoveryCatalogue _identityCatalogue(
    SeerrDiscoveryCatalogue catalogue,
  ) => catalogue;

  static Future<SeerrDiscoverPage> _unsupportedExternal(
    SeerrDiscoverySection section,
    int page, {
    bool forceRefresh = false,
  }) async => throw StateError('External Discovery list is not configured');

  static void _noopExternalClear() {}

  Future<void> load() async {
    final generation = ++_generation;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _loadCatalogue();
      if (generation != _generation) return;
      _catalogue = _mergeCatalogue(result.catalogue);
      _catalogueSource = result.source;
      _sessionSeed = await _loadSessionSeed();
      if (generation != _generation) return;

      final existing = _activeTabId;
      _activeTabId = tabs.any((tab) => tab.id == existing)
          ? existing
          : _defaultTabId();
      await _loadActiveTab(generation: generation);
    } catch (exception) {
      if (generation != _generation) return;
      _error = exception.toString();
      debugPrint('[SeerrDeepDiscovery] Load failed: $exception');
      _rows = const [];
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectTab(String tabId) async {
    if (_activeTabId == tabId || !tabs.any((tab) => tab.id == tabId)) return;
    final generation = ++_generation;
    _activeTabId = tabId;
    _error = null;
    _rows = const [];
    _isLoading = true;
    notifyListeners();
    try {
      await _loadActiveTab(generation: generation);
    } catch (exception) {
      if (generation != _generation) return;
      _error = exception.toString();
      debugPrint('[SeerrDeepDiscovery] Tab load failed: $exception');
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    _refreshNonce++;
    _clearExternal();
    final generation = ++_generation;
    _sessions[_activeTabId]?.reset();
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _loadCatalogue();
      if (generation != _generation) return;
      _catalogue = _mergeCatalogue(result.catalogue);
      _catalogueSource = result.source;
      if (!tabs.any((tab) => tab.id == _activeTabId)) {
        _activeTabId = _defaultTabId();
      }
      await _loadActiveTab(generation: generation, forcePersonalRefresh: true);
    } catch (exception) {
      if (generation != _generation) return;
      _error = exception.toString();
      debugPrint('[SeerrDeepDiscovery] Refresh failed: $exception');
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore(int rowIndex) async {
    if (rowIndex < 0 || rowIndex >= _rows.length) return;
    final row = _rows[rowIndex];
    if (!row.hasMore || row.isLoading) return;

    final generation = _generation;
    _rows = List<SeerrDeepDiscoveryRow>.of(_rows);
    _rows[rowIndex] = row.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final nextPage = row.page + 1;
      final SeerrDiscoverPage page;
      if (row.isPersonalised) {
        page = (await _fetchPersonal(row.section, nextPage)).page;
      } else if (row.section.query.source ==
          SeerrDiscoverySource.externalList) {
        page = await _fetchExternal(row.section, nextPage);
      } else {
        page = await _fetchPage(row.section.query, nextPage);
      }
      if (generation != _generation) return;

      final existing = <String>{
        for (final item in row.items) _identity(row.section, item),
      };
      final additions = page.results
          .where((item) => _include(row.section, item))
          .where((item) => existing.add(_identity(row.section, item)))
          .toList(growable: false);
      _rows = List<SeerrDeepDiscoveryRow>.of(_rows);
      _rows[rowIndex] = row.copyWith(
        items: [...row.items, ...additions],
        isLoading: false,
        page: page.page,
        totalPages: page.totalPages,
        clearError: true,
      );
    } catch (exception) {
      if (generation != _generation) return;
      _rows = List<SeerrDeepDiscoveryRow>.of(_rows);
      _rows[rowIndex] = row.copyWith(
        isLoading: false,
        error: exception.toString(),
      );
      debugPrint(
        '[SeerrDeepDiscovery] Load more failed for ${row.section.id}: $exception',
      );
    }
    notifyListeners();
  }

  String? _defaultTabId() {
    if (tabs.isEmpty) return null;
    if (tabs.any((tab) => tab.id == 'for-you')) return 'for-you';
    return tabs.first.id;
  }

  Future<void> _loadActiveTab({
    required int generation,
    bool forcePersonalRefresh = false,
  }) async {
    final tab = activeTab;
    if (tab == null) {
      _rows = const [];
      return;
    }

    final history = _rotationHistory.putIfAbsent(
      tab.id,
      SeerrDiscoveryRotationHistory.new,
    );
    final sections = _composer.compose(
      tab,
      sessionSeed: '$_sessionSeed|${tab.id}',
      refreshNonce: _refreshNonce,
      sessionsSinceSeen: history.sessionsSinceSeen,
    );
    if (generation != _generation) return;

    _rows = sections
        .map(
          (section) => SeerrDeepDiscoveryRow(
            section: section,
            title: section.title,
            isLoading: true,
          ),
        )
        .toList(growable: false);
    notifyListeners();

    final loaded =
        await mapBounded<SeerrDiscoverySection, SeerrDeepDiscoveryRow?>(
          sections,
          _laneConcurrency,
          (section) =>
              _loadSection(section, forcePersonalRefresh: forcePersonalRefresh),
        );
    if (generation != _generation) return;

    final session = _sessions.putIfAbsent(tab.id, SeerrDiscoverySession.new);
    final rendered = <SeerrDeepDiscoveryRow>[];
    for (final candidate in loaded.whereType<SeerrDeepDiscoveryRow>()) {
      if (candidate.error != null) {
        if (candidate.section.isAnchor) rendered.add(candidate);
        continue;
      }
      var items = candidate.items;
      if (candidate.section.sessionDedup && items.isNotEmpty) {
        items = session.filterFresh<SeerrDiscoverItem>(
          group: candidate.section.dedupGroup,
          sharedGroup: 'tab:${tab.id}',
          items: items,
          identity: (item) => _identity(candidate.section, item),
          minimumRetained: candidate.section.minItems,
        );
      }
      if (items.length < candidate.section.minItems) continue;
      rendered.add(candidate.copyWith(items: items));
    }

    _rows = rendered;
    history.commitSession(
      rendered.where((row) => row.error == null).map((row) => row.section.id),
    );
    notifyListeners();
  }

  Future<SeerrDeepDiscoveryRow?> _loadSection(
    SeerrDiscoverySection section, {
    required bool forcePersonalRefresh,
  }) async {
    if (section.query.source == SeerrDiscoverySource.externalList) {
      try {
        final page = await _fetchExternal(section, 1);
        final items = page.results
            .where((item) => _include(section, item))
            .toList(growable: false);
        if (items.length < section.minItems) return null;
        return SeerrDeepDiscoveryRow(
          section: section,
          title: section.title,
          items: items.take(section.previewLimit).toList(growable: false),
          page: page.page,
          totalPages: page.totalPages,
        );
      } catch (exception) {
        return SeerrDeepDiscoveryRow(
          section: section,
          title: section.title,
          error: exception.toString(),
        );
      }
    }

    if (section.query.source == SeerrDiscoverySource.personalised) {
      try {
        final personal = await _fetchPersonal(
          section,
          1,
          forceRefresh: forcePersonalRefresh,
        );
        final items = personal.page.results
            .where((item) => _include(section, item))
            .toList(growable: false);
        if (items.length < section.minItems) return null;
        return SeerrDeepDiscoveryRow(
          section: section,
          title: personal.title,
          items: items.take(section.previewLimit).toList(growable: false),
          page: personal.page.page,
          totalPages: personal.page.totalPages,
        );
      } catch (exception) {
        return SeerrDeepDiscoveryRow(
          section: section,
          title: section.title,
          error: exception.toString(),
        );
      }
    }

    final laneLoader = SeerrDiscoveryLaneLoader(
      fetchPage: _fetchPage,
      include: (candidateSection, item) => _include(candidateSection, item),
      maxPagesPerScan: 6,
    );
    final result = await laneLoader.load(section);
    if (result.hasError) {
      return SeerrDeepDiscoveryRow(
        section: section,
        title: section.title,
        error: result.error.toString(),
      );
    }
    if (!result.isUsable) return null;
    return SeerrDeepDiscoveryRow(
      section: section,
      title: section.title,
      items: result.items,
      page: result.throughPage <= 0 ? 1 : result.throughPage,
      totalPages: result.totalPages <= 0 ? 1 : result.totalPages,
    );
  }

  bool _include(SeerrDiscoverySection section, SeerrDiscoverItem item) {
    if (!SeerrDiscoveryAvailabilityPolicy.include(
      item,
      section.availabilityMode,
    )) {
      return false;
    }
    if (_blockNsfw() && _isNsfw(item)) return false;
    return true;
  }

  bool _isNsfw(SeerrDiscoverItem item) {
    if (item.adult) return true;
    final text = '${item.displayTitle} ${item.overview ?? ''}';
    return _nsfwPatterns.any((pattern) => pattern.hasMatch(text));
  }

  String _identity(SeerrDiscoverySection section, SeerrDiscoverItem item) {
    final type = item.mediaType?.isNotEmpty == true
        ? item.mediaType!
        : section.query.mediaType;
    return '$type:${item.id}';
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
