#!/usr/bin/env python3

import unittest

import compile_home_lab_discovery_catalogue as compiler
import generate_home_lab_discovery_catalogue as generator


class CatalogueTests(unittest.TestCase):
    def _lookups(self):
        catalogue = generator.build()
        keyword_names = []
        provider_names = []
        for tab in catalogue["tabs"]:
            for section in tab["sections"]:
                query = section["query"]
                keyword_names.extend(query.get("keywordNames") or [])
                keyword_names.extend(query.get("excludeKeywordNames") or [])
                provider_names.extend(query.get("providerNames") or [])
        keywords = {
            compiler.normalise(name): index + 1000
            for index, name in enumerate(dict.fromkeys(keyword_names))
        }
        providers = {
            compiler.normalise(name): index + 5000
            for index, name in enumerate(dict.fromkeys(provider_names))
        }
        return keywords, providers

    def test_authoring_catalogue_has_exact_planned_counts(self):
        catalogue = generator.build()
        counts = {tab["id"]: len(tab["sections"]) for tab in catalogue["tabs"]}
        self.assertEqual(
            counts,
            {
                "for-you": 16,
                "movies": 130,
                "series": 140,
                "anime": 160,
                "new-upcoming": 20,
                "lists": 20,
            },
        )
        self.assertEqual(sum(counts.values()), 486)

    def test_lists_are_deep_executable_smart_collections(self):
        catalogue = generator.build()
        lists = next(tab for tab in catalogue["tabs"] if tab["id"] == "lists")
        self.assertEqual(len(lists["sections"]), 20)
        self.assertEqual(lists["poolBudgets"]["smart-collections"], 12)
        self.assertEqual(lists["poolBudgets"]["configured-lists"], 6)
        for section in lists["sections"]:
            query = section["query"]
            self.assertIn(query["source"], {"discoverMovies", "discoverTv"})
            self.assertNotEqual(query.get("listProvider"), "server")
            self.assertNotIn("listId", query)
            self.assertEqual(section["pool"], "smart-collections")
            self.assertTrue(section["expandable"])
        titles = {section["title"] for section in lists["sections"]}
        self.assertIn("Essential Sci-Fi", titles)
        self.assertIn("Prestige TV Essentials", titles)
        self.assertIn("Anime Starter Pack", titles)
        self.assertIn("Best Anime Movies", titles)

    def test_full_synthetic_lookup_compiles_all_authoring_lanes(self):
        keywords, providers = self._lookups()
        catalogue, diagnostics = compiler.compile_catalogue(keywords, providers)
        counts = {tab["id"]: len(tab["sections"]) for tab in catalogue["tabs"]}
        self.assertEqual(sum(counts.values()), 486)
        self.assertEqual(diagnostics["droppedSections"], [])

        for tab in catalogue["tabs"]:
            for section in tab["sections"]:
                query = section["query"]
                self.assertNotIn("keywordNames", query)
                self.assertNotIn("excludeKeywordNames", query)
                self.assertNotIn("providerNames", query)

    def test_semantic_aliases_still_require_exact_upstream_names(self):
        lookup = {
            "serial killer": 101,
            "post apocalyptic future": 102,
            "based on true story": 103,
            "video game": 104,
            "superhero": 105,
        }
        self.assertEqual(
            compiler.resolve_one("Serial Killers", lookup, compiler.KEYWORD_ALIASES),
            101,
        )
        self.assertEqual(
            compiler.resolve_one("Post-Apocalyptic", lookup, compiler.KEYWORD_ALIASES),
            102,
        )
        self.assertEqual(
            compiler.resolve_one("Based on True Events", lookup, compiler.KEYWORD_ALIASES),
            103,
        )
        self.assertEqual(
            compiler.resolve_one("Video Games", lookup, compiler.KEYWORD_ALIASES),
            104,
        )
        self.assertEqual(
            compiler.resolve_one("Superheroes", lookup, compiler.KEYWORD_ALIASES),
            105,
        )
        self.assertIsNone(
            compiler.resolve_one(
                "Medical Drama",
                {"hospital": 999},
                compiler.KEYWORD_ALIASES,
            )
        )

    def test_provider_compilation_uses_current_seerr_pipe_semantics(self):
        keywords, providers = self._lookups()
        catalogue, _ = compiler.compile_catalogue(keywords, providers)
        section = next(
            section
            for tab in catalogue["tabs"]
            for section in tab["sections"]
            if section["id"] == "movies-provider-netflix"
        )
        filters = section["query"]["filters"]
        self.assertEqual(filters["watchRegion"], "AU")
        self.assertEqual(filters["watchProviders"], str(providers["netflix"]))

    def test_unresolved_semantic_lane_is_dropped_not_broadened(self):
        catalogue, diagnostics = compiler.compile_catalogue({}, {})
        ids = {
            section["id"]
            for tab in catalogue["tabs"]
            for section in tab["sections"]
        }
        self.assertNotIn("movies-theme-time-travel", ids)
        self.assertNotIn("movies-provider-netflix", ids)
        self.assertIn("movies-trending", ids)
        self.assertGreater(len(diagnostics["droppedSections"]), 0)


if __name__ == "__main__":
    unittest.main()
