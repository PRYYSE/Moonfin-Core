# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-09 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file and `docs/AI_PROJECT_STATE.md` first. Use `GITHUB_COMPLETION_PLAN.md` for implementation order and `docs/UPSTREAM_UPDATE_PROTOCOL.md` for official Moonfin updates.

Do not restart completed work or modify the live server during GitHub-only completion work.

## Current boundary

Shared personalisation and Web are verified complete. Android mobile/tablet is at its final GitHub/CI gate.

- Slice 1 — adaptive/touch baseline: **VERIFIED**
- Slice 2 — mobile UX/state robustness: **VERIFIED**
- Slice 3 — final Android validation: **FULL CANDIDATE #119 IN PROGRESS**

## Slice 1 — VERIFIED

Source `086a41b0092f388d82c98ca2803e37b89dc6e46d`.

Workflow **#116** / `34320947110` passed:

- route integration
- 486-lane catalogue/compiler + 8 Python tests
- Dart format
- Flutter analyse
- Discovery suite **96 passed, 5 Web-only skipped**
- Chrome Web/route suite **12 passed**
- narrow custom-scope gate

Verified mobile baseline:

- compact/medium/expanded breakpoints `<600`, `600–839`, `>=840` px
- lane card widths `124 / 140 / 148` px
- wide Web behaviour preserved
- non-Web tabs retain 48 px minimum touch height
- native regressions cover phone/tablet density, tab tapping and card fallback/touch activation

## Slice 2 — VERIFIED

Functional source `0aeadfb6ef948502c5e64bface0374fe2ed66ceb` implemented:

- retained successful tab state across ordinary reconstruction/orientation/resume
- coalesced concurrent normal tab loads
- failed results remain retryable without forced rotation
- explicit Refresh clears retained state and rotates
- session reset waits for active work then clears state/history
- deep See All owns one active advance
- duplicate paging joins the active operation
- pull-to-refresh waits for active paging before destructive reset/reload
- synchronous reset during active paging is deferred until completion

Workflow **#117** / `34322168040` failed only Dart formatting in one regression test.

Formatter-only recovery:

- `3cab6c5430eb6175320c4f16c4932218b41d42b8`
- exactly one test file reformatted; no runtime logic changed

Workflow **#118** / `34322882024` — **GREEN**:

- route integration PASS
- authoring catalogue PASS
- format PASS
- analyse PASS
- focused Discovery tests PASS
- Chrome Web/route tests PASS
- custom-scope PASS
- candidate build skipped as intended

Slice 2 is therefore verified complete.

## Slice 3 — final Android mobile/tablet validation

Final review found no remaining code-testable Android mobile/tablet defect requiring product changes.

Safety review:

- delta from pre-mobile source `9491b145de7b3ea64dc6e31c4863e9c7c60520f6` is confined to Discovery UI/controllers/tests and docs
- no Android Gradle, manifest, package, auth, secure-storage or signing files changed
- production mobile application ID remains `org.moonfin.androidtv`
- beta application ID remains `org.moonfin.androidtv.beta`
- release build continues to use the existing release keystore when available
- CI debug signing remains a deliberate candidate-only fallback and is not a deployable production identity
- production certificate SHA-256 invariant remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate it

Final UI/routing review retained existing correct behaviour for:

- loading / failure / genuine-empty states
- touch pull-to-refresh
- automatic deep paging + visible loading/error/end states
- title/artwork fallback
- local Jellyfin vs external Seerr routing and malformed local pointer handling
- Android system Back through native `Navigator.push(MaterialPageRoute)` See All paths

One final regression was added because duplicate near-end paging coalescing was implemented but lacked its own exact test:

- final source `f0fbec0a9b29dcc2df0cf0e9b02ce3a8989c7b52`
- `[full-build] test(discovery-v2): close Android mobile paging gate`
- exact diff: `test/homelab_discovery/discovery_see_all_controller_test.dart` only
- test proves two overlapping `loadMore()` calls issue only one page-2 request and both receive the same accumulated result

Required final full candidate workflow:

- **#119** / ID `34323556542`
- exact source `f0fbec0a9b29dcc2df0cf0e9b02ce3a8989c7b52`
- status at checkpoint: **in progress**
- `[full-build]` marker ensures the full Web + `mobile-beta` + `androidTv-beta` candidate job is enabled after focused validation

Do not poll #119. Inspect it once on continuation.

## Production signing invariant

Accepted production Android certificate SHA-256:

`3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Never regenerate or replace it.

CI does not contain the private release keystore, so its APKs are intentionally `debug-fallback-not-for-deployment`. A green candidate proves build/update compatibility of the code and package configuration, not the private production certificate itself. Production deployment must continue using the existing Home Lab release keystore.

## Last fully green full-build baseline

Until #119 is green and artefact evidence is recorded:

- source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- workflow **#115** / `34291216084` — GREEN
- Discovery suite **93 passed, 5 Web-only skipped**
- Chrome suite **12 passed**
- catalogue Python tests **8 passed**
- Web + `mobile-beta` + `androidTv-beta` candidate builds passed
- artifact `10082137559`
- digest `sha256:f2a7fc6b32667d3f4d38cf3a8e4165c2cce46d39facbd6dccb029687365e2abc`

## Do not redo

- shared semantics/personalisation
- 486-lane catalogue/compiler
- request-cost/paging/cache/dedup/identity safeguards
- guarded fallback
- landing + deep See All foundations
- local-vs-Seerr details routing
- TV focus/D-pad foundations
- verified Web completion
- verified Android Slice 1
- verified Android Slice 2
- separately advanced Smart-TV work

Unsupported structural/context semantics remain fail-closed.

## Exact next action

Inspect **#119 (`34323556542`) once**.

### If green

- capture focused-validation test counts and gate results;
- capture full candidate result;
- capture artifact ID/digest, `BUILD_INFO.txt` and SHA256s;
- record Android mobile candidate evidence and signing mode;
- mark Android mobile/tablet **GitHub/code COMPLETE**;
- proceed to **Android TV / Google TV completion**.

### If red

Inspect only the exact failure, fix its root cause without weakening coverage or changing signing/update identity, trigger a replacement full candidate run, record exact source/run, and stop under the long-CI rule.

Physical phone/tablet acceptance remains deferred.
