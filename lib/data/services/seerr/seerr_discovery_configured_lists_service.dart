import 'dart:convert';

import '../../../preference/home_section_config.dart';
import '../../../preference/user_preferences.dart';
import '../custom_external_lists_service.dart';
import 'seerr_api_models.dart';
import 'seerr_discovery_schema.dart';

typedef SeerrDiscoveryConfiguredListReader = List<HomeSectionConfig> Function();
typedef SeerrDiscoveryConfiguredListFetcher =
    Future<List<ImdbExternalListItem>> Function(
      HomeSectionConfig config, {
      bool forceRefresh,
    });

/// Bridges Moonfin's existing user-configured external rows into deep Discovery.
///
/// The existing Home configuration remains authoritative. This service only
/// imports enabled `custom` plugin rows whose source is one of the already
/// supported external-list backends (IMDb, TMDb, Letterboxd or MDBList).
/// Credentials and source fetching stay behind Moonbase/CustomExternalListsService.
class SeerrDiscoveryConfiguredListsService {
  static const supportedSources = <String>{
    'imdb',
    'tmdb',
    'letterboxd',
    'mdblist',
  };
  static const pageSize = 20;

  final SeerrDiscoveryConfiguredListReader _readConfigs;
  final SeerrDiscoveryConfiguredListFetcher _fetchItems;
  final Map<String, HomeSectionConfig> _configByStableId = {};
  final Map<String, List<SeerrDiscoverItem>> _itemsByStableId = {};

  SeerrDiscoveryConfiguredListsService({
    required UserPreferences preferences,
    required CustomExternalListsService externalLists,
  }) : _readConfigs = (() => preferences.activeHomeSectionConfigs),
       _fetchItems = externalLists.fetchCustomRow;

  SeerrDiscoveryConfiguredListsService.forTesting({
    required SeerrDiscoveryConfiguredListReader readConfigs,
    required SeerrDiscoveryConfiguredListFetcher fetchItems,
  }) : _readConfigs = readConfigs,
       _fetchItems = fetchItems;

  /// Returns only executable external-list sections. Existing placeholder
  /// `server` list IDs are intentionally not treated as configured sources.
  List<SeerrDiscoverySection> configuredSections() {
    _configByStableId.clear();
    final output = <SeerrDiscoverySection>[];
    for (final config in _readConfigs()) {
      final definition = _definitionFor(config);
      if (definition == null) continue;
      final stableId = config.stableId;
      _configByStableId[stableId] = config;
      output.add(
        SeerrDiscoverySection(
          id: 'configured-list-${_stableHash(stableId)}',
          title: definition.title,
          subtitle: definition.subtitle,
          query: SeerrDiscoveryQuery(
            source: SeerrDiscoverySource.externalList,
            mediaType: definition.mediaType,
            listProvider: definition.source,
            listId: stableId,
          ),
          pool: 'configured-lists',
          priority: SeerrDiscoveryPriority.high,
          previewLimit: pageSize,
          minItems: 3,
          cooldownSessions: 0,
          dedupGroup: 'configured-lists',
          tags: ['curated', 'configured-list', definition.source],
        ),
      );
    }
    return output;
  }

  /// Replaces non-executable authoring placeholders in the Lists tab with the
  /// user's real configured list rows. If none exist, hide the Lists tab until
  /// a source is configured rather than presenting an empty destination.
  SeerrDiscoveryCatalogue mergeIntoCatalogue(
    SeerrDiscoveryCatalogue catalogue,
  ) {
    final configured = configuredSections();
    final tabs = <SeerrDiscoveryTab>[];
    for (final tab in catalogue.tabs) {
      if (tab.id != 'lists') {
        tabs.add(tab);
        continue;
      }
      if (configured.isEmpty) continue;
      final budget = configured.length < tab.initialLaneBudget
          ? configured.length
          : tab.initialLaneBudget;
      final minimum = configured.length < tab.minimumLaneCount
          ? configured.length
          : tab.minimumLaneCount;
      tabs.add(
        SeerrDiscoveryTab(
          id: tab.id,
          title: tab.title,
          sections: configured,
          initialLaneBudget: budget < 1 ? 1 : budget,
          minimumLaneCount: minimum < 1 ? 1 : minimum,
          poolBudgets: {'configured-lists': budget < 1 ? 1 : budget},
        ),
      );
    }
    return SeerrDiscoveryCatalogue(
      schemaVersion: catalogue.schemaVersion,
      tabs: tabs,
    );
  }

  Future<SeerrDiscoverPage> load(
    SeerrDiscoverySection section, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final stableId = section.query.listId;
    if (stableId == null || stableId.isEmpty) {
      throw StateError('Configured external-list section has no listId');
    }
    _refreshConfigIndexIfNeeded(stableId);
    final config = _configByStableId[stableId];
    if (config == null) {
      throw StateError('Configured external list is no longer enabled');
    }

    if (forceRefresh) _itemsByStableId.remove(stableId);
    var items = _itemsByStableId[stableId];
    if (items == null) {
      final raw = await _fetchItems(config, forceRefresh: forceRefresh);
      final seen = <String>{};
      items = raw
          .map(_toSeerrItem)
          .whereType<SeerrDiscoverItem>()
          .where((item) => seen.add('${item.mediaType}:${item.id}'))
          .toList(growable: false);
      _itemsByStableId[stableId] = items;
    }

    final safePage = page < 1 ? 1 : page;
    final total = items.length;
    final totalPages = total == 0 ? 0 : (total + pageSize - 1) ~/ pageSize;
    final start = (safePage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, total).toInt();
    final window = start >= total
        ? const <SeerrDiscoverItem>[]
        : items.sublist(start, end);
    return SeerrDiscoverPage(
      page: safePage,
      totalPages: totalPages,
      totalResults: total,
      results: window,
    );
  }

  Future<SeerrDiscoverPage> loadQuery(
    SeerrDiscoveryQuery query, {
    int page = 1,
    bool forceRefresh = false,
  }) {
    if (query.source != SeerrDiscoverySource.externalList) {
      throw ArgumentError.value(
        query.source,
        'query.source',
        'Configured Lists only execute externalList queries',
      );
    }
    final stableId = query.listId;
    if (stableId == null || stableId.isEmpty) {
      throw StateError('Configured external-list query has no listId');
    }
    return load(
      SeerrDiscoverySection(
        id: 'expanded-configured-list',
        title: 'Configured List',
        query: query,
        minItems: 1,
        previewLimit: pageSize,
        pool: 'configured-lists',
        dedupGroup: 'configured-lists-expanded',
        sessionDedup: false,
      ),
      page: page,
      forceRefresh: forceRefresh,
    );
  }

  void clear() => _itemsByStableId.clear();

  void _refreshConfigIndexIfNeeded(String stableId) {
    if (_configByStableId.containsKey(stableId)) return;
    configuredSections();
  }

  _ConfiguredListDefinition? _definitionFor(HomeSectionConfig config) {
    if (!config.enabled ||
        !config.isPluginDynamic ||
        config.pluginSource != HomeSectionPluginSource.custom) {
      return null;
    }
    final additional = config.pluginAdditionalData;
    if (additional == null || additional.trim().isEmpty) return null;

    final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(additional);
      if (decoded is! Map) return null;
      data = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }

    final source = data['source']?.toString().trim().toLowerCase() ?? '';
    final type = data['type']?.toString().trim().toLowerCase() ?? '';
    if (!supportedSources.contains(source) || type.isEmpty) return null;
    final params = data['params'] is Map
        ? Map<String, dynamic>.from(data['params'] as Map)
        : const <String, dynamic>{};

    final configuredMedia = (data['media_type'] ?? params['media_type'])
        ?.toString()
        .trim()
        .toLowerCase();
    final mediaType = switch (configuredMedia) {
      'movie' || 'movies' => 'movie',
      'tv' || 'series' || 'show' || 'shows' => 'tv',
      _ when source == 'tmdb' && type == 'movie_collection' => 'movie',
      _ => 'all',
    };
    final display = config.pluginDisplayText?.trim();
    final title = display != null && display.isNotEmpty
        ? display
        : (data['title']?.toString().trim().isNotEmpty ?? false)
        ? data['title'].toString().trim()
        : config.pluginSection?.trim().isNotEmpty == true
        ? config.pluginSection!.trim()
        : 'Curated List';
    return _ConfiguredListDefinition(
      source: source,
      mediaType: mediaType,
      title: title,
      subtitle: _sourceLabel(source),
    );
  }

  static String _sourceLabel(String source) => switch (source) {
    'imdb' => 'IMDb',
    'tmdb' => 'TMDb',
    'letterboxd' => 'Letterboxd',
    'mdblist' => 'MDBList',
    _ => source,
  };

  static String _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static SeerrDiscoverItem? _toSeerrItem(ImdbExternalListItem item) {
    final tmdbId = int.tryParse(item.tmdbId);
    if (tmdbId == null || tmdbId <= 0) return null;
    final type = item.type.trim().toLowerCase();
    final mediaType = switch (type) {
      'movie' || 'film' => 'movie',
      'series' || 'tv' || 'show' || 'tvshow' || 'tv show' => 'tv',
      _ => null,
    };
    if (mediaType == null) return null;
    final date = item.year == null
        ? null
        : '${item.year!.toString().padLeft(4, '0')}-01-01';
    return SeerrDiscoverItem(
      id: tmdbId,
      mediaType: mediaType,
      title: mediaType == 'movie' ? item.title : null,
      name: mediaType == 'tv' ? item.title : null,
      posterPath: _tmdbImagePath(item.posterUrl),
      backdropPath: _tmdbImagePath(item.backdropUrl),
      releaseDate: mediaType == 'movie' ? date : null,
      firstAirDate: mediaType == 'tv' ? date : null,
      voteAverage: item.rating,
      popularity: item.popularity,
    );
  }

  static String? _tmdbImagePath(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.startsWith('/') && !trimmed.startsWith('/t/p/')) return trimmed;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.host.toLowerCase().contains('image.tmdb.org')) {
      return null;
    }
    final parts = uri.pathSegments;
    final sizeIndex = parts.indexWhere((part) => part.startsWith('w'));
    if (sizeIndex < 0 || sizeIndex >= parts.length - 1) return null;
    return '/${parts.sublist(sizeIndex + 1).join('/')}';
  }
}

class _ConfiguredListDefinition {
  final String source;
  final String mediaType;
  final String title;
  final String subtitle;

  const _ConfiguredListDefinition({
    required this.source,
    required this.mediaType,
    required this.title,
    required this.subtitle,
  });
}
