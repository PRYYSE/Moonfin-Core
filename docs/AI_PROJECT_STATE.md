# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

**Current phase:** Android TV / Google TV completion — TV recovery Slice 1 is verified complete; deterministic focus/navigation Slice 2 is implemented and replacement focused workflow **#126** is pending after #125 failed only the Dart format gate. Android mobile/tablet remains GitHub/code complete.

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

Product source `9788338cb27a86cb4024ee8dbe57b82bfcf68f21` (`feat(discovery-v2): make TV recovery remote-safe`) added remote-safe failure/empty recovery:

- TV landing/runtime/tab failure or genuine-empty actions autofocus
- deep genuine-empty exposes explicit TV Refresh and autofocuses it
- deep initial failure Retry autofocuses
- remote Select regressions cover tab selection, empty Refresh and failure Retry

Test-harness-only recoveries followed for missing isolated app services, non-quiescing TV chrome, and an over-strict duplicate-title-node assertion. No production behaviour was weakened.

Final Slice 1 gate:

- workflow **#124 / `34416882794`** — GREEN
- exact source `955b5496d8e0d82d90ddb8de69b838737333243a`
- focused job `102683613449`
- route PASS
- 486-lane catalogue/compiler PASS
- catalogue Python tests: 8 passed
- format: 54 files, 0 changed
- analyse: no issues
- Discovery suite: **103 passed, 5 skipped**
- Chrome Web/entry-route: **12 passed**
- custom-scope gate PASS
- full-build job skipped as expected because this was a focused recovery gate

### TV Slice 2 — deterministic focus/navigation implemented

Functional source:

`2a204646fd296df1f57bd4dc4d7d3d1f969d7e6a`

`feat(discovery-v2): complete deterministic TV focus paths`

Exact functional commit is one parented commit touching only six intended files: four Discovery TV UI/focus files plus two focused test files. No catalogue/controller, Android Gradle/package/signing, Smart-TV or live code changed.

Implemented:

- `HomeLabDiscoveryTabStrip` has one TV focus owner; left/right changes tabs while retaining strip focus, Down/Select hands into active content, Up/horizontal boundary can return to host traversal
- landing keeps stable per-tab view keys, remembers the last focused lane, makes first-lane Up explicitly return to the tab strip, and restores the remembered lane when re-entering content
- first TV lanes no longer use framework `autofocus`; active-tab-only scheduled focus remains authoritative, preventing inactive `TabBarView` pages competing for focus
- `HomeLabDiscoveryTvGrid` exposes deterministic vertical edge callbacks without changing normal row movement, partial-row clamping, Select, Back or paging behaviour
- populated TV deep browse has an explicit Refresh action; grid Up at the first row reaches it and Refresh returns focus to the grid
- paging-error Retry More is explicitly reachable from grid Down at the final row; Up returns to the grid and successful retry restores grid focus
- focused regressions cover TV tab-strip focus ownership/content entry, grid vertical edges, populated deep Refresh and paging-error Retry More recovery

### #125 — formatter-only failure

Workflow **#125 / `34417981160`**, exact functional source `2a204646fd296df1f57bd4dc4d7d3d1f969d7e6a`:

- route PASS
- 486-lane catalogue/compiler + 8 Python tests PASS
- format gate failed because `dart format` changed exactly one formatting site in `homelab_discovery_see_all_screen.dart`
- required change only collapsed the `homelab-discovery-deep-refresh` `ValueKey` constructor from three lines to the formatter's single-line form
- analyse, focused tests, Chrome tests and scope gate were skipped after the format failure
- no behavioural failure was observed because behavioural validation did not run

Exact formatter recovery:

- source `a37ed60b9a996f4e292fe75e747fe1d95dcf16f4`
- commit `style(discovery-v2): apply TV focus slice formatter output`
- verified diff from the prior checkpoint: one file only, +1/-3
- no behaviour, tests, catalogue, package/signing, Smart-TV or live code changed

### Current Slice 2 replacement gate

- workflow **#126 / `34418234678`**
- exact source `a37ed60b9a996f4e292fe75e747fe1d95dcf16f4`
- status at checkpoint: **in progress**
- focused validation only; no `[full-build]`

Per the long-CI rule, do not poll #126. Inspect this exact run once on continuation.

### Remaining TV review after #126 green

- confirm Back/detail return and re-entry coverage remains intact with the new focus bridge
- validate off-screen focus/scroll behaviour at representative 1080p and 4K TV widths
- confirm lifecycle/resume/retained-state inheritance from shared controllers
- re-check package/version/signing/update invariants
- run final targeted TV coverage and the required `[full-build]` candidate before declaring Android TV GitHub/code complete

Physical TV acceptance remains deferred.

## Smart-TV / webOS and live

Do not inspect or modify Smart-TV/webOS until Android TV / Google TV is complete. Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Existing recovery refs remain intact.

## Completion order

1. shared semantics/personalisation — COMPLETE
2. Web — COMPLETE
3. Android mobile/tablet — COMPLETE
4. Android TV / Google TV — **ACTIVE; Slice 2 #126 PENDING**
5. final webOS reconciliation
6. cross-platform parity/recommendation quality
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance

## Exact next action

Inspect workflow #126 (`34418234678`) exactly once. If green, record its focused evidence and continue the remaining Android-TV-specific review, starting with Back/detail return plus representative 1080p/4K off-screen focus/scroll behaviour. If red, inspect only the failing gate, fix the root cause without weakening the deterministic focus paths, launch a replacement focused run, checkpoint exact source/run and stop under the long-CI rule.
