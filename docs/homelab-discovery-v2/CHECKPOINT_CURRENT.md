# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file with `docs/AI_PROJECT_STATE.md`. Do not restart completed work or touch live services during GitHub-only completion.

## Current boundary

- Shared semantics/personalisation: COMPLETE
- Web: COMPLETE
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **ACTIVE — deterministic focus/navigation Slice 2 workflow #125 pending**
- Smart-TV/webOS: do not reconcile until Android TV is complete

## Android mobile/tablet closure

Final source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`; workflow #120 / `34326151119` GREEN.

#120 passed route, 486-lane catalogue/compiler + 8 Python tests, format, analyse, 100 Discovery tests with 5 skipped, 12 Chrome interaction tests, custom-scope validation, and full Web + `mobile-beta` + `androidTv-beta` candidate packaging.

Artifact `10094778627`; digest `sha256:27e01f5d5db575ee8d853e9808bbee7a2595dfa453be9ccd086ea0b3313cb421`.

Production signing invariant remains SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate it. CI candidates are debug fallback and not deployment artefacts.

## Android TV / Google TV

### Slice 1 — VERIFIED COMPLETE

Product source `9788338cb27a86cb4024ee8dbe57b82bfcf68f21` fixes the remote-recovery defect family: TV failure/empty actions autofocus, deep genuine-empty exposes explicit Refresh, and deep initial failure exposes focused Retry.

Final recovery validation:

- workflow **#124 / `34416882794`** — GREEN
- exact source `955b5496d8e0d82d90ddb8de69b838737333243a`
- focused job `102683613449`
- route PASS
- 486-lane catalogue/compiler + 8 Python tests PASS
- format: 54 files, 0 changed
- analyse: no issues
- Discovery: **103 passed, 5 skipped**
- Chrome Web/entry-route: **12 passed**
- custom-scope gate PASS
- full-build skipped as intended for this focused gate

Earlier #121–#123 failures were isolated test-harness/wait/assertion-cardinality issues only; production recovery behaviour remained intact.

### Slice 2 — deterministic TV focus/navigation implemented

Source:

`2a204646fd296df1f57bd4dc4d7d3d1f969d7e6a`

`feat(discovery-v2): complete deterministic TV focus paths`

The source commit touches only six intended files: four Discovery TV UI/focus files and two focused test files.

Implemented:

1. TV tab strip has one focus owner; left/right changes tabs without losing strip focus, Down/Select enters active content, and first-lane Up returns explicitly to the tab strip.
2. Landing remembers the last focused lane and re-enters that lane; first lanes no longer independently autofocus, so inactive `TabBarView` pages cannot compete for focus.
3. TV deep grid has explicit Up/Down edge callbacks while preserving normal D-pad movement, partial-row clamping, Select, Back and paging semantics.
4. Populated deep browse exposes remote Refresh; first-row Up reaches it and Refresh restores grid focus.
5. Paging-error Retry More is reachable from final-row Down; Retry More Up returns to the grid and successful retry restores grid focus.
6. Regressions cover tab-strip focus/content entry, grid edge delegation, populated Refresh and paging-error Retry More recovery.

No catalogue/controller, Android package/signing, Smart-TV or live changes.

### Current focused gate

- **#125 / `34417981160`**
- exact source `2a204646fd296df1f57bd4dc4d7d3d1f969d7e6a`
- status at checkpoint: **in progress**
- no full candidate requested

Do not poll #125. Inspect it once on continuation.

## Remaining TV completion gate after #125 green

1. confirm Back/detail return and re-entry coverage with the new focus bridge;
2. validate off-screen focus/scroll at representative 1080p and 4K widths;
3. confirm lifecycle/resume/retained-state behaviour inherited from shared controllers;
4. re-check TV package/version/signing/update identity unchanged;
5. run final targeted TV coverage and required `[full-build]` candidate green;
6. only then mark Android TV / Google TV GitHub/code complete.

Physical TV acceptance remains deferred.

## Do not redo

Shared semantic/personalisation work, catalogue/compiler, request-cost/paging/cache/dedup/identity safeguards, local-vs-Seerr routing, verified Web, verified Android mobile/tablet, existing TV grid/lane primitives, Slice 1 recovery, docs-only CI hygiene, or separately advanced Smart-TV work.

## Exact next action

Inspect #125 (`34417981160`) exactly once. If green, record its evidence and continue the remaining TV review beginning with Back/detail return and 1080p/4K off-screen focus/scroll. If red, inspect only the failing gate, fix the root cause, launch a replacement focused run, record exact source/run and stop under the long-CI rule.
