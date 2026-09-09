# AI Project State

**Updated:** 2026-09-09 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across the Home Lab Moonfin Discovery product before physical-device, live-service or production acceptance.

**Current phase:** Android mobile/tablet completion pass — **Slice 1 verified; Slice 2 implemented and awaiting focused validation**.

Durable implementation order: `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`  
Mandatory official-update procedure: `docs/UPSTREAM_UPDATE_PROTOCOL.md`

## Moonfin-Core current state

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

Current source-changing commit:

- `0aeadfb6ef948502c5e64bface0374fe2ed66ceb`
- `feat(discovery-v2): retain Android Discovery state safely`

Current focused workflow:

- run **#117** / ID `34322168040`
- exact source `0aeadfb6ef948502c5e64bface0374fe2ed66ceb`
- status at checkpoint: **in progress**
- no `[full-build]`; candidate build is not part of this slice

Per the long-CI rule, do not poll #117. On continuation inspect this exact run once.

## Android mobile/tablet pass — 3 slices

### Slice 1 — adaptive/touch baseline — VERIFIED

Implementation source:

- `086a41b0092f388d82c98ca2803e37b89dc6e46d`
- workflow **#116** / ID `34320947110` — GREEN
- focused-validation job `102367214024` — GREEN
- full candidate job skipped as intended

Verified evidence:

- route overlay: PASS
- 486-lane catalogue/compiler: PASS
- catalogue Python tests: **8 passed**
- Dart format: **53 files, 0 changed**
- Flutter analyse: **no issues**
- normal Discovery suite: **96 passed, 5 Web-only skipped**
- Chrome Web/route suite: **12 passed**
- narrow custom-scope gate: PASS

Implemented and verified:

- compact / medium / expanded window classes at `<600`, `600–839`, `>=840` px
- lane-card widths `124 / 140 / 148` px; wide Web behaviour remains unchanged
- non-Web Discovery tabs preserve the Material minimum interactive height (`48` px)
- native/mobile regressions cover breakpoint/grid density, tab touch target + selection, missing-art fallback and exactly-once card touch activation

### Slice 2 — mobile UX/state robustness — IMPLEMENTED, VALIDATION PENDING

Implementation source: `0aeadfb6ef948502c5e64bface0374fe2ed66ceb`.

Root causes fixed:

1. **Tab state/rebuild/resume reloads**
   - `HomeLabDiscoveryTabController` now retains the last successful tab result.
   - ordinary widget reconstruction/orientation/lifecycle resume can reuse retained state without another lane/API load or novelty/rotation mutation.
   - concurrent ordinary loads coalesce onto one in-flight future.
   - failed results are deliberately not cached, so Retry performs a genuine same-selection reload without rotating.
   - explicit Refresh still clears retained state and advances the refresh nonce.
   - session reset waits for active work, clears retained state and then resets novelty history.

2. **Deep-browse refresh/paging race**
   - `HomeLabDiscoverySeeAllController` now owns one active advance operation.
   - duplicate near-end paging joins the active operation rather than requesting the same page again.
   - pull-to-refresh waits for active paging to settle before clearing/reloading page 1, preventing stale page responses from repopulating refreshed state.
   - synchronous reset during active paging is deferred until that operation settles.

Regression coverage added:

- ordinary rebuild/resume shares and retains one successful tab load
- failed tab result is not cached and Retry can heal without rotation
- refresh waits for an in-flight deep page before replacing state, then discards the old accumulated page data
- existing tab ordering/concurrency/rotation/session and See All paging/retry/refresh tests remain intact

Exact Slice 2 diff is limited to:

- `lib/features/homelab_discovery/engine/discovery_tab_controller.dart`
- `lib/features/homelab_discovery/engine/discovery_see_all_controller.dart`
- `test/homelab_discovery/discovery_tab_controller_test.dart`
- `test/homelab_discovery/discovery_see_all_controller_test.dart`

Reviewed during Slice 2; no product-code rewrite was justified:

- non-Web See All already uses `Navigator.push(MaterialPageRoute)` so Android system Back naturally pops to the retained landing route
- `NavigationLayout` already observes lifecycle resume without forcing Discovery data reload
- landing and deep views already distinguish loading, failure and genuine-empty states; Retry/Refresh or pull-to-refresh is available on the appropriate touch paths
- local Jellyfin vs external Seerr routing and malformed local-pointer fallback were already shared and verified in the Web/shared pass

### Slice 3 — final Android validation — NEXT AFTER #117 GREEN

- inspect #117 once and fix only a genuine failing gate if present
- final mobile/tablet defect review
- Android/auth/local-state/update-safety checks that are practical in GitHub/CI
- production signing identity safeguards; never regenerate signing
- required full candidate workflow
- exact Android mobile artifact/build/signing evidence
- durable Android-mobile/tablet COMPLETE checkpoint

Physical phone/tablet acceptance remains deferred.

## Last fully verified product/build baseline

Until Slice 3 produces a new full candidate, the accepted full-build source remains:

- source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- workflow **#115** / ID `34291216084` — GREEN
- normal Discovery suite: **93 passed, 5 Web-only skipped**
- Chrome suite: **12 passed**
- catalogue Python tests: **8 passed**
- Web release + Android `mobile-beta` + Android `androidTv-beta` candidate builds passed
- artifact `10082137559`
- digest `sha256:f2a7fc6b32667d3f4d38cf3a8e4165c2cce46d39facbd6dccb029687365e2abc`

Production Android signing certificate SHA-256 must remain `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate it.

## Completed foundations — do not redo

- shared semantic/personalisation contract
- truthful source-specific personalisation adapters
- bounded request cost, caching, paging, deduplication and identity handling
- guarded stock fallback
- landing + deep `See All` foundations
- details/local-vs-Seerr routing foundations
- TV focus/D-pad foundations
- **Web completion pass verified at `1ac1499a...` / #115**
- **Android Slice 1 verified at `086a41b...` / #116**
- docs-only workflow trigger hygiene

Unsupported structural/context semantics remain fail-closed.

## Smart-TV / webOS

Do not redo Smart-TV during Android work. Final webOS reconciliation comes after Android TV / Google TV. No physical LG acceptance is claimed yet.

## Stable / rollback state

Live remains deliberately untouched:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Existing recovery refs remain intact, including `archive/pre-android-mobile-slice1-2026-09-09`. The redundant `tmp-placeholder-do-not-use` branch also exists but does not affect the working branch or CI. Do not modify live services during GitHub-only completion work.

## Completion order

1. shared semantic/personalisation contract — **COMPLETE**
2. Web completion pass — **COMPLETE**
3. Android mobile/tablet completion pass — **SLICE 1 VERIFIED; SLICE 2 AWAITING #117; SLICE 3 NEXT**
4. Android TV / Google TV completion pass
5. final webOS reconciliation
6. cross-platform parity/recommendation-quality pass
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance and cutover

## Exact next action

Inspect workflow **#117 (`34322168040`) once**.

- If green: record Slice 2 as verified and begin **Slice 3 — final Android validation**. Do not revisit verified shared/Web/Slice-1 work.
- If red: inspect only the failing gate/test, fix the genuine root cause without weakening retained-state/paging coverage, trigger the appropriate focused workflow, checkpoint its exact source/run, and stop under the long-CI rule.
