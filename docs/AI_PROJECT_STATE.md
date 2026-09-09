# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

**Current phase:** Android TV / Google TV completion — Slice 1 product fix remains intact; replacement focused validation **#123** is in progress after #122 exposed only a non-quiescing TV test wait. Android mobile/tablet is GitHub/code complete.

## Android mobile/tablet — COMPLETE

Final source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`; workflow #120 / `34326151119` GREEN.

Final evidence:

- route + 486-lane catalogue/compiler PASS
- catalogue Python tests: 8 passed
- format: 53 files, 0 changed
- analyse: no issues
- Discovery suite: 100 passed, 5 skipped
- Chrome Web/entry-route: 12 passed
- full Web + `mobile-beta` + `androidTv-beta` candidate PASS
- artifact `10094778627`
- digest `sha256:27e01f5d5db575ee8d853e9808bbee7a2595dfa453be9ccd086ea0b3313cb421`
- mobile SHA256 `4d968b1ee2a27dddfdba8c2aa117f7301323dee3d3ce861f075b015992aced8e`
- TV baseline SHA256 `2c7ece2f5042f93d247b89d490d57de844d8d5b80f1ee05634128d7930e63621`
- Web SHA256 `8f17099b4668300f763d246a6db96ddc7938962b4cad1712171c30dff48b4b73`

Physical mobile/tablet acceptance remains deferred.

## Android TV / Google TV — ACTIVE

### Existing foundations — do not redo

- `HomeLabDiscoveryTvLane` uses the locked-focus row primitive
- `HomeLabDiscoveryTvGrid` has deterministic single focus ownership
- existing regressions cover Select, D-pad movement, partial final rows, Back, near-end paging, pointer activation and focus memory
- landing restores lane focus after details and See All return
- deep browse restores grid focus after details and paging retry
- local Jellyfin vs Seerr routing is shared and already verified
- #120 proves current `androidTv-beta` compiles/packages, but is not TV product-completion proof

TV/update identity remains:

- production app ID `org.moonfin.androidtv`; beta `.beta`
- TV version `2.5.1`, build `2000016`
- forced-TV build uses `MOONFIN_FORCE_TV=true`
- production signing certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- never regenerate production signing material
- CI APKs remain `debug-fallback-not-for-deployment`

### TV Slice 1 — product fix implemented

Product source `9788338cb27a86cb4024ee8dbe57b82bfcf68f21` (`feat(discovery-v2): make TV recovery remote-safe`) fixes the remote-only recovery defect family:

- deep genuine-empty exposes an explicit TV Refresh action and autofocuses it
- deep load Retry autofocuses on TV
- landing/runtime/tab failure or genuine-empty action autofocuses on TV
- TV regressions cover tab selection, deep-empty Refresh via Select and deep-failure Retry via Select

No shared controller/catalogue/routing, Android Gradle/package/signing, Smart-TV or live code changed.

### #121 — test bootstrap failure only

Workflow #121 / `34331824783`, source `9788338cb...`:

- route PASS
- 486-lane catalogue/compiler PASS
- catalogue Python tests: 8 passed
- format: 54 files, 0 changed
- analyse: no issues
- focused suite: **101 passed, 2 failed, 5 skipped**
- TV tab-strip regression passed
- two new deep-recovery screen tests failed before render because isolated `NavigationLayout` lacked required app services

Harness bootstrap recovery source `ebbabb7cd8fe84a3dd9f5bd746dbf1aafb3ed136` registered in-memory preferences, real `PlaybackManager`, and minimal mocked app services. Production code remained unchanged.

### #122 — bounded-wait issue only

Workflow #122 / `34335668107`, source `ebbabb7cd...` again passed route, 486-lane catalogue/compiler + 8 Python tests, format (54 files, 0 changed) and analyse.

Focused suite again ended **101 passed, 2 failed, 5 skipped**. Both previously crashing screen tests now mounted successfully; their only failure was `pumpAndSettle timed out` because the real TV navigation chrome does not become globally quiescent. No product exception or assertion mismatch was reported before the timeout.

Test-only recovery source:

- `373a1a44d68d375dff1b17a35da76f578820d4d5`
- `test(discovery-v2): bound TV recovery screen pumps`
- exact diff from the prior checkpoint: one test file only, +10/-4
- replaces broad screen-level `pumpAndSettle()` waits with bounded pumps around the actual asynchronous state transition
- tab-strip test remains unchanged
- no production/runtime code changed

### Current replacement gate

- workflow **#123 / `34407316688`**
- exact source `373a1a44d68d375dff1b17a35da76f578820d4d5`
- status at checkpoint: **in progress**
- focused validation only; no `[full-build]`

Per the long-CI rule, do not poll #123. Inspect this exact run once on continuation.

### Remaining TV-specific review after #123 green

Known areas to finish before TV closure:

- deterministic tab-strip ↔ active-lane hand-off and first-lane Up behaviour
- prevent inactive TabBar pages competing for TV autofocus
- populated deep-grid Refresh reachability
- paging-error Retry reachability from the grid bottom and focus restoration
- Back/detail return and off-screen focus/scroll at 1080p/4K
- lifecycle/resume/retained-state inheritance
- package/version/signing/update safety
- final targeted tests and required `[full-build]` candidate

Physical TV acceptance remains deferred.

## Completed foundations — do not redo

- shared semantics/personalisation and request-cost/paging/cache/dedup/identity safeguards
- 486-lane catalogue/compiler
- local-vs-Seerr details routing
- Web completion `1ac1499a0d43d404fa46d1e1abf49a433f972ea9` / #115
- Android mobile/tablet completion `4af01af054d9b7cbe8e230b7ded482cb8fea330c` / #120
- docs-only CI trigger hygiene

Unsupported structural/context semantics remain fail-closed.

## Smart-TV / webOS and live

Do not inspect or modify Smart-TV/webOS until Android TV / Google TV is complete. Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Existing recovery refs remain intact.

## Completion order

1. shared semantics/personalisation — COMPLETE
2. Web — COMPLETE
3. Android mobile/tablet — COMPLETE
4. Android TV / Google TV — **ACTIVE; #123 PENDING**
5. final webOS reconciliation
6. cross-platform parity/recommendation quality
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance

## Exact next action

Inspect workflow #123 (`34407316688`) exactly once. If green, record its focused evidence, close TV Slice 1 recovery and implement the remaining deterministic TV focus/remote-navigation slice. If red, inspect only the failing gate, fix the root cause without weakening the TV recovery regressions, launch a replacement focused run, checkpoint exact source/run and stop under the long-CI rule.
