# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

Complete all reasonable GitHub/code work for Home Lab Moonfin Discovery v2 before physical-device, live-service or production acceptance.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`  
Smart-TV repo/accepted branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`

**Current phase:** stable upstream update integration — Smart-TV `2.8.2`.

## Completed — do not redo

- Discovery catalogue/compiler + shared semantics/personalisation: **COMPLETE** (`486 authored / 481 accepted active`).
- Web: **GITHUB/CODE COMPLETE**, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: **GITHUB/CODE COMPLETE**, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN.
- Android TV / Google TV: **GITHUB/CODE COMPLETE**, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, workflow #128 / `34429841034` GREEN.
- Smart-TV/webOS Discovery parity: **GITHUB/CODE COMPLETE**, product source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, workflow #52 / `34439022624` GREEN. webOS remains intentionally `468 executable / 481 active`; 13 structural/context strategies fail closed.
- Cross-platform parity/recommendation semantics: **COMPLETE for GitHub/code evidence**.
- Whole-product Flutter release engineering: **COMPLETE**, workflow #139 / `34571653740` GREEN, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.

## Locked release / identity evidence

Flutter candidate artifact:

- artifact ID `10188826944`
- size `304,690,594` bytes
- ZIP digest `sha256:59f6678026ea665eceb74a2ed3fd3c43ae1d593c9c121b1d2ff2a81d29fc65e5`
- Web SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- mobile APK SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`
- Android TV APK SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`
- CI signer `9590094799a3b051292ad54904df0d964815a871ef9f6238068607e7ee1202b9`
- protected production Android certificate remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Smart-TV accepted candidate:

- artifact `10137277340`
- digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`
- preserve rollback branch `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`
- preserve app ID `org.moonfin.webos`, entry `index.html`, Node 20 legacy-TV compatibility

CI candidates are not production deployment artifacts. No physical/live acceptance is implied.

## Upstream update automation — stable-release detector corrected

Policy source: `docs/UPSTREAM_UPDATE_PROTOCOL.md`.

Initial automation integration `6f0a333774ca430531f06e3985a968fcb7b4b645` and Smart-TV workflow support `a4e0a3251bf3a987e6c92ad4c1575e5c528401e0` validated GREEN in Core #140 / impact #1 / Smart-TV #53.

A material semantic defect was then found: the first detector treated upstream `main` drift as an available update even though the protocol requires official releases/tags.

Correction:

- Core commit `f1c8b6d68e559a3ba3192f1c2df605bd51cc57a4` — `fix(upstream): detect stable releases by tag`
- accepted source-base SHAs remain the ancestry/diff anchors
- `accepted_release_tag` now separately records the accepted stable release
- latest stable release is resolved through GitHub Releases and fetched by tag
- tag equality decides whether a stable update exists; unreleased `main` drift is not reported as an update
- synthetic same-tag/different-tag fixtures PASS
- corrected impact workflow #2 / `34578894538` GREEN
- artifact `10190766738`, digest `sha256:300441223b24a440604929c0b5c35e1d4238b61aca0c7f2a6859607411e71d05`

Corrected stable evidence:

### Core

- accepted release `2.5.1`
- latest stable release `2.5.1`
- accepted/release commit `f18c45b1fbf9b63871b4f93237179f9706154763`
- **NO stable update**
- **0 stable-release/Home-Lab overlaps**

### Smart-TV/webOS

- accepted release lineage `2.7.0`
- accepted source base `384d7cab3642f846463a4308e92d213e51507edf` (a later upstream-main commit on the accepted 2.7.0 lineage; do not rewrite this ancestry)
- latest stable release `2.8.2`
- release commit `ed327948aeb8ef19098b810145ab6a3b76ccf372`
- **stable update available**
- 156 commits from accepted source base to stable 2.8.2
- **5 overlapping paths requiring explicit review**:
  - `packages/app/src/context/SettingsContext.js`
  - `packages/app/src/utils/homeLayout.js`
  - `packages/app/src/utils/homeLayout.test.js`
  - `packages/app/src/utils/seerrTarget.js`
  - `packages/app/src/utils/seerrTarget.test.js`

The earlier raw upstream-main drift counts are superseded as update signals.

## Smart-TV 2.8.2 isolated update — CURRENT

- Isolated branch `update/webos-2.8.2` created directly from official `2.8.2` commit `ed327948aeb8ef19098b810145ab6a3b76ccf372`.
- Draft PR #1 (`homelab/webos-discovery-v2` -> `update/webos-2.8.2`) is only a three-way conflict probe; GitHub reports it is not automatically mergeable. Do not force it.
- Accepted Home-Lab branch, live services and rollback refs remain untouched.
- Smart-TV commit `2c2a7627db8910752d587328cdacef6c76afb537` adds a **read-only** stable-update port-analysis workflow. It checks out the latest stable release, attempts the three-way merge without pushing, records conflict paths/diff/status and uploads the complete merge worktree for explicit resolution.

Home-Lab overlap intent already reviewed at patch level:

- `SettingsContext.js`: retain upstream 2.8.2 settings changes; layer Home-Lab custom-row profile plumbing only.
- `homeLayout.js` / test: retain upstream layout evolution; preserve external/Home-Lab row ingestion and metadata plus its regression test.
- `seerrTarget.js` / test: retain upstream 2.8.2 IMDb/title search-fallback semantics while preserving Discovery's Jellyfin-owned-item routing (`seerrSelectionMediaId`) and associated tests.

## Runs currently waiting — inspect each ONCE next continuation

- Core Discovery #141 / `34578894678`, source `f1c8b6d68e559a3ba3192f1c2df605bd51cc57a4` — captured **IN PROGRESS**.
- Smart-TV validation #54 / `34578965395`, source `2c2a7627db8910752d587328cdacef6c76afb537` — captured **IN PROGRESS**.
- Smart-TV Port Analysis #1 / `34578965427`, source `2c2a7627db8910752d587328cdacef6c76afb537` — captured **IN PROGRESS**.

Do not poll these again in the current waiting cycle.

## Exact next actions

1. Inspect the three exact runs above once.
2. If Port Analysis #1 is green, download its workspace artifact and resolve only the reported merge conflicts against official 2.8.2, preserving both upstream and Home-Lab semantics.
3. Write the resolved result only to `update/webos-2.8.2`; do not modify accepted/rollback branches.
4. Run the update branch through `.github/workflows/homelab-webos-discovery-v2.yml`; capture artifact/version/app-ID/legacy-TV evidence.
5. Update the stable baseline only after the 2.8.2 update candidate is GitHub-integrated/accepted at the appropriate protocol stage; do not falsely mark production acceptance.
6. Only when no known stable upstream update or GitHub/code blocker remains, create the explicit GitHub completion checkpoint. Physical/live acceptance stays separate.

## Known non-blocking debt

- GitHub Action runtime deprecation warnings and future Flutter Built-in Kotlin migration remain separate maintenance work.
- Smart-TV application remains Node 20 unless legacy LG C6 compatibility is independently proven with a newer runtime.
- The upstream-impact cron remains dormant while the workflow exists only on a non-default branch; do not contaminate the clean upstream-mirror/default branch merely to activate scheduling.

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
