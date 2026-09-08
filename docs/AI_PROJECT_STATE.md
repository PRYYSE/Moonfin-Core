# AI Project State

**Updated:** 2026-09-08 Australia/Adelaide

## Current objective

Home Lab Discovery v2: deliver one polished Discovery experience across Web, Android mobile/tablet, Android TV/Google TV and LG webOS while keeping the custom Moonfin diff narrow and maintainable.

Current implementation slice is **LG/webOS**. The code-side webOS gate is now strong enough that the next slice is controlled physical LG acceptance, not more speculative feature work. Green CI/packages remain milestones only. After LG acceptance, return to all four clients for shared semantic/recommendation/UX/performance/integration refinement and final real-device acceptance.

## Repositories / branches

- `PRYYSE/Moonfin-Core:homelab/discovery-v2`
  - Flutter/Web/Android product source milestone remains `86acba1246ea5e9424fcc96c9729c1e474359c53`
  - documentation/checkpoint commits are newer than product code
- `PRYYSE/Smart-TV:homelab/webos-discovery-v2`
  - current verified product source: `3cf33a70b45854f7db9b703a011511f941f21802`
  - documentation commits may be newer than verified product source
- preserved Smart-TV baseline: `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`

## Completed milestones

### Moonfin Flutter/Web/Android

- isolated Home Lab Discovery architecture and guarded stock fallback
- deterministic concurrent loading/post-fetch presentation
- 486-lane authoring catalogue/compiler validation
- membership filtering, persistent lane rotation and deep `See All`
- landing/deep TV focus hardening
- reproducible Web/mobile/Android-TV candidate builds
- source workflow `34104075134` / #62 GREEN

These clients are **not product-finished**. The webOS semantic audit exposed a shared personalisation-parity issue that must be corrected in the later whole-product pass.

### webOS verified through `3cf33a70b45854f7db9b703a011511f941f21802`

Foundation already complete:

- guarded six-tab catalogue UI + stock `SeerrDiscover` fallback
- aligned fail-closed planner/filter/sort/date policy
- authenticated narrow Moonbase Seerr proxy
- bounded lane loading, deterministic presentation, membership/dedup and persistent lane rotation
- truthful Jellyfin/Seerr personalisation sources; unsupported structural/context labels fail closed
- incremental personalised deep paging while landing stays one logical page
- bounded retained deep-state LRU, refresh invalidation and stale-load generation guards
- exact landing/deep focus restoration and remotely reachable retry/Load More actions
- owned Discovery results preserve reconciled Jellyfin identity and open the real local detail/playback path
- complete refresh failures preserve last usable rows with an explicit warning
- panel-history Back paths are code-reviewed for landing/detail/deep transitions

Latest old-TV/edge/quality hardening:

- performance-tier-aware Discovery visual policy
- low tier uses `w780` backdrops, zero blur, no backdrop scale/fade animation, 240 ms debounce and non-animated row scrolling
- mid tier caps backdrop blur at 4 px; high tier preserves configured quality
- disabled Home backdrops no longer trigger hidden backdrop image requests
- <=800 px viewport uses a smaller deep virtual-grid footprint and tighter spacing
- poster load/network failures fall back cleanly instead of leaving broken-image tiles
- missing/non-numeric/non-positive TMDB identities are removed before presentation
- exhausted populated deep lists explicitly show `End of list`
- active loaded tabs can emit aggregate recommendation-quality snapshots through the existing opt-in diagnostic logger: duplicate rate, sparse/underfilled rows, missing artwork/identity, hidden/failed rows and owned-item ratio; no titles or Jellyfin IDs are included
- no new telemetry service and no increase to personalised landing request depth

Verification:

- Smart-TV workflow `34184135140` / run #49: **GREEN**
- 16/16 focused Discovery/integration suites, 85/85 tests
- strict lint + legacy WebKit compatibility + production Enact build + IPK identity/package verification
- artifact `10039954551`
- artifact digest `sha256:870e681ff9b3023c007b8ee1392e23362b78b1b1ea277a61683836e457fb0e6c`
- IPK manifest SHA-256 `5f7012852c7c0dbad17876cb079ba9eb98e28cfa335b7b1414ec6ce13e29a030`
- identity remains `org.moonfin.webos` / `2.7.0` / `index.html`

## Semantic accounting

Shared accepted reference remains **486 authored / 481 active**, with five known compiler-resolution failures already documented.

Current webOS truthful static capability ceiling remains **468 executable sections** before runtime sparse/error hiding. Thirteen active catalogue lanes remain deliberately ineligible because current data does not prove their advertised series-count/status/context semantics:

- For You: Continue Exploring
- Series: Limited-Series Spotlight; Continue Exploring Series; One-Season Wonders; Long-Running Favourites; Weekend Binge
- Anime: Anime Specials & TV Movies; One-Season Anime; Long-Running Anime; Bingeable Anime; Completed Anime; Continuing Anime; Anime Miniseries & Short Runs

This is an explicit semantic gap. Re-enable only with a truthful, old-TV-appropriate source/filter strategy.

## Cross-platform issue discovered

Current Flutter `lib/features/homelab_discovery/engine/discovery_personalisation.dart` still maps named strategies to deterministic row slots and hashes specialised names while the current stable `RowDataSource.loadSinceYouWatchedRow` is materially simpler than the accepted archived v1 recommendation engine.

Therefore Flutter/Web/Android/Android-TV green CI does **not** prove semantic parity for personal lanes. Do not copy old slot/hash behaviour back into webOS to make counts match. The later whole-product pass must redesign/revalidate shared personalisation semantics and recommendation quality.

## Known issues / blockers

- no physical LG acceptance yet
- actual Home Lab Jellyfin/Seerr recommendation quality and duplication still need real-data capture/review
- physical C6 rendering/performance, remote focus/back, long-text/missing-image presentation and exhausted/sparse paging remain unaccepted
- request actions, owned/local playback and detail-return need controlled real-service/device acceptance
- launch/resume/auth persistence/update compatibility still need real LG acceptance
- Web/mobile/Android-TV still need the later whole-product semantic/UX/performance/integration review and real acceptance
- live server/cutover remains deliberately untouched

## Important decisions / quirks

- quality/maintainability/truthful semantics over nominal lane count or speed
- unsupported catalogue semantics fail closed
- old-TV request and memory cost remain explicit
- preserve real Jellyfin identity when Discovery proves ownership
- existing diagnostic logging is opt-in; quality snapshots must not become always-on telemetry
- preserve webOS v1 and `org.moonfin.webos`
- never regenerate Android signing certificate
- do not equate green CI/package generation with completion
- production legacy state remains rollback until replacement passes acceptance

## Tests/builds

- Smart-TV workflow `34184135140` / #49: GREEN
  - 16/16 suites
  - 85/85 tests
  - lint, legacy compatibility, production build, IPK, identity verification and artifact upload
- Moonfin Flutter source milestone workflow `34104075134` / #62: GREEN

## Exact next actions

1. Prepare and execute controlled **LG OLED65C6PSA acceptance** using verified Smart-TV source `3cf33a70...`, with reversible installation/update and minimal diagnostics.
2. Validate launch/resume/auth, 720p/1080p rendering/performance, remote focus/Back, landing/detail/deep transitions, exhausted/sparse paging, request/detail behaviour and owned playback.
3. Capture the aggregate quality snapshot against actual Home Lab Jellyfin/Seerr data and use evidence, not guesswork, for any recommendation tuning.
4. If LG acceptance is credible, return to the whole Moonfin Discovery product and fix/revalidate shared personalisation semantics, recommendation quality, duplication, UX, performance, details/request/playback and edge cases across all clients.
5. Perform final cross-platform real-device acceptance, then prepare atomic server cutover/rollback and production deployment.

If the current agent cannot execute on the physical LG directly, prepare the exact candidate/install/rollback/acceptance procedure and minimise user-side commands rather than claiming the gate passed.
