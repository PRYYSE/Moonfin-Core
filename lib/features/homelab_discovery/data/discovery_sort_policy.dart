abstract final class HomeLabDiscoverySortPolicy {
  static const allowed = <String>{
    'popularity.desc',
    'popularity.asc',
    'release_date.desc',
    'release_date.asc',
    'revenue.desc',
    'revenue.asc',
    'primary_release_date.desc',
    'primary_release_date.asc',
    'original_title.asc',
    'original_title.desc',
    'vote_average.desc',
    'vote_average.asc',
    'vote_count.desc',
    'vote_count.asc',
    'first_air_date.desc',
    'first_air_date.asc',
  };

  static String normalise(String? value) {
    final sort = value?.trim();
    return sort != null && allowed.contains(sort) ? sort : 'popularity.desc';
  }
}
