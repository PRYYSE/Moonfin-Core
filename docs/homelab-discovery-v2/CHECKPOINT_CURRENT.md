# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-08 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point. Read this file and `docs/AI_PROJECT_STATE.md`, then use `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md` for implementation order and `docs/UPSTREAM_UPDATE_PROTOCOL.md` for future official Moonfin releases.

Do not restart completed work or modify the live server during GitHub-only completion work.

## Current boundary

The interrupted **shared source-aware Flutter personalisation batch is complete and verified**.

**Verified product source:** `5d9f3e63d644f303db918b02d31bf55be7e92346`  
**Workflow:** `34189599805` / run **#102 — GREEN**

Documentation-only commits may be newer than the verified product source. `5d9f3e63...` remains the code/build acceptance point until another source-changing full build passes.

Do **not** redo this batch. The next large implementation batch is the **Web completion pass**.

## #102 verification evidence

Focused validation job `101944756312` passed:

- route integration gate
- 486-lane authoring/compiler gate
- 8 Python catalogue tests
- strict Dart format gate
- Discovery overlay analysis
- complete `test/homelab_discovery` suite: **88 tests passed**
- narrow custom-scope gate

Full candidate job `101945260461` passed:

- Web release build
- Android `mobile-beta` APK
- Android `androidTv-beta` APK
- package metadata/checksum generation
- artifact upload

Verified artifact:

- ID `10042251886`
- name `homelab-discovery-v2-candidates-5d9f3e63d644f303db918b02d31bf55be7e92346`
- size `304648360` bytes
- digest `sha256:aae6742a1c300a3f6aef66c9a3e1af67a545505c7894282add9346052d7baab4`
- expires `2026-09-22T05:35:04Z`

The downloaded ZIP digest was independently recomputed and matched the GitHub artifact digest. Internal candidate checksums were also independently recomputed and matched `SHA256SUMS.txt`:

- Android TV APK: `18edb7f1eba31bc287b69a2b12327d9b8b030a6c502cd91bff10286d5979c921`
- Android mobile APK: `15fa5131a477e7d45e44b4e85b8c21906408cd9ba4cac30d3d0c7f2551f19f24`
- Web tarball: `547cba256df6217e4791ca8ec2aa5219982003d013cee5ef1c41cf3cc44b2334`

`BUILD_INFO.txt` confirms:

- source SHA `5d9f3e63d644f303db918b02d31bf55be7e92346`
- Flutter `3.44.1`
- app `2.5.1+30000149`
- Android TV `2.5.1` / build `2000016`
- mobile flavour `mobile-beta`
- TV flavour `androidTv-beta`
- CI Android signing `debug-fallback-not-for-deployment`

Production Android signing remains protected and must preserve cert SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`.

## Source-aware personalisation completed

Flutter now has two truthful personalisation paths:

1. provenance-specific source adapters in `discovery_personal_sources.dart`;
2. explicit generic affinity policies in `discovery_personal_policy.dart`.

`HomeLabDiscoveryPersonalisation` uses one of those paths only. Unknown structural/context strategies have no generic fallback and fail closed.

### Proven source-specific strategy identifiers

Supported now:

- `recent-history`
- `favourites`
- `watchlist`
- `high-ratings`
- `likes`
- `mixed-positive`
- `anime-recent-history`
- `anime-favourites`
- `anime-watchlist`
- `anime-high-ratings`
- `recently-added`
- `trending-anime`

Provenance:

- recent history -> Jellyfin played movies plus played episodes resolved to their series
- favourites -> Jellyfin favourites
- watchlist -> Seerr watchlist
- high ratings -> Jellyfin personal rating >= 8
- likes -> Jellyfin positive-like state
- mixed positive -> deduped union of favourites/high-ratings/likes/watchlist
- recently added -> direct Jellyfin DateCreated-descending movie/series source
- trending anime -> direct Seerr trending filtered to anime
- anime variants -> same proven source with anime-only enforcement

### Generic affinity strategy identifiers retained

Supported:

- `movie-affinity`
- `series-affinity`
- `anime-affinity`
- `short-runtime-affinity`
- `older-affinity`
- `recent-affinity`
- `highly-rated-unseen`
- `anime-action-affinity`
- `anime-fantasy-affinity`
- `anime-romance-drama-affinity`
- `anime-highly-rated-unseen`
- `anime-recent-affinity`
- `anime-older-affinity`
- `anime-movie-affinity`
- `anime-short-affinity`

These are fixed explicit policies with result constraints. Their row index selects only a deterministic upstream recommendation source; it does not define lane meaning.

### Bounded source behaviour

- Discovery source page size: 15
- maximum source snapshot: 60 items
- maximum recommendation seeds: 2
- maximum rated candidates: 100
- maximum Seerr watchlist pages: 2
- source pools, recommendation results and section snapshots are cached
- force refresh clears source/recommendation snapshots
- source seed items are excluded from their own recommendation results
- canonical identity dedup is enforced
- malformed/non-positive TMDB identity is discarded
- local Jellyfin identity is preserved only when real
- external Seerr results never receive fabricated local ownership
- source deep paging reports totals for the actual bounded snapshot

## Intentionally fail-closed personal families

Any personalised strategy not in the two supported mappings above remains unsupported.

Known authored fail-closed groups include:

- novelty/random: `novelty`, `anime-novelty`, personalised “something different” variants
- rewatch/context: `rewatch`, `comfort-rewatch-candidates`, `recent-discovery-context`
- structural series: `limited-series`, `one-season-wonders`, `long-running-favourites`, `weekend-binge`
- structural anime: `anime-specials`, `anime-one-season`, `anime-long-running`, `anime-bingeable`, `anime-completed`, `anime-continuing`, `anime-short-runs`
- other structural/availability-context personalised labels without an exact proven source/filter, including “popular but not in your library” style variants

Unsupported sections are filtered before tab composition/I/O. Direct deep requests fail explicitly. Do not re-enable them by approximation.

## Stable / rollback state

Live remains deliberately untouched:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Recovery refs remain intact:

- `archive/pre-v2-main-2026-09-06` -> `cfe9c5c1a4c32d1c0828eff5ed41ea3a2947d126`
- `archive/seerr-discovery-v1-2026-09-06` -> `aa604b6cdc0083cebe8762f85ede896024f88725`
- `archive/live-web-a9c789-2026-09-06` -> `a9c789fff317b41bba268d3a213439e23b8d1af5`
- `archive/android-accepted-e7e5ab-2026-09-06` -> `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`

## Current verified webOS milestone

Repository `PRYYSE/Smart-TV`, branch `homelab/webos-discovery-v2`.

- verified source `a3a3317894a90bbab8b12cc7764187a8c5591369`
- workflow `34184420915` / #50 GREEN
- 16/16 suites, 85/85 tests
- artifact `10040048352`
- digest `sha256:6e765d2ad65fcd0cfb487bfc13075da209332e3f5004ea3e14a434b8d2661eef`
- IPK manifest SHA-256 `24e7a3af27c6ddf77d747b9990780073edb692ad6cef6453957d3afc45ee8e06`
- identity `org.moonfin.webos` / `2.7.0` / `index.html`

Preserved Smart-TV v1 baseline/candidate remain untouched. No physical LG acceptance is claimed.

## Semantic accounting

Accepted shared reference remains **486 authored / 481 active**.

Current truthful webOS static capability ceiling remains **468 executable active sections** before runtime sparse/error hiding. Its 13 deliberately unsupported active lanes remain intentionally disabled.

## Completed work that must not be redone

- isolated Home Lab Discovery architecture + guarded stock fallback
- deterministic concurrent lane loading and post-fetch presentation
- catalogue/compiler validation
- membership/NSFW filtering
- persistent rotation
- landing + deep `See All`
- TV focus/D-pad hardening
- external/local identity correction
- explicit generic affinity contract
- **real source-aware personalisation adapters with bounded request cost, paging, dedup, identity and refresh tests**
- full Web/mobile/Android-TV candidate gate at `5d9f3e63...`
- existing advanced webOS code-side work at its verified checkpoint

## Exact next large batch

Begin the **Web completion pass** only after this checkpointing run ends.

Scope for that next batch:

- Web pointer/mouse/touch/keyboard behaviour
- responsive layouts and resize behaviour
- landing/deep browsing integration
- details/request/local Jellyfin playback routing
- browser history/Back and retained state
- refresh/retry/error/genuine-empty distinctions
- missing artwork/provider identity and malformed-data handling
- recommendation diversity/dedup quality on Web
- memory/performance and guarded fallback
- focused tests and reproducible Web candidate evidence

Do not redo source-aware personalisation unless a concrete integration defect is found.

## Do not

- begin physical acceptance yet
- delete recovery refs/candidates
- modify the live server during GitHub-only work
- regenerate Android signing
- change `org.moonfin.webos` without deliberate migration
- fake unsupported semantics
- treat green CI/packages as physical acceptance
