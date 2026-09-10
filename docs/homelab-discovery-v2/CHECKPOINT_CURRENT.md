# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file with `docs/AI_PROJECT_STATE.md`. Do not restart completed work or touch live services during GitHub-only completion.

## Current boundary

- Shared semantics/personalisation: COMPLETE
- Web: COMPLETE
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **ACTIVE — Slice 2 replacement focused workflow #127 pending**
- Smart-TV/webOS: do not reconcile until Android TV is complete

## Verified foundations

Android mobile/tablet final source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`; workflow #120 / `34326151119` GREEN.

TV remote recovery Slice 1 final gate #124 / `34416882794` GREEN with route, 486-lane catalogue/compiler + 8 Python tests, format, analyse, Discovery **103 passed / 5 skipped**, Chrome **12 passed**, scope gate PASS.

Production signing invariant remains SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate it. CI candidates are debug fallback and not deployment artefacts.

## Android TV / Google TV — Slice 2

Primary deterministic focus source `2a204646fd296df1f57bd4dc4d7d3d1f969d7e6a`; formatter-only follow-up `a37ed60b9a996f4e292fe75e747fe1d95dcf16f4`.

Implemented:

1. TV tab strip owns one focus node; left/right switches tabs while retaining focus, Down/Select enters content, first-lane Up returns to tabs.
2. Landing remembers the last focused lane and prevents inactive tab pages competing for autofocus.
3. Deep TV grid exposes deterministic Up/Down edge delegation.
4. Populated deep browse exposes remote Refresh and restores grid focus.
5. Paging-error Retry More is reachable from final-row Down and returns focus to the grid.

### Validation sequence

#125 / `34417981160`: route/catalogue passed; failed only Dart format.

#126 / `34418234678`, source `a37ed60b9a996f4e292fe75e747fe1d95dcf16f4`:

- route PASS
- 486-lane catalogue/compiler + 8 Python tests PASS
- format: 54 files, 0 changed
- analyse: no issues
- Discovery **105 passed, 1 failed, 5 skipped**
- sole failure: `TV paging error reaches Retry More and restores grid focus`

The failure exposed a real paging-latch defect: unchanged controller items arrive in fresh list wrappers, and list identity incorrectly re-armed near-end paging. A failed page-2 request could therefore be auto-retried immediately, clearing the error before Retry More stayed visible.

### Root-cause fix — PUBLISHED

Source:

`5e0886a114dc1ee7ba783512e80e648634b915a7`

`fix(discovery-v2): keep TV paging errors user-actionable`

Verified source diff from parent `c8ce1001a9907824621863d569e886aa24e0101e`: exactly two TV product files:

- `discovery_tv_grid.dart`: +19/-2
- `homelab_discovery_see_all_screen.dart`: +5/-3

Fix semantics:

- same ordered logical media (`mediaType` + `id`) does not re-arm paging because only the list wrapper changed
- actual logical media changes still re-arm paging
- explicit user Refresh deliberately resets the latch
- Retry More/detail-return focus restoration does not reset it
- no controller/catalogue, package/version/signing, Smart-TV or live changes

### Current focused gate

- **#127 / `34422202215`**
- exact source **`5e0886a114dc1ee7ba783512e80e648634b915a7`**
- status at checkpoint: **in progress**
- no full candidate requested

Do not poll #127. Inspect it exactly once on continuation.

## Remaining TV completion after #127 green

1. record #127 evidence and close the paging-retry defect;
2. confirm Back/detail return and re-entry coverage;
3. validate off-screen focus/scroll at representative 1080p and 4K widths;
4. confirm lifecycle/resume/retained-state inheritance;
5. re-check TV package/version/signing/update identity unchanged;
6. run final targeted checks and required `[full-build]` candidate;
7. then mark Android TV / Google TV GitHub/code complete.

Physical TV acceptance remains deferred.

## Exact next action

Inspect #127 (`34422202215`) exactly once. If green, continue directly into the remaining TV closure review and final full-candidate preparation. If red, inspect only the failing gate, fix the root cause, launch one replacement focused run and checkpoint it.