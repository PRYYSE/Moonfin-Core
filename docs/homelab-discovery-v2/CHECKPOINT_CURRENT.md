# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-08 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point. Read this file, then `docs/AI_PROJECT_STATE.md`, `ARCHITECTURE.md`, `PROGRESS.md` and `SOURCE_MATRIX.md`. Do not restart completed work or modify the live server before the cutover gates are met.

## Objective / quality lock

Replace the legacy broad Home Lab Moonfin fork with current stable official Moonfin + a narrow isolated Discovery overlay + server-driven catalogue, preserving and improving Discovery across Web, Android mobile/tablet, Google TV/Android TV and LG webOS.

Quality, maintainability, truthful semantics and polish take priority over speed or nominal lane counts. Green CI/packages are milestones only.

Current implementation slice: **LG/webOS**. The current webOS code gate is strong enough that the next step is controlled physical LG acceptance. After that, return to the whole product for shared semantic, recommendation, UX, performance, integration and real-device acceptance work.

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

The LG remains a lightweight Smart-TV/Enact client. Do not replace it with Flutter Web merely for convenience.

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

`a3a3317894a90bbab8b12cc7764187a8c5591369`

Workflow `34184420915` / run **#50** — **GREEN**.

Verification:

- 16/16 focused Discovery/integration suites
- 85/85 tests
- strict Enact lint
- legacy CSS/WebKit compatibility
- production Enact build
- IPK package + preserved identity verification
- isolated artifact upload

Artifact:

- ID `10040048352`
- name `Moonfin-HomeLab-webOS-DiscoveryV2-a3a3317894a90bbab8b12cc7764187a8c5591369`
- size 4,312,422 bytes
- digest `sha256:6e765d2ad65fcd0cfb487bfc13075da209332e3f5004ea3e14a434b8d2661eef`
- IPK manifest SHA-256 `24e7a3af27c6ddf77d747b9990780073edb692ad6cef6453957d3afc45ee8e06`
- identity remains `org.moonfin.webos` / `2.7.0` / `index.html`

Smart-TV documentation commits may be newer than this code commit. The verified product source above is still the package acceptance point.

### webOS product foundation completed

Do not redo:

- guarded six-tab catalogue UI + stock fallback
- fail-closed planner/filter/sort/date-token policy
- authenticated Moonbase Seerr proxy
- bounded lane loading, membership and deterministic post-fetch presentation
- persistent surfaced-lane rotation
- truthful Jellyfin/Seerr personalisation sources with unsupported semantics failing closed
- Enact Spotlight landing navigation and exact card/See All restoration
- deep virtual-grid route/controller with incremental paging, dedup, retry and retained state
- owned result -> real Jellyfin detail/playback identity preservation
- refresh-failure fallback and explicit remotely reachable error/retry/Load More states
- legacy-WebKit build path

### Truthful personalisation semantics

Accepted shared reference remains **486 authored / 481 active**. Current truthful webOS static capability ceiling remains **468 executable active sections** before runtime sparse/error hiding.

The 13 deliberately ineligible active lanes remain:

- For You: Continue Exploring
- Series: Limited-Series Spotlight; Continue Exploring Series; One-Season Wonders; Long-Running Favourites; Weekend Binge
- Anime: Anime Specials & TV Movies; One-Season Anime; Long-Running Anime; Bingeable Anime; Completed Anime; Continuing Anime; Anime Miniseries & Short Runs

Do not re-enable them without a real source/filter/detail strategy that proves the label at acceptable old-TV cost.

### Latest old-TV / edge / recommendation-quality gate

Verified in run #50:

- Discovery visual cost follows the existing performance tier
- low-tier webOS uses lower-resolution `w780` backdrops, zero blur, no backdrop scale/fade animation, longer focus debounce and non-animated row scrolling
- mid tier caps blur at 4 px; high tier retains configured visual quality
- disabled Home backdrops do not trigger hidden backdrop requests
- <=800 px viewports use a smaller/tighter deep virtual grid; normal 1080p grid dimensions remain unchanged
- compact card sizing merges with Enact VirtualGrid's supplied positioning style, preserving virtual-list transforms/positioning rather than overwriting them
- poster URL/image failures render a deliberate text fallback instead of a broken image
- missing/non-numeric/non-positive TMDB identities are filtered before presentation so dead cards cannot be selected
- populated exhausted deep lists explicitly show `End of list`; sparse personalised lists retain bounded explicit Load More
- an aggregate opt-in quality snapshot can measure duplicate/repeat rate, underfilled lanes, hidden/failed lanes, missing artwork/identity and owned-item ratio against actual Home Lab data
- quality snapshot contains no titles or Jellyfin IDs and adds no new telemetry service
- personalised landing request depth remains one logical page; this hardening does not multiply initial old-TV I/O

No physical LG acceptance is claimed.

## Exact next work

1. Prepare and execute controlled **LG OLED65C6PSA acceptance** from verified source `a3a3317894a90bbab8b12cc7764187a8c5591369`, preserving rollback/update identity.
2. Validate launch/resume/auth, 720p/1080p rendering/performance, remote focus/Back, landing/detail/deep transitions, missing imagery/long text, sparse/exhausted paging, request/detail behaviour and owned playback.
3. Capture the aggregate quality snapshot against real Jellyfin/Seerr data and use it to assess actual repetition/diversity/sparse signals before recommendation tuning.
4. If physical LG acceptance is credible, return to the whole Moonfin Discovery product and fix/revalidate Flutter/Web/Android/Android-TV personalisation semantics plus shared recommendation quality, duplication, UX, performance, details/request/playback and edge cases.
5. Perform final cross-platform device acceptance before cutover.

If direct physical LG execution is unavailable to the current agent, prepare the exact candidate/install/rollback/acceptance procedure with minimal user-side commands instead of claiming the gate passed.

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
