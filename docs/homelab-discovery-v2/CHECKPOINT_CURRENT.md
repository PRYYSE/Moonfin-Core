# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-07 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point. Read this file, then `ARCHITECTURE.md`, `PROGRESS.md` and `SOURCE_MATRIX.md`. Do not restart the migration or modify the live server before cutover gates are met.

## Objective / quality lock

Replace the legacy broad Home Lab Moonfin fork with current stable official Moonfin + a narrow isolated Discovery overlay + server-driven catalogue, while preserving and improving the polished Discovery product.

Maintained clients:

1. Web
2. Android mobile/tablet
3. Google TV / Android TV
4. LG TV / webOS

Quality, maintainability and polish take priority over speed. Existing work may be replaced when there is a concrete correctness, UX, architecture or maintainability improvement.

User requested Unlazy **Solo Complete**: continue all safe GitHub/testing/preparation without routine approval pauses and create durable checkpoints at meaningful verified milestones. Server/device execution remains a later explicit gate.

## Stable baseline

- Moonfin stable 2.5.1: `f18c45b1fbf9b63871b4f93237179f9706154763`
- upstream main at architecture decision: `508f052f4da725b1f520f4a73b64330d43c86f92`
- Moonbase stable 2.2.0
- Flutter 3.44.1
- official Moonbase supports `MOONFIN_WEB_ROOT`
- official personal recommendation engine reused via `RowDataSource.loadSinceYouWatchedRow`

Production follows stable tags. Upstream main is canary only.

## Recovery refs / live rollback

Moonfin-Core immutable recovery refs:

- `archive/pre-v2-main-2026-09-06` -> `cfe9c5c1a4c32d1c0828eff5ed41ea3a2947d126`
- `archive/seerr-discovery-v1-2026-09-06` -> `aa604b6cdc0083cebe8762f85ede896024f88725`
- `archive/live-web-a9c789-2026-09-06` -> `a9c789fff317b41bba268d3a213439e23b8d1af5`
- `archive/android-accepted-e7e5ab-2026-09-06` -> `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`

Live remains untouched:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- legacy Discovery 481/486
- Seerr enabled
- old pointer/touch hotfix not deployed; do not resume under v2

Accepted Android baseline:

- source `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`
- version `2.4.0+30000147`
- signing root `/srv/appdata/moonfin/android-signing`
- cert SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Never regenerate signing.

## webOS source of truth

Repository `PRYYSE/Smart-TV`:

- maintained branch `homelab/webos-v1-staging`
- branch/candidate commit `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`
- candidate tag `homelab-webos-v1-candidate` -> same commit
- beta tag `homelab-webos-beta-latest` -> `264988874b330b11b5ca54fbf2115e42b5662d34`
- app ID `org.moonfin.webos`
- candidate version 2.7.0
- build package `packages/build-webos/`
- existing CI publishes `Moonfin_HomeLab_webOS.ipk` with checksum/manifest

`7424826381c91d3293f44bd1d41e65024c595fb9` is the candidate commit's tree SHA, not the branch commit. Preserve app identity, upgrade compatibility and separate Smart-TV wrapper. Real LG OLED65C6PSA acceptance is mandatory later.

## Architecture lock

Custom Flutter product code lives under `lib/features/homelab_discovery/`.

Only mandatory core product diff is the guarded Seerr Discovery route in `lib/ui/navigation/app_router.dart`, generated/checkable by `tooling/homelab-discovery-v2/apply_route_overlay.py`.

- valid compatible catalogue -> custom Discovery
- missing/invalid/incompatible catalogue -> stock Seerr Discovery

Catalogue URL: `/Moonfin/Web/homelab/discovery.catalogue.json`.

Future server root: `/srv/appdata/moonfin/`; stock Moonbase serves persistent external Web releases through `MOONFIN_WEB_ROOT`.

## Implemented foundation

- strict catalogue schema/models and migrations;
- network-first load + per-server last-known-good cache;
- guarded stock fallback;
- deterministic composer/session rotation;
- isolated Seerr bridge/request mapper;
- bounded paginator/cross-page dedup;
- lane error isolation/sparse hide;
- stock recommendation adapter with sixteen personal strategy slots;
- personal title/family presentation helpers;
- 486-lane authoring catalogue/compiler tests.

Authoring catalogue: For You 16, Movies 130, Series 140, Anime 160, New & Upcoming 20, Lists 20. Accepted live 481/486 remains the semantic regression reference. Never invent unsafe semantics to force 486/486.

## Latest verified milestone — deterministic controller

During expert review on 2026-09-07, a real race-order defect was found in earlier code: shared session novelty/deduplication was still being mutated inside concurrent lane loaders. That could make visible items depend on network completion order even after personal title/family presentation had been fixed.

It was corrected at the architecture boundary:

- `79a4130b24c512c653e00c70992034f917cf6ed4`: concurrent lane loader made presentation/session-pure.
- `4caacb23697a436385f8cd6c4fa3f5dd87a76179`: session novelty/shared dedup moved to deterministic post-fetch presentation.
- `fa89efb72c09f7cbd0d2b63a638dd726fc691820`: regression test proves shared novelty follows catalogue order.
- `f42629138787fd2c71cb901719ca7ef757689ad0`: added feature-local `HomeLabDiscoveryTabController` for deterministic selection -> concurrent lane loads keyed by section ID -> pure catalogue-order presentation.
- `1c3a9fd5196c04bdb6a7ae2249d347e6f9755822`: controller tests deliberately reverse async completion and verify deterministic output, lane failure isolation, refresh nonce and session reset.

Strict CI was also improved:

- GitHub token remains `contents: read`;
- no source commits/pushes from CI;
- formatter runs in ephemeral checkout and `git diff --exit-code` shows exact formatting drift;
- superseded branch runs cancel automatically;
- route/catalogue/format/analyse/test/narrow-scope gates remain mandatory.

**Verified green source head before this checkpoint:** `48e10844a4773b71e6aa444921b131b9c269911d`  
**Workflow:** `34077891738`  
**Result:** GREEN — route, 486-lane catalogue, format, focused analysis, focused tests and narrow custom-scope all passed.

This is stronger than the earlier implementation: neither shared item novelty/dedup nor personal title/family presentation can depend on concurrent request completion order.

## Current exact work position

The data/engine/controller foundation is now coherent and verified. `HomeLabDiscoveryScreen` is still the temporary shell that lists section names only. The next product slice is to connect the verified controller to real runtime dependencies and replace that shell with actual Moonfin-native Discovery lanes and states.

## Exact next work

1. Resolve feature-local runtime construction using existing official session/Seerr/DI services without broad DI patches.
2. Integrate one controller per Discovery tab into `HomeLabDiscoveryScreen`.
3. Implement loading, partial-success, empty, retry and refresh behaviour; hide sparse lanes while retaining lane-level failure isolation.
4. Render polished native horizontal media lanes/cards using upstream Moonfin card/theme/focus/navigation primitives.
5. Add widget/controller integration tests including Web pointer/touch/keyboard and TV focus foundations where testable.
6. Implement `See All` as a real deep browse route with paginator/refinement/back state; do not apply preview-only family/session presentation to the full deep result list.
7. Validate compiled semantics against accepted 481-lane reference.
8. Build reproducible Web, `mobile-beta`, `androidTv-beta` artefacts and preserve Android signing/version rules.
9. Feed the compatible tested Web experience through preserved `PRYYSE/Smart-TV` webOS packaging, preserving `org.moonfin.webos`; real TV acceptance remains manual.
10. Create server build/cutover/rollback scripts plus `SERVER_RUNBOOK.md`/handover.
11. Do not change live until replacement artefacts pass code/build gates and the user is available for controlled server/device acceptance.

## Cutover gates

- recovery refs intact;
- strict CI green;
- narrow explainable custom diff;
- guarded stock fallback;
- no unexplained semantic regression below accepted 481 baseline;
- deterministic concurrency proven;
- polished landing + See All tested;
- Web mouse/touch/keyboard accepted;
- Android mobile touch/back/resume accepted;
- Android TV D-pad/focus/back accepted;
- LG webOS remote/focus/back/resume/rendering/update accepted on real TV;
- details/request/local-media routing accepted;
- Android certificate unchanged and versionCode increased;
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
