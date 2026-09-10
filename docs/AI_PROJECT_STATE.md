# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

**Current phase:** Android TV / Google TV final candidate validation. Focus/recovery/navigation work is focused-green; required full candidate workflow **#128** is now the only open Android-TV GitHub gate.

## Completed foundations — do not redo

- Shared semantics/personalisation, request-cost, paging, cache, dedup and identity safeguards: COMPLETE.
- 486-lane catalogue/compiler; unsupported structural/context semantics fail closed.
- Web: COMPLETE, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`, workflow #115.
- Android mobile/tablet: GITHUB/CODE COMPLETE, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN. Candidate artifact `10094778627`, digest `sha256:27e01f5d5db575ee8d853e9808bbee7a2595dfa453be9ccd086ea0b3313cb421`.
- Android TV remote-safe empty/failure recovery Slice 1: VERIFIED COMPLETE, final gate #124 / `34416882794` GREEN.

Physical mobile/tablet/TV acceptance remains deferred.

## Android TV / Google TV — focused implementation VERIFIED

Primary deterministic-focus source:

`2a204646fd296df1f57bd4dc4d7d3d1f969d7e6a`

Paging-error root-cause fix:

`5e0886a114dc1ee7ba783512e80e648634b915a7`

Implemented and retained:

- one TV focus owner for the Discovery tab strip
- left/right tab switching while retaining strip focus; Down/Select enters active content
- first-lane Up returns to tabs; remembered-lane re-entry
- inactive TabBar pages do not compete for autofocus
- deterministic deep-grid vertical edges
- populated deep Refresh and paging-error Retry More remote paths
- failed paging remains user-actionable rather than auto-retrying because a controller state supplied a fresh list wrapper
- actual logical media changes still re-arm near-end paging; explicit Refresh deliberately re-arms it

### Final focused evidence — #127 GREEN

Workflow **#127 / `34422202215`**, exact source `5e0886a114dc1ee7ba783512e80e648634b915a7`, focused job `102699868587`:

- route integration PASS
- authoring catalogue schemaVersion 2 / total **486**; tab counts unchanged
- catalogue Python tests: **8 passed**
- format: **54 files, 0 changed**
- analyse: **no issues**
- Discovery suite: **106 passed, 5 skipped**
- Chrome Web/entry-route: **12 passed**
- custom-scope gate PASS
- full-build job skipped as expected for this focused run

The previously failing paging-error Retry More regression is green in #127.

## Final TV closure review

No further TV production defect was found before the final candidate:

- Landing detail and See All routes await return and then restore the originating lane focus from memory.
- Deep browse detail return restores the grid focus; remote Back is delegated once to the owning route and has focused coverage.
- Both TV lanes and the deep grid use `Scrollable.ensureVisible` when restoring/moving focus.
- Shared controller coverage already proves ordinary rebuilds retain one successful tab load, failed loads retry safely, refresh/reset sequencing is bounded, and deep refresh waits for in-flight paging; there is no separate TV lifecycle state machine that would invalidate this inheritance.
- Package/update identity remains unchanged: app `2.5.1+30000149`, Android TV `2.5.1`, TV build `2000016`, production app ID `org.moonfin.androidtv`, beta `.beta`, forced TV uses `MOONFIN_FORCE_TV=true`.
- Production signing certificate invariant remains SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate or replace it. CI candidates remain `debug-fallback-not-for-deployment`.

### Wide-TV regression / final candidate source

Source:

`15ccc28b84727543ad714ef19dd318f907d1a1d8`

`test(discovery-v2): validate wide TV focus scrolling [full-build]`

Verified exact diff from prior checkpoint `5637c30efdbed55d1f597c119e0cdac4b86c892e`: **one test file only**, `test/homelab_discovery/discovery_tv_grid_test.dart`, +42/-2.

The new regression runs the real TV grid at representative **1920x1080** and **3840x2160** logical test viewports, drives D-pad focus into initially off-screen rows, verifies expected 10/12-column layouts, and asserts the focused card is scrolled into the viewport.

## Current required full candidate gate

- workflow **#128 / `34429841034`**
- exact source **`15ccc28b84727543ad714ef19dd318f907d1a1d8`**
- triggered by `[full-build]`
- status at checkpoint: **in progress**
- required candidate job builds Web + `mobile-beta` + `androidTv-beta`; Android TV uses `MOONFIN_FORCE_TV=true`
- candidate APK signing is CI debug fallback and must not be described as production-signed

Per the long-CI rule, do **not** poll #128. Inspect this exact run once on continuation.

## Smart-TV / webOS and live

Do not inspect or modify Smart-TV/webOS until Android TV / Google TV is declared GitHub/code complete. Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Existing archive/recovery refs remain intact.

## Completion order

1. shared semantics/personalisation — COMPLETE
2. Web — COMPLETE
3. Android mobile/tablet — COMPLETE
4. Android TV / Google TV — **ACTIVE; final full candidate #128 pending**
5. final webOS reconciliation
6. cross-platform parity/recommendation quality
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance

## Exact next action

Inspect workflow #128 (`34429841034`) exactly once. If green, extract focused + full-build evidence, artifact ID/digest and candidate SHA-256 values, mark Android TV / Google TV GitHub/code complete in both checkpoints, then continue into final Smart-TV/webOS reconciliation. If red, inspect only the failing gate/job, fix the root cause, launch one replacement full candidate, checkpoint exact source/run and stop under the long-CI rule.
