# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-07 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point. Read this file, then `ARCHITECTURE.md`, `PROGRESS.md` and `SOURCE_MATRIX.md`. Do not restart completed work or modify the live server before the cutover gates are met.

## Objective / quality lock

Replace the legacy broad Home Lab Moonfin fork with current stable official Moonfin + a narrow isolated Discovery overlay + server-driven catalogue, while preserving and improving the polished Discovery product.

Maintained clients:

1. Web
2. Android mobile/tablet
3. Google TV / Android TV
4. LG TV / webOS

Quality, maintainability and polish take priority over speed. Existing work may be replaced when there is a concrete correctness, UX, architecture or maintainability improvement. User requested Unlazy **Solo Complete**: continue all safe GitHub/testing/preparation without routine approval pauses and leave durable checkpoints. Server/device execution remains a later explicit gate.

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

## Implemented and verified Discovery v2 foundation

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

## Verified reproducible client candidate milestone

**Verified product source:** `cc4f03b1e9e4d80314f83a764944670460dd6c58`  
**Workflow:** `34086546081`  
**Result:** GREEN

Both jobs passed:

- focused validation: route overlay, 486-lane catalogue, format, analysis, focused tests, narrow custom-scope
- candidate build: Web release, `mobile-beta`, `androidTv-beta`, packaging and artifact upload

Artifact:

- GitHub artifact ID: `10005927276`
- name: `homelab-discovery-v2-candidates-cc4f03b1e9e4d80314f83a764944670460dd6c58`
- artifact digest: `sha256:2baccfb03a43bfb61ec5d82b7a5f9e75a63bea6630613b6652b167b045632713`
- source version: `2.5.1+30000149`
- Android TV version/build: `2.5.1` / `2000016`

Files were downloaded and independently checksum-verified after CI:

- Android TV beta APK: `a81e091f5fa458711a233983f495657dd9a01157bfa7de0b806cf58cdbda1df8`
- Android mobile beta APK: `f732133d4bdbb4a90bc429091760448e772c5a20e5bfc63cd6878da455bb194c`
- Web tarball: `469bc0acdf9179726683c58e29a7061767585873e8d934a8c8a4e481fbe6d78f`

The Web archive opens and contains the expected built application assets. Both APK files are structurally recognised as Android packages.

**Important:** CI Android artifacts use debug fallback signing and are build-validation candidates only. They are not deployment candidates. Production/beta deployment must use the preserved Home Lab certificate above.

## Latest verified Moonfin milestone — TV focus hardening

**Verified source:** `a8be4622657a5355abc0e369fcfa4c7ada967759`  
**Workflow:** `34101228326` / run **#57**  
**Result:** GREEN

This source includes the feature-local Android TV Discovery row/focus slice:

- current upstream `LockedFocusRow` reused for TV-only Discovery rows;
- Web/mobile retain the normal pointer/touch row implementation;
- selected cards receive `externalIsFocused` rather than a custom pointer/focus patch;
- D-pad left/right selection and right-edge `See All` behaviour are covered;
- vertical up/down delegation between built Discovery lanes is covered;
- pointer taps remain covered even when the TV-focused card path exists;
- the test harness now loads Moonfin `AppLocalizations`, fixing run #56's test-only `SeerrMediaTypeBadge` null-localisation failure.

Run #57 passed route overlay, catalogue generation, format, analysis, focused tests and narrow-scope validation. Its full client-build job correctly skipped because this commit did not request a full build. No live server or deployment was changed.

## Verified webOS v2 service/build foundation

Branch: `PRYYSE/Smart-TV:homelab/webos-discovery-v2`  
Verified service/package source: `eb6b4ad409a76134745263cfcfc5eefbb8789272`  
Workflow: `34089074388` / run **#4**  
Result: **GREEN**  
Current documentation checkpoint head: `84bc92402a3cb457692c85b950f758cabd559435`

Verified foundation:

- fail-closed catalogue query planner mirroring Moonfin-Core filter/sort/date-token policy;
- network-first server-scoped catalogue/LKG loader;
- narrow authenticated Moonbase Seerr proxy client with path/query allow-lists;
- focused Discovery service tests;
- catalogue capability/fallback gate;
- isolated webOS package build;
- preserved `org.moonfin.webos` identity and 2.7.0 baseline metadata verification;
- isolated candidate artifact upload without publishing over the known-good v1 candidate.

The preserved `homelab/webos-v1-staging` branch/tag remains untouched.

## Exact next work

1. Finish the Flutter TV interaction slice by verifying/strengthening initial focus, focus return and deep `See All` grid/back behaviour without changing Web/mobile pointer/touch behaviour.
2. Rebuild Web, `mobile-beta` and `androidTv-beta` from the completed focus source and verify the resulting artifact bundle.
3. Build the six-tab catalogue-driven webOS Discovery UI behind guarded fallback to the existing stock Smart-TV Seerr Discover screen, including remote focus/back and deep browse.
4. Determine the correct webOS personalisation implementation from existing Jellyfin capabilities; do not fake unsupported `personalised` semantics.
5. Rebuild and verify a separate webOS IPK without changing app identity.
6. Run semantic regression accounting against the accepted 481-lane legacy reference; explicitly explain every genuinely unsupported lane.
7. Prepare atomic server build/cutover/rollback scripts and `SERVER_RUNBOOK.md` for stock Moonbase + external Web root + catalogue.
8. Do not change live until replacement artifacts pass code/build gates and the user is available for controlled server/device acceptance.

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
- details/request/local-media routing accepted
- Android certificate unchanged and deployment versionCode increased appropriately
- webOS app ID/update compatibility preserved
- stock Moonbase + external Web-root rollback prepared
- previous Web/APKs/webOS package and bundled stock Web fallback retained

## Do not

- delete legacy branches/backups
- modify the live server during GitHub-only work
- regenerate Android signing
- change/regenerate webOS app identity without deliberate migration
- broaden Home/nav/player customisation
- patch stock Seerr repository/client when a feature-local adapter is sufficient
- force unsafe semantic lanes
- continuously merge upstream main into production
- claim physical-client acceptance without real execution
