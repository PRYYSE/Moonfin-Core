# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

**Current phase:** Android TV / Google TV completion — deterministic focus/navigation Slice 2 remains under focused validation. Workflow #126 exposed one real TV paging-retry defect after 105 tests passed; the root-cause fix has been rebased cleanly as source `be69146480f9c9c334d1f2d948ccdbbde702037f` and is ready for branch publication.

## Completed platform foundations — do not redo

- shared semantics/personalisation, request-cost, paging, cache, dedup and identity safeguards
- 486-lane catalogue/compiler; unsupported structural/context semantics fail closed
- local Jellyfin vs Seerr details routing
- Web completion: source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`, workflow #115
- Android mobile/tablet completion: source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN
- docs-only CI trigger hygiene

#120 final mobile evidence: route + catalogue/compiler + 8 Python tests PASS; format/analyse PASS; Discovery 100 passed / 5 skipped; Chrome 12 passed; Web + `mobile-beta` + `androidTv-beta` candidate packaging PASS; artifact `10094778627`, digest `sha256:27e01f5d5db575ee8d853e9808bbee7a2595dfa453be9ccd086ea0b3313cb421`.

Physical mobile/tablet acceptance remains deferred.

## Android TV / Google TV — ACTIVE

### Identity / update invariants

- production app ID `org.moonfin.androidtv`; beta `.beta`
- TV version `2.5.1`, build `2000016`
- forced-TV build uses `MOONFIN_FORCE_TV=true`
- production signing certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- never regenerate production signing material
- CI APKs are `debug-fallback-not-for-deployment`

### TV Slice 1 — VERIFIED COMPLETE

Product source `9788338cb27a86cb4024ee8dbe57b82bfcf68f21` added remote-safe failure/empty recovery. Final recovery validation #124 / `34416882794` was GREEN with route, 486-lane catalogue + 8 Python tests, format, analyse, Discovery **103 passed / 5 skipped**, Chrome **12 passed**, scope gate PASS.

### TV Slice 2 — deterministic focus/navigation implemented

Primary feature source:

`2a204646fd296df1f57bd4dc4d7d3d1f969d7e6a`

Formatter-only follow-up:

`a37ed60b9a996f4e292fe75e747fe1d95dcf16f4`

Implemented:

- single TV focus owner for the Discovery tab strip
- left/right tab changes retain strip focus; Down/Select enters active content
- first-lane Up returns to tab strip; remembered lane re-entry is deterministic
- inactive TabBar pages no longer compete for autofocus
- TV deep grid exposes vertical edge callbacks
- populated deep browse exposes remote Refresh
- paging-error Retry More is reachable from final-row Down
- focused regressions cover these paths

### #125 / #126 validation sequence

#125 / `34417981160` failed only the Dart format gate; route and catalogue passed. Formatter-only source `a37ed60b...` corrected exactly one `ValueKey` formatting expression.

#126 / `34418234678`, exact source `a37ed60b...`:

- route PASS
- 486-lane catalogue/compiler PASS
- catalogue Python tests: 8 passed
- format: 54 files, 0 changed
- analyse: no issues
- focused Discovery suite: **105 passed, 1 failed, 5 skipped**
- sole failure: `TV paging error reaches Retry More and restores grid focus`

Root cause is a real product issue in `HomeLabDiscoveryTvGrid`: every rebuilt controller state wraps unchanged media items in a fresh list object; `didUpdateWidget` used list identity to re-arm the near-end latch, so the first page-2 failure could immediately auto-trigger another `loadMore`, clearing the error before the Retry More button remained user-actionable.

### Root-cause fix ready to publish

Final rebased source:

`be69146480f9c9c334d1f2d948ccdbbde702037f`

`fix(discovery-v2): keep TV paging errors user-actionable`

Exact source diff remains two TV product files only:

- `discovery_tv_grid.dart`: logical item identity now controls near-end latch re-arming; requestFocusFromMemory can explicitly reset the latch for a user Refresh
- `homelab_discovery_see_all_screen.dart`: explicit Refresh requests that reset; Retry More/detail return do not

Fix semantics:

- unchanged ordered logical media (`mediaType` + `id`) does not re-arm near-end paging merely because the list wrapper changed
- explicit user Refresh can deliberately reset the near-end latch, even if refreshed page 1 contains the same media
- Retry More/detail-return focus restoration does not implicitly re-arm paging

No catalogue/controller, package/version/signing, Smart-TV or live changes.

## Remaining TV completion after replacement focused validation green

1. confirm Back/detail return and re-entry coverage with the new focus bridge;
2. validate off-screen focus/scroll at representative 1080p and 4K widths;
3. confirm lifecycle/resume/retained-state behaviour inherited from shared controllers;
4. re-check TV package/version/signing/update identity unchanged;
5. run final targeted TV coverage and required `[full-build]` candidate green;
6. only then mark Android TV / Google TV GitHub/code complete.

Physical TV acceptance remains deferred.

## Smart-TV / webOS and live

Do not inspect or modify Smart-TV/webOS until Android TV / Google TV is complete. Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Existing recovery refs remain intact.

## Completion order

1. shared semantics/personalisation — COMPLETE
2. Web — COMPLETE
3. Android mobile/tablet — COMPLETE
4. Android TV / Google TV — **ACTIVE; Slice 2 paging-retry fix ready to publish**
5. final webOS reconciliation
6. cross-platform parity/recommendation quality
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance

## Exact next action

Publish source `be69146480f9c9c334d1f2d948ccdbbde702037f` to `homelab/discovery-v2`, capture its replacement workflow run ID/source, update both durable checkpoints with that exact run, then stop under the long-CI rule. On the following continuation, inspect that exact run once; if green, proceed directly into the remaining TV closure review and final full candidate.