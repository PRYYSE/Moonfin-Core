# AI Project State

**Updated:** 2026-09-09 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across the Home Lab Moonfin Discovery product before physical-device, live-service or production acceptance.

**Current phase:** Android mobile/tablet completion pass is NEXT. Shared personalisation and the Web completion pass are verified complete and must not be restarted without a concrete regression.

Durable implementation order: `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`  
Mandatory official-update procedure: `docs/UPSTREAM_UPDATE_PROTOCOL.md`

## Moonfin-Core current verified state

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

### Verified product/build source

- source: `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- commit: `test(discovery-v2): restore Web media-card harness [full-build]`
- workflow: **#115** / ID `34291216084` — GREEN
- focused-validation job: `102277953232` — GREEN
- full candidate job: `102279011763` — GREEN

Documentation-only checkpoint commits may be newer than this SHA. `1ac1499a...` remains the verified product/build source until a later source-changing full build passes.

### #115 validation evidence

Focused validation passed:

- route overlay integration gate
- 486-lane authoring/catalogue compiler gate
- catalogue Python tests: **8 passed**
- Dart format: **52 files, 0 changed**
- Flutter analyse: **no issues found**
- normal `test/homelab_discovery` suite: **93 passed, 5 Web-only skipped**
- Chrome Web/route suite: **12 passed**
- narrow custom-scope gate

The Chrome suite proves the Web contracts added in this pass, including:

- adaptive Web grid density
- correct Jellyfin-vs-Seerr item routing and malformed-local-pointer fallback
- tab selection by touch, mouse and keyboard
- shared missing-art/title fallback (`Untitled` / `UNTITLED`)
- media-card activation exactly once from touch, mouse and keyboard
- browser/deep-route history, direct deep URL resolution and landing restoration

The earlier media-card Chrome failures were a test-environment localisation omission, not a runtime product defect. The harness now installs Moonfin localisation delegates; runtime `HomeLabDiscoveryMediaCard`/`MediaCard` behaviour was not weakened or bypassed.

### #115 candidate evidence

Full candidate build passed:

- Web release
- Android `mobile-beta` release APK
- Android `androidTv-beta` release APK
- packaging/checksum generation
- artifact upload

Artifact:

- ID: `10082137559`
- name: `homelab-discovery-v2-candidates-1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- size: `304771572` bytes
- digest: `sha256:f2a7fc6b32667d3f4d38cf3a8e4165c2cce46d39facbd6dccb029687365e2abc`

Internal candidate SHA-256 values:

- Android TV APK: `acc1477625c1a24d2644b8b871b168e4e8c9430cb6b1694c70c1f9273cbbb029`
- Android mobile APK: `e83c4c099e73548c2110b82b5da66c6bb981700582d35aef43c0fc74f3c2f326`
- Web tarball: `c50ae5eff6956946d5339ea99f11dd4a383fa6e09a7fb9e79132516bc1437079`

`BUILD_INFO.txt` confirms source `1ac1499a...`, Flutter `3.44.1`, app `2.5.1+30000149`, Android TV `2.5.1` / build `2000016`, Web release, `mobile-beta`, and `androidTv-beta`.

CI Android signing remains `debug-fallback-not-for-deployment`. Production Android signing must preserve the accepted Home Lab certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate it.

The Android APKs above are validation artefacts only. They do **not** mean the Android mobile/tablet or Android TV completion passes are complete.

## Completed foundations — do not redo

- isolated Home Lab Discovery architecture with guarded stock fallback
- deterministic concurrent loading and post-fetch presentation
- 486-lane authoring/catalogue validation
- membership/NSFW filtering
- persistent rotation and session novelty handling
- landing + deep `See All`, paging, retry and refresh state
- local/external identity safeguards and details routing
- TV focus/D-pad foundations
- explicit generic affinity personalisation
- truthful source-specific personalisation adapters
- bounded request cost, caching, paging, deduplication, identity and force-refresh safeguards
- **Web completion pass verified at `1ac1499a...` / #115**
- workflow push hygiene: `docs/**` commits no longer start/cancel Discovery validation

Unsupported structural/context semantics remain fail-closed. Do not re-enable them by approximation.

## Smart-TV / webOS

Do not redo the separately completed advanced Smart-TV work while starting Android. Final webOS reconciliation comes after Android TV in the completion order. No physical LG acceptance is claimed yet.

## Stable / rollback state

Live remains deliberately untouched:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Recovery refs/candidates remain intact. Do not modify live services during GitHub-only completion work.

## Completion order

1. shared semantic/personalisation contract — **COMPLETE**
2. Web completion pass — **COMPLETE at `1ac1499a...` / #115**
3. Android mobile/tablet completion pass — **NEXT**
4. Android TV / Google TV completion pass
5. final webOS reconciliation
6. cross-platform parity/recommendation-quality pass
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance and cutover

## Acceptance-only work still deferred

- subjective Web browser acceptance
- Android phone/tablet device acceptance
- Android TV / Google TV device acceptance
- physical LG rendering/performance/remote/Back/lifecycle/update acceptance
- live Jellyfin/Seerr recommendation-quality capture
- real request/detail/local playback acceptance
- production deployment/cutover

## Exact next action

Begin the **Android mobile/tablet completion pass** as the next implementation batch. Use the already-verified shared Discovery contracts and Web work; do not rebuild them. Finish everything code-testable for phone/tablet, run focused validation, then use the full candidate workflow as the final GitHub-side gate. Keep physical-device acceptance deferred until the whole GitHub completion sequence reaches its explicit checkpoint.
