# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

**Current phase:** Android TV / Google TV completion — deterministic focus/navigation Slice 2 is implemented. Workflow #126 exposed one real TV paging-retry defect; the narrow root-cause fix is now published and replacement focused validation **#127** is in progress.

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

#126 / `34418234678`, exact source `a37ed60b9a996f4e292fe75e747fe1d95dcf16f4`:

- route PASS
- 486-lane catalogue/compiler PASS
- catalogue Python tests: 8 passed
- format: 54 files, 0 changed
- analyse: no issues
- focused Discovery suite: **105 passed, 1 failed, 5 skipped**
- sole failure: `TV paging error reaches Retry More and restores grid focus`
- Web interaction/scope gates were skipped only because focused tests failed

Root cause was a real product issue in `HomeLabDiscoveryTvGrid`: rebuilt controller states wrap unchanged media items in fresh list objects; `didUpdateWidget` used list identity to re-arm the near-end latch. After the first page-2 failure, the focused grid could therefore auto-trigger another `loadMore`, clear the error, and hide Retry More before the user could act.

### Paging-retry root-cause fix — PUBLISHED

Published source:

`5e0886a114dc1ee7ba783512e80e648634b915a7`

`fix(discovery-v2): keep TV paging errors user-actionable`

Parent/source checkpoint: `c8ce1001a9907824621863d569e886aa24e0101e`.

Verified exact diff: one commit, two TV product files only:

- `lib/features/homelab_discovery/ui/discovery_tv_grid.dart`: +19/-2
- `lib/features/homelab_discovery/ui/homelab_discovery_see_all_screen.dart`: +5/-3

Fix semantics:

- unchanged ordered logical media (`mediaType` + `id`) does not re-arm near-end paging merely because the list wrapper changed
- actual logical media changes still re-arm near-end paging
- explicit user Refresh deliberately resets the near-end latch even when refreshed page 1 contains the same media
- Retry More/detail-return focus restoration does not implicitly re-arm paging

No controller/catalogue, Android Gradle/package/version/signing, Smart-TV or live changes.

### Current replacement focused gate

- workflow **#127 / `34422202215`**
- exact source **`5e0886a114dc1ee7ba783512e80e648634b915a7`**
- status at checkpoint: **in progress**
- focused validation only; no `[full-build]`

Per the long-CI rule, do not poll #127. Inspect this exact run once on continuation.

## Remaining TV completion after #127 green

1. record #127 focused evidence and close the paging-retry defect;
2. confirm Back/detail return and re-entry coverage with the new focus bridge;
3. validate off-screen focus/scroll at representative 1080p and 4K widths;
4. confirm lifecycle/resume/retained-state behaviour inherited from shared controllers;
5. re-check TV package/version/signing/update identity unchanged;
6. run final targeted TV coverage and required `[full-build]` candidate green;
7. only then mark Android TV / Google TV GitHub/code complete.

Physical TV acceptance remains deferred.

## Smart-TV / webOS and live

Do not inspect or modify Smart-TV/webOS until Android TV / Google TV is complete. Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Existing recovery refs remain intact.

## Completion order

1. shared semantics/personalisation — COMPLETE
2. Web — COMPLETE
3. Android mobile/tablet — COMPLETE
4. Android TV / Google TV — **ACTIVE; #127 PENDING**
5. final webOS reconciliation
6. cross-platform parity/recommendation quality
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance

## Exact next action

Inspect workflow #127 (`34422202215`) exactly once. If green, extract its focused evidence and continue in the same turn into the remaining Android-TV closure review, beginning with Back/detail return plus representative 1080p/4K off-screen focus/scroll behaviour. If red, inspect only the failing gate, fix the root cause, launch one replacement focused run, checkpoint exact source/run and stop under the long-CI rule.