# AI Project State

**Updated:** 2026-09-08 Australia/Adelaide

## Current objective

Home Lab Discovery v2: produce one polished Discovery experience across Web, Android mobile/tablet, Android TV/Google TV and LG webOS while keeping the custom Moonfin diff narrow and maintainable.

Current implementation slice is **LG/webOS**. Green builds/packages are milestones only. After webOS reaches a strong equivalent state, return to all four clients for semantic validation, UX/performance/integration refinement, real-device acceptance and final polish.

## Repositories / branches

- `PRYYSE/Moonfin-Core:homelab/discovery-v2`
  - Flutter product source milestone remains `86acba1246ea5e9424fcc96c9729c1e474359c53`
  - documentation/checkpoint commits are newer than product code
- `PRYYSE/Smart-TV:homelab/webos-discovery-v2`
  - current verified product source: `21a21acf6f5b9fcb835c8c863c19ee3ce84929e0`
  - Smart-TV checkpoint docs are newer than that verified source
- preserved Smart-TV baseline: `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`

## Completed milestones

### Moonfin Flutter/Web/Android

- isolated Home Lab Discovery architecture and guarded stock fallback
- deterministic concurrent loading/post-fetch presentation
- full 486-lane authoring catalogue/compiler validation
- membership filtering, persistent lane rotation and deep `See All`
- landing/deep TV focus hardening
- reproducible Web/mobile/Android-TV candidate builds
- source milestone workflow `34104075134` / #62 GREEN

These clients are **not product-finished**. The webOS semantic audit exposed a shared personalisation-parity issue that must be corrected in the later whole-product pass.

### webOS verified through `21a21acf6f5b9fcb835c8c863c19ee3ce84929e0`

Product foundation:

- guarded six-tab catalogue UI + stock `SeerrDiscover` fallback
- aligned fail-closed planner/filter/sort/date policy
- authenticated narrow Moonbase Seerr proxy
- bounded lane loading, deterministic presentation, membership/dedup and persistent lane rotation
- Enact Spotlight landing navigation, exact card/See All focus restoration and deep virtual-grid browse
- existing Seerr detail/request routing
- explicit real personalisation signals/sources instead of arbitrary named-strategy slot hashing
- unsupported structural/context labels fail closed

Current deep-browse/performance hardening:

- personal `See All` now advances through later Seerr recommendation pages incrementally instead of paging only a bounded first capture
- personal row expansion is cached, deduplicated and serialised with a bounded per-logical-page upstream request budget
- personal landing previews deliberately load only one logical page, preventing deep paging from multiplying initial old-TV request cost
- `mediaType: all` now correctly accepts both movie and series results
- deep pages are retained across detail returns in a bounded server/user/section-revision cache
- tab refresh/reset invalidates retained deep snapshots for that server/user scope
- landing and deep refresh now propagate `forceRefresh` to personal data sources
- deep controller generation guards prevent obsolete in-flight loads overwriting state after refresh/reset
- sparse personal deep rows avoid multiplied automatic read-ahead and expose explicit Load More continuation

Verification:

- Smart-TV workflow `34181464956` / run #38: **GREEN**
- 12/12 focused Discovery suites, 64/64 tests
- strict lint + legacy WebKit compatibility + production Enact build + IPK identity/package verification
- artifact `10039078886`
- artifact digest `sha256:af90f1782149cae8703ec8afa7237d26426800feb0e648d54b5ce9fe567cd15a`
- IPK manifest SHA-256 `7b55b12a693700ecfa587098b269cb43bb945bf0762b5605d6eb183b0e007869`
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
- catalogue/Seerr/Jellyfin failure combinations and empty/sparse/exhausted states need another deliberate pass
- old-TV visual/performance polish remains
- detail/deep/landing Back and remote edge cases need physical validation
- request/detail/owned/playback/return flows need controlled integration/device acceptance
- Web/mobile/Android-TV still need the later whole-product semantic/UX/performance/integration review and real acceptance
- live server/cutover remains deliberately untouched

## Important decisions / quirks

- quality/maintainability/truthful semantics over nominal lane count or speed
- unsupported catalogue semantics fail closed
- old-TV request and memory cost must remain explicit
- do not overwrite preserved webOS v1 or change `org.moonfin.webos`
- do not regenerate Android signing certificate
- do not equate green CI/package generation with completion
- production legacy state stays rollback until replacement passes acceptance

## Tests/builds

- Smart-TV workflow `34181464956` / #38: GREEN
  - 12/12 suites
  - 64/64 tests
  - lint, legacy compatibility, production build, IPK, identity verification and artifact upload
- Moonfin Flutter source milestone workflow `34104075134` / #62: GREEN

## Exact next actions

1. Continue webOS with one substantial **failure-state + remote/integration + visual/performance hardening** batch, using code/tests first and preserving old-TV request/memory limits.
2. If that gate is strong, prepare controlled physical LG OLED65C6PSA acceptance in the following batch; do not deploy production merely because CI is green.
3. Return to the whole Moonfin Discovery product and fix/revalidate shared personalisation semantics, recommendation quality, duplication, UX, performance, details/request/playback, edge cases and cross-platform consistency.
4. Perform real-device acceptance across Web, Android mobile/tablet, Android TV/Google TV and LG webOS.
5. Only after product gates are credible, finalise atomic server cutover/rollback and production deployment.
