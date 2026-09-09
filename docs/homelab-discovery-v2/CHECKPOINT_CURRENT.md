# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-09 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file and `docs/AI_PROJECT_STATE.md` first. Use `GITHUB_COMPLETION_PLAN.md` for implementation order and `docs/UPSTREAM_UPDATE_PROTOCOL.md` for official Moonfin updates.

Do not restart completed work or modify the live server during GitHub-only completion work.

## Current boundary

The shared source-aware personalisation batch and the **Web completion pass are verified complete**.

Verified Web/product source:

- `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- `test(discovery-v2): restore Web media-card harness [full-build]`
- workflow **#115** / ID `34291216084` — GREEN
- focused-validation job `102277953232` — GREEN
- full candidate job `102279011763` — GREEN

Documentation-only commits may be newer than `1ac1499a...`; that SHA remains the verified product/build source until a later source-changing full build passes.

## Web completion verification

#115 focused validation passed:

- route integration
- 486-lane authoring/catalogue validation
- catalogue Python tests: **8 passed**
- format gate: **52 files, 0 changed**
- Flutter analyse: **no issues**
- normal Discovery Flutter suite: **93 passed, 5 Web-only skipped**
- Chrome Web/entry-route suite: **12 passed**
- narrow custom-scope gate

The 12 Chrome tests include:

- adaptive Web card density
- owned Jellyfin vs external Seerr routing
- malformed local pointer safe fallback
- touch/mouse/keyboard tab selection
- `Untitled` / `UNTITLED` missing-art fallback
- exactly-once card activation by touch, mouse and keyboard
- URL-safe section routing
- navigation-history landing restoration
- direct deep-URL catalogue/section resolution

The earlier four media-card failures were caused by the Chrome test harness missing Moonfin localisation delegates required by the shared Seerr media-type badge. `1ac1499a...` corrects the harness without changing runtime media-card behaviour.

## Verified candidate artifact

- ID `10082137559`
- name `homelab-discovery-v2-candidates-1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- size `304771572` bytes
- digest `sha256:f2a7fc6b32667d3f4d38cf3a8e4165c2cce46d39facbd6dccb029687365e2abc`

Internal SHA-256 values:

- Android TV APK: `acc1477625c1a24d2644b8b871b168e4e8c9430cb6b1694c70c1f9273cbbb029`
- Android mobile APK: `e83c4c099e73548c2110b82b5da66c6bb981700582d35aef43c0fc74f3c2f326`
- Web tarball: `c50ae5eff6956946d5339ea99f11dd4a383fa6e09a7fb9e79132516bc1437079`

`BUILD_INFO.txt` confirms source `1ac1499a...`, Flutter `3.44.1`, app `2.5.1+30000149`, Android TV `2.5.1` / build `2000016`, Web release, `mobile-beta`, `androidTv-beta`, and CI signing `debug-fallback-not-for-deployment`.

Android packages produced by this workflow are validation artefacts only. Android platform completion has **not** started.

## Web scope now closed code-side

Do not redo without a concrete regression:

- responsive/adaptive Web density
- pointer/touch/mouse/keyboard interaction coverage
- landing/deep browse routing and browser history
- Jellyfin local vs Seerr external details routing
- malformed-data/identity fallback covered by the current tests
- missing-art/title fallback
- shared personalisation semantics, recommendation safeguards, deduplication and fail-closed behaviour
- guarded stock fallback

Workflow hygiene is also corrected: push-triggered Discovery CI ignores `docs/**`, so durable checkpoint commits do not cancel active validation runs.

## Completed foundations that must not be redone

- isolated Home Lab Discovery architecture
- deterministic concurrent lane loading/presentation
- 486-lane catalogue/compiler validation
- membership/NSFW filtering
- persistent rotation/session novelty
- landing + deep `See All`, paging, retry and refresh behaviour
- TV focus/D-pad foundations
- external/local identity correction
- explicit generic affinity contract
- truthful source-aware personalisation adapters
- bounded request cost, paging, caching, dedup, identity and force-refresh safeguards
- **Web completion verified by #115**
- existing advanced webOS code-side work at its separate checkpoint

Unsupported structural/context semantics remain intentionally fail-closed.

## Stable / rollback state

Live remains untouched:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Recovery refs/candidates remain intact. Production Android signing must preserve certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate it.

## Exact next large batch

**Android mobile/tablet completion pass.**

Use the current shared Discovery implementation as the base. Finish everything reasonably code-testable for Android phone/tablet, including mobile interaction/layout/navigation/lifecycle/state edges and platform-specific routing/integration needed by Discovery. Preserve the already-verified semantic, identity, paging, deduplication and guarded-fallback contracts.

Finish the Android mobile/tablet batch with focused validation and the required full candidate workflow. Do not start Android TV in that same completion slice, and do not begin physical-device acceptance yet.
