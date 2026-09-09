# AI Project State

**Updated:** 2026-09-09 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

**Current phase:** Android mobile/tablet completion pass — **Slices 1 and 2 verified; Slice 3 final full-candidate validation in progress**.

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

Durable implementation order: `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`  
Mandatory update procedure: `docs/UPSTREAM_UPDATE_PROTOCOL.md`

## Android mobile/tablet status

### Slice 1 — VERIFIED

- source `086a41b0092f388d82c98ca2803e37b89dc6e46d`
- workflow **#116** / `34320947110` — GREEN
- route/catalogue/format/analyse/scope gates passed
- Discovery suite: **96 passed, 5 Web-only skipped**
- Chrome Web/route suite: **12 passed**
- adaptive phone/tablet breakpoints, card density, 48 px mobile tab target and native touch regressions verified

### Slice 2 — VERIFIED

Functional implementation source:

- `0aeadfb6ef948502c5e64bface0374fe2ed66ceb`
- `feat(discovery-v2): retain Android Discovery state safely`

Implemented:

- successful tab state retained across ordinary widget reconstruction/orientation/lifecycle resume
- concurrent ordinary tab loads coalesce
- failed tab results are not cached, so Retry genuinely reloads without rotation
- explicit Refresh clears retained state and rotates normally
- session reset waits for active load, then clears retained state and novelty history
- deep See All paging coalesces duplicate active advances
- pull-to-refresh waits for active paging before destructive reset/reload
- synchronous deep reset during active paging is deferred until the active operation settles
- Android native Back remains the existing `Navigator.push(MaterialPageRoute)` path and requires no rewrite

Workflow **#117** / `34322168040` failed only Dart formatting. CI identified one wrapping/indentation change in `test/homelab_discovery/discovery_tab_controller_test.dart`; no runtime logic failed.

Formatter-only recovery:

- `3cab6c5430eb6175320c4f16c4932218b41d42b8`
- `style(discovery-v2): format Android state regression test`
- exactly one test file changed; no product/runtime logic changed

Workflow **#118** / `34322882024` on `3cab6c...` — **GREEN**.

Verified by the completed focused-validation job:

- route integration: PASS
- authoring catalogue gate: PASS
- Dart format: PASS
- Flutter analyse: PASS
- focused Discovery tests: PASS
- Chrome Web/route interaction tests: PASS
- narrow custom-scope gate: PASS
- candidate build skipped as intended because this was not a `[full-build]`

### Slice 3 — FINAL CANDIDATE VALIDATION IN PROGRESS

Final code/CI review completed before triggering the candidate:

- compared the Android mobile Slice 1/2 delta against pre-mobile source `9491b145de7b3ea64dc6e31c4863e9c7c60520f6`
- changes are confined to Discovery UI/controllers/tests plus durable docs
- **no Android Gradle, manifest, package identity, auth, secure-storage or signing files changed**
- production mobile application ID remains `org.moonfin.androidtv`
- `mobile-beta` application ID remains `org.moonfin.androidtv.beta`
- release Gradle still uses the existing release keystore when present and debug signing only as the deliberate CI fallback when the private keystore is absent
- CI `BUILD_INFO.txt` explicitly marks `android_ci_signing=debug-fallback-not-for-deployment` and `production_android_signing=preserve-existing-homelab-certificate`
- final mobile UI review found no remaining code-testable defect in loading/error/empty, pull-to-refresh, paging, artwork/title fallback or local-vs-Seerr item routing

One final regression was added because the code now promises duplicate near-end paging coalescing and that exact mobile-scroll race lacked an independent test:

- final source `f0fbec0a9b29dcc2df0cf0e9b02ce3a8989c7b52`
- commit `[full-build] test(discovery-v2): close Android mobile paging gate`
- exact diff: only `test/homelab_discovery/discovery_see_all_controller_test.dart`
- adds a test proving two concurrent `loadMore()` calls produce only one page-2 request and both receive the same accumulated result

Required final full candidate workflow:

- **#119** / ID `34323556542`
- exact source `f0fbec0a9b29dcc2df0cf0e9b02ce3a8989c7b52`
- status at checkpoint: **in progress**
- `[full-build]` marker present, so this run owns the final Web + `mobile-beta` + `androidTv-beta` candidate build gate

Per the long-CI rule, do **not** poll #119. On continuation inspect this exact run once.

## Signing / update identity invariant

Production Android signing certificate SHA-256 must remain:

`3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Never regenerate production signing material.

The GitHub candidate workflow intentionally cannot cryptographically verify the private production certificate because the release keystore is not present in CI. Code-side/update safety is verified by unchanged package/signing configuration and the preserved expected certificate invariant. Final production deployment must use the existing Home Lab release keystore and must not use the CI debug-fallback APK as a deployment artefact.

## Last fully verified full-build baseline

Until #119 is green and its artefact evidence is recorded:

- source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- workflow **#115** / `34291216084` — GREEN
- Discovery suite **93 passed, 5 Web-only skipped**
- Chrome suite **12 passed**
- catalogue Python tests **8 passed**
- Web release + Android `mobile-beta` + `androidTv-beta` candidate builds passed
- artifact `10082137559`
- digest `sha256:f2a7fc6b32667d3f4d38cf3a8e4165c2cce46d39facbd6dccb029687365e2abc`

## Completed foundations — do not redo

- shared semantic/personalisation contract
- truthful source-specific personalisation adapters
- request-cost/caching/paging/dedup/identity safeguards
- guarded stock fallback
- landing + deep See All foundations
- local-vs-Seerr details routing
- TV focus/D-pad foundations
- Web completion at `1ac1499a...` / #115
- Android Slice 1 at `086a41b...` / #116
- Android Slice 2 at `0aeadfb...` + formatter recovery `3cab6c...` / #118
- docs-only workflow trigger hygiene

Unsupported structural/context semantics remain fail-closed.

## Smart-TV / webOS

Do not reconcile Smart-TV during Android mobile/tablet work. Final webOS reconciliation comes after Android TV / Google TV. No physical LG acceptance is claimed yet.

## Stable / rollback state

Live remains deliberately untouched:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Existing recovery refs remain intact. Do not modify live services during GitHub-only completion work.

## Completion order

1. shared semantic/personalisation — COMPLETE
2. Web — COMPLETE
3. Android mobile/tablet — **FINAL FULL CANDIDATE #119 IN PROGRESS**
4. Android TV / Google TV
5. final webOS reconciliation
6. cross-platform parity/recommendation-quality
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance and cutover

## Exact next action

Inspect workflow **#119 (`34323556542`) once**.

### If green

1. record focused-validation evidence and exact final test counts from #119;
2. record full candidate job result;
3. record artifact ID/digest, `BUILD_INFO.txt` and SHA256s for Web, Android mobile and Android TV candidates;
4. confirm candidate Android signing remains `debug-fallback-not-for-deployment` and production signing invariant remains the accepted certificate above;
5. mark Android mobile/tablet **GitHub/code COMPLETE** in both durable checkpoints;
6. proceed next to **Android TV / Google TV completion**, not Smart-TV/webOS yet.

### If red

Inspect only the exact failing job/gate, fix the genuine root cause without weakening coverage or changing signing identity, launch the appropriate replacement full candidate workflow, record its exact source/run, and stop under the long-CI rule.
