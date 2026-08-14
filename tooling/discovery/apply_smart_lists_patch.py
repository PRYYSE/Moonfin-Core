#!/usr/bin/env python3
"""Replace placeholder Lists with deep smart collections and append user lists.

The built-in Lists destination should never depend on opaque third-party list
IDs. Twenty executable Seerr/TMDb smart collections provide a deep baseline;
real user-configured MDBList/TMDb/Letterboxd/IMDb sources are then added with
higher priority rather than replacing or hiding the destination.
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GENERATOR = ROOT / "tooling/discovery/generate_home_lab_discovery_catalogue.py"
SERVICE = ROOT / "lib/data/services/seerr/seerr_discovery_configured_lists_service.dart"
INDEX = ROOT / "lib/data/services/seerr/seerr_discovery_catalogue_index.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_generator(text: str) -> str:
    if '"Essential Crime & Thriller"' in text and '"smart-collections"' in text:
        return text
    old = '''def curated_lists() -> list[dict[str, Any]]:
    definitions = [
        ("Award Winners & Nominees", "movie"), ("Best Picture Winners", "movie"), ("Modern Movie Classics", "movie"),
        ("Essential Sci-Fi", "movie"), ("Essential Horror", "movie"), ("Australian Cinema Spotlight", "movie"),
        ("Prestige TV Essentials", "tv"), ("Limited Series Essentials", "tv"), ("Best Crime Series", "tv"),
        ("Best Sci-Fi Series", "tv"), ("Australian Series Spotlight", "tv"), ("Anime Starter Pack", "all"),
        ("Modern Anime Essentials", "all"), ("Classic Anime Essentials", "all"), ("Best Anime Movies", "movie"),
        ("Best Mecha Anime", "tv"), ("Best Romance Anime", "tv"), ("Best Psychological Anime", "tv"),
        ("Seasonal Anime Staff Picks", "tv"), ("Recently Refreshed Lists", "all"),
    ]
    return [lane(f"lists-{slug(title)}", title, q("externalList", media, list_id=slug(title)), "lists", min_items=5, tags=("curated",)) for title, media in definitions]
'''
    new = '''def curated_lists() -> list[dict[str, Any]]:
    # These are intentionally executable smart collections rather than opaque
    # external-list placeholders. Real configured MDBList/TMDb/Letterboxd rows
    # are appended client-side without replacing this baseline.
    definitions = [
        ("Award Season Favourites", q("discoverMovies", "movie", sort="vote_average.desc", filters={"voteAverageGte": "7.2", "voteCountGte": "1000"}, keywords=("academy award",))),
        ("Modern Movie Classics", q("discoverMovies", "movie", sort="vote_average.desc", filters={"primaryReleaseDateGte": "2000-01-01", "voteAverageGte": "7.5", "voteCountGte": "3000"})),
        ("Essential Sci-Fi", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "878", "voteAverageGte": "7.0", "voteCountGte": "500"})),
        ("Essential Horror", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "27", "voteAverageGte": "6.5", "voteCountGte": "300"})),
        ("Essential Crime & Thriller", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "80|53", "voteAverageGte": "7.0", "voteCountGte": "500"})),
        ("Great Films Under Two Hours", q("discoverMovies", "movie", sort="vote_average.desc", filters={"withRuntimeLte": "120", "voteAverageGte": "7.2", "voteCountGte": "500"})),
        ("Family Favourites", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "10751|16", "voteAverageGte": "6.8", "voteCountGte": "300"})),
        ("A24 Essentials", q("discoverMovies", "movie", sort="vote_average.desc", filters={"studio": "41077", "voteAverageGte": "6.5", "voteCountGte": "100"})),
        ("Animated Film Essentials", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "16", "voteAverageGte": "7.0", "voteCountGte": "300"})),
        ("Korean Cinema Essentials", q("discoverMovies", "movie", sort="vote_average.desc", filters={"language": "ko", "voteAverageGte": "7.0", "voteCountGte": "100"})),
        ("Prestige TV Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "18", "voteAverageGte": "8.0", "voteCountGte": "500"})),
        ("Crime Series Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "80", "voteAverageGte": "7.5", "voteCountGte": "250"})),
        ("Sci-Fi & Fantasy Series Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "10765", "voteAverageGte": "7.5", "voteCountGte": "250"})),
        ("Comedy Series Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "35", "voteAverageGte": "7.5", "voteCountGte": "250"})),
        ("Documentary Series Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "99", "voteAverageGte": "7.5", "voteCountGte": "50"})),
        ("Korean Series Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"language": "ko", "voteAverageGte": "7.5", "voteCountGte": "100"})),
        ("Anime Starter Pack", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "16", "language": "ja", "voteAverageGte": "7.5", "voteCountGte": "200"})),
        ("Modern Anime Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "16", "language": "ja", "firstAirDateGte": "2010-01-01", "voteAverageGte": "8.0", "voteCountGte": "150"})),
        ("Classic Anime Essentials", q("discoverTv", "tv", sort="vote_average.desc", filters={"genre": "16", "language": "ja", "firstAirDateLte": "2009-12-31", "voteAverageGte": "7.8", "voteCountGte": "75"})),
        ("Best Anime Movies", q("discoverMovies", "movie", sort="vote_average.desc", filters={"genre": "16", "language": "ja", "voteAverageGte": "7.5", "voteCountGte": "50"})),
    ]
    return [
        lane(
            f"lists-{slug(title)}",
            title,
            query,
            "smart-collections",
            min_items=5,
            tags=("curated", "smart-collection"),
        )
        for title, query in definitions
    ]
'''
    text = replace_once(text, old, new, "smart list definitions")
    return replace_once(
        text,
        'tab("lists", "Lists", curated_lists(), 16, 8, {"lists": 16}),',
        'tab("lists", "Lists", curated_lists(), 16, 8, {"smart-collections": 12, "configured-lists": 6}),',
        "smart list pool budgets",
    )


def patch_service(text: str) -> str:
    if "final combined = <SeerrDiscoverySection>[...configured, ...tab.sections];" in text:
        return text
    old = '''  /// Replaces non-executable authoring placeholders in the Lists tab with the
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
'''
    new = '''  /// Adds the user's real configured external lists to the always-available
  /// smart-collection baseline. Configured lists are inserted first and carry
  /// high priority, while pool budgets prevent them from monopolising a normal
  /// rotating session. The full catalogue index still exposes every list.
  SeerrDiscoveryCatalogue mergeIntoCatalogue(
    SeerrDiscoveryCatalogue catalogue,
  ) {
    final configured = configuredSections();
    if (configured.isEmpty) return catalogue;

    final tabs = <SeerrDiscoveryTab>[];
    for (final tab in catalogue.tabs) {
      if (tab.id != 'lists') {
        tabs.add(tab);
        continue;
      }
      final combined = <SeerrDiscoverySection>[...configured, ...tab.sections];
      final budget = combined.length < tab.initialLaneBudget
          ? combined.length
          : tab.initialLaneBudget;
      final minimum = combined.length < tab.minimumLaneCount
          ? combined.length
          : tab.minimumLaneCount;
      final configuredBudget = configured.length.clamp(1, 6).toInt();
      tabs.add(
        SeerrDiscoveryTab(
          id: tab.id,
          title: tab.title,
          sections: combined,
          initialLaneBudget: budget < 1 ? 1 : budget,
          minimumLaneCount: minimum < 1 ? 1 : minimum,
          poolBudgets: {
            ...tab.poolBudgets,
            'configured-lists': configuredBudget,
          },
        ),
      );
    }
    return SeerrDiscoveryCatalogue(
      schemaVersion: catalogue.schemaVersion,
      tabs: tabs,
    );
  }
'''
    return replace_once(text, old, new, "additive configured lists merge")


def patch_index(text: str) -> str:
    if "'collections' => 'Curated Collections'" in text:
        return text
    return replace_once(
        text,
        "      'lists' => 'Curated Lists',\n",
        "      'lists' => 'Curated Lists',\n"
        "      'collections' => 'Curated Collections',\n",
        "smart collection index label",
    )


def apply(path: Path, transform, check: bool) -> bool:
    original = path.read_text(encoding="utf-8")
    patched = transform(original)
    changed = patched != original
    if check:
        if changed:
            raise RuntimeError(f"{path.relative_to(ROOT)} is not patched")
        return False
    if changed:
        path.write_text(patched, encoding="utf-8")
    return changed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    changed = []
    for path, transform in (
        (GENERATOR, patch_generator),
        (SERVICE, patch_service),
        (INDEX, patch_index),
    ):
        if apply(path, transform, args.check):
            changed.append(str(path.relative_to(ROOT)))
    if args.check:
        print("smart_lists_patch=present")
    else:
        print("smart_lists_patch=applied")
        for path in changed:
            print(f"changed={path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
