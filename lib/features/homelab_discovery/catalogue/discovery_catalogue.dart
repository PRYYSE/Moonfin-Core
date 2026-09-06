enum HomeLabDiscoverySource {
  discoverMovies,
  discoverTv,
  trending,
  upcomingMovies,
  upcomingTv,
  watchlist,
  personalised,
  externalList,
}

enum HomeLabDiscoveryPresentation { carousel, grid }

enum HomeLabDiscoveryPriority { anchor, high, normal, low }

enum HomeLabDiscoveryAvailabilityMode {
  all,
  requestable,
  available,
  requested,
  notOwned,
  unwatched,
}

T _enumValue<T extends Enum>(List<T> values, Object? raw, String field) {
  if (raw is! String || raw.isEmpty) {
    throw FormatException('Discovery field $field must be a non-empty string');
  }
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Unsupported discovery $field: $raw');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Discovery field $key must be a non-empty string');
  }
  return value;
}

Map<String, String> _stringMap(Object? raw, String field) {
  if (raw == null) return const {};
  if (raw is! Map) {
    throw FormatException('Discovery field $field must be an object');
  }
  return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
}

List<String> _stringList(Object? raw, String field) {
  if (raw == null) return const [];
  if (raw is! List) {
    throw FormatException('Discovery field $field must be an array');
  }
  return raw.map((value) => value.toString()).toList(growable: false);
}

class HomeLabDiscoveryQuery {
  final HomeLabDiscoverySource source;
  final String mediaType;
  final String sortBy;
  final Map<String, String> filters;
  final List<String> keywordNames;
  final List<String> excludeKeywordNames;
  final List<String> providerNames;
  final String? seedStrategy;
  final String? listProvider;
  final String? listId;

  const HomeLabDiscoveryQuery({
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

  factory HomeLabDiscoveryQuery.fromJson(Map<String, dynamic> json) {
    return HomeLabDiscoveryQuery(
      source: _enumValue(
        HomeLabDiscoverySource.values,
        json['source'],
        'query.source',
      ),
      mediaType: _requiredString(json, 'mediaType'),
      sortBy: json['sortBy']?.toString() ?? 'popularity.desc',
      filters: _stringMap(json['filters'], 'query.filters'),
      keywordNames: _stringList(json['keywordNames'], 'query.keywordNames'),
      excludeKeywordNames: _stringList(
        json['excludeKeywordNames'],
        'query.excludeKeywordNames',
      ),
      providerNames: _stringList(json['providerNames'], 'query.providerNames'),
      seedStrategy: json['seedStrategy']?.toString(),
      listProvider: json['listProvider']?.toString(),
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

  String get cacheKey {
    final sorted = filters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      source.name,
      mediaType,
      sortBy,
      sorted.map((entry) => '${entry.key}=${entry.value}').join('&'),
      [...keywordNames]..sort(),
      [...excludeKeywordNames]..sort(),
      [...providerNames]..sort(),
      seedStrategy ?? '',
      listProvider ?? '',
      listId ?? '',
    ].join('|');
  }
}

class HomeLabDiscoverySection {
  final String id;
  final String title;
  final String? subtitle;
  final HomeLabDiscoveryQuery query;
  final HomeLabDiscoveryPresentation presentation;
  final bool expandable;
  final int previewLimit;
  final String dedupGroup;
  final bool sessionDedup;
  final String pool;
  final HomeLabDiscoveryPriority priority;
  final double weight;
  final int cooldownSessions;
  final int minItems;
  final HomeLabDiscoveryAvailabilityMode availabilityMode;
  final List<String> tags;
  final Map<String, String> conditions;

  const HomeLabDiscoverySection({
    required this.id,
    required this.title,
    required this.query,
    this.subtitle,
    this.presentation = HomeLabDiscoveryPresentation.carousel,
    this.expandable = true,
    this.previewLimit = 20,
    this.dedupGroup = 'global',
    this.sessionDedup = true,
    this.pool = 'general',
    this.priority = HomeLabDiscoveryPriority.normal,
    this.weight = 1,
    this.cooldownSessions = 0,
    this.minItems = 8,
    this.availabilityMode = HomeLabDiscoveryAvailabilityMode.all,
    this.tags = const [],
    this.conditions = const {},
  });

  factory HomeLabDiscoverySection.fromJson(Map<String, dynamic> json) {
    final query = json['query'];
    if (query is! Map) {
      throw const FormatException('Discovery section query must be an object');
    }
    return HomeLabDiscoverySection(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      subtitle: json['subtitle']?.toString(),
      query: HomeLabDiscoveryQuery.fromJson(Map<String, dynamic>.from(query)),
      presentation: json['presentation'] == null
          ? HomeLabDiscoveryPresentation.carousel
          : _enumValue(
              HomeLabDiscoveryPresentation.values,
              json['presentation'],
              'section.presentation',
            ),
      expandable: json['expandable'] as bool? ?? true,
      previewLimit: (json['previewLimit'] as num?)?.toInt() ?? 20,
      dedupGroup: json['dedupGroup']?.toString() ?? 'global',
      sessionDedup: json['sessionDedup'] as bool? ?? true,
      pool: json['pool']?.toString() ?? 'general',
      priority: json['priority'] == null
          ? HomeLabDiscoveryPriority.normal
          : _enumValue(
              HomeLabDiscoveryPriority.values,
              json['priority'],
              'section.priority',
            ),
      weight: (json['weight'] as num?)?.toDouble() ?? 1,
      cooldownSessions: (json['cooldownSessions'] as num?)?.toInt() ?? 0,
      minItems: (json['minItems'] as num?)?.toInt() ?? 8,
      availabilityMode: json['availabilityMode'] == null
          ? HomeLabDiscoveryAvailabilityMode.all
          : _enumValue(
              HomeLabDiscoveryAvailabilityMode.values,
              json['availabilityMode'],
              'section.availabilityMode',
            ),
      tags: _stringList(json['tags'], 'section.tags'),
      conditions: _stringMap(json['conditions'], 'section.conditions'),
    );
  }

  bool get isAnchor => priority == HomeLabDiscoveryPriority.anchor;
}

class HomeLabDiscoveryTab {
  final String id;
  final String title;
  final List<HomeLabDiscoverySection> sections;
  final int initialLaneBudget;
  final int minimumLaneCount;
  final Map<String, int> poolBudgets;

  const HomeLabDiscoveryTab({
    required this.id,
    required this.title,
    required this.sections,
    this.initialLaneBudget = 20,
    this.minimumLaneCount = 8,
    this.poolBudgets = const {},
  });

  factory HomeLabDiscoveryTab.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    if (rawSections is! List) {
      throw const FormatException('Discovery tab sections must be an array');
    }
    final rawPoolBudgets = json['poolBudgets'];
    final poolBudgets = <String, int>{};
    if (rawPoolBudgets != null) {
      if (rawPoolBudgets is! Map) {
        throw const FormatException('Discovery poolBudgets must be an object');
      }
      for (final entry in rawPoolBudgets.entries) {
        if (entry.value is! num) {
          throw FormatException(
            'Discovery pool budget ${entry.key} must be numeric',
          );
        }
        poolBudgets[entry.key.toString()] = (entry.value as num).toInt();
      }
    }
    return HomeLabDiscoveryTab(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      sections: rawSections
          .map(
            (entry) => HomeLabDiscoverySection.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
      initialLaneBudget: (json['initialLaneBudget'] as num?)?.toInt() ?? 20,
      minimumLaneCount: (json['minimumLaneCount'] as num?)?.toInt() ?? 8,
      poolBudgets: Map.unmodifiable(poolBudgets),
    );
  }
}

class HomeLabDiscoveryCatalogue {
  static const supportedSchemaVersions = {1, 2};

  final int schemaVersion;
  final String? catalogueRevision;
  final DateTime? generatedAt;
  final int? minimumDiscoveryCapability;
  final List<HomeLabDiscoveryTab> tabs;

  const HomeLabDiscoveryCatalogue({
    required this.schemaVersion,
    required this.tabs,
    this.catalogueRevision,
    this.generatedAt,
    this.minimumDiscoveryCapability,
  });

  factory HomeLabDiscoveryCatalogue.fromJson(Map<String, dynamic> json) {
    final schemaRaw = json['schemaVersion'];
    if (schemaRaw is! num) {
      throw const FormatException('Discovery schemaVersion must be numeric');
    }
    final rawTabs = json['tabs'];
    if (rawTabs is! List) {
      throw const FormatException('Discovery tabs must be an array');
    }
    DateTime? generatedAt;
    final generatedRaw = json['generatedAt'];
    if (generatedRaw != null) {
      generatedAt = DateTime.tryParse(generatedRaw.toString());
      if (generatedAt == null) {
        throw const FormatException('Discovery generatedAt must be ISO-8601');
      }
    }
    final capabilityRaw = json['minimumDiscoveryCapability'];
    if (capabilityRaw != null && capabilityRaw is! num) {
      throw const FormatException(
        'Discovery minimumDiscoveryCapability must be numeric',
      );
    }
    final catalogue = HomeLabDiscoveryCatalogue(
      schemaVersion: schemaRaw.toInt(),
      catalogueRevision: json['catalogueRevision']?.toString(),
      generatedAt: generatedAt,
      minimumDiscoveryCapability: (capabilityRaw as num?)?.toInt(),
      tabs: rawTabs
          .map(
            (entry) => HomeLabDiscoveryTab.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
    );
    catalogue.validate();
    return catalogue;
  }

  Iterable<HomeLabDiscoverySection> get allSections sync* {
    for (final tab in tabs) {
      yield* tab.sections;
    }
  }

  void validate() {
    if (!supportedSchemaVersions.contains(schemaVersion)) {
      throw FormatException(
        'Unsupported Discovery schemaVersion: $schemaVersion',
      );
    }
    if (tabs.isEmpty) {
      throw const FormatException('Discovery catalogue must contain tabs');
    }
    final tabIds = <String>{};
    final sectionIds = <String>{};
    for (final tab in tabs) {
      if (!tabIds.add(tab.id)) {
        throw FormatException('Duplicate Discovery tab id: ${tab.id}');
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
        if (!sectionIds.add(section.id)) {
          throw FormatException(
            'Duplicate Discovery section id: ${section.id}',
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
        if (section.pool.trim().isEmpty) {
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
