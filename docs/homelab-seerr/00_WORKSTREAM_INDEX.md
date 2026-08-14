# Home Lab Seerr Endless Discovery - Workstream Index

Status: active design/implementation on `homelab/seerr-discovery-v1-staging`. No release branch or installed client is changed by this work.

## Product definition

The Seerr area is not another copy of the existing Home/Movies/TV/Anime hubs. Those hubs keep their accepted 33 Moonbase editorial rows and local-library behaviour. Seerr is the deep discovery product reached from the existing discovery entry point.

"Endless" means all of the following, not merely a long list of static carousels:

1. **Breadth:** a large catalogue of useful lanes covering genres, combinations, moods/themes, eras, runtimes, ratings, studios, networks, languages, providers, seasonal windows, external lists and personalised seeds.
2. **Depth:** every eligible lane opens a full filtered result screen and can paginate through the underlying result set.
3. **Rotation:** not every optional lane appears every session. Stable anchor lanes remain, while discovery pools rotate so revisits expose different routes into the catalogue.
4. **Deduplication:** adjacent/visible lanes should not repeatedly show the same small set of titles when alternatives exist.
5. **Rabbit holes:** media, people, genres, studios, networks, collections, keywords/tags, similar items and recommendations can lead to further browse surfaces.
6. **Personalisation:** history, favourites, likes/ratings, watchlist and library data influence some lanes without making the whole page a filter bubble.
7. **Server ownership:** future catalogue/list changes should propagate without APK/IPK rebuilds wherever the installed client schema already supports them.
8. **Cross-platform parity:** Web, Android phone/tablet, LG webOS and Android TV consume the same content definitions but use platform-appropriate interaction/focus UI.

## Workstreams

| ID | File | Scope | Current state |
|---|---|---|---|
| 01 | `01_CURRENT_CAPABILITY_AUDIT.md` | Existing Moonfin, Seerr, request and list capability | researched; document first |
| 02 | `02_ENDLESS_ENGINE_AND_ROTATION.md` | Catalogue pools, anchors, rotation, pagination, refresh and session model | design in progress |
| 03 | `03_MOVIES_CATALOGUE.md` | Deep Movie taxonomy and exact filter strategy | expand heavily |
| 04 | `04_SERIES_CATALOGUE.md` | Deep Series taxonomy and exact filter strategy | expand heavily |
| 05 | `05_ANIME_CATALOGUE.md` | Anime-specific taxonomy, seasonal logic and safety | expand heavily |
| 06 | `06_PERSONALISATION_AND_DEDUP.md` | Per-user seeds, diversity, novelty, dedup and cold start | design in progress |
| 07 | `07_BROWSE_FILTER_SEARCH_RABBITHOLES.md` | See All, infinite grid, filters, search and drill-down navigation | existing pieces identified |
| 08 | `08_REQUESTS_STATES_QUALITY_LOCAL_ROUTING.md` | Preserve base Moonfin request/profile/season flow and consistent ownership states | audit proves most is already present |
| 09 | `09_EXTERNAL_LISTS_AND_CURATION.md` | MDBList, Letterboxd, IMDb, TMDb lists/collections and editorial rotations | existing list service identified |
| 10 | `10_SERVER_CONFIG_CACHE_AUTH.md` | Server-delivered schema, validation, caching, auth and failure isolation | architecture in progress |
| 11 | `11_CROSS_PLATFORM_UX.md` | Web, Android, LG and Android TV interaction/focus rules | design after shared core |
| 12 | `12_REFERENCE_PROJECT_RESEARCH.md` | Seerr native, SeerrFin, Jellyfin Enhanced and features worth adapting | research in progress |
| 13 | `13_IMPLEMENTATION_VALIDATION_ROLLOUT.md` | Code order, tests, ServerBox gates, build/deploy boundaries and rollback | maintained continuously |

## Implementation rule

Do not jump directly from this index to client UI work. Work through the numbered files, recording:

- confirmed current capability;
- upstream/API evidence;
- exact desired behaviour;
- data/config schema required;
- code locations to change;
- tests/gates;
- server-only versus rebuild-required changes;
- open risks and intentionally deferred items.

A workstream is only marked complete when both design and executable implementation/tests for its shared-core portion exist. Visual platform polish can follow after the shared behaviour is stable.

## Immediate correction from the first pass

The initial fallback catalogue of roughly thirty sections is a scaffold, not the target catalogue. It should not be presented as "endless". The intended design is a much larger server-delivered catalogue plus rotation/depth, with the built-in Dart fallback kept deliberately smaller for recovery.

## Existing request-flow assumption

Do not build a replacement quality/profile request system unless a real gap is found. Current Moonfin already has Seerr request sheets, HD/4K selection, season selection, advanced server/profile/root-folder options, saved preferences, quota handling and request-state UI. This phase should reuse that path from every new discovery surface.
