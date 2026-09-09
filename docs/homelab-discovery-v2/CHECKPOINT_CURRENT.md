# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file with `docs/AI_PROJECT_STATE.md`. Do not restart completed work or touch live services during GitHub-only completion.

## Current boundary

- Shared semantics/personalisation: COMPLETE
- Web: COMPLETE
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **ACTIVE — Slice 1 replacement workflow #123 pending**
- Smart-TV/webOS: do not reconcile until Android TV is complete

## Android mobile/tablet closure

Final source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`; final workflow #120 / `34326151119` GREEN.

#120 passed route, 486-lane catalogue/compiler + 8 Python tests, format, analyse, 100 Discovery tests with 5 skipped, 12 Chrome interaction tests, custom-scope validation, and full Web + `mobile-beta` + `androidTv-beta` candidate packaging.

Artifact:

- ID `10094778627`
- digest `sha256:27e01f5d5db575ee8d853e9808bbee7a2595dfa453be9ccd086ea0b3313cb421`
- mobile SHA256 `4d968b1ee2a27dddfdba8c2aa117f7301323dee3d3ce861f075b015992aced8e`
- TV baseline SHA256 `2c7ece2f5042f93d247b89d490d57de844d8d5b80f1ee05634128d7930e63621`
- Web SHA256 `8f17099b4668300f763d246a6db96ddc7938962b4cad1712171c30dff48b4b73`

Production signing invariant remains SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate it. CI candidates are debug fallback and not deployment artefacts.

## Android TV / Google TV — Slice 1

Product source `9788338cb27a86cb4024ee8dbe57b82bfcf68f21` fixes the remote-recovery defect family:

- deep genuine-empty explicitly shows Refresh for TV and autofocuses it
- deep load Retry autofocuses on TV
- landing/runtime/tab failure or genuine-empty action autofocuses on TV
- TV regressions cover tab selection, deep-empty Refresh via Select and deep-failure Retry via Select

No controller/catalogue/routing, Gradle/package/signing, Smart-TV or live changes.

### #121

Workflow #121 / `34331824783` failed only the two new screen tests because isolated `NavigationLayout` lacked app-service registrations. Route, 486-lane catalogue/compiler, 8 Python tests, format and analyse passed. Focused suite: **101 passed, 2 failed, 5 skipped**. TV tab-strip regression passed.

Harness bootstrap recovery source: `ebbabb7cd8fe84a3dd9f5bd746dbf1aafb3ed136`. Production code unchanged.

### #122

Workflow #122 / `34335668107` again passed route, 486-lane catalogue/compiler + 8 Python tests, format (54 files, 0 changed) and analyse.

Focused suite: **101 passed, 2 failed, 5 skipped**. Both deep-recovery screen tests now mounted; their only failure was `pumpAndSettle timed out`, caused by waiting for the real TV navigation chrome to become globally quiescent.

No product exception or failed product assertion was reported before the timeout.

### Bounded-pump recovery / #123

Test-only source:

`373a1a44d68d375dff1b17a35da76f578820d4d5`

`test(discovery-v2): bound TV recovery screen pumps`

Exact diff from the prior checkpoint is one test file only (+10/-4). Broad screen-level `pumpAndSettle()` calls were replaced with bounded pumps around the state transitions under test. Product/runtime code remains unchanged.

Replacement focused workflow:

- **#123 / `34407316688`**
- exact source `373a1a44d68d375dff1b17a35da76f578820d4d5`
- status at checkpoint: **in progress**
- no full candidate requested

Do not poll #123. Inspect it once on continuation.

## Remaining TV completion gate

After #123 is green, verify/fix:

1. deterministic navbar/tab/lane traversal and tab-strip ↔ active-lane re-entry;
2. prevent inactive tab pages competing for TV autofocus;
3. focus memory/restoration after detail return, paging/retry and re-entry;
4. populated deep-grid Refresh and paging-error Retry reachability;
5. Back/Select behaviour, partial rows and off-screen focus/scroll at 1080p/4K;
6. lifecycle/resume/retained-state behaviour inherited from shared controllers;
7. TV package/version/signing/update identity unchanged;
8. targeted TV tests and final full candidate green.

Physical TV acceptance remains deferred.

## Do not redo

Shared semantic/personalisation work, catalogue/compiler, request-cost/paging/cache/dedup/identity safeguards, local-vs-Seerr routing, verified Web, verified Android mobile/tablet, existing TV grid/lane primitives, docs-only CI hygiene, or separately advanced Smart-TV work.

## Exact next action

Inspect #123 (`34407316688`) exactly once. If green, close Slice 1 recovery and implement the remaining deterministic TV focus/remote-navigation slice. If red, fix only the failing gate, preserve the remote-recovery behaviour, launch replacement focused CI, record exact source/run and stop under the long-CI rule.
