/// Shared, serialisable contract for Moonfin's deep-discovery experience.
///
/// The contract deliberately keeps content/query configuration separate from
/// presentation. Web, Android, webOS and Android TV can consume the same
/// definition while choosing platform-appropriate carousel/grid/focus UI.
///
/// A section's [query] is the single source of truth for both its preview row
/// and its expanded collection. This prevents a "See all" screen from drifting
/// away from the filter that produced the row.
enum SeerrDiscoverySource {
  discoverMovies,
  discoverTv,
  trending,
  upcomingMovies,
  upcomingTv,
  watchlist,
  personalised,
  externalList,
}

enum SeerrDiscoveryPresentation { carousel, grid }

enum SeerrDiscoveryPriority { anchor, high, normal, low }

/// Controls how ownership/request state affects membership of a lane.
///
/// The old request-oriented discovery implementation globally removed already
/// available media. Deep Discovery cannot do that: most lanes should show the
/// catalogue regardless of ownership and simply decorate each item with its
/// local/request state. Narrow lanes can opt into a stricter mode.
enum SeerrDiscoveryAvailabilityMode {
  all,
  requestable,
  available,
  requested,
  notOwned,
  unwatched,
}

class SeerrDiscoveryQuery {
  final SeerrDiscoverySource source;
  final String mediaType;
  final String sortBy;

  /// Compiled executable filters understood by the current Seerr API.
  final Map<String, String> filters;

  /// Human-readable authoring metadata for filters that should be resolved on
  /// the server before execution. Clients must not fuzzy-resolve these values.
  final List<String> keywordNames;
  final List<String> excludeKeywordNames;
  final List<String> providerNames;

  final String? seedStrategy;
  final String? listProvider;
  final String? listId;

  const SeerrDiscoveryQuery({
    required this.source,
    required this.mediaType,
    this.sortBy = 'popularity.desc',
    this.filters = const {},
    this.keywordNames = const [],
    this.excludeKeywordNames = const [],
    this.providerNames = const [],
    this.seedStrategy,
    this.listProvider,
    this.listId,
  });

  factory SeerrDiscoveryQuery.fromJson(Map<String, dynamic> json) {
    final sourceName = json['source'] as String? ?? 'discoverMovies';
    final source = SeerrDiscoverySource.values.firstWhere(
      (value) => value.name == sourceName,
      orElse: () => SeerrDiscoverySource.discoverMovies,
    );
    final rawFilters = json['filters'] as Map? ?? const {};

    List<String> stringList(String key) =>
        (json[key] as List? ?? const []).map((value) => value.toString()).toList(
              growable: false,
            );

    return SeerrDiscoveryQuery(
      source: source,
      mediaType: json['mediaType'] as String? ?? 'movie',
      sortBy: json['sortBy'] as String? ?? 'popularity.desc',
      filters: rawFilters.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      keywordNames: stringList('keywordNames'),
      excludeKeywordNames: stringList('excludeKeywordNames'),
      providerNames: stringList('providerNames'),
      seedStrategy: json['seedStrategy'] as String?,
      listProvider: json['listProvider'] as String?,
      listId: json['listId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'source': source.name,
        'mediaType': mediaType,
        'sortBy': sortBy,
        if (filters.isNotEmpty) 'filters': filters,
        if (keywordNames.isNotEmpty) 'keywordNames': keywordNames,
        if (excludeKeywordNames.isNotEmpty)
          'excludeKeywordNames': excludeKeywordNames,
        if (providerNames.isNotEmpty) 'providerNames': providerNames,
        if (seedStrategy != null) 'seedStrategy': seedStrategy,
        if (listProvider != null) 'listProvider': listProvider,
        if (listId != null) 'listId': listId,
      };

  /// Query parameters for the Moonfin full-screen discovery route.
  ///
  /// Only compiled executable filters are emitted here. Semantic authoring
  /// fields such as [keywordNames] and [providerNames] must have been resolved
  /// by the catalogue compiler/server first. Filters are prefixed with `q.` so
  /// routing metadata can never collide with Seerr/TMDb filter names.
  Map<String, String> toRouteParameters({String? title}) => {
        'source': source.name,
        'mediaType': mediaType,
        'sortBy': sortBy,
        if (title != null && title.isNotEmpty) 'filterName': title,
        for (final entry in filters.entries) 'q.${entry.key}': entry.value,
        if (seedStrategy != null) 'seedStrategy': seedStrategy!,
        if (listProvider != null) 'listProvider': listProvider!,
        if (listId != null) 'listId': listId!,
      };

  /// Stable identity used for preview/expanded-query equality and caches.
  String get cacheKey {
    final sorted = filters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final encodedFilters = sorted.map((e) => '${e.key}=${e.value}').join('&');

    String encodedNames(List<String> values) {
      final sortedNames = [...values]..sort();
      return sortedNames.join(',');
    }

    return [
      source.name,
      mediaType,
      sortBy,
      encodedFilters,
      encodedNames(keywordNames),
      encodedNames(excludeKeywordNames),
      encodedNames(providerNames),
      seedStrategy ?? '',
      listProvider ?? '',
      listId ?? '',
    ].join('|');
  }
}

class SeerrDiscoverySection {
  final String id;
  final String title;
  final String? subtitle;
  final SeerrDiscoveryQuery query;
  final SeerrDiscoveryPresentation presentation;
  final bool expandable;
  final int previewLimit;
  final String dedupGroup;
  final bool sessionDedup;

  /// Composition metadata. A large catalogue is reduced to a useful session
  /// by keeping anchors and selecting weighted sections from rotating pools.
  final String pool;
  final SeerrDiscoveryPriority priority;
  final double weight;
  final int cooldownSessions;
  final int minItems;
  final SeerrDiscoveryAvailabilityMode availabilityMode;
  final List<String> tags;
  final Map<String, String> conditions;

  const SeerrDiscoverySection({
    required this.id,
    required this.title,
    required this.query,
    this.subtitle,
    this.presentation = SeerrDiscoveryPresentation.carousel,
    this.expandable = true,
    this.previewLimit = 20,
    this.dedupGroup = 'global',
    this.sessionDedup = true,
    this.pool = 'general',
    this.priority = SeerrDiscoveryPriority.normal,
    this.weight = 1.0,
    this.cooldownSessions = 0,
    this.minItems = 8,
    this.availabilityMode = SeerrDiscoveryAvailabilityMode.all,
    this.tags = const [],
    this.conditions = const {},
  });

  factory SeerrDiscoverySection.fromJson(Map<String, dynamic> json) {
    final presentationName = json['presentation'] as String? ?? 'carousel';
    final priorityName = json['priority'] as String? ?? 'normal';
    final availabilityName = json['availabilityMode'] as String? ?? 'all';
    final rawConditions = json['conditions'] as Map? ?? const {};

    return SeerrDiscoverySection(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      query: SeerrDiscoveryQuery.fromJson(
        Map<String, dynamic>.from(json['query'] as Map),
      ),
      presentation: SeerrDiscoveryPresentation.values.firstWhere(
        (value) => value.name == presentationName,
        orElse: () => SeerrDiscoveryPresentation.carousel,
      ),
      expandable: json['expandable'] as bool? ?? true,
      previewLimit: (json['previewLimit'] as num?)?.toInt() ?? 20,
      dedupGroup: json['dedupGroup'] as String? ?? 'global',
      sessionDedup: json['sessionDedup'] as bool? ?? true,
      pool: json['pool'] as String? ?? 'general',
      priority: SeerrDiscoveryPriority.values.firstWhere(
        (value) => value.name == priorityName,
        orElse: () => SeerrDiscoveryPriority.normal,
      ),
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      cooldownSessions: (json['cooldownSessions'] as num?)?.toInt() ?? 0,
      minItems: (json['minItems'] as num?)?.toInt() ?? 8,
      availabilityMode: SeerrDiscoveryAvailabilityMode.values.firstWhere(
        (value) => value.name == availabilityName,
        orElse: () => SeerrDiscoveryAvailabilityMode.all,
      ),
      tags: (json['tags'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      conditions: rawConditions.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'query': query.toJson(),
        'presentation': presentation.name,
        'expandable': expandable,
        'previewLimit': previewLimit,
        'dedupGroup': dedupGroup,
        'sessionDedup': sessionDedup,
        'pool': pool,
        'priority': priority.name,
        'weight': weight,
        'cooldownSessions': cooldownSessions,
        'minItems': minItems,
        'availabilityMode': availabilityMode.name,
        if (tags.isNotEmpty) 'tags': tags,
        if (conditions.isNotEmpty) 'conditions': conditions,
      };

  bool get isAnchor => priority == SeerrDiscoveryPriority.anchor;
}

class SeerrDiscoveryTab {
  final String id;
  final String title;
  final List<SeerrDiscoverySection> sections;

  /// Normal landing pages intentionally mount only a subset of the full
  /// catalogue. Category indexes and expanded lanes expose the rest.
  final int initialLaneBudget;
  final int minimumLaneCount;
  final Map<String, int> poolBudgets;

  const SeerrDiscoveryTab({
    required this.id,
    required this.title,
    required this.sections,
    this.initialLaneBudget = 20,
    this.minimumLaneCount = 8,
    this.poolBudgets = const {},
  });

  factory SeerrDiscoveryTab.fromJson(Map<String, dynamic> json) {
    final rawPoolBudgets = json['poolBudgets'] as Map? ?? const {};
    return SeerrDiscoveryTab(
      id: json['id'] as String,
      title: json['title'] as String,
      sections: (json['sections'] as List? ?? const [])
          .map(
            (entry) => SeerrDiscoverySection.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
      initialLaneBudget: (json['initialLaneBudget'] as num?)?.toInt() ?? 20,
      minimumLaneCount: (json['minimumLaneCount'] as num?)?.toInt() ?? 8,
      poolBudgets: rawPoolBudgets.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sections': sections.map((section) => section.toJson()).toList(),
        'initialLaneBudget': initialLaneBudget,
        'minimumLaneCount': minimumLaneCount,
        if (poolBudgets.isNotEmpty) 'poolBudgets': poolBudgets,
      };
}

class SeerrDiscoveryCatalogue {
  final int schemaVersion;
  final List<SeerrDiscoveryTab> tabs;

  const SeerrDiscoveryCatalogue({
    required this.schemaVersion,
    required this.tabs,
  });

  factory SeerrDiscoveryCatalogue.fromJson(Map<String, dynamic> json) =>
      SeerrDiscoveryCatalogue(
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
        tabs: (json['tabs'] as List? ?? const [])
            .map(
              (entry) => SeerrDiscoveryTab.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'tabs': tabs.map((tab) => tab.toJson()).toList(),
      };

  Iterable<SeerrDiscoverySection> get allSections sync* {
    for (final tab in tabs) {
      yield* tab.sections;
    }
  }

  void validate() {
    if (schemaVersion < 1) {
      throw const FormatException('Discovery schemaVersion must be >= 1');
    }
    final tabIds = <String>{};
    final sectionIds = <String>{};
    for (final tab in tabs) {
      if (tab.id.isEmpty || !tabIds.add(tab.id)) {
        throw FormatException('Duplicate/empty discovery tab id: ${tab.id}');
      }
      if (tab.initialLaneBudget < 1 || tab.initialLaneBudget > 100) {
        throw FormatException(
          'Invalid initialLaneBudget for ${tab.id}: ${tab.initialLaneBudget}',
        );
      }
      if (tab.minimumLaneCount < 1 ||
          tab.minimumLaneCount > tab.initialLaneBudget) {
        throw FormatException(
          'Invalid minimumLaneCount for ${tab.id}: ${tab.minimumLaneCount}',
        );
      }
      for (final entry in tab.poolBudgets.entries) {
        if (entry.key.isEmpty || entry.value < 0) {
          throw FormatException(
            'Invalid pool budget for ${tab.id}: ${entry.key}=${entry.value}',
          );
        }
      }

      for (final section in tab.sections) {
        if (section.id.isEmpty || !sectionIds.add(section.id)) {
          throw FormatException(
            'Duplicate/empty discovery section id: ${section.id}',
          );
        }
        if (section.previewLimit < 1 || section.previewLimit > 100) {
          throw FormatException(
            'Invalid previewLimit for ${section.id}: ${section.previewLimit}',
          );
        }
        if (section.minItems < 1 || section.minItems > section.previewLimit) {
          throw FormatException(
            'Invalid minItems for ${section.id}: ${section.minItems}',
          );
        }
        if (section.pool.isEmpty) {
          throw FormatException('Empty pool for ${section.id}');
        }
        if (!section.weight.isFinite || section.weight <= 0) {
          throw FormatException('Invalid weight for ${section.id}');
        }
        if (section.cooldownSessions < 0) {
          throw FormatException('Invalid cooldown for ${section.id}');
        }
      }
    }
  }
}
