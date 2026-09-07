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

## Verified deterministic-controller milestone

Expert review found and fixed a race-order defect in earlier code: shared session novelty/deduplication was being mutated inside concurrent lane loaders. The corrected architecture is:

`deterministic section selection -> bounded concurrent lane I/O -> results keyed by section ID -> catalogue-order novelty/dedup -> catalogue-order personal title/family presentation`

Key commits:

- `79a4130b24c512c653e00c70992034f917cf6ed4`: concurrent lane loader made presentation/session-pure.
- `4caacb23697a436385f8cd6c4fa3f5dd87a76179`: novelty/shared dedup moved post-fetch.
- `fa89efb72c09f7cbd0d2b63a638dd726fc691820`: catalogue-order novelty regression proof.
- `f42629138787fd2c71cb901719ca7ef757689ad0`: feature-local tab controller.
- `1c3a9fd5196c04bdb6a7ae2249d347e6f9755822`: reverse-completion/failure/refresh/reset controller tests.

Strict CI is read-only, shows exact formatter drift and cancels superseded runs.

## Latest verified milestone — runtime + real landing UI

The temporary section-name shell has now been replaced by a real feature-local runtime and landing-page implementation without broadening Moonfin's core DI.

Implemented:

- feature-local `HomeLabDiscoveryRuntime` consumes stock `MediaServerClient`, async `SeerrRepository` and `RowDataSource` registrations;
- one tab controller per catalogue tab;
- lane I/O is bounded with Moonfin's existing `mapBounded` utility while final presentation remains deterministic;
- controller test proves the concurrency cap without depending on unstable hash identities;
- runtime/entry/bridge bind to the authoritative active `MediaServerClient`, not `MediaServerClientFactory.getActiveClient()`/last-loaded-client ordering;
- runtime creation disposes a late result if the screen has already unmounted;
- landing screen now renders loading, retry, empty, partial-failure and refresh states plus real horizontal `MediaCard` rows;
- item taps use stock Seerr media-detail routing;
- stock catalogue fallback remains unchanged.

**Verified source head:** `56daef893ac3baa010532dcd33e7a35c5b411a31`  
**Workflow:** `34079224788`  
**Result:** GREEN — route, 486-lane catalogue, format, focused analysis, focused tests and narrow custom-scope all passed.

No live server, Android signing or webOS identity was changed.

## Expert-review findings still to resolve

The runtime/UI milestone is green, but it is not yet a release candidate. Review against the accepted v1 behaviour exposed material gaps that must be solved rather than hidden:

1. `availabilityMode` exists in the v2 schema but the new runtime currently supplies no lane predicate, so requestable/available/requested/not-owned/unwatched membership is not yet enforced.
2. The authoring catalogue contains `externalList` lanes. The generic Seerr request planner deliberately does not execute `externalList`, so those lanes need an explicit feature-local external-list adapter or deliberate compile-time exclusion. Do not silently let curated lanes fail at runtime.
3. `See All` is not implemented yet. It needs its own deep paging state and must not reuse preview-only family/session diversification.
4. The first real landing UI deliberately uses simple Flutter tab/horizontal scrolling primitives. Before final polish, selectively reuse upstream Moonfin focus/row primitives where they materially improve TV/keyboard behaviour without reviving the old broad fork or the old pointer/touch regression.
5. Rotation history is currently runtime-local. Persistent cross-launch rotation from the accepted v1 implementation should be evaluated before release so catalogue variety does not regress after app restarts.

## Exact next work

1. Restore feature-local availability/NSFW membership policy with tests and wire it into landing + deep browse.
2. Decide and implement executable `externalList` behaviour from supported official/current services; fail closed for unsupported server placeholders rather than pretending they work.
3. Implement a feature-local `See All` controller with deep paging, dedup, personal-page support, load-more failure recovery and reset/refresh tests.
4. Integrate `See All` into Web/mobile/TV navigation with back behaviour and a Moonfin-native media grid.
5. Harden landing focus/keyboard/D-pad behaviour using current upstream primitives while retaining standard pointer/touch-safe tabs.
6. Validate compiled semantics against the accepted 481-lane reference and explicitly account for every dropped/unsupported lane.
7. Add automated Web pointer/touch/keyboard and TV focus regression coverage where Flutter tests can prove behaviour.
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
