# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-09 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file and `docs/AI_PROJECT_STATE.md` first. Use `GITHUB_COMPLETION_PLAN.md` for implementation order and `docs/UPSTREAM_UPDATE_PROTOCOL.md` for official Moonfin updates.

Do not restart completed work or modify the live server during GitHub-only completion work.

## Current boundary

Shared personalisation and Web are verified complete. Android mobile/tablet is intentionally split into three slices to reduce timeout risk.

- Slice 1 — adaptive/touch baseline: **VERIFIED**
- Slice 2 — mobile UX/state robustness: **IMPLEMENTED; #117 VALIDATION IN PROGRESS**
- Slice 3 — final Android validation: **NEXT after #117 green**

Current source-changing commit:

- `0aeadfb6ef948502c5e64bface0374fe2ed66ceb`
- `feat(discovery-v2): retain Android Discovery state safely`

Current focused workflow:

- **#117** / ID `34322168040`
- exact source `0aeadfb6ef948502c5e64bface0374fe2ed66ceb`
- status at checkpoint: **in progress**
- full candidate build not requested in this slice

Do not poll it. Inspect #117 once on continuation.

## Android Slice 1 — VERIFIED

Implementation source `086a41b0092f388d82c98ca2803e37b89dc6e46d`.

Workflow **#116** / `34320947110` passed focused validation:

- route integration: PASS
- 486-lane catalogue/compiler: PASS
- catalogue Python tests: **8 passed**
- format: **53 files, 0 changed**
- Flutter analyse: **no issues**
- Discovery suite: **96 passed, 5 Web-only skipped**
- Chrome Web/route suite: **12 passed**
- narrow-scope gate: PASS
- full candidate job skipped as intended

Verified Slice 1 behaviour:

- compact/medium/expanded classes: `<600`, `600–839`, `>=840` px
- lane-card widths: `124`, `140`, `148` px
- wide Web sizing preserved
- non-Web Discovery tabs explicitly retain a 48 px minimum touch height
- mobile regressions cover breakpoint/grid density, tab tap/target size and card fallback/touch activation

## Android Slice 2 — IMPLEMENTED, VALIDATION PENDING

Source `0aeadfb6ef948502c5e64bface0374fe2ed66ceb` changes exactly four files:

- `lib/features/homelab_discovery/engine/discovery_tab_controller.dart`
- `lib/features/homelab_discovery/engine/discovery_see_all_controller.dart`
- `test/homelab_discovery/discovery_tab_controller_test.dart`
- `test/homelab_discovery/discovery_see_all_controller_test.dart`

### Retained landing/tab state

`HomeLabDiscoveryTabController` now:

- coalesces concurrent ordinary `load()` calls
- retains the last successful tab result across widget reconstruction/orientation/lifecycle resume
- avoids duplicate lane/API I/O and accidental novelty/rotation mutation on ordinary rebuilds
- does not cache failed results, preserving genuine Retry behaviour without rotation
- clears retained state and rotates only on explicit Refresh
- waits for active work and clears retained state on session reset

New regressions prove retained/coalesced successful loading and failure-not-cached retry behaviour.

### Deep refresh/paging sequencing

`HomeLabDiscoverySeeAllController` now:

- owns one active deep advance operation
- joins duplicate near-end paging requests
- waits for active paging before destructive pull-to-refresh reset/reload
- prevents an old page response from repopulating a newly refreshed collection
- defers synchronous reset until an active operation settles

New regression explicitly starts page 2, requests Refresh while it is pending, proves refresh page 1 waits, then proves final refreshed state contains only the refreshed page data.

### Reviewed and retained as already-correct

No Android-specific rewrite was justified for:

- Android Back: non-Web See All already uses `Navigator.push(MaterialPageRoute)` and system Back naturally pops to the retained landing route
- lifecycle shell: `NavigationLayout` already observes resume without forcing a Discovery reload
- loading/failure/empty paths: existing landing/deep UI already supplies progress, Retry and Refresh/pull-to-refresh actions on touch surfaces
- local/external item routing and malformed local pointer: shared path already verified

## Slice 3 — final Android validation

After #117 is green:

1. mark Slice 2 verified;
2. run a final mobile/tablet defect review only for remaining code-testable gaps;
3. verify auth/local-state/update-safety behaviour that is practical in GitHub/CI;
4. preserve production Android signing cert SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604` — never regenerate it;
5. trigger the required full candidate workflow;
6. record exact mobile build/artifact/signing evidence;
7. close Android mobile/tablet in both durable checkpoints.

Physical-device acceptance remains deferred.

## Last fully green full-build baseline

Until Slice 3 supersedes it:

- source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- workflow **#115** / `34291216084` — GREEN
- Discovery suite: **93 passed, 5 Web-only skipped**
- Chrome suite: **12 passed**
- catalogue Python tests: **8 passed**
- Web + `mobile-beta` + `androidTv-beta` candidate builds passed
- artifact `10082137559`
- digest `sha256:f2a7fc6b32667d3f4d38cf3a8e4165c2cce46d39facbd6dccb029687365e2abc`

## Completed work that must not be redone

- shared semantic/personalisation contract
- 486-lane catalogue/compiler validation
- guarded stock fallback
- request-cost/paging/cache/dedup/identity safeguards
- landing + deep See All foundations
- local-vs-Seerr details routing
- TV focus/D-pad foundations
- Web completion at `1ac1499a...` / #115
- Android Slice 1 at `086a41b...` / #116
- advanced Smart-TV implementation at its separate checkpoint

Unsupported structural/context semantics remain fail-closed.

## Exact next action

Inspect **#117 (`34322168040`) once**.

### If green

1. mark Slice 2 verified;
2. begin **Slice 3 — final Android validation**;
3. do not redo shared/Web/Slice-1 work;
4. keep physical-device testing deferred.

### If red

1. inspect only the exact failing gate/test;
2. fix the root cause without weakening retained-state/paging coverage;
3. trigger the appropriate focused workflow;
4. record exact source/run here and in `docs/AI_PROJECT_STATE.md`;
5. stop under the long-CI rule.
