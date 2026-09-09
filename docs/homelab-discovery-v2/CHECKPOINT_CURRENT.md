# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-09 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file and `docs/AI_PROJECT_STATE.md` first. Use `GITHUB_COMPLETION_PLAN.md` for implementation order and `docs/UPSTREAM_UPDATE_PROTOCOL.md` for official Moonfin updates.

Do not restart completed work or modify the live server during GitHub-only completion work.

## Current boundary

Shared personalisation and Web are verified complete. Android mobile/tablet is split into three slices.

- Slice 1 — adaptive/touch baseline: **VERIFIED**
- Slice 2 — mobile UX/state robustness: **IMPLEMENTED; FORMATTER-ONLY RECOVERY #118 IN PROGRESS**
- Slice 3 — final Android validation: **NEXT only after #118 green**

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

## Slice 2 — implementation complete

Functional source:

`0aeadfb6ef948502c5e64bface0374fe2ed66ceb`

Implemented:

- tab controller retains last successful data across ordinary reconstruction/orientation/resume
- concurrent normal tab loads share one in-flight request
- failed results are not cached; Retry reloads without rotating
- explicit Refresh clears retained state and rotates
- session reset waits for active work then clears retained state/history
- deep See All owns one active advance; duplicate paging joins it
- pull-to-refresh waits for active paging before resetting/reloading
- synchronous reset during active paging is deferred until completion

Existing Android Back/lifecycle/loading/error/empty paths were reviewed and retained where already correct; no unnecessary product rewrite was made.

## #117 result and recovery

Workflow **#117** / `34322168040` on functional source `0aeadfb6...` failed **only** the Dart formatter gate.

- route integration: PASS
- 486-lane catalogue/compiler: PASS
- formatter: one test file needed reformatting
- analyse/tests/build: skipped after formatter failure

CI's formatter diff changed only wrapping/indentation in:

`test/homelab_discovery/discovery_tab_controller_test.dart`

Formatter-only recovery commit:

- `3cab6c5430eb6175320c4f16c4932218b41d42b8`
- `style(discovery-v2): format Android state regression test`
- exactly one test file changed
- no runtime/product logic changed

Current focused workflow:

- **#118** / `34322882024`
- exact source `3cab6c5430eb6175320c4f16c4932218b41d42b8`
- status at checkpoint: **in progress**
- full candidate build not requested

Do not poll #118. Inspect it once on continuation.

## Slice 3 — final Android mobile/tablet validation

Only after #118 is green:

1. mark Slice 2 verified;
2. do one final mobile/tablet code defect review;
3. verify auth/local-state/update-safe app identity practical in GitHub/CI;
4. preserve production signing certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604` — never regenerate it;
5. trigger the required `[full-build]` candidate workflow from the exact final source;
6. record exact Android mobile APK/artifact/build/signing evidence;
7. close Android mobile/tablet in both checkpoints;
8. stop before Android TV / Google TV.

Physical phone/tablet acceptance remains deferred.

## Last fully green full-build baseline

Until Slice 3 supersedes it:

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
- separately advanced Smart-TV work

Unsupported structural/context semantics remain fail-closed.

## Exact next action

Inspect **#118 (`34322882024`) once**.

### If green

Mark Slice 2 verified and begin Slice 3 without revisiting shared/Web/Slice-1 work.

### If red

Inspect only the failing gate, fix its root cause without weakening Slice-2 coverage, launch the appropriate focused workflow, record exact source/run, and stop under the long-CI rule.
