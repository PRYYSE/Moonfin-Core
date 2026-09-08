# AI Project State

**Updated:** 2026-09-08 Australia/Adelaide

## Current objective

Home Lab Discovery v2: produce one polished Discovery experience across Web, Android mobile/tablet, Android TV/Google TV and LG webOS while keeping the custom Moonfin diff narrow and maintainable.

Current implementation slice is **LG/webOS**. Green builds/packages are milestones only. After webOS reaches a strong equivalent state, return to all four clients for semantic validation, UX/performance/integration refinement, real-device acceptance and final polish.

## Repositories / branches

- `PRYYSE/Moonfin-Core:homelab/discovery-v2`
  - Flutter/Web/Android product source milestone remains `86acba1246ea5e9424fcc96c9729c1e474359c53`
  - documentation/checkpoint commits are newer than product code
- `PRYYSE/Smart-TV:homelab/webos-discovery-v2`
  - current verified product source: `1f15b031207551d86eea52326fa8bd9eda394517`
  - Smart-TV checkpoint docs are newer than verified product source
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

### webOS verified through `1f15b031207551d86eea52326fa8bd9eda394517`

Product foundation:

- guarded six-tab catalogue UI + stock `SeerrDiscover` fallback
- aligned fail-closed planner/filter/sort/date policy
- authenticated narrow Moonbase Seerr proxy
- bounded lane loading, deterministic presentation, membership/dedup and persistent lane rotation
- Enact Spotlight landing navigation, exact card/See All focus restoration and deep virtual-grid browse
- truthful Jellyfin/Seerr personalisation sources; unsupported structural/context labels fail closed
- incremental personalised deep paging with bounded landing request cost
- bounded server/user/section-revision retained deep-state LRU, refresh invalidation and stale-load generation guards
- sparse personal deep continuation without multiplied automatic read-ahead

Failure/detail integration hardening in the current milestone:

- provider-ID reconciled owned Discovery items now keep `jellyfinMediaId` through selection and open the **real Jellyfin detail item**, restoring normal local-detail/playback behaviour instead of incorrectly opening a Seerr-only stub
- requestable/not-owned titles remain on the existing Seerr-only detail path
- complete refresh failure keeps the last usable rows visible with an explicit warning; successful/genuinely empty refreshes still replace them
- all-lane transport failures are classified as failure rather than empty content
- zero-row landing states have an explicit D-pad reachable retry target; toolbar DOWN no longer consumes input with nowhere to focus
- deep initial transport failure is distinguished from genuine empty content
- catalogue retry, initial deep retry, sparse Load More and partial-page retry have stable Spotlight targets
- existing app panel-history ownership was reviewed: landing -> detail -> Back, landing -> See All -> Back, and See All -> detail -> Back all resolve through the intended history/retained-state path
- the Discovery workflow now includes the Seerr/local detail-selection integration suite

Verification:

- Smart-TV workflow `34182625716` / run #39: **GREEN**
- 13/13 focused Discovery/integration suites, 78/78 tests
- strict lint + legacy WebKit compatibility + production Enact build + IPK identity/package verification
- artifact `10039454952`
- artifact digest `sha256:059f75d539a7937d1f4593930a0a21b7797e79cc20ccfbad9e7542b18f86d4b3`
- IPK manifest SHA-256 `f98d3b8556b4822c61e20e1c07b68475c18dce09f71387c7803318296d9cd099`
- identity remains `org.moonfin.webos` / `2.7.0` / `index.html`

## Semantic accounting

Shared accepted reference remains **486 authored / 481 active**, with five known compiler-resolution failures already documented.

Current webOS truthful static capability ceiling remains **468 executable sections** before runtime sparse/error hiding. Thirteen active catalogue lanes remain deliberately ineligible because current data does not prove their advertised series-count/status/context semantics:

- For You: Continue Exploring
- Series: Limited-Series Spotlight; Continue Exploring Series; One-Season Wonders; Long-Running Favourites; Weekend Binge
- Anime: Anime Specials & TV Movies; One-Season Anime; Long-Running Anime; Bingeable Anime; Completed Anime; Continuing Anime; Anime Miniseries & Short Runs

This is an explicit semantic gap, not an unexplained regression. Re-enable only with a truthful, old-TV-appropriate source/filter strategy.

## Cross-platform issue discovered

Current Flutter `lib/features/homelab_discovery/engine/discovery_personalisation.dart` still maps named strategies to deterministic row slots and hashes specialised names while current stable `RowDataSource.loadSinceYouWatchedRow` is materially simpler than the accepted archived v1 recommendation engine.

Therefore Flutter/Web/Android/Android-TV green CI does **not** prove semantic parity for personal lanes. Do not copy old slot/hash behaviour back into webOS to make counts match. The later whole-product pass must redesign/revalidate shared personalisation semantics and recommendation quality.

## Known issues / blockers

- no physical LG acceptance yet
- recommendation quality/duplication still needs real Jellyfin/Seerr data validation
- missing-image/provider-ID, empty-signal and exhausted-paging presentation still needs deliberate visual/device review
- old-TV visual/performance polish remains, especially long text, backdrop/card cost, 720p/1080p rendering and memory responsiveness
- panel-history Back paths are code-reviewed but still need physical LG remote acceptance
- request actions and owned/local playback need controlled service/device acceptance
- launch/resume/auth/update lifecycle still needs real LG acceptance
- Web/mobile/Android-TV still need the later whole-product semantic/UX/performance/integration review and real acceptance
- live server/cutover remains deliberately untouched

## Important decisions / quirks

- quality/maintainability/truthful semantics over nominal lane count or speed
- unsupported catalogue semantics fail closed
- old-TV request and memory cost must remain explicit
- preserve the real Jellyfin identity when Discovery proves ownership; do not degrade owned media to Seerr-only detail
- do not overwrite preserved webOS v1 or change `org.moonfin.webos`
- do not regenerate Android signing certificate
- do not equate green CI/package generation with completion
- production legacy state stays rollback until replacement passes acceptance

## Tests/builds

- Smart-TV workflow `34182625716` / #39: GREEN
  - 13/13 suites
  - 78/78 tests
  - lint, legacy compatibility, production build, IPK, identity verification and artifact upload
- Moonfin Flutter source milestone workflow `34104075134` / #62: GREEN

## Exact next actions

1. Continue webOS with one substantial **visual/old-TV performance + remaining failure-edge + real-data recommendation-quality preparation** batch, code/test driven and preserving old-TV request/memory limits.
2. If that gate is strong, begin controlled physical LG OLED65C6PSA acceptance in the following batch; do not deploy production merely because CI is green.
3. Return to the whole Moonfin Discovery product and fix/revalidate shared personalisation semantics, recommendation quality, duplication, UX, performance, details/request/playback, edge cases and cross-platform consistency.
4. Perform real-device acceptance across Web, Android mobile/tablet, Android TV/Google TV and LG webOS.
5. Only after product gates are credible, finalise atomic server cutover/rollback and production deployment.
