import 'seerr_discovery_schema.dart';

class SeerrDiscoveryCatalogueGroup {
  final String id;
  final String title;
  final List<SeerrDiscoverySection> sections;

  const SeerrDiscoveryCatalogueGroup({
    required this.id,
    required this.title,
    required this.sections,
  });
}

/// Builds a lightweight navigation index over the full server catalogue.
///
/// Normal Discovery intentionally mounts only 16-26 poster lanes. This index
/// makes every expandable lane directly reachable without mounting hundreds of
/// live carousels or waiting for rotation to surface a particular category.
abstract final class SeerrDiscoveryCatalogueIndex {
  static List<SeerrDiscoveryCatalogueGroup> groups(SeerrDiscoveryTab tab) {
    final byPool = <String, List<SeerrDiscoverySection>>{};
    for (final section in tab.sections) {
      if (!section.expandable) continue;
      byPool.putIfAbsent(section.pool, () => []).add(section);
    }
    return [
      for (final entry in byPool.entries)
        SeerrDiscoveryCatalogueGroup(
          id: entry.key,
          title: poolTitle(entry.key),
          sections: List.unmodifiable(entry.value),
        ),
    ];
  }

  static int expandableCount(SeerrDiscoveryTab tab) =>
      tab.sections.where((section) => section.expandable).length;

  static String poolTitle(String pool) {
    final suffix = pool.split('-').last.toLowerCase();
    return switch (suffix) {
      'anchor' => 'Essentials',
      'discovery' => 'Discover More',
      'runtime' => 'By Length',
      'era' || 'time' => 'Eras & Seasons',
      'genres' => 'Genres',
      'mixes' => 'Genre Mixes',
      'themes' => 'Themes & Topics',
      'studios' => 'Studios',
      'networks' => 'Networks',
      'languages' => 'Languages & Regions',
      'providers' => 'Streaming Services',
      'occasions' => 'Moods & Occasions',
      'rating' => 'Ratings & Hidden Gems',
      'format' => 'Format & Length',
      'global' => 'Global Animation',
      'personal' => 'For You',
      'lists' => 'Curated Lists',
      'collections' => 'Curated Collections',
      'upcoming' => 'New & Upcoming',
      _ => _humanise(pool),
    };
  }

  static String _humanise(String value) {
    final words = value
        .split(RegExp(r'[-_]'))
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return 'More Discovery';
    return words
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}
