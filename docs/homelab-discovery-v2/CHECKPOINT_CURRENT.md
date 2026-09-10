# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this with `docs/AI_PROJECT_STATE.md`. Do not restart completed work or touch live services during GitHub-only completion.

## Current boundary

- Shared semantics/personalisation: COMPLETE
- Web: COMPLETE
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **ACTIVE — final full candidate #128 pending**
- Smart-TV/webOS: do not reconcile until Android TV is complete

## Android TV verified focused state

Remote recovery Slice 1 final gate #124 / `34416882794` GREEN.

Deterministic focus/navigation feature source `2a204646fd296df1f57bd4dc4d7d3d1f969d7e6a` plus paging-error root fix `5e0886a114dc1ee7ba783512e80e648634b915a7` provide:

1. one TV tab-strip focus owner with deterministic tab/content hand-off;
2. remembered lane focus and no inactive-tab autofocus competition;
3. deterministic deep-grid vertical edges;
4. populated deep Refresh and paging-error Retry More remote paths;
5. paging failures stay visible/user-actionable instead of auto-retrying from fresh list wrappers;
6. logical media changes and explicit Refresh still re-arm paging correctly.

Final focused gate **#127 / `34422202215`** on source `5e0886a114dc1ee7ba783512e80e648634b915a7` is GREEN:

- route PASS
- catalogue schemaVersion 2 / **486** total + **8 Python tests PASS**
- format **54 files, 0 changed**
- analyse **no issues**
- Discovery **106 passed, 5 skipped**
- Chrome Web/entry-route **12 passed**
- custom-scope gate PASS

## Final closure review

- Detail and See All return paths restore remembered TV lane focus.
- Deep detail return restores grid focus; remote Back delegates once.
- Lane/grid focus restoration uses `Scrollable.ensureVisible`.
- Shared controller tests cover retained ordinary loads, safe retries, refresh/reset and in-flight paging sequencing; no separate TV lifecycle state machine was found.
- Current identity remains app `2.5.1+30000149`, TV `2.5.1` build `2000016`, production app ID `org.moonfin.androidtv`, beta `.beta`, TV force define `MOONFIN_FORCE_TV=true`.
- Production signing certificate invariant: SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`. Never regenerate it. CI APKs remain debug fallback, not deployment artefacts.

## Final wide-TV/full-build candidate

Source:

`15ccc28b84727543ad714ef19dd318f907d1a1d8`

`test(discovery-v2): validate wide TV focus scrolling [full-build]`

Verified exact diff from `5637c30efdbed55d1f597c119e0cdac4b86c892e`: one test file only, `discovery_tv_grid_test.dart`, +42/-2.

New regression covers real grid D-pad focus/scroll at representative **1920x1080** and **3840x2160** test viewports, including expected 10/12-column layouts and focused-card visibility after moving into initially off-screen rows.

### Current required gate

- **#128 / `34429841034`**
- exact source **`15ccc28b84727543ad714ef19dd318f907d1a1d8`**
- `[full-build]` requested
- status at checkpoint: **in progress**
- if focused validation passes, candidate job builds Web + `mobile-beta` + `androidTv-beta`

Do not poll #128. Inspect it exactly once on continuation.

## Do not redo

Shared semantics/personalisation, catalogue/compiler, request-cost/paging/cache/dedup/identity safeguards, verified Web, verified Android mobile/tablet, TV Slice 1 recovery, deterministic focus Slice 2, paging-retry fix, docs-only CI hygiene, or separately advanced Smart-TV work.

## Exact next action

Inspect #128 (`34429841034`) once. If green, capture focused/full-build evidence plus artifact ID/digest and candidate hashes, mark Android TV / Google TV GitHub/code complete, then move to final Smart-TV/webOS reconciliation. If red, inspect only the failing gate/job, fix it and launch one replacement full candidate.
