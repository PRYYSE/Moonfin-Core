# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo state is authoritative. Do not restart completed Discovery platform work or touch live services during GitHub-only work.

## Current boundary

- Shared Discovery semantics/catalogue: **COMPLETE** (`486 authored / 481 active`).
- Web: **GITHUB/CODE COMPLETE**.
- Android mobile/tablet: **GITHUB/CODE COMPLETE**.
- Android TV / Google TV: **GITHUB/CODE COMPLETE**.
- Smart-TV/webOS Discovery parity: **GITHUB/CODE COMPLETE** (`468 executable / 481 active` intentionally).
- Cross-platform parity/recommendation semantics: **COMPLETE for GitHub/code evidence**.
- Whole-product CI/release engineering: **COMPLETE — #139 GREEN**.
- Upstream automation: **stable-release detector corrected and GREEN**.
- Current work: **port official Smart-TV 2.8.2 onto isolated `update/webos-2.8.2` branch**.

## Locked release evidence

Flutter whole-product candidate:

- #139 / `34571653740` GREEN, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- artifact `10188826944`, digest `sha256:59f6678026ea665eceb74a2ed3fd3c43ae1d593c9c121b1d2ff2a81d29fc65e5`
- Web `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- mobile APK `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`
- Android TV APK `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`
- CI signer `9590094799a3b051292ad54904df0d964815a871ef9f6238068607e7ee1202b9`
- protected production cert `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Smart-TV accepted candidate:

- source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`
- #52 / `34439022624` GREEN
- artifact `10137277340`, digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`
- preserve rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`

## Stable upstream automation

Corrected source: `f1c8b6d68e559a3ba3192f1c2df605bd51cc57a4`.

The detector now distinguishes accepted release tags from accepted source-base SHAs. Stable release tags determine update availability; source SHAs remain the fail-closed ancestry/overlap anchors. Unreleased `main` drift is not treated as an available update.

Corrected workflow #2 / `34578894538` is GREEN.

- impact artifact `10190766738`
- digest `sha256:300441223b24a440604929c0b5c35e1d4238b61aca0c7f2a6859607411e71d05`
- Core: accepted/latest `2.5.1`, **NO update**, **0 overlap**.
- Smart-TV: accepted `2.7.0`, latest `2.8.2` at `ed327948aeb8ef19098b810145ab6a3b76ccf372`, **UPDATE AVAILABLE**, **5 overlap paths**.

Smart-TV accepted source base remains `384d7cab3642f846463a4308e92d213e51507edf`, a later commit on the accepted 2.7.0 lineage. Do not replace it with the older 2.7.0 tag commit merely to make the labels match.

## Smart-TV 2.8.2 update WIP

- `update/webos-2.8.2` exists and is rooted directly at official 2.8.2 `ed327948aeb8ef19098b810145ab6a3b76ccf372`.
- Draft PR #1 from `homelab/webos-discovery-v2` to the update branch is a conflict probe only; it is not automatically mergeable. Do not force-merge it.
- Five overlap paths require explicit resolution:
  - `packages/app/src/context/SettingsContext.js`
  - `packages/app/src/utils/homeLayout.js`
  - `packages/app/src/utils/homeLayout.test.js`
  - `packages/app/src/utils/seerrTarget.js`
  - `packages/app/src/utils/seerrTarget.test.js`
- Smart-TV commit `2c2a7627db8910752d587328cdacef6c76afb537` adds read-only port analysis. It attempts the three-way merge in CI, captures conflict markers/status/diff/full worktree and uploads them; it never pushes or deploys.
- Preserve upstream 2.8.2 changes in overlap files. Reapply only Home-Lab intent: custom-row profile/layout support plus Discovery local-Jellyfin selection semantics, while retaining upstream IMDb/title fallback behaviour.

## Waiting runs — inspect each once next continuation

- Core Discovery #141 / `34578894678` — **IN PROGRESS** at first capture.
- Smart-TV validation #54 / `34578965395` — **IN PROGRESS** at first capture.
- Smart-TV Port Analysis #1 / `34578965427` — **IN PROGRESS** at first capture.

Do not poll these again in this waiting cycle.

## Exact next actions

1. Inspect #141, #54 and Port Analysis #1 once.
2. Download the port-analysis artefact if green and resolve only actual conflict paths.
3. Commit the resolved Home-Lab overlay onto `update/webos-2.8.2` only.
4. Run the existing webOS Discovery workflow on that update branch; verify Node 20/legacy build, tests, app ID `org.moonfin.webos`, `index.html`, version >=2.7.0 and isolated IPK artefact.
5. Keep accepted and rollback branches untouched until later physical/live acceptance/promotion.
6. Create the final GitHub completion checkpoint only after this known stable update no longer leaves GitHub/code work open.

## Do not redo

Catalogue/compiler foundations, Web/mobile/TV implementation, Android TV focus/deep paging, webOS old-TV hardening, parity work, #133–#139 release recovery, or live/physical acceptance.

## Live boundary

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
