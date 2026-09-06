# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-06 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point for any future chat/agent. Read this file, then `ARCHITECTURE.md` and `SOURCE_MATRIX.md`. Do not restart the migration or modify the live server before the prepared cutover gates are met.

## Objective

Replace the legacy broad Home Lab Moonfin fork with:

> current stable official Moonfin + a small isolated Home Lab Discovery overlay + server-driven Discovery catalogue.

Maintained clients:

1. Web
2. Android mobile/tablet
3. Google TV / Android TV (Google TV Streamer 4K)

LG webOS is retired.

## Work mode

The user requested Unlazy **Solo Complete**: complete all safe GitHub/research/testing/preparation possible without waiting for interactive checkpoints. This environment cannot run commands on `docker01`, so live server/device execution remains a later explicit gate. Prepare batched scripts rather than asking for many commands.

## Verified upstream state

Re-checked 2026-09-06:

- official Moonfin stable: `2.5.1`
- stable commit: `f18c45b1fbf9b63871b4f93237179f9706154763`
- official upstream `main` at check: `508f052f4da725b1f520f4a73b64330d43c86f92`
- official Moonbase stable: `2.2.0`
- Moonbase 2.2.0 bundles Web 2.5.1
- Flutter for Moonfin 2.5.1: `3.44.1`
- official Android has `mobile`, `mobile-beta`, `androidTv`, `androidTv-beta`
- official Moonbase supports `MOONFIN_WEB_ROOT`
- official Moonbase Seerr catch-all proxy forwards authenticated query strings, allowing rich Home Lab Discovery filters without patching core `SeerrRepository`/`SeerrHttpClient`
- official `RowDataSource.loadSinceYouWatchedRow(serverId, rowIndex)` still exposes the accepted Home recommendation engine and supports stable row indices beyond the five visible preference rows; use it through a feature-local adapter instead of patching Home.

Production follows stable tags. Upstream `main` is compatibility-canary only.

## Git archive/sync completed

Repository: `PRYYSE/Moonfin-Core`

Created before reset:

- `archive/pre-v2-main-2026-09-06` -> `cfe9c5c1a4c32d1c0828eff5ed41ea3a2947d126`
- `archive/seerr-discovery-v1-2026-09-06` -> `aa604b6cdc0083cebe8762f85ede896024f88725`
- `archive/live-web-a9c789-2026-09-06` -> live accepted Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- `archive/android-accepted-e7e5ab-2026-09-06` -> accepted Android source `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`

Then fork `main` was force-synchronised to official upstream `main`:

- `main` -> `508f052f4da725b1f520f4a73b64330d43c86f92`

Created clean production branch from stable 2.5.1:

- `homelab/discovery-v2` initially -> `f18c45b1fbf9b63871b4f93237179f9706154763`

Legacy branches were not deleted.

## Legacy live state — preserve until cutover

- custom Moonbase `2.0.3.1`
- live Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- compiled Discovery `481/486`
- Seerr enabled
- old pointer/touch hotfix was prepared but never deployed; do not spend time finishing it unless this architecture pivot is abandoned

Accepted Android baseline:

- source `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`
- version `2.4.0+30000147`
- signing root `/srv/appdata/moonfin/android-signing`
- signing certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Never regenerate signing.

## Architectural lock

Custom product code lives under:

`lib/features/homelab_discovery/`

Official Moonfin remains authoritative for Home, general navigation, player, downloads, themes, Seerr session/auth/request handling, media details, mobile input and Android TV focus/D-pad primitives.

The only currently approved core product diff is the Seerr Discovery route in:

`lib/ui/navigation/app_router.dart`

It is generated/checkable by:

`tooling/homelab-discovery-v2/apply_route_overlay.py`

The route is guarded:

- valid compatible catalogue -> Home Lab Discovery
- missing/invalid/incompatible catalogue -> stock `SeerrDiscoverScreen`

Catalogue URL:

`/Moonfin/Web/homelab/discovery.catalogue.json`

Target server root:

`/srv/appdata/moonfin/`

with stock Moonbase `MOONFIN_WEB_ROOT` pointing to an external persistent Web release symlink.

## V2 implementation already on branch

### Documentation

- `docs/homelab-discovery-v2/ARCHITECTURE.md`
- `docs/homelab-discovery-v2/SOURCE_MATRIX.md`
- this checkpoint

### Guarded catalogue foundation

- strict feature-local catalogue schema/models
- schema v1/v2 migration compatibility
- revision/generated/capability metadata
- static server URL loader
- network-first validation
- SharedPreferences per-server last-known-good cache
- network failure -> valid cache
- network/cache failure -> unavailable without throwing
- guarded entry selects custom or stock Discovery
- focused tests for valid/invalid/unsupported/cache/fallback behaviour

### Deterministic engine

- `engine/discovery_composer.dart`
- `engine/discovery_session.dart`
- stable anchor/deep-pool interleave
- deterministic seed/refresh behaviour
- pool budgets/cooldowns
- presentation-only shared dedup with backfill
- read-only novelty checks fixed to avoid mutating session state

### Catalogue tooling

Proven legacy authoring/compiler validators were moved under:

`tooling/homelab-discovery-v2/`

Current authoring gate reports exactly **486 lanes**:

- For You: 16
- Movies: 130
- Series: 140
- Anime: 160
- New & Upcoming: 20
- Lists: 20

Accepted live semantic compile remains the regression reference at 481 lanes; do not force unsafe mappings merely to reach 486.

### Isolated Seerr bridge and lane paging

Added feature-local:

- safe rich filter allow-list and date-token resolver
- safe sort allow-list
- request-plan mapper
- `MoonfinHomeLabDiscoveryBridge`
- bounded paginator
- lane loader

The bridge keeps official `SeerrRepository` responsible for session/auth state, then uses Moonbase's existing authenticated catch-all proxy for rich Discovery query parameters. This avoids modifying official Seerr repository/client code.

Paginator/lane loader provide:

- bounded read-ahead
- cross-page identity dedup
- media-type/predicate filtering
- per-lane error isolation
- preview limit
- session novelty/backfill
- sparse-lane hide behaviour

## CI evidence

Workflow:

`.github/workflows/homelab-discovery-v2.yml`

Verified successful run:

- run `34037731579`
- head `cdb88d6c027840a6346845a18d67e434110d67a1`
- catalogue gate PASS
- Dart format PASS
- focused analysis PASS
- focused tests PASS
- narrow custom-scope gate PASS

Current route-integration run at this checkpoint:

- run `34037869613`
- source head `2a30cef26dae97f057bfebdbda0587df46632e30`
- route overlay persisted by CI as bot commit `edbc65d59883837d550502b14d432f2d98a25339`
- route gate PASS
- 486-lane authoring gate PASS
- format gate PASS
- analysis/tests were still running when this checkpoint was written

If resuming after interruption, inspect that run/result before relying on route integration as fully verified.

## Legacy breadth evidence

Old base `cfe9c5c...` to accepted live source `a9c789...` is **346 commits ahead** with broad Home/navigation/Seerr/DI/browse/tooling changes. Whole-branch cherry-picks are forbidden.

## Exact next work

Continue only on `homelab/discovery-v2`.

1. Finish/inspect run `34037869613`; repair exact failure if any.
2. Port personalisation through stock `RowDataSource.loadSinceYouWatchedRow` in a feature-local adapter; no Home patch. Preserve stable 16 strategy slots, post-filter media/anime where safe, and keep generated `Because You Watched` titles.
3. Port personal presentation/title-family and cross-row novelty regression logic.
4. Replace the temporary Discovery shell with real current-Moonfin UI using official `NavigationLayout`, cards, focus and platform primitives.
5. Implement See All/deep paging and catalogue index/refinement.
6. Add Web pointer/touch/keyboard regression tests and TV focus tests where Flutter widget tests can prove them.
7. Add actual Web/mobile-beta/androidTv-beta compile gates.
8. Restore CI to read-only strict mode once bootstrap autoformat/route persistence is no longer required.
9. Create `SERVER_RUNBOOK.md`, `PROGRESS.md`, `HANDOVER.md` and exact-ref server build/cutover/rollback scripts.
10. Do not change live until replacement artefacts pass code/build gates and the user is available to run the prepared server command.

## Acceptance gates before live cutover

- archive refs verified
- stable baseline and v2 overlay compile
- custom diff narrow and explainable
- missing/invalid catalogue falls back to stock Discovery
- catalogue schema and compiler diagnostics pass
- no unexplained semantic regression below accepted 481 baseline
- Web mouse/touch/keyboard tabs work
- Android mobile touch works
- Google TV D-pad/focus/back works
- request and local media routes work
- Android certificate unchanged and versionCode increased
- stock Moonbase + external Web-root cutover has exact rollback
- previous Web/APKs and bundled stock Web fallback retained

## Do not

- delete legacy branches/backups
- modify live server from GitHub-only work
- regenerate Android signing
- reintroduce broad Home/nav/player customisation
- patch official Seerr repository/client unless a real current gap cannot be isolated
- force the last five semantic lanes
- continuously merge upstream `main` into production
- claim server/device acceptance before real execution
