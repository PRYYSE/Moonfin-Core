# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-08 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point. Read this file and `docs/AI_PROJECT_STATE.md`, then use `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md` for the remaining implementation order and `docs/UPSTREAM_UPDATE_PROTOCOL.md` for future official Moonfin releases.

Do not restart completed work or modify the live server during GitHub-only completion work.

## Objective / quality lock

Replace the legacy broad Home Lab Moonfin fork with current official Moonfin + a narrow isolated Discovery overlay + server-driven catalogue while preserving/improving Discovery across:

- Web
- Android mobile/tablet
- Android TV / Google TV
- LG webOS

The immediate project phase is **whole-product GitHub completion**, not physical LG acceptance.

Everything that can reasonably be completed in source, tests, CI, build/release engineering and cross-platform contracts should be completed first. Physical/device/live acceptance starts only after `docs/AI_PROJECT_STATE.md` explicitly records that no known GitHub/code-side work remains.

Quality, maintainability, truthful semantics and polish take priority over speed or nominal lane counts. Green CI/packages are milestones only.

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

## Current Flutter/Web/Android milestone

**Verified product source:** `86acba1246ea5e9424fcc96c9729c1e474359c53`  
**Workflow:** `34104075134` / run #62 — **GREEN**  
**Artifact:** `10012562778`

Verified foundation includes schema/catalogue/LKG/fallback architecture, deterministic concurrent loading/post-fetch presentation, membership/NSFW filtering, safe compiled catalogue semantics, persistent lane rotation, landing + deep See All, TV focus/D-pad hardening and reproducible Web/mobile/Android-TV builds.

This is not the final product source. The webOS semantic audit proved the current Flutter personalisation adapter can overstate named strategy semantics.

## Current webOS milestone

Repository: `PRYYSE/Smart-TV`  
Branch: `homelab/webos-discovery-v2`  
Preserved baseline: `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`

**Verified product source:** `a3a3317894a90bbab8b12cc7764187a8c5591369`  
**Workflow:** `34184420915` / run #50 — **GREEN**

Verification:

- 16/16 focused Discovery/integration suites
- 85/85 tests
- strict Enact lint
- legacy CSS/WebKit compatibility
- production Enact build
- IPK identity/package verification
- isolated artifact upload

Artifact:

- ID `10040048352`
- digest `sha256:6e765d2ad65fcd0cfb487bfc13075da209332e3f5004ea3e14a434b8d2661eef`
- IPK manifest SHA-256 `24e7a3af27c6ddf77d747b9990780073edb692ad6cef6453957d3afc45ee8e06`
- identity `org.moonfin.webos` / `2.7.0` / `index.html`

Do not redo its completed code-side foundation: truthful personalisation/fail-closed semantics, bounded landing/deep loads, retained state, focus/retry/Back integration, local Jellyfin identity routing, old-TV visual policy, malformed identity filtering, artwork fallback and aggregate quality diagnostics.

No physical LG acceptance is claimed.

## Semantic accounting

Accepted shared reference remains **486 authored / 481 active**.

Current truthful webOS static capability ceiling remains **468 executable active sections** before runtime sparse/error hiding.

The 13 deliberately unsupported active lanes remain:

- For You: Continue Exploring
- Series: Limited-Series Spotlight; Continue Exploring Series; One-Season Wonders; Long-Running Favourites; Weekend Binge
- Anime: Anime Specials & TV Movies; One-Season Anime; Long-Running Anime; Bingeable Anime; Completed Anime; Continuing Anime; Anime Miniseries & Short Runs

Do not fake these semantics.

## Current GitHub work: shared personalisation contract

Highest-priority defect:

`lib/features/homelab_discovery/engine/discovery_personalisation.dart` currently maps named `personalised` strategies to generic `RowDataSource` loaders using deterministic slot/hash selection.

A specialised row label can therefore receive unrelated generic content. This is semantically invalid and must be removed before platform-specific completion passes.

Required first correction:

- explicit strategy/source mapping
- only advertise support when current APIs can truthfully provide the strategy
- unsupported strategy families fail closed
- no arbitrary fallback row
- targeted tests proving specialised strategies cannot silently become unrelated rows
- preserve bounded paging/request cost

Archived accepted v1 personalisation files at `archive/seerr-discovery-v1-2026-09-06` may be used as reference, not blindly restored.

## Whole-product GitHub completion order

1. shared semantics/personalisation contract
2. Web completion pass
3. Android mobile/tablet completion pass
4. Android TV / Google TV completion pass
5. final webOS reconciliation
6. cross-platform parity/recommendation-quality pass
7. whole-product CI/release engineering
8. official upstream update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance and production cutover

Full detail: `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`.

## Official Moonfin update protocol

`docs/UPSTREAM_UPDATE_PROTOCOL.md` is mandatory.

When an official Moonfin update is released:

- record old/new upstream refs
- create an isolated update branch from the new official base
- generate an upstream/Home-Lab overlap impact report
- reapply/adapt only the narrow Home Lab overlay
- rerun semantic validation
- build Web + Android mobile + Android TV + webOS
- verify Android package/signing/versionCode and webOS app identity/update compatibility
- generate isolated candidate artifacts without overwriting the previous accepted release
- run whole-product regression gates
- perform physical acceptance only after GitHub integration is green

Release detection/reporting may be automated. Automatic production merge/deploy/promotion is prohibited.

## Exact next actions

1. Inspect current and archived personalisation/data APIs only as needed.
2. Remove arbitrary Flutter slot/hash personalisation and implement explicit truthful/fail-closed strategy handling.
3. Add targeted regression tests.
4. Run the relevant Moonfin-Core workflow/build gate and fix failures.
5. Update `docs/AI_PROJECT_STATE.md` and this checkpoint to the exact verified product source/workflow.
6. Continue with the Web completion pass in the next substantial batch.

## Do not

- delete legacy branches/backups
- modify the live server during GitHub-only work
- regenerate Android signing
- change/regenerate webOS app identity without deliberate migration
- patch broad core/stock Seerr code when a feature-local adapter is sufficient
- force unsafe semantic lanes
- claim physical acceptance without real execution
- treat green CI or packaging as product completion
