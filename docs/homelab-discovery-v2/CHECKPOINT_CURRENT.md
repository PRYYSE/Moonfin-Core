# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-08 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point. Read this file, then `ARCHITECTURE.md`, `PROGRESS.md` and `SOURCE_MATRIX.md`. Do not restart completed work or modify the live server before the cutover gates are met.

## Objective / quality lock

Replace the legacy broad Home Lab Moonfin fork with current stable official Moonfin + a narrow isolated Discovery overlay + server-driven catalogue, while preserving and improving the polished Discovery product.

Maintained clients:

1. Web
2. Android mobile/tablet
3. Google TV / Android TV
4. LG TV / webOS

Quality, maintainability and polish take priority over speed. Existing work may be replaced when there is a concrete correctness, UX, architecture or maintainability improvement. Green CI and successful packages are milestones only, not final acceptance.

Current implementation slice: **LG/webOS**. After webOS reaches a strong equivalent state, return to the whole Discovery product across all four maintained clients for remaining cross-platform development, semantic validation, UX refinement, real-device acceptance and final polish.

## Stable baseline

- Moonfin stable 2.5.1: `f18c45b1fbf9b63871b4f93237179f9706154763`
- upstream main at architecture decision: `508f052f4da725b1f520f4a73b64330d43c86f92`
- Moonbase stable 2.2.0
- Flutter 3.44.1
- official Moonbase supports `MOONFIN_WEB_ROOT`
- official personal recommendation engine reused via `RowDataSource.loadSinceYouWatchedRow`
- production follows stable tags; upstream main is compatibility canary only

## Recovery refs / live rollback

Immutable Moonfin-Core recovery refs:

- `archive/pre-v2-main-2026-09-06` -> `cfe9c5c1a4c32d1c0828eff5ed41ea3a2947d126`
- `archive/seerr-discovery-v1-2026-09-06` -> `aa604b6cdc0083cebe8762f85ede896024f88725`
- `archive/live-web-a9c789-2026-09-06` -> `a9c789fff317b41bba268d3a213439e23b8d1af5`
- `archive/android-accepted-e7e5ab-2026-09-06` -> `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`

Live remains untouched:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- legacy Discovery 481/486
- Seerr enabled
- old pointer/touch hotfix not deployed; do not resume it under v2

Accepted Android production signing baseline:

- source `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`
- version `2.4.0+30000147`
- signing root `/srv/appdata/moonfin/android-signing`
- cert SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Never regenerate signing.

## webOS source of truth

Repository `PRYYSE/Smart-TV`:

- preserved known-good branch: `homelab/webos-v1-staging`
- preserved candidate commit/tag: `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`
- app ID: `org.moonfin.webos`
- baseline version: 2.7.0
- packaging: `packages/build-webos/`
- real LG OLED65C6PSA acceptance remains mandatory

New isolated v2 work is on `homelab/webos-discovery-v2`, branched from the preserved candidate. Do not rewrite the old staging branch. The webOS client remains the lightweight Smart-TV/Enact client; do not force the Flutter Web build onto the old LG platform.

## Architecture lock

Custom Flutter product code lives under `lib/features/homelab_discovery/`.

Only mandatory core product diff is the guarded Seerr Discovery route in `lib/ui/navigation/app_router.dart`, generated/checkable by `tooling/homelab-discovery-v2/apply_route_overlay.py`.

- valid compatible catalogue -> custom Discovery
- missing/invalid/incompatible catalogue -> stock Seerr Discovery

Catalogue URL: `/Moonfin/Web/homelab/discovery.catalogue.json`.

Future server root: `/srv/appdata/moonfin/`; stock Moonbase will serve persistent external Web releases through `MOONFIN_WEB_ROOT`.

## Implemented and verified shared Discovery v2 foundation

- strict catalogue schema/models and migrations
- network-first load + per-server last-known-good cache
- guarded stock fallback
- deterministic composer/session rotation
- bounded concurrent lane I/O with deterministic post-fetch presentation
- isolated Seerr bridge/request mapper
- bounded paginator/cross-page dedup
- lane error isolation/sparse hide
- stock recommendation adapter with sixteen personal strategy slots
- catalogue-order personal title/family diversification
- feature-local tab controller with reverse-completion race regression tests
- feature-local runtime using authoritative active Moonfin services
- real landing UI with loading/retry/empty/partial-failure/refresh states and Moonfin media cards
- availability/NSFW membership policy
- authoring placeholders compiled to safe executable queries; unresolved runtime semantic names fail closed
- independent deep `See All` paging/dedup/load-more recovery/reset
- persistent surfaced-lane rotation history with persistent reset
- 486-lane authoring catalogue/compiler tests
- strict read-only CI and narrow-scope gate

Authoring catalogue remains:

- For You 16
- Movies 130
- Series 140
- Anime 160
- New & Upcoming 20
- Lists 20

Accepted live 481/486 remains the semantic regression reference. Never invent unsafe semantics merely to report 486/486.

## Current Moonfin Flutter/Web/Android milestone

**Verified product source:** `86acba1246ea5e9424fcc96c9729c1e474359c53`  
**Workflow:** `34104075134` / run **#62**  
**Result:** GREEN

Focused validation passed route overlay, 486-lane catalogue, format, analysis, focused tests and narrow custom-scope verification. The completed interaction slice includes TV landing focus, row focus restoration, deterministic deep `See All` focus/grid behaviour, D-pad traversal, near-end paging and pointer-tap regression coverage while preserving normal Web/mobile pointer/touch paths.

Rebuilt candidate artifact:

- GitHub artifact ID: `10012562778`
- name: `homelab-discovery-v2-candidates-86acba1246ea5e9424fcc96c9729c1e474359c53`
- artifact digest: `sha256:1853f6960394fe902e8ac9b72d0d4709bd2ddfe87265bf64b2ea3695de4083e4`
- app version: `2.5.1+30000149`
- Android TV version/build: `2.5.1` / `2000016`
- Android TV beta APK SHA-256: `a56ccc1a12e9e7e34fa54ade4725d96e4979ec544f68f0cc5f5e2d2997092a71`
- Android mobile beta APK SHA-256: `ab18aebdb5bbbf8a3ba3192960937c77850bbf9fbefe4ff0bb615083d9c579c0`
- Web tarball SHA-256: `ec8ec792b32c6e4c1bdd69af0efbf2a26983bf544cb4c8aaddd3ad9dff1730a2`

**Important:** these are build-validation candidates, not evidence that Web/Android/Android TV are finished. CI APKs remain debug-fallback signed and are not deployment candidates. The whole shared product still needs semantic, UX, performance, integration and real-device acceptance work after the current webOS slice.

## Current webOS Discovery v2 milestone — UI, deep browse, personalisation and persistent rotation

Branch: `PRYYSE/Smart-TV:homelab/webos-discovery-v2`  
**Verified product source before its checkpoint-doc commit:** `08df13b15bf0b5bd66fdf7dceb6359b18d67042b`  
**Workflow:** `34178662792` / run **#15**  
**Result:** GREEN

This supersedes the stale `439e64...` engine-only checkpoint. Verified repository state now includes:

- guarded six-tab catalogue-driven Home Lab Discovery UI with fallback to existing `SeerrDiscover`;
- Enact Spotlight remote/focus foundation, active-tab focus scheduling, row focus memory, navbar return and deterministic vertical movement;
- feature-local deep `See All` route/controller with virtual grid, focus restoration and bounded deep paging/dedup;
- fail-closed catalogue planner, server-scoped catalogue/LKG loader, authenticated Moonbase Seerr proxy and membership filtering;
- real Jellyfin-backed personalisation reusing the existing Smart-TV Home recommendation engine across sixteen deterministic personal slots;
- Jellyfin candidate hydration, movie/series filtering, explicit anime filtering and dynamic `Because You Watched ...` titles;
- persistent server/user/tab-scoped surfaced-lane rotation, refresh rotation and persistent reset;
- deterministic post-fetch presentation and lane error isolation.

Recovery repair details:

- desynchronised commit `dd1b52eb5503ee37e74fbaba56f65360ad24f8a7` contained the personalisation/rotation implementation but workflow #13 failed because Jest reached Enact/Jellyfin runtime modules while initialising pure service tests;
- `635574bac20bb0a8a75ddf6dab117d8bc2d5add1` isolated the production runtime imports behind lazy adapters without weakening the production Jellyfin path;
- the newly reachable production builder exposed one strict `no-shadow` warning in the personalised lane path;
- `08df13b15bf0b5bd66fdf7dceb6359b18d67042b` fixed that warning without behavioural change;
- run #15 then passed **11 test suites / 53 tests**, strict lint/build, legacy-WebKit compatibility processing, Enact production compilation, IPK packaging, identity verification and artifact upload.

Current isolated webOS artifact:

- ID: `10038154398`
- name: `Moonfin-HomeLab-webOS-DiscoveryV2-08df13b15bf0b5bd66fdf7dceb6359b18d67042b`
- artifact digest: `sha256:8babd2765d40c5480acf765a186a673c648ec2c790f7d088d71b76ee3b611d3e`
- IPK manifest SHA-256: `ebceaf7da758c792eaf939102d76ceac9b2d3d1ae330d9bf69eea7960ca14018`
- package identity verified: `org.moonfin.webos`, version `2.7.0`, main `index.html`

The preserved `homelab/webos-v1-staging` branch/candidate remains untouched. No physical LG acceptance is claimed.

## Exact next work

Current next batch remains **webOS product-quality hardening**, not deployment:

1. semantic regression accounting against the accepted legacy 481/486 result, with explicit reasons for every genuinely unsupported lane;
2. assess/fix recommendation quality, personal strategy diversity, lane ordering, sparse results and cross-row/title-family duplication;
3. harden remote focus/navigation/Back and return-from-detail/See-All behaviour across tab transitions, long rows, partial grids and load-more edges;
4. review visual consistency/responsiveness/old-TV rendering, caching/performance/stale-request handling and loading/error/empty/partial-failure combinations;
5. verify request/detail/local-media/playback routing and catalogue-refresh edge cases in code/tests where possible;
6. produce another isolated candidate only when meaningful webOS product improvements justify it;
7. later perform controlled LG OLED65C6PSA acceptance on the real TV.

After webOS reaches strong equivalent state, return to the **whole Moonfin Discovery product**. Reassess Web, Android mobile/tablet and Android TV/Google TV alongside webOS for correctness/architecture, navigation/focus/back, recommendation/lane quality, deep browsing, visual consistency, performance/caching, error/loading states, request/detail/playback integration, edge cases/duplication and cross-platform consistency. Then perform real-device acceptance and final polish before any final cutover.

Atomic server build/cutover/rollback and `SERVER_RUNBOOK.md` remain required later, but are not the next priority merely because packages now build.

## Cutover gates

- recovery refs intact
- strict CI green
- narrow explainable custom diff
- guarded stock fallback
- no unexplained semantic regression below accepted 481 baseline
- deterministic concurrency proven
- polished landing + See All tested
- Web mouse/touch/keyboard accepted
- Android mobile touch/back/resume accepted
- Android TV D-pad/focus/back accepted
- LG webOS remote/focus/back/resume/rendering/update accepted on the real TV
- details/request/local-media/playback routing accepted
- recommendation/lane quality and duplication accepted across platforms
- Android certificate unchanged and deployment versionCode increased appropriately
- webOS app ID/update compatibility preserved
- stock Moonbase + external Web-root rollback prepared
- previous Web/APKs/webOS package and bundled stock Web fallback retained

## Do not

- delete legacy branches/backups
- modify the live server during GitHub-only work
- regenerate Android signing
- change/regenerate webOS app identity without deliberate migration
- broaden Home/nav/player customisation without a concrete need
- patch stock Seerr repository/client when a feature-local adapter is sufficient
- force unsafe semantic lanes
- continuously merge upstream main into production
- claim physical-client acceptance without real execution
- treat green CI or packaging as product completion
