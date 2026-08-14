/// Shared, serialisable contract for Moonfin's deep-discovery experience.
///
/// The contract deliberately keeps content/query configuration separate from
/// Flutter presentation. Web, Android, webOS and Android TV can consume the
/// same definition while choosing platform-appropriate carousel/grid/focus UI.
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

class SeerrDiscoveryQuery {
  final SeerrDiscoverySource source;
  final String mediaType;
  final String sortBy;
  final Map<String, String> filters;
  final String? seedStrategy;
  final String? listProvider;
  final String? listId;

  const SeerrDiscoveryQuery({
    required this.source,
    required this.mediaType,
    this.sortBy = 'popularity.desc',
    this.filters = const {},
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
    return SeerrDiscoveryQuery(
      source: source,
      mediaType: json['mediaType'] as String? ?? 'movie',
      sortBy: json['sortBy'] as String? ?? 'popularity.desc',
      filters: rawFilters.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
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
        if (seedStrategy != null) 'seedStrategy': seedStrategy,
        if (listProvider != null) 'listProvider': listProvider,
        if (listId != null) 'listId': listId,
      };

  /// Query parameters for the Moonfin full-screen discovery route.
  ///
  /// Filters are prefixed with `q.` so routing metadata can never collide with
  /// Seerr/TMDb filter names. The browse layer is responsible for allow-listing
  /// supported upstream parameters before forwarding them.
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

  /// Stable identity used for preview/expanded-query equality and dedup caches.
  String get cacheKey {
    final sorted = filters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final encodedFilters = sorted.map((e) => '${e.key}=${e.value}').join('&');
    return [
      source.name,
      mediaType,
      sortBy,
      encodedFilters,
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
  });

  factory SeerrDiscoverySection.fromJson(Map<String, dynamic> json) {
    final presentationName = json['presentation'] as String? ?? 'carousel';
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
      previewLimit: json['previewLimit'] as int? ?? 20,
      dedupGroup: json['dedupGroup'] as String? ?? 'global',
      sessionDedup: json['sessionDedup'] as bool? ?? true,
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
      };
}

class SeerrDiscoveryTab {
  final String id;
  final String title;
  final List<SeerrDiscoverySection> sections;

  const SeerrDiscoveryTab({
    required this.id,
    required this.title,
    required this.sections,
  });

  factory SeerrDiscoveryTab.fromJson(Map<String, dynamic> json) =>
      SeerrDiscoveryTab(
        id: json['id'] as String,
        title: json['title'] as String,
        sections: (json['sections'] as List? ?? const [])
            .map(
              (entry) => SeerrDiscoverySection.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sections': sections.map((section) => section.toJson()).toList(),
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
        schemaVersion: json['schemaVersion'] as int? ?? 1,
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
      }
    }
  }
}
