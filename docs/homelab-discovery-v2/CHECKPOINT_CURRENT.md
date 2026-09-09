# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-09 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file with `docs/AI_PROJECT_STATE.md`. Do not restart completed work or touch live services during GitHub-only completion.

## Current boundary

- Shared semantics/personalisation: COMPLETE
- Web: COMPLETE
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **ACTIVE — Slice 1 focused workflow #121 pending**
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

Existing TV lane/grid focus foundations were retained. Current review found one concrete remote-recovery defect family:

- deep genuine-empty had Web Refresh and touch pull-refresh, but no TV remote Refresh
- landing/deep failure/empty action buttons were focusable but not deterministically initial-focused for TV recovery

Implemented source:

`9788338cb27a86cb4024ee8dbe57b82bfcf68f21`

`feat(discovery-v2): make TV recovery remote-safe`

Changes:

- deep genuine-empty explicitly shows Refresh for TV and autofocuses it
- deep load Retry autofocuses on TV
- landing/runtime/tab failure or genuine-empty action autofocuses on TV
- new TV integration regressions cover tab D-pad selection, deep-empty Refresh via Select and deep-failure Retry via Select

Exact diff is limited to two Discovery UI files plus one new TV test file. No controller/catalogue/routing, Gradle/package/signing, Smart-TV or live changes.

Focused workflow:

- **#121 / `34331824783`**
- exact source `9788338cb27a86cb4024ee8dbe57b82bfcf68f21`
- status at checkpoint: **in progress**
- no full candidate requested

Do not poll #121. Inspect it once on continuation.

## TV completion gate

Before Android TV / Google TV can close, verify/fix:

1. deterministic D-pad traversal through navbar/tabs/lanes/deep grids;
2. focus memory/restoration after detail return, paging/retry and re-entry;
3. Select/Enter and Back behaviour;
4. partial rows and off-screen focus/scroll;
5. remotely reachable loading/error/empty/paging recovery;
6. lifecycle/resume/retained-state behaviour inherited from shared controllers;
7. TV package/version/signing/update identity unchanged;
8. targeted TV tests and final full candidate green.

Physical TV acceptance remains deferred.

## Do not redo

Shared semantic/personalisation work, catalogue/compiler, request-cost/paging/cache/dedup/identity safeguards, local-vs-Seerr routing, verified Web, verified Android mobile/tablet, existing TV grid/lane primitives, docs-only CI hygiene, or separately advanced Smart-TV work.

## Exact next action

Inspect #121 (`34331824783`) exactly once. If green, continue only the remaining Android-TV-specific review and final validation sequence. If red, fix only the failing gate, preserve the remote-recovery behaviour, launch replacement focused CI, record exact source/run, and stop under the long-CI rule.
