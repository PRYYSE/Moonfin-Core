# AI Project State

**Updated:** 2026-09-08 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across the Home Lab Moonfin Discovery product before physical-device, live-service or production acceptance.

The shared source-aware Flutter personalisation batch is now **verified complete**. The next large implementation phase is the **Web completion pass**. Do not restart the source-aware personalisation work and do not move to physical acceptance yet.

Durable plan: `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`  
Mandatory official-update procedure: `docs/UPSTREAM_UPDATE_PROTOCOL.md`

## Repositories / current verified sources

### Moonfin-Core

- repository: `PRYYSE/Moonfin-Core`
- branch: `homelab/discovery-v2`
- **current verified Flutter/Web/Android product source:** `5d9f3e63d644f303db918b02d31bf55be7e92346`
- commit: `ci(discovery-v2): verify personal sources [full-build]`
- workflow `34189599805` / run **#102: GREEN**
- focused-validation job `101944756312`: GREEN
- full candidate job `101945260461`: GREEN
- focused gate passed route integration, 486-lane authoring/compiler validation, strict format, overlay analysis, full `test/homelab_discovery`, and narrow-scope validation
- Discovery Flutter tests: **88 passed**
- catalogue Python tests: **8 passed**
- full candidate build passed Web release + Android `mobile-beta` APK + Android `androidTv-beta` APK + packaging/upload

Verified candidate artifact:

- ID `10042251886`
- name `homelab-discovery-v2-candidates-5d9f3e63d644f303db918b02d31bf55be7e92346`
- size `304648360` bytes
- artifact digest `sha256:aae6742a1c300a3f6aef66c9a3e1af67a545505c7894282add9346052d7baab4`
- expires `2026-09-22T05:35:04Z`
- downloaded artifact digest independently rechecked and matched GitHub metadata
- Android TV APK SHA-256 `18edb7f1eba31bc287b69a2b12327d9b8b030a6c502cd91bff10286d5979c921`
- Android mobile APK SHA-256 `15fa5131a477e7d45e44b4e85b8c21906408cd9ba4cac30d3d0c7f2551f19f24`
- Web tarball SHA-256 `547cba256df6217e4791ca8ec2aa5219982003d013cee5ef1c41cf3cc44b2334`
- `BUILD_INFO.txt` confirms source SHA `5d9f3e63...`, Flutter `3.44.1`, app `2.5.1+30000149`, Android TV `2.5.1` / build `2000016`
- CI Android candidates remain `debug-fallback-not-for-deployment`; production signing must preserve the existing Home Lab certificate

Documentation-only commits may be newer than `5d9f3e63...`. That SHA remains the current product/build acceptance point until another source-changing full build passes.

### Smart-TV / webOS

- repository: `PRYYSE/Smart-TV`
- branch: `homelab/webos-discovery-v2`
- verified product source: `a3a3317894a90bbab8b12cc7764187a8c5591369`
- workflow `34184420915` / #50: GREEN
- 16/16 suites, 85/85 tests
- artifact `10040048352`
- artifact digest `sha256:6e765d2ad65fcd0cfb487bfc13075da209332e3f5004ea3e14a434b8d2661eef`
- IPK manifest SHA-256 `24e7a3af27c6ddf77d747b9990780073edb692ad6cef6453957d3afc45ee8e06`
- identity `org.moonfin.webos` / `2.7.0` / `index.html`

Preserved Smart-TV rollback baseline remains `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.

## Shared personalisation contract now verified at `5d9f3e63...`

Flutter personalisation now has two truthful execution paths. Unknown semantics have no generic fallback.

### 1. Provenance-specific source adapters

`HomeLabDiscoveryPersonalSources` now supports these exact authored strategy identifiers:

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

Production provenance is explicit:

- recent history: Jellyfin played movies plus played episodes resolved back to their series
- favourites: Jellyfin favourites
- watchlist: Seerr watchlist
- high ratings: Jellyfin personal ratings >= 8
- likes: Jellyfin positive-like state
- mixed positive: deterministic deduped union of favourites, high ratings, likes and watchlist
- recently added: direct Jellyfin DateCreated-descending movie/series source
- trending anime: direct Seerr trending source filtered to anime
- anime source variants apply the same proven source while enforcing anime-only candidates/results

Recommendation-backed source families select only from the already-correct source pool, then fetch recommendations from at most **2 seeds**. The seed hash can choose a candidate inside that source but cannot redefine lane meaning.

### 2. Generic affinity policies retained

The pre-existing explicit generic affinity path remains supported for:

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

These use fixed policies and explicit result constraints; row selection does not invent the authored semantic label.

### Request cost, paging, dedup and identity safeguards

- source page size: 15
- bounded source snapshot: 60 items
- recommendation seeds: maximum 2 per source-specific recommendation lane
- rated source candidate scan: maximum 100
- Seerr watchlist scan: maximum 2 pages
- source snapshots and per-seed recommendations are cached and shared across concurrent landing rows
- source pool items are excluded from their own recommendation result set
- recommendation results are deterministically interleaved and deduplicated by canonical identity
- malformed/non-positive TMDB identity is omitted before presentation
- real local Jellyfin identity is preserved only when actually present
- external Seerr/TMDB recommendations are never fabricated as local Jellyfin ownership
- source-specific deep paging reports the truth about the bounded snapshot rather than pretending to expose an unbounded server total
- force refresh clears source/recommendation snapshots

### Intentionally fail-closed personal families

Any personalised strategy not present in either supported mapping above remains unsupported and is excluded before composition/I/O. Direct deep access fails explicitly.

Known authored fail-closed families include:

- novelty/random: `novelty`, `anime-novelty` and equivalent “something different” personalised variants
- rewatch/context: `rewatch`, `comfort-rewatch-candidates`, `recent-discovery-context`
- structural series semantics: `limited-series`, `one-season-wonders`, `long-running-favourites`, `weekend-binge`
- structural anime semantics: `anime-specials`, `anime-one-season`, `anime-long-running`, `anime-bingeable`, `anime-completed`, `anime-continuing`, `anime-short-runs`
- other personalised structural/availability-context labels without an exact source/filter contract, including “popular but not in your library” style variants

Do not re-enable these by approximation. They require a source/filter that proves the advertised meaning.

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

## Semantic accounting

Accepted shared reference remains **486 authored / 481 active**.

Current truthful webOS static capability ceiling remains **468 executable active sections** before runtime sparse/error hiding. Its 13 deliberately unsupported active lanes remain unchanged and must not be faked.

## Completed foundations that must not be redone

### Flutter/Web/Android

- isolated Home Lab Discovery architecture with guarded stock fallback
- deterministic concurrent loading/post-fetch presentation
- 486-lane authoring catalogue/compiler validation
- membership/NSFW filtering
- persistent lane rotation
- landing + deep `See All`
- TV focus/D-pad hardening
- truthful generic affinity personalisation
- **truthful source-specific personalisation adapters and fail-closed unsupported contract**
- source-level paging/dedup/identity/force-refresh regression coverage
- reproducible Web/mobile/Android-TV candidate builds at `5d9f3e63...`

### webOS

The advanced isolated webOS implementation remains complete to its existing code-side checkpoint. Do not rebuild it during the next Web pass. Reconcile it only later against the final shared contract.

No physical LG acceptance is claimed.

## Whole-product GitHub completion order

1. **shared semantic/personalisation source contract — COMPLETE at `5d9f3e63...` / #102**
2. Web completion pass — NEXT
3. Android mobile/tablet completion pass
4. Android TV / Google TV completion pass
5. final webOS reconciliation against corrected shared contracts
6. cross-platform parity/recommendation-quality pass
7. whole-product CI/release engineering
8. official upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance and cutover

## Known acceptance-only work

Still deliberately deferred while GitHub-side work remains:

- Web browser subjective/interactive acceptance
- Android phone/tablet device acceptance
- Android TV / Google TV device acceptance
- physical LG OLED65C6PSA rendering/performance/remote/Back/lifecycle/update acceptance
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
- green CI/package generation is evidence, not physical/product acceptance

## Exact next actions

Start the **Web completion pass** only in the next implementation batch. Review and finish everything code-testable for Web: pointer/keyboard/touch, responsive layout/resize, landing/deep browse, details/request/local playback routing, browser history/Back, retained state/refresh/retry/error/empty distinctions, artwork/identity edge cases, recommendation quality rules, memory/performance, guarded fallback and reproducible Web candidate evidence.

Do not redo the source-aware personalisation batch unless a concrete Web integration defect demonstrates a fault in it.
