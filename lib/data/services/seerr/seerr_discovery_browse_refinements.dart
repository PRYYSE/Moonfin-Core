class SeerrDiscoveryBrowseRefinements {
  final Set<int> genreIds;
  final int? yearFrom;
  final int? yearTo;
  final double? minimumRating;
  final int? minimumVotes;
  final int? runtimeMin;
  final int? runtimeMax;
  final String? originalLanguage;

  const SeerrDiscoveryBrowseRefinements({
    this.genreIds = const {},
    this.yearFrom,
    this.yearTo,
    this.minimumRating,
    this.minimumVotes,
    this.runtimeMin,
    this.runtimeMax,
    this.originalLanguage,
  });

  bool get isEmpty => activeCount == 0;

  int get activeCount {
    var count = 0;
    if (genreIds.isNotEmpty) count++;
    if (yearFrom != null || yearTo != null) count++;
    if (minimumRating != null && minimumRating! > 0) count++;
    if (minimumVotes != null && minimumVotes! > 0) count++;
    if ((runtimeMin != null && runtimeMin! > 0) ||
        (runtimeMax != null && runtimeMax! > 0)) {
      count++;
    }
    if (originalLanguage?.trim().isNotEmpty ?? false) count++;
    return count;
  }

  Map<String, String> toFilters(String mediaType) {
    final filters = <String, String>{};
    if (genreIds.isNotEmpty) {
      final sorted = genreIds.toList()..sort();
      // Current Seerr/TMDb semantics use comma-separated genre IDs for AND.
      // The UI labels this as all selected genres rather than implying OR.
      filters['genre'] = sorted.join(',');
    }

    final movie = mediaType == 'movie';
    final fromKey = movie ? 'primaryReleaseDateGte' : 'firstAirDateGte';
    final toKey = movie ? 'primaryReleaseDateLte' : 'firstAirDateLte';
    if (yearFrom != null) filters[fromKey] = '${yearFrom!}-01-01';
    if (yearTo != null) filters[toKey] = '${yearTo!}-12-31';

    if (minimumRating != null && minimumRating! > 0) {
      filters['voteAverageGte'] = _compactDouble(minimumRating!);
    }
    if (minimumVotes != null && minimumVotes! > 0) {
      filters['voteCountGte'] = minimumVotes.toString();
    }
    if (runtimeMin != null && runtimeMin! > 0) {
      filters['withRuntimeGte'] = runtimeMin.toString();
    }
    if (runtimeMax != null && runtimeMax! > 0) {
      filters['withRuntimeLte'] = runtimeMax.toString();
    }
    final language = originalLanguage?.trim().toLowerCase();
    if (language != null && language.isNotEmpty) {
      filters['language'] = language;
    }
    return filters;
  }

  SeerrDiscoveryBrowseRefinements copyWith({
    Set<int>? genreIds,
    int? yearFrom,
    bool clearYearFrom = false,
    int? yearTo,
    bool clearYearTo = false,
    double? minimumRating,
    bool clearMinimumRating = false,
    int? minimumVotes,
    bool clearMinimumVotes = false,
    int? runtimeMin,
    bool clearRuntimeMin = false,
    int? runtimeMax,
    bool clearRuntimeMax = false,
    String? originalLanguage,
    bool clearOriginalLanguage = false,
  }) => SeerrDiscoveryBrowseRefinements(
    genreIds: genreIds ?? this.genreIds,
    yearFrom: clearYearFrom ? null : (yearFrom ?? this.yearFrom),
    yearTo: clearYearTo ? null : (yearTo ?? this.yearTo),
    minimumRating: clearMinimumRating
        ? null
        : (minimumRating ?? this.minimumRating),
    minimumVotes: clearMinimumVotes
        ? null
        : (minimumVotes ?? this.minimumVotes),
    runtimeMin: clearRuntimeMin ? null : (runtimeMin ?? this.runtimeMin),
    runtimeMax: clearRuntimeMax ? null : (runtimeMax ?? this.runtimeMax),
    originalLanguage: clearOriginalLanguage
        ? null
        : (originalLanguage ?? this.originalLanguage),
  );

  static String _compactDouble(double value) {
    final rounded = value.toStringAsFixed(1);
    return rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
  }
}

class SeerrDiscoveryGenreOption {
  final int id;
  final String label;

  const SeerrDiscoveryGenreOption(this.id, this.label);
}

abstract final class SeerrDiscoveryBrowseTaxonomy {
  static const movieGenres = <SeerrDiscoveryGenreOption>[
    SeerrDiscoveryGenreOption(28, 'Action'),
    SeerrDiscoveryGenreOption(12, 'Adventure'),
    SeerrDiscoveryGenreOption(16, 'Animation'),
    SeerrDiscoveryGenreOption(35, 'Comedy'),
    SeerrDiscoveryGenreOption(80, 'Crime'),
    SeerrDiscoveryGenreOption(99, 'Documentary'),
    SeerrDiscoveryGenreOption(18, 'Drama'),
    SeerrDiscoveryGenreOption(10751, 'Family'),
    SeerrDiscoveryGenreOption(14, 'Fantasy'),
    SeerrDiscoveryGenreOption(36, 'History'),
    SeerrDiscoveryGenreOption(27, 'Horror'),
    SeerrDiscoveryGenreOption(10402, 'Music'),
    SeerrDiscoveryGenreOption(9648, 'Mystery'),
    SeerrDiscoveryGenreOption(10749, 'Romance'),
    SeerrDiscoveryGenreOption(878, 'Science Fiction'),
    SeerrDiscoveryGenreOption(53, 'Thriller'),
    SeerrDiscoveryGenreOption(10752, 'War'),
    SeerrDiscoveryGenreOption(37, 'Western'),
  ];

  static const tvGenres = <SeerrDiscoveryGenreOption>[
    SeerrDiscoveryGenreOption(10759, 'Action & Adventure'),
    SeerrDiscoveryGenreOption(16, 'Animation'),
    SeerrDiscoveryGenreOption(35, 'Comedy'),
    SeerrDiscoveryGenreOption(80, 'Crime'),
    SeerrDiscoveryGenreOption(99, 'Documentary'),
    SeerrDiscoveryGenreOption(18, 'Drama'),
    SeerrDiscoveryGenreOption(10751, 'Family'),
    SeerrDiscoveryGenreOption(10762, 'Kids'),
    SeerrDiscoveryGenreOption(9648, 'Mystery'),
    SeerrDiscoveryGenreOption(10763, 'News'),
    SeerrDiscoveryGenreOption(10764, 'Reality'),
    SeerrDiscoveryGenreOption(10765, 'Sci-Fi & Fantasy'),
    SeerrDiscoveryGenreOption(10766, 'Soap'),
    SeerrDiscoveryGenreOption(10767, 'Talk'),
    SeerrDiscoveryGenreOption(10768, 'War & Politics'),
    SeerrDiscoveryGenreOption(37, 'Western'),
  ];

  static const languages = <MapEntry<String, String>>[
    MapEntry('', 'Any language'),
    MapEntry('en', 'English'),
    MapEntry('ja', 'Japanese'),
    MapEntry('ko', 'Korean'),
    MapEntry('fr', 'French'),
    MapEntry('es', 'Spanish'),
    MapEntry('de', 'German'),
    MapEntry('it', 'Italian'),
    MapEntry('hi', 'Hindi'),
    MapEntry('zh', 'Chinese'),
    MapEntry('sv', 'Swedish'),
    MapEntry('no', 'Norwegian'),
    MapEntry('da', 'Danish'),
  ];

  static List<SeerrDiscoveryGenreOption> genresFor(String mediaType) =>
      mediaType == 'tv' ? tvGenres : movieGenres;
}
