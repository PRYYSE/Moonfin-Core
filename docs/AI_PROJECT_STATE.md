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
  - current verified product source: `0a234e8d83b67c6a7aa9a5775dc016d476721da6`
  - current Smart-TV checkpoint commit is newer than verified product source
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

These clients are **not product-finished**. The webOS semantic audit below exposed a shared personalisation-parity issue that must be revisited in the later cross-platform pass.

### webOS verified through `0a234e8d83b67c6a7aa9a5775dc016d476721da6`

- guarded six-tab catalogue UI + stock `SeerrDiscover` fallback
- aligned fail-closed planner/filter/sort/date policy
- authenticated narrow Moonbase Seerr proxy
- bounded lane loading, deterministic presentation, membership/dedup and persistent lane rotation
- Enact Spotlight landing navigation and deep virtual-grid `See All`
- exact landing card/See All focus restoration added; stale indices clamp safely
- existing Seerr detail/request routing preserved
- personalisation semantics substantially corrected:
  - actual Jellyfin played/favourite/like signals
  - actual Seerr watchlist
  - real Seerr movie/TV recommendation endpoints
  - provider-ID reconciliation back to owned Jellyfin items
  - explicit anime/media/affinity filtering
  - supported direct recently-added/trending/popular-not-owned paths
  - unsupported structural/context labels fail closed instead of hashing to arbitrary recommendation slots
- focused regressions now cover truthful source selection, owned resolution, anime filtering, cache refresh, fail-closed personal lanes and exact focus targets

Verification:

- workflow `34180294426` / run #23: **GREEN**
- 11/11 focused Discovery suites, 56/56 tests
- strict lint + legacy WebKit compatibility + production Enact build + IPK identity/package verification
- artifact `10038690055`
- artifact digest `sha256:4de853e478c6633f3b4eb0316b3b080c66db1691f58de870a7d36e4b83e9224c`
- IPK manifest SHA-256 `ff0319b5032d29dd8535f54b05a01da60586332f97e5e221ea1465580669d013`
- identity remains `org.moonfin.webos` / `2.7.0` / `index.html`

## Semantic accounting

Shared accepted reference remains **486 authored / 481 active**, with five known compiler-resolution failures already documented.

The webOS audit found that the first personalisation adapter produced different rows but overstated semantics: many named strategies were just deterministic slots of the same recent-history/local source, and specialised names could hash to arbitrary slots.

That is now removed. Against the accepted 481 active catalogue, current webOS has a truthful static capability ceiling of **468 executable sections** before runtime sparse/error hiding. Thirteen active catalogue lanes are deliberately ineligible because the available data path does not prove their advertised series-count/status/context semantics:

- For You: Continue Exploring
- Series: Limited-Series Spotlight; Continue Exploring Series; One-Season Wonders; Long-Running Favourites; Weekend Binge
- Anime: Anime Specials & TV Movies; One-Season Anime; Long-Running Anime; Bingeable Anime; Completed Anime; Continuing Anime; Anime Miniseries & Short Runs

This is an explicit semantic gap, not an unexplained regression. Re-enable only with a real truthful and old-TV-appropriate source/filter strategy.

## Cross-platform issue discovered

Current Flutter `lib/features/homelab_discovery/engine/discovery_personalisation.dart` still maps named strategies to deterministic row slots and hashes specialised names while current stable `RowDataSource.loadSinceYouWatchedRow` is materially simpler than the accepted archived v1 recommendation engine.

Therefore Flutter/Web/Android/Android-TV green CI does **not** prove semantic parity for personal lanes. Do not copy the old slot/hash behaviour back into webOS to make counts match. The later whole-product pass must redesign/revalidate shared personalisation semantics and recommendation quality deliberately.

## Known issues / blockers

- no physical LG acceptance yet
- personal webOS `See All` currently pages a bounded cached recommendation set rather than incrementally fetching deep upstream recommendations
- recommendation quality/duplication still needs real Jellyfin/Seerr data validation
- retained state/cache/stale-request behaviour needs another deliberate webOS pass
- old-TV visual/performance/failure-state polish remains
- request/detail/owned/playback/return flows need controlled live/device acceptance
- Web/mobile/Android-TV still need whole-product semantic/UX/performance/integration review and real acceptance after webOS reaches the next gate
- live server/cutover remains deliberately untouched

## Important decisions / quirks

- quality/maintainability/truthful semantics over nominal lane count or speed
- unsupported catalogue semantics fail closed
- do not overwrite preserved webOS v1 or change `org.moonfin.webos`
- do not regenerate Android signing certificate
- do not equate green CI/package generation with completion
- production legacy state stays rollback until replacement passes acceptance

## Tests/builds

- Smart-TV workflow `34180294426` / #23: GREEN
  - 11/11 suites
  - 56/56 tests
  - lint, legacy compatibility, production build, IPK, identity verification and artifact upload
- Moonfin Flutter source milestone workflow `34104075134` / #62: GREEN

## Exact next actions

1. Continue webOS with one substantial **deep-browse + retained-state/performance/error/integration hardening** batch, including genuinely deeper personal `See All` without multiplying initial old-TV request load.
2. Continue webOS visual/remote polish and then controlled physical LG OLED65C6PSA acceptance when appropriate.
3. Return to the whole Moonfin Discovery product and fix/revalidate shared personalisation semantics, recommendation quality, duplication, UX, performance, details/request/playback, edge cases and cross-platform consistency.
4. Perform real-device acceptance across Web, Android mobile/tablet, Android TV/Google TV and LG webOS.
5. Only after product gates are credible, finalise atomic server cutover/rollback and production deployment.
