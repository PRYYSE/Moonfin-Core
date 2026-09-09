# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-09 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file with `docs/AI_PROJECT_STATE.md`. Do not restart completed work or touch live services during GitHub-only completion.

## Current boundary

- Shared semantics/personalisation: **COMPLETE**
- Web: **COMPLETE**
- Android mobile/tablet Slice 1: **VERIFIED**
- Android mobile/tablet Slice 2: **VERIFIED**
- Android mobile/tablet Slice 3: **replacement full-build #120 IN PROGRESS**
- Android TV / Google TV: next only after Android mobile closes
- Smart-TV/webOS: do not reconcile until after Android TV

## Verified Android mobile work

### Slice 1

Source `086a41b0092f388d82c98ca2803e37b89dc6e46d`; workflow #116 / `34320947110` GREEN.

Verified adaptive phone/tablet breakpoints, lane/card density, 48 px non-Web tab target, native tapping and missing-art/title fallback. Discovery suite 96 passed with 5 Web-only skipped; Chrome suite 12 passed.

### Slice 2

Functional source `0aeadfb6ef948502c5e64bface0374fe2ed66ceb`:

- retains successful tab data across normal reconstruction/orientation/resume
- coalesces concurrent normal loads
- keeps failed results retryable without rotation
- preserves explicit refresh/reset semantics
- serialises deep paging/refresh/reset so stale page responses cannot repopulate refreshed state
- duplicate active paging joins the same in-flight operation

#117 failed only formatting; formatter-only recovery `3cab6c5430eb6175320c4f16c4932218b41d42b8`; #118 / `34322882024` GREEN across route/catalogue/format/analyse/focused tests/Chrome/scope.

## Slice 3 — current final gate

Final review found no remaining code-testable Android mobile/tablet product defect.

Update/signing invariants remain intact:

- production mobile app ID `org.moonfin.androidtv`
- beta app ID `org.moonfin.androidtv.beta`
- no Gradle/manifest/auth/secure-storage/signing config changed during the mobile pass
- accepted production signing certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- never regenerate or replace production signing material
- CI APKs are `debug-fallback-not-for-deployment`; production deployment must use the existing release keystore

Final regression source `f0fbec0a9b29dcc2df0cf0e9b02ce3a8989c7b52` added one exact overlapping near-end paging test.

### #119

Workflow #119 / `34323556542` failed only Dart format before tests/full build:

- route PASS
- 486-lane catalogue/compiler PASS
- 8 catalogue Python tests PASS
- one new test reformatted by Dart
- analyse/tests/full candidate skipped

### #120 — CURRENT

Applied CI formatter output exactly; no test logic changed.

- source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`
- commit `[full-build] style(discovery-v2): format final Android paging regression`
- one test file formatting-only diff
- workflow **#120** / `34326151119`
- status at checkpoint: **in progress**
- `[full-build]` present, therefore candidate job will build Web + `mobile-beta` + `androidTv-beta` after focused validation

Do not poll #120. Inspect it once next continuation.

## Last green full-build baseline

Until #120 supersedes it:

- source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- workflow #115 / `34291216084` GREEN
- artifact `10082137559`
- artifact digest `sha256:f2a7fc6b32667d3f4d38cf3a8e4165c2cce46d39facbd6dccb029687365e2abc`

## Do not redo

Shared semantic/personalisation work, catalogue/compiler, request-cost/paging/cache/dedup/identity safeguards, local-vs-Seerr routing, verified Web pass, Android Slices 1/2, existing TV focus/D-pad foundations, docs-only workflow hygiene.

Live remains untouched. Existing recovery refs remain intact.

## Exact next action

Inspect **#120 (`34326151119`) once**.

If green:
- capture exact focused gate/test counts;
- capture full candidate job result;
- capture artifact ID/digest, BUILD_INFO and all SHA256s;
- mark Android mobile/tablet **GitHub/code COMPLETE**;
- begin Android TV / Google TV completion only.

If red: inspect only the failing gate, fix the genuine root cause without weakening coverage or changing update/signing identity, launch a replacement full-build and checkpoint it.
