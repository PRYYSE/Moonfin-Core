# AI Project State

**Updated:** 2026-09-08 Australia/Adelaide

## Current objective

Complete **everything reasonably possible in GitHub/code across the entire Home Lab Moonfin Discovery product before physical-device, live-service or production acceptance**.

Scope:

- Web
- Android mobile/tablet
- Android TV / Google TV
- LG webOS
- shared catalogue/compiler/schema/semantic contracts
- personalisation/recommendation quality
- details/request/playback integration
- navigation/focus/back
- state/cache/error handling
- performance/constrained-device behaviour
- tests, CI, reproducible builds/packages
- cross-platform parity
- official Moonfin update/release engineering

Durable plan: `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`  
Mandatory official-update procedure: `docs/UPSTREAM_UPDATE_PROTOCOL.md`

**Do not move to physical LG/device acceptance merely because one platform is green.** Physical/live acceptance becomes the primary phase only when this file explicitly records that no known GitHub/code-side work remains.

## Repositories / current verified sources

### Moonfin-Core

- repository: `PRYYSE/Moonfin-Core`
- branch: `homelab/discovery-v2`
- **current verified Flutter/Web/Android product source:** `e88fd308521287b326ba58e31c1e4457fba62c60`
- workflow `34186256083` / run **#95: GREEN**
- focused validation: route integration, 486-lane authoring/compiler tests, format, analysis, Discovery tests and narrow-scope gate all passed
- full candidate build: Web release + `mobile-beta` APK + `androidTv-beta` APK all passed
- artifact ID `10041082791`
- artifact name `homelab-discovery-v2-candidates-e88fd308521287b326ba58e31c1e4457fba62c60`
- artifact size `304511071` bytes
- artifact digest `sha256:20a85a58060ed22862f0b2b69ab1c7c2891d7da0646be8c7a21c1a74bf4372d6`
- artifact expires `2026-09-22`
- CI Android candidates remain debug-fallback signing and are not deployment packages; accepted production signing identity remains protected separately

The branch may contain newer documentation-only commits. `e88fd308...` remains the current product/build acceptance point until another source-changing full build passes.

### Smart-TV / webOS

- repository: `PRYYSE/Smart-TV`
- branch: `homelab/webos-discovery-v2`
- verified product source: `a3a3317894a90bbab8b12cc7764187a8c5591369`
- workflow `34184420915` / #50: GREEN
- 16/16 suites, 85/85 tests
- artifact `10040048352`
- artifact digest `sha256:6e765d2ad65fcd0cfb487bfc13075da209332e3f5004ea3e14a434b8d2661eef`
- IPK manifest SHA-256 `24e7a3af27c6ddf77d747b9990780073edb692ad6cef6453957d3afc45ee8e06`
- identity remains `org.moonfin.webos` / `2.7.0` / `index.html`

Preserved Smart-TV rollback baseline remains `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.

## Stable / recovery state

Live remains deliberately untouched as rollback:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Recovery refs remain intact:

- `archive/pre-v2-main-2026-09-06` -> `cfe9c5c1a4c32d1c0828eff5ed41ea3a2947d126`
- `archive/seerr-discovery-v1-2026-09-06` -> `aa604b6cdc0083cebe8762f85ede896024f88725`
- `archive/live-web-a9c789-2026-09-06` -> `a9c789fff317b41bba268d3a213439e23b8d1af5`
- `archive/android-accepted-e7e5ab-2026-09-06` -> `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`

Accepted Android signing cert SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`. Never regenerate signing.

## Completed shared semantic slice at `e88fd308...`

The arbitrary Flutter personalisation slot/hash behaviour has been removed.

### Truthful personal strategy contract

New `discovery_personal_policy.dart` provides an explicit capability policy. The current upstream `Since You Watched` source is used only for generic affinity semantics that can be represented truthfully with explicit result constraints.

Currently executable generic affinity strategies include:

- `movie-affinity`
- `series-affinity`
- `anime-affinity`
- `short-runtime-affinity`
- `older-affinity`
- `recent-affinity`
- `highly-rated-unseen`
- anime action/fantasy/romance-drama/highly-rated-unseen/recent/older/movie/short affinity variants

The deterministic row index now only chooses a repeatable recommendation seed. It no longer invents the semantic meaning of an authored lane.

### Fail-closed source provenance

Strategies requiring a source that the current Flutter adapter cannot prove now fail closed instead of silently using unrelated data. This currently includes source-specific families such as:

- recent history
- favourites
- watchlist
- high ratings
- likes
- mixed positive signals
- novelty/random
- rewatch
- recently added
- trending/popular anime direct sources
- structural/context series/anime labels

Unsupported personal sections are filtered before tab composition/I/O, so they do not consume lane budget or network slots. Landing loading hides them cleanly. Deep loading fails explicitly if an unsupported section is invoked directly.

### Identity correction

The personalisation bridge no longer fabricates local Jellyfin ownership for external Seerr recommendations:

- local Jellyfin item -> status available + real Jellyfin ID
- external Seerr item -> Seerr status retained, local Jellyfin ID remains null
- invalid/non-positive TMDB identity -> omitted

This prevents external recommendations from being routed as fake local media.

### Authored meaning preserved

The authored Discovery lane title remains authoritative. An unrelated upstream recommendation-seed title can no longer silently redefine the catalogue row.

### Regression coverage

Tests now prove:

- source-specific/structural labels fail closed without recommendation-row I/O
- supported affinities use explicit fixed policy mappings rather than hash selection
- anime/genre/rating/unseen constraints are applied
- external recommendations do not receive fabricated local identity
- invalid TMDB IDs are omitted
- unsupported personal lanes hide cleanly
- unsupported deep personal requests fail explicitly
- ineligible sections never enter composition or lane I/O

## Completed foundations that must not be redone

### Flutter/Web/Android

- isolated Home Lab Discovery architecture with guarded stock fallback
- deterministic concurrent loading/post-fetch presentation
- 486-lane authoring catalogue/compiler validation
- membership/NSFW filtering
- persistent lane rotation
- landing + deep `See All`
- TV focus/D-pad hardening
- reproducible Web/mobile/Android-TV candidate builds
- current truthful personal capability gate described above

### webOS

webOS is already code-side advanced and should be reconciled later, not rebuilt:

- guarded six-tab catalogue UI + stock Seerr fallback
- fail-closed planner/filter/sort/date-token behaviour
- authenticated narrow Moonbase Seerr proxy
- bounded lane loading, deterministic composition, membership/dedup and persistent rotation
- real Jellyfin/Seerr personalisation sources with unsupported semantics failing closed
- incremental personalised deep paging while landing remains one logical page
- bounded retained deep-state LRU, refresh invalidation and stale-load generation guards
- exact landing/deep focus restoration and remotely reachable retry/Load More actions
- owned results preserve Jellyfin identity and route to real local detail/playback
- refresh failure preserves usable rows
- code-reviewed landing/detail/deep Back history
- performance-tier-aware old-TV visual policy
- compact <=800 px deep grid with Enact VirtualGrid positioning preserved
- poster failure fallback, malformed identity filtering and explicit exhausted-list state
- opt-in privacy-safe aggregate recommendation-quality diagnostics

No physical LG acceptance is claimed.

## Semantic accounting

Accepted shared reference remains **486 authored / 481 active**.

Current truthful webOS static capability ceiling remains **468 executable active sections** before runtime sparse/error hiding. Thirteen active lanes remain deliberately unsupported because current data does not prove their advertised semantics:

- For You: Continue Exploring
- Series: Limited-Series Spotlight; Continue Exploring Series; One-Season Wonders; Long-Running Favourites; Weekend Binge
- Anime: Anime Specials & TV Movies; One-Season Anime; Long-Running Anime; Bingeable Anime; Completed Anime; Continuing Anime; Anime Miniseries & Short Runs

Do not re-enable these by approximation.

## Remaining shared work before platform completion passes

The fail-closed correction is an important safety milestone, not final personalisation parity.

Next, build **real source-specific Flutter personalisation adapters** for the source semantics already proven in webOS where current Jellyfin/Seerr APIs permit it, including history/favourites/watchlist/high-ratings/likes/positive signals and direct recommendation sources. Requirements:

- real provenance, not labels over generic rows
- deterministic bounded request cost
- truthful pagination/totals
- dedup and identity preservation
- no regression to unsupported structural/context semantics
- tests for every supported source and explicit unsupported family

Only after this shared source layer is complete should the Web-specific completion pass begin.

## Whole-product GitHub completion order

1. finish shared semantic/personalisation source contract
2. Web completion pass
3. Android mobile/tablet completion pass
4. Android TV / Google TV completion pass
5. final webOS reconciliation against corrected shared contracts
6. cross-platform parity/recommendation-quality pass
7. whole-product CI/release engineering
8. official upstream update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance and cutover

See `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md` for full gates.

## Official Moonfin update policy

`docs/UPSTREAM_UPDATE_PROTOCOL.md` is mandatory for every official Moonfin update.

Core rule: start from the new official upstream release, generate an overlap/impact report, then reapply/adapt the narrow Home Lab overlay. Do not simply carry an old modified fork forward.

Every update must protect Web deployment paths, Android package/signing/versionCode, Android TV compatibility, webOS `org.moonfin.webos`, rollback refs/candidates, semantic contracts and the complete cross-platform regression gate. Automated release detection/reporting/building is allowed; automatic production merge/promotion/deployment is prohibited.

## Known future acceptance-only work

These remain real gates but are deliberately not the primary phase while GitHub-side work remains:

- physical LG C6 rendering/performance/remote/Back/lifecycle/update acceptance
- Android phone/tablet device acceptance
- Android TV / Google TV device acceptance
- Web browser subjective/interactive acceptance
- actual Home Lab Jellyfin/Seerr recommendation-quality capture
- real request/detail/local playback acceptance
- live server/cutover/deployment

## Important decisions / safeguards

- quality, maintainability and truthful semantics over nominal lane count
- unsupported semantics fail closed
- preserve real Jellyfin identity whenever ownership is proven
- preserve old-TV request/memory limits
- existing diagnostic logging remains opt-in; no new always-on telemetry
- preserve recovery refs and accepted candidates
- never regenerate Android signing
- never change `org.moonfin.webos` without deliberate migration
- do not modify the live server during GitHub-only work
- green CI/package generation is evidence, not completion

## Exact next actions

1. Implement the real shared Flutter source-specific personalisation layer for history/favourites/watchlist/high-ratings/likes/positive/direct sources that current APIs can truthfully provide.
2. Preserve fail-closed behaviour for structural/context semantics that remain unproven.
3. Add source-level provenance, paging, identity and dedup tests.
4. Run focused validation plus a full Web/mobile/Android-TV candidate build and checkpoint the exact verified source.
5. Continue to the Web completion pass only after the shared source layer is credible.
