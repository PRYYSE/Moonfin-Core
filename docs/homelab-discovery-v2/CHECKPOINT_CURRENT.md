# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-08 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point. Read this file, then `docs/AI_PROJECT_STATE.md`, `ARCHITECTURE.md`, `PROGRESS.md` and `SOURCE_MATRIX.md`. Do not restart completed work or modify the live server before the cutover gates are met.

## Objective / quality lock

Replace the legacy broad Home Lab Moonfin fork with current stable official Moonfin + a narrow isolated Discovery overlay + server-driven catalogue, while preserving and improving the Discovery product across:

1. Web
2. Android mobile/tablet
3. Google TV / Android TV
4. LG TV / webOS

Quality, maintainability, truthful semantics and polish take priority over speed or nominal lane counts. Green CI/packages are milestones only.

Current implementation slice: **LG/webOS**. After webOS reaches a strong equivalent state, return to the whole product for shared semantic, UX, performance, integration and real-device acceptance work.

## Stable / rollback state

Moonfin stable baseline: `f18c45b1fbf9b63871b4f93237179f9706154763` (2.5.1).

Live remains deliberately untouched as rollback:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Important recovery refs remain intact:

- `archive/pre-v2-main-2026-09-06` -> `cfe9c5c1a4c32d1c0828eff5ed41ea3a2947d126`
- `archive/seerr-discovery-v1-2026-09-06` -> `aa604b6cdc0083cebe8762f85ede896024f88725`
- `archive/live-web-a9c789-2026-09-06` -> `a9c789fff317b41bba268d3a213439e23b8d1af5`
- `archive/android-accepted-e7e5ab-2026-09-06` -> `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`

Accepted Android signing cert SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`. Never regenerate signing.

## Architecture lock

Custom Flutter Discovery code remains under `lib/features/homelab_discovery/` with the guarded Seerr Discovery route in `lib/ui/navigation/app_router.dart`.

Catalogue URL remains `/Moonfin/Web/homelab/discovery.catalogue.json`.

Valid compatible catalogue -> Home Lab Discovery. Missing/invalid/incompatible catalogue -> stock Seerr Discovery.

The old LG remains a lightweight Smart-TV/Enact client. Do not replace it with Flutter Web merely for convenience.

## Current Moonfin Flutter/Web/Android milestone

**Verified product source:** `86acba1246ea5e9424fcc96c9729c1e474359c53`  
**Workflow:** `34104075134` / run #62 — **GREEN**

Implemented/verified foundation includes:

- strict schema/catalogue/LKG/fallback architecture
- deterministic concurrent loading with catalogue-order post-fetch presentation
- membership/NSFW filtering
- safe compiled authoring catalogue and fail-closed unresolved semantics
- persistent surfaced-lane rotation
- landing + deep `See All`
- TV focus/D-pad/partial-grid/load-more hardening
- reproducible Web/mobile/Android-TV candidate builds

Artifact: `10012562778` / `homelab-discovery-v2-candidates-86acba1246ea5e9424fcc96c9729c1e474359c53`.

These clients are **not finished**. The later webOS semantic audit proved that the current Flutter personalisation adapter still overstates some named strategy semantics through slot/hash mapping. The whole-product pass must redesign/revalidate that rather than treating run #62 as final parity.

## Current webOS source of truth

Repository: `PRYYSE/Smart-TV`

Preserved baseline:

- branch `homelab/webos-v1-staging`
- candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`
- app ID `org.moonfin.webos`
- version `2.7.0`
- target LG OLED65C6PSA

Current isolated branch: `homelab/webos-discovery-v2`.

### Verified webOS product source

`21a21acf6f5b9fcb835c8c863c19ee3ce84929e0`

Workflow `34181464956` / run **#38** — **GREEN**.

Verification:

- 12/12 focused Discovery suites
- 64/64 tests
- strict Enact lint
- legacy CSS/WebKit compatibility
- production Enact build
- IPK package + preserved identity verification
- isolated artifact upload

Artifact:

- ID `10039078886`
- name `Moonfin-HomeLab-webOS-DiscoveryV2-21a21acf6f5b9fcb835c8c863c19ee3ce84929e0`
- digest `sha256:af90f1782149cae8703ec8afa7237d26426800feb0e648d54b5ce9fe567cd15a`
- IPK manifest SHA-256 `7b55b12a693700ecfa587098b269cb43bb945bf0762b5605d6eb183b0e007869`
- identity remains `org.moonfin.webos` / `2.7.0` / `index.html`

### webOS product foundation completed

Do not redo:

- guarded six-tab catalogue UI + stock fallback
- fail-closed planner/filter/sort/date-token policy
- authenticated Moonbase Seerr proxy
- bounded lane loading, membership and deterministic post-fetch presentation
- persistent surfaced-lane rotation
- Enact Spotlight landing navigation and exact card/See All restoration
- deep virtual-grid route/controller with paging, dedup and retry
- existing details/request routing
- legacy-WebKit build path

### Truthful personalisation semantics

webOS no longer maps arbitrary named strategies onto pseudo-distinct recommendation slots. Current supported sources/signals include:

- Jellyfin played history, favourites and likes
- real Seerr watchlist
- real Seerr movie/TV recommendations seeded by actual TMDB identities
- provider-ID resolution back to owned Jellyfin items
- explicit anime/media/runtime/era affinity rules
- real recently-added/trending/popular-not-owned paths

Unsupported structural/context semantics fail closed.

Accepted shared reference remains **486 authored / 481 active**. Current truthful webOS static capability ceiling remains **468 executable active sections** before runtime sparse/error hiding.

The 13 deliberately ineligible active lanes remain:

- For You: Continue Exploring
- Series: Limited-Series Spotlight; Continue Exploring Series; One-Season Wonders; Long-Running Favourites; Weekend Binge
- Anime: Anime Specials & TV Movies; One-Season Anime; Long-Running Anime; Bingeable Anime; Completed Anime; Continuing Anime; Anime Miniseries & Short Runs

Do not re-enable them without a real source/filter/detail strategy that proves the label at acceptable old-TV cost.

### Current deep-browse / retained-state milestone

The old bounded personal `See All` limitation is now resolved:

- later deep pages increment later Seerr recommendation pages rather than slicing only the first capture
- row expansion is cached, globally deduplicated and serialised
- per-logical-page upstream request budget is bounded
- landing personal rows intentionally load one logical page only
- sparse personal deep rows avoid multiplied automatic read-ahead and provide explicit Load More continuation
- `mediaType: all` correctly accepts movie + series results
- deep loaded pages persist across detail-return in a bounded server/user/section-revision cache
- refresh/reset invalidates retained deep snapshots for the affected server/user scope
- landing/deep refresh propagates personal source invalidation
- stale in-flight deep loads cannot overwrite newer refresh/reset state

No physical LG acceptance is claimed.

## Exact next work

Continue webOS product hardening, not deployment:

1. failure-state combinations: catalogue, Seerr and Jellyfin partial failures; empty signals; sparse/exhausted paging; missing images/provider IDs; retries;
2. remote/back integration: landing/detail/deep transitions, tabs, navbar edge, partial grids and exhausted paging;
3. visual/old-TV performance: card/backdrop spacing, long text, 720p/1080p rendering, memory and responsiveness;
4. request/detail/owned/playback/return integration;
5. real recommendation/duplication quality review against Home Lab data;
6. if those code gates are strong, prepare the following batch for controlled LG OLED65C6PSA acceptance.

After webOS reaches strong equivalent state, return to the whole Moonfin Discovery product and correct/revalidate Flutter/Web/Android/Android-TV personalisation semantics plus shared recommendation quality, duplication, UX, performance, details/request/playback and edge cases. Then perform real-device acceptance before cutover.

## Cutover gates

- recovery refs intact
- strict CI green
- narrow explainable custom diff
- guarded stock fallback
- truthful semantic accounting
- deterministic concurrency proven
- polished landing + See All
- Web mouse/touch/keyboard accepted
- Android mobile touch/back/resume accepted
- Android TV D-pad/focus/back accepted
- LG webOS remote/focus/back/resume/rendering/update accepted on real TV
- details/request/local-media/playback accepted
- recommendation/lane quality and duplication accepted
- Android certificate unchanged and deployment versionCode correct
- webOS app ID/update compatibility preserved
- stock Moonbase + external Web-root rollback prepared

## Do not

- delete legacy branches/backups
- modify the live server during GitHub-only work
- regenerate Android signing
- change/regenerate webOS app identity without deliberate migration
- patch broad core/stock Seerr code when a feature-local adapter is sufficient
- force unsafe semantic lanes
- claim physical acceptance without real execution
- treat green CI or packaging as product completion
