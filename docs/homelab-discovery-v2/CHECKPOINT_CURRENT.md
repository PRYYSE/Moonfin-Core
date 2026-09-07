# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-07 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point. Read this file, then `ARCHITECTURE.md`, `PROGRESS.md` and `SOURCE_MATRIX.md`. Do not restart the migration or modify the live server before cutover gates are met.

## Objective

Replace the legacy broad Home Lab Moonfin fork with current stable official Moonfin + a small isolated Discovery overlay + server-driven catalogue, while preserving a polished Discovery product.

Maintained clients:

1. Web
2. Android mobile/tablet
3. Google TV / Android TV
4. LG TV / webOS

Quality, maintainability and polish take priority over speed. Existing work may be replaced when there is a concrete improvement.

## Work mode

User requested Unlazy **Solo Complete**. Complete all safe GitHub/testing/preparation possible without routine approval pauses. Create durable checkpoints at meaningful milestones. Server/device execution remains a later explicit gate.

## Product goal

Discovery should feel like a polished streaming service rather than a raw Seerr row dump:

- For You, Movies, Series, Anime, New & Upcoming, Lists;
- Jellyfin-driven personalisation;
- broad curated catalogue with low visible repetition;
- deterministic cross-row novelty, title uniqueness and family diversification;
- graceful backfill and isolated lane failures;
- fast previews plus genuinely deep `See All` browsing;
- native Moonfin details/request/player/navigation behaviour;
- platform-specific Web, Android, Android TV and webOS acceptance.

## Stable/upstream baseline

- Moonfin stable 2.5.1: `f18c45b1fbf9b63871b4f93237179f9706154763`
- upstream main at decision: `508f052f4da725b1f520f4a73b64330d43c86f92`
- Moonbase stable 2.2.0
- Flutter 3.44.1
- official Moonbase supports `MOONFIN_WEB_ROOT`
- official personal recommendation engine reused via `RowDataSource.loadSinceYouWatchedRow`

Production follows stable tags. Upstream main is canary only.

## Recovery refs

`PRYYSE/Moonfin-Core`:

- `archive/pre-v2-main-2026-09-06` -> `cfe9c5c1a4c32d1c0828eff5ed41ea3a2947d126`
- `archive/seerr-discovery-v1-2026-09-06` -> `aa604b6cdc0083cebe8762f85ede896024f88725`
- `archive/live-web-a9c789-2026-09-06` -> `a9c789fff317b41bba268d3a213439e23b8d1af5`
- `archive/android-accepted-e7e5ab-2026-09-06` -> `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`

Legacy branches/backups remain intact.

## Live state — do not change yet

- custom Moonbase 2.0.3.1
- live Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- compiled legacy Discovery 481/486
- Seerr enabled
- old pointer/touch hotfix not deployed and should not be resumed under v2

Accepted Android baseline:

- source `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`
- version `2.4.0+30000147`
- signing root `/srv/appdata/moonfin/android-signing`
- cert SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Never regenerate Android signing.

## webOS source of truth restored

Repository: `PRYYSE/Smart-TV`

- maintained branch `homelab/webos-v1-staging`
- current branch/candidate commit `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`
- candidate tag `homelab-webos-v1-candidate` -> same commit
- beta tag `homelab-webos-beta-latest` -> `264988874b330b11b5ca54fbf2115e42b5662d34`
- app ID `org.moonfin.webos`
- candidate version 2.7.0
- build package `packages/build-webos/`
- existing CI publishes `Moonfin_HomeLab_webOS.ipk` with checksum/manifest

The branch commit above is the commit SHA; `7424826381c91d3293f44bd1d41e65024c595fb9` is its tree SHA, not the branch commit.

Preserve app identity/update compatibility and the separate Smart-TV wrapper architecture. Real LG OLED65C6PSA acceptance is mandatory later.

## Architectural lock

Custom Flutter product code: `lib/features/homelab_discovery/`.

Only mandatory core product diff: Seerr Discovery route in `lib/ui/navigation/app_router.dart`, applied/checkable by `tooling/homelab-discovery-v2/apply_route_overlay.py`.

Guard:

- valid compatible catalogue -> custom Discovery
- missing/invalid/incompatible catalogue -> stock `SeerrDiscoverScreen`

Catalogue URL: `/Moonfin/Web/homelab/discovery.catalogue.json`.

Future server root: `/srv/appdata/moonfin/`, with stock Moonbase `MOONFIN_WEB_ROOT` serving persistent external Web releases.

## Implemented/verified v2 foundation

- strict catalogue schema/models and migration compatibility;
- network-first catalogue loading with per-server last-known-good cache;
- guarded stock fallback;
- deterministic composer/session rotation;
- cross-row novelty and graceful backfill;
- isolated Seerr bridge/request mapper;
- bounded paginator/cross-page dedup;
- per-lane error isolation/sparse hide;
- stock recommendation adapter with sixteen deterministic personal strategy slots;
- personal row title/family presentation helpers;
- 486-lane authoring catalogue and compiler tests.

Authoring lane counts:

- For You 16
- Movies 130
- Series 140
- Anime 160
- New & Upcoming 20
- Lists 20

Accepted live 481/486 remains semantic regression reference. Do not fake unsupported mappings to force 486/486.

## Recovery and deterministic presentation milestone

Previous broken head `d03534042b49ab479829862bf81e266f670cb9ae` failed after moving presentation out of concurrent lane loads.

Repairs:

- `0e33e6d8e98f2062a4f79b55eaf4c6bd17e1b625`: fixed invalid result constructor + stale loader test args without restoring shared mutable presentation state.
- run `34076786844`: GREEN all focused gates.
- `f2de6fc4804dacc9c5bb06a51e4121be5831c89c`: added `HomeLabDiscoveryTabPresentation`, a pure post-fetch catalogue-order presentation stage.
- CI formatter produced `5181232cefc6df403e491ee52dea9faa1107e967`.
- `ca786ca6571f65b63443144738df1814d8d7f6b9`: fixed only two collection-literal lints in the new regression test.
- run `34077193024`: **GREEN** route, catalogue, format, analysis, focused tests, narrow-scope.

The tests prove reversed asynchronous-result insertion order does not alter personal row titles or family-diversification output.

## CI hardening / durable docs milestone

After the green `ca786ca...` run:

- `22c2712adbd4c2fda3d03f9582437bea925924fa`: converted Discovery CI from branch-mutating bootstrap mode to strict read-only validation (`contents: read`, no auto-format/route apply/push).
- `a221aa90d85aa965e43a3b942062760aac783b3a`: created `PROGRESS.md`.
- `13dae3ee055cddfbba6f1d15bc8fc640338a2ae8`: corrected `ARCHITECTURE.md` for all four maintained clients and exact Smart-TV/webOS source-of-truth refs.

This checkpoint commit follows those changes. The newest workflow must be checked and green before strict-CI hardening is considered verified. Because CI is now read-only it must not create new branch commits.

## Exact next work after strict CI is green

1. Build feature-local tab controller/view-model: deterministic section selection -> concurrent lane loads -> results keyed by section ID -> pure catalogue-order presentation.
2. Add controller-level tests using reversed completion order, refresh nonce/session behaviour, per-lane failures and sparse rows.
3. Integrate controller into `HomeLabDiscoveryScreen` and replace `_PortInProgressTab` with real loading/error/usable lane states.
4. Build polished Moonfin-native horizontal media lanes/cards using upstream design/focus/platform primitives.
5. Implement `See All` deep paging/refinement/back behaviour without applying preview-only diversification to the full result list.
6. Validate catalogue semantics against accepted 481-lane baseline.
7. Add Web pointer/touch/keyboard and Android TV D-pad/focus regression coverage where automated tests can prove it.
8. Prepare actual Web, `mobile-beta`, `androidTv-beta` artefact gates.
9. Reconcile the compatible Web experience into `PRYYSE/Smart-TV` and build a preserved-identity webOS candidate; real TV test remains manual.
10. Create `SERVER_RUNBOOK.md`, `HANDOVER.md` and exact-ref build/cutover/rollback scripts.
11. Do not change live until code/build gates pass and the user is available for controlled migration/device acceptance.

## Cutover acceptance gates

- archives/rollback refs preserved;
- strict source/catalogue CI green;
- narrow custom diff;
- guarded stock fallback;
- no unexplained semantic regression below accepted 481 baseline;
- deterministic post-fetch presentation proven race-order independent;
- polished landing + See All tested;
- Web mouse/touch/keyboard accepted;
- Android mobile touch/back/resume accepted;
- Android TV D-pad/focus/back accepted;
- LG webOS remote/focus/back/resume/rendering/update path accepted on real TV;
- request/local-media routes accepted;
- Android cert unchanged and versionCode increased;
- webOS app ID/update compatibility preserved;
- stock Moonbase + external Web-root exact rollback prepared;
- previous Web/APKs/webOS package and bundled stock Web fallback retained.

## Do not

- delete legacy branches/backups;
- modify live server during GitHub-only work;
- regenerate Android signing;
- change/regenerate webOS app identity without deliberate migration;
- broaden Home/nav/player customisation;
- patch stock Seerr repository/client unless a real gap cannot be isolated;
- force unsafe semantic lanes;
- continuously merge upstream main into production;
- claim physical-client acceptance without real execution.
