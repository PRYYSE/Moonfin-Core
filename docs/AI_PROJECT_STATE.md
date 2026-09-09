# AI Project State

**Updated:** 2026-09-09 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

**Current phase:** Android mobile/tablet completion pass — Slice 1 verified; Slice 2 implementation complete with formatter-only validation recovery in progress; Slice 3 must not begin until that focused run is green.

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

Durable implementation order: `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`  
Mandatory update procedure: `docs/UPSTREAM_UPDATE_PROTOCOL.md`

## Android mobile/tablet — current validation boundary

### Slice 1 — VERIFIED

- source `086a41b0092f388d82c98ca2803e37b89dc6e46d`
- workflow **#116** / `34320947110` — GREEN
- route/catalogue/format/analyse/scope gates passed
- Discovery suite: **96 passed, 5 Web-only skipped**
- Chrome Web/route suite: **12 passed**
- adaptive phone/tablet breakpoints, card density, 48 px mobile tab target and native touch regressions verified

### Slice 2 — IMPLEMENTED; FORMATTER RECOVERY PENDING

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

Exact functional Slice 2 diff remains limited to the two controllers and their two regression-test files.

Workflow **#117** / `34322168040` on `0aeadfb6...` failed **only** the Dart formatter gate. Route and 486-lane catalogue gates passed; analyse/tests/build were skipped after the formatter failure. CI showed exactly one formatting-only change in `test/homelab_discovery/discovery_tab_controller_test.dart`.

Formatter-only recovery commit:

- `3cab6c5430eb6175320c4f16c4932218b41d42b8`
- `style(discovery-v2): format Android state regression test`
- diff: exactly one test file; no runtime/product logic changed

Current focused workflow:

- **#118** / ID `34322882024`
- exact source `3cab6c5430eb6175320c4f16c4932218b41d42b8`
- status at checkpoint: **in progress**
- no `[full-build]`; candidate build is not part of this recovery

Per the long-CI rule, do not poll #118. On continuation inspect this exact run once.

### Slice 3 — NEXT ONLY AFTER #118 GREEN

Then perform one final Android mobile/tablet code/CI pass:

- final defect review limited to remaining mobile/tablet code-testable gaps
- auth/local-state/update-safety checks practical in GitHub/CI
- verify package/update identity and signing safeguards
- never regenerate production signing
- run required full candidate workflow from the exact final source
- record exact mobile APK/artifact/build/signing evidence
- close Android mobile/tablet in durable checkpoints
- stop before Android TV / Google TV

Physical phone/tablet acceptance remains deferred.

## Signing / update identity invariant

Production Android signing certificate SHA-256 must remain:

`3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Never regenerate production signing material. CI candidate signing may remain debug fallback until the final Android release/signing gate explicitly verifies production identity.

## Last fully verified full-build baseline

Until Slice 3 supersedes it:

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
3. Android mobile/tablet — Slice 1 VERIFIED; Slice 2 awaiting #118; Slice 3 NEXT
4. Android TV / Google TV
5. final webOS reconciliation
6. cross-platform parity/recommendation-quality
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance and cutover

## Exact next action

Inspect workflow **#118 (`34322882024`) once**.

- If green: mark Slice 2 verified and begin Slice 3.
- If red: inspect only the failing gate, fix the root cause without weakening retained-state/paging coverage, trigger the appropriate focused workflow, record the exact source/run, and stop under the long-CI rule.
