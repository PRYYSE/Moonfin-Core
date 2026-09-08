# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-08 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point. Read this file, then `docs/AI_PROJECT_STATE.md`, `ARCHITECTURE.md`, `PROGRESS.md` and `SOURCE_MATRIX.md`. Do not restart completed work or modify the live server before the cutover gates are met.

## Objective / quality lock

Replace the legacy broad Home Lab Moonfin fork with current stable official Moonfin + a narrow isolated Discovery overlay + server-driven catalogue, while preserving and improving Discovery across Web, Android mobile/tablet, Google TV/Android TV and LG webOS.

Quality, maintainability, truthful semantics and polish take priority over speed or nominal lane counts. Green CI/packages are milestones only.

Current implementation slice: **LG/webOS**. After webOS reaches a strong equivalent state, return to the whole product for shared semantic, UX, performance, integration and real-device acceptance work.

## Stable / rollback state

Moonfin stable baseline: `f18c45b1fbf9b63871b4f93237179f9706154763` (2.5.1).

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

## Architecture lock

Custom Flutter Discovery code remains under `lib/features/homelab_discovery/` with the guarded Seerr Discovery route in `lib/ui/navigation/app_router.dart`.

Catalogue URL remains `/Moonfin/Web/homelab/discovery.catalogue.json`.

Valid compatible catalogue -> Home Lab Discovery. Missing/invalid/incompatible catalogue -> stock Seerr Discovery.

The old LG remains a lightweight Smart-TV/Enact client. Do not replace it with Flutter Web merely for convenience.

## Current Moonfin Flutter/Web/Android milestone

**Verified product source:** `86acba1246ea5e9424fcc96c9729c1e474359c53`  
**Workflow:** `34104075134` / run #62 — **GREEN**

Verified foundation includes schema/catalogue/LKG/fallback architecture, deterministic concurrent loading/post-fetch presentation, membership/NSFW filtering, safe compiled catalogue semantics, persistent lane rotation, landing + deep See All, TV focus/D-pad hardening and reproducible Web/mobile/Android-TV builds.

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

`1f15b031207551d86eea52326fa8bd9eda394517`

Workflow `34182625716` / run **#39** — **GREEN**.

Verification:

- 13/13 focused Discovery/integration suites
- 78/78 tests
- strict Enact lint
- legacy CSS/WebKit compatibility
- production Enact build
- IPK package + preserved identity verification
- isolated artifact upload

Artifact:

- ID `10039454952`
- name `Moonfin-HomeLab-webOS-DiscoveryV2-1f15b031207551d86eea52326fa8bd9eda394517`
- digest `sha256:059f75d539a7937d1f4593930a0a21b7797e79cc20ccfbad9e7542b18f86d4b3`
- IPK manifest SHA-256 `f98d3b8556b4822c61e20e1c07b68475c18dce09f71387c7803318296d9cd099`
- identity remains `org.moonfin.webos` / `2.7.0` / `index.html`

### webOS product foundation completed

Do not redo:

- guarded six-tab catalogue UI + stock fallback
- fail-closed planner/filter/sort/date-token policy
- authenticated Moonbase Seerr proxy
- bounded lane loading, membership and deterministic post-fetch presentation
- persistent surfaced-lane rotation
- Enact Spotlight landing navigation and exact card/See All restoration
- deep virtual-grid route/controller with incremental paging, dedup and retry
- truthful Jellyfin/Seerr personalisation sources
- bounded retained deep-state LRU with refresh invalidation and stale-load generation guards
- legacy-WebKit build path

### Truthful personalisation semantics

Accepted shared reference remains **486 authored / 481 active**. Current truthful webOS static capability ceiling remains **468 executable active sections** before runtime sparse/error hiding.

The 13 deliberately ineligible active lanes remain:

- For You: Continue Exploring
- Series: Limited-Series Spotlight; Continue Exploring Series; One-Season Wonders; Long-Running Favourites; Weekend Binge
- Anime: Anime Specials & TV Movies; One-Season Anime; Long-Running Anime; Bingeable Anime; Completed Anime; Continuing Anime; Anime Miniseries & Short Runs

Do not re-enable them without a real source/filter/detail strategy that proves the label at acceptable old-TV cost.

### Deep browse / retained-state work already verified

- personal See All advances later Seerr recommendation pages rather than slicing only the first capture
- personal landing previews stay one logical page to bound initial old-TV request cost
- mixed personal rows accept movies + series
- deep pages survive detail-return in a bounded server/user/section-revision LRU
- refresh/reset invalidates affected retained deep state
- obsolete in-flight loads cannot overwrite newer refresh/reset state
- sparse personal deep rows expose explicit continuation without multiplied read-ahead

### Current failure / remote / detail-integration milestone

The latest webOS batch fixed several concrete product defects:

- owned Discovery results with a reconciled `jellyfinMediaId` no longer lose that local identity when selected; they open the real Jellyfin item so normal local details/playback remain available
- requestable/not-owned results continue to use the existing Seerr-only detail route
- a complete refresh failure preserves the last usable rows and surfaces an explicit warning instead of replacing them with an error/empty screen
- all-lane transport failures are classified as failure rather than `Nothing is available`
- zero-row landing states expose a stable D-pad retry target; toolbar DOWN no longer consumes navigation with nowhere to go
- initial deep transport failure is distinguished from genuine empty content
- catalogue retry, initial deep retry, sparse Load More and partial-page retry have stable Spotlight IDs/focus behaviour
- app panel-history ownership was reviewed and deliberately preserved for landing -> detail -> Back, landing -> See All -> Back, and See All -> detail -> Back
- `seerrTarget.test.js` is now part of the strict Discovery workflow gate so local-vs-Seerr detail routing is regression-tested

No physical LG acceptance is claimed.

## Exact next work

Continue webOS product hardening, not deployment:

1. visual/old-TV performance: card/backdrop spacing, long text, missing imagery, 720p/1080p rendering, memory and responsiveness;
2. remaining failure edges: empty personal signals, missing provider identity and exhausted paging presentation;
3. prepare real-data recommendation/duplication review against the Home Lab Jellyfin/Seerr data path without increasing landing request cost;
4. if those code gates are strong, begin controlled LG OLED65C6PSA acceptance in the following batch, covering remote Back/focus, request/detail/local playback, launch/resume/auth and update compatibility.

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
