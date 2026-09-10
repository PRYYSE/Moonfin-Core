# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file with `docs/AI_PROJECT_STATE.md`. Do not restart completed work or touch live services during GitHub-only completion.

## Current boundary

- Shared semantics/personalisation: COMPLETE
- Web: COMPLETE
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **ACTIVE — deterministic focus/navigation Slice 2 paging-retry fix ready for publication**
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

#126 / `34418234678`, source `a37ed60b...`:

- route PASS
- 486-lane catalogue/compiler + 8 Python tests PASS
- format: 54 files, 0 changed
- analyse: no issues
- Discovery **105 passed, 1 failed, 5 skipped**
- sole failure: `TV paging error reaches Retry More and restores grid focus`

### Root cause / final rebased fix

The failure is a real TV paging-state defect. Rebuilt controller states wrap unchanged media in fresh list objects; the grid used list identity to reset its near-end latch, so a failed page-2 request could immediately auto-trigger another load-more request and clear the error before Retry More remained visible.

Final rebased source ready for branch publication:

`20a6e609abca82f4eefc008632d77c9afd4632df`

`fix(discovery-v2): keep TV paging errors user-actionable`

Fix semantics:

- unchanged ordered logical media (`mediaType` + `id`) does not re-arm near-end paging merely because the list wrapper changed
- explicit user Refresh can deliberately reset the near-end latch, even if refreshed page 1 contains the same media
- Retry More/detail-return focus restoration does not implicitly re-arm paging
- exact source change remains two TV product files only; no controller/catalogue, package/signing, Smart-TV or live changes

## Remaining TV completion after replacement focused validation green

1. confirm Back/detail return and re-entry coverage;
2. validate off-screen focus/scroll at representative 1080p and 4K widths;
3. confirm lifecycle/resume/retained-state behaviour inherited from shared controllers;
4. re-check TV package/version/signing/update identity unchanged;
5. run final targeted TV checks and required `[full-build]` candidate;
6. then mark Android TV / Google TV GitHub/code complete.

Physical TV acceptance remains deferred.

## Exact next action

Publish source `20a6e609abca82f4eefc008632d77c9afd4632df` to `homelab/discovery-v2`, capture its single replacement workflow run, then update both durable checkpoints with exact source/run and stop under the long-CI rule. On continuation, inspect that exact run once; if green, proceed directly into the remaining TV closure review and final full candidate.