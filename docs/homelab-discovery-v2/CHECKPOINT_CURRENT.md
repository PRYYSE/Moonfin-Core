# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-07 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point for any future chat/agent. Read this file, then `ARCHITECTURE.md` and `SOURCE_MATRIX.md`. Do not restart the migration or modify the live server before the prepared cutover gates are met.

## Objective

Replace the legacy broad Home Lab Moonfin fork with:

> current stable official Moonfin + a small isolated Home Lab Discovery overlay + server-driven Discovery catalogue.

Maintained clients:

1. Web
2. Android mobile/tablet
3. Google TV / Android TV (Google TV Streamer 4K)
4. LG TV / webOS

**Correction from 2026-09-07:** LG webOS is active again and must be treated as a first-class maintained target. Existing working webOS identity/deployment knowledge must be preserved and reconciled rather than discarded.

## Work mode

The user requested Unlazy **Solo Complete**. Complete all safe GitHub/research/testing/preparation possible without waiting for routine interactive checkpoints. Prioritise a polished maintainable final product over speed. It is acceptable to replace earlier work when there is a concrete quality, correctness, architecture, or maintainability improvement.

This environment cannot execute commands on `docker01`, so live server/device execution remains a later explicit gate. Prepare batched scripts rather than asking for many commands.

## Product goal

Discovery should feel like a polished streaming-service discovery system rather than a large Seerr row dump:

- primary areas: For You, Movies, Series, Anime, New & Upcoming, Lists;
- useful Jellyfin-driven personalisation and `Because You Watched` style rows;
- broad curated discovery catalogue while avoiding repetitive neighbouring rows;
- deterministic session behaviour, cross-row novelty, family diversification and graceful backfill;
- fast landing-page previews plus genuinely deep `See All` browsing/pagination;
- sparse/invalid lanes fail individually and disappear or fall back safely;
- existing media opens normal Moonfin/Jellyfin details; unavailable media uses normal Seerr request flows;
- normal Moonfin Home/player/navigation/settings/themes stay upstream-owned;
- all four maintained targets receive platform-specific acceptance, including webOS remote/focus/back/resume/rendering behaviour.

## Verified upstream state

Re-checked 2026-09-06:

- official Moonfin stable: `2.5.1`
- stable commit: `f18c45b1fbf9b63871b4f93237179f9706154763`
- official upstream `main` at check: `508f052f4da725b1f520f4a73b64330d43c86f92`
- official Moonbase stable: `2.2.0`
- Moonbase 2.2.0 bundles Web 2.5.1
- Flutter for Moonfin 2.5.1: `3.44.1`
- official Android flavours: `mobile`, `mobile-beta`, `androidTv`, `androidTv-beta`
- official Moonbase supports `MOONFIN_WEB_ROOT`
- official Moonbase Seerr catch-all proxy forwards authenticated query strings
- official `RowDataSource.loadSinceYouWatchedRow(serverId, rowIndex)` exposes the accepted recommendation engine and is reused through a feature-local adapter instead of patching Home

Production follows stable tags. Upstream `main` is compatibility-canary only.

## Git archive/sync completed

Repository: `PRYYSE/Moonfin-Core`

Immutable recovery/archive refs created before reset:

- `archive/pre-v2-main-2026-09-06` -> `cfe9c5c1a4c32d1c0828eff5ed41ea3a2947d126`
- `archive/seerr-discovery-v1-2026-09-06` -> `aa604b6cdc0083cebe8762f85ede896024f88725`
- `archive/live-web-a9c789-2026-09-06` -> live accepted Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- `archive/android-accepted-e7e5ab-2026-09-06` -> accepted Android source `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`

Fork `main` was force-synchronised to official upstream `main`:

- `main` -> `508f052f4da725b1f520f4a73b64330d43c86f92`

Clean production branch started from stable 2.5.1:

- `homelab/discovery-v2` base -> `f18c45b1fbf9b63871b4f93237179f9706154763`

Legacy branches were not deleted.

## Legacy live state — preserve until cutover

No v2 server migration has been performed. Live remains the accepted legacy installation:

- custom Moonbase `2.0.3.1`
- live Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- compiled Discovery `481/486`
- Seerr enabled
- old pointer/touch hotfix was prepared but never deployed; do not resume it unless the architecture pivot is abandoned

Accepted Android baseline:

- source `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`
- version `2.4.0+30000147`
- signing root `/srv/appdata/moonfin/android-signing`
- signing certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Never regenerate signing.

Existing LG/webOS package identity, pairing/install/update path and previously confirmed TV deployment are now preservation requirements. Reconcile exact identity/build details from the archived working source/handover before producing replacement webOS artefacts; do not invent or regenerate them.

## Architectural lock

Custom product code lives under:

`lib/features/homelab_discovery/`

Official Moonfin remains authoritative for Home, general navigation, player, downloads, themes, Seerr session/auth/request handling, media details, mobile input and Android TV focus/D-pad primitives.

The approved core product diff is the Seerr Discovery route in:

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

### Personalisation

- feature-local adapter reuses stock `RowDataSource.loadSinceYouWatchedRow`
- stable sixteen recommendation strategy slots
- local media/anime filtering after stock scoring
- personal presentation helper for row-title uniqueness and title-family diversification
- presentation policy intentionally belongs after concurrent lane fetching so network completion order cannot change visible cross-row choices

### Catalogue tooling

Proven authoring/compiler validators live under:

`tooling/homelab-discovery-v2/`

Current authoring gate reports exactly **486 lanes**:

- For You: 16
- Movies: 130
- Series: 140
- Anime: 160
- New & Upcoming: 20
- Lists: 20

Accepted live semantic compile remains the regression reference at 481 lanes. Do not force unsafe mappings merely to reach 486.

### Isolated Seerr bridge and lane paging

Feature-local bridge/paging provides:

- rich filter allow-list and date-token resolver
- safe sort allow-list
- request-plan mapper
- authenticated Moonbase catch-all proxy bridge
- bounded read-ahead paginator
- cross-page identity dedup
- media-type/predicate filtering
- per-lane error isolation
- preview limits
- session novelty/backfill
- sparse-lane hide behaviour

## Current exact resume state

Previous chat stopped on:

- branch head `d03534042b49ab479829862bf81e266f670cb9ae`
- workflow run `34038412914` -> **FAILURE**
- route gate PASS
- authoring catalogue gate PASS
- format gate PASS
- analyser failed on three mechanical mismatches after moving personal presentation out of concurrently fetched lane loaders

Errors were:

1. invalid `const` result constructor because `displayTitle ?? section.title` is runtime state;
2. stale test parameter `personalUsedTitles`;
3. stale test parameter `personalSurfacedFamilies`.

2026-09-07 recovery work fixed those without reintroducing race-order mutable presentation state:

- `HomeLabDiscoveryLaneLoadResult` constructor is now non-const;
- lane-loader regression test now verifies the loader returns stock-adapter ranking/title unchanged;
- title uniqueness/family diversification remains covered separately in `discovery_personal_presentation_test.dart` and must be applied later in deterministic catalogue order.

Repair commit before this checkpoint:

- `0e33e6d8e98f2062a4f79b55eaf4c6bd17e1b625` — `fix(discovery-v2): repair deterministic presentation refactor`

This checkpoint commit is intentionally the push that should trigger the next CI validation. Inspect the newest workflow run and repair only the exact failure if it is not green.

## CI evidence before current repair

Workflow:

`.github/workflows/homelab-discovery-v2.yml`

Earlier verified successful run:

- run `34037731579`
- head `cdb88d6c027840a6346845a18d67e434110d67a1`
- catalogue gate PASS
- Dart format PASS
- focused analysis PASS
- focused tests PASS
- narrow custom-scope gate PASS

Run `34037869613` later established route integration before subsequent personalisation/refactor work.

The most recent pre-recovery run is the known failed `34038412914` at `d035340...` described above.

## Quality policy

Do not optimise for the quickest apparent completion. For each substantial slice:

1. complete the intended behaviour;
2. expert-review architecture and integration;
3. defect-hunt correctness, edge cases, platform behaviour and regressions;
4. polish and recheck;
5. only then update this checkpoint as verified.

CI green is necessary but not sufficient for product completion.

## Exact next work

Continue only on `homelab/discovery-v2`.

1. Inspect the workflow triggered after this checkpoint; repair exact failures until the focused suite is fully green.
2. Immediately record the green run/head here and create/update `PROGRESS.md`.
3. Complete deterministic post-fetch personal presentation integration in catalogue order, with tests proving completion order cannot affect visible titles/family diversity.
4. Replace the temporary Discovery shell with polished current-Moonfin UI using upstream navigation/cards/focus/platform primitives.
5. Implement `See All`, deep paging, catalogue index/refinement, back navigation and error/empty/loading states.
6. Validate catalogue semantics against the accepted 481-lane reference; fix genuine mappings but do not fake unsupported semantics.
7. Add Web mouse/touch/keyboard regression coverage and Android TV focus/D-pad tests where Flutter tests can prove them.
8. Restore LG/webOS as a maintained release path: recover exact existing package identity/build/deploy knowledge, add build/compatibility preparation, and document real-device gates separately from Web/Android TV.
9. Add actual Web, `mobile-beta`, `androidTv-beta`, and feasible webOS packaging/build gates.
10. Restore CI to read-only strict mode once bootstrap autoformat/route persistence is no longer required.
11. Create `SERVER_RUNBOOK.md`, `PROGRESS.md`, `HANDOVER.md` and exact-ref server build/cutover/rollback scripts.
12. Do not change live until replacement artefacts pass code/build gates and the user is available for the prepared server command/device acceptance.

## Acceptance gates before live cutover

- archive refs verified
- stable baseline and v2 overlay compile
- custom diff narrow and explainable
- missing/invalid catalogue falls back to stock Discovery
- catalogue schema/compiler diagnostics pass
- no unexplained semantic regression below accepted 481 baseline
- deterministic personal presentation proven independent of concurrent fetch completion order
- polished Discovery landing UI and deep `See All` behaviour pass focused tests
- Web mouse/touch/keyboard tabs work
- Android mobile touch/back/resume works
- Google TV D-pad/focus/back works
- LG webOS remote/focus/back/resume/rendering/package-update path works on real TV
- request and local media routes work
- Android certificate unchanged and versionCode increased
- webOS app identity/update compatibility preserved
- stock Moonbase + external Web-root cutover has exact rollback
- previous Web/APKs/webOS package and bundled stock Web fallback retained

## Do not

- delete legacy branches/backups
- modify live server from GitHub-only work
- regenerate Android signing
- regenerate/change webOS app identity without a deliberate migration decision
- reintroduce broad Home/nav/player customisation
- patch official Seerr repository/client unless a real current gap cannot be isolated
- force the last five semantic lanes
- continuously merge upstream `main` into production
- claim server/device acceptance before real execution
