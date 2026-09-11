# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo state is authoritative. Do not restart completed Discovery platform work or touch live services during GitHub-only work.

## Boundary

- Shared Discovery catalogue/semantics: **COMPLETE** (`486 authored / 481 active`).
- Web, Android mobile/tablet, Android TV/Google TV: **GITHUB/CODE COMPLETE**.
- Smart-TV/webOS accepted Discovery parity: **GITHUB/CODE COMPLETE** (`468 executable / 481 active` intentionally).
- Cross-platform parity/recommendation semantics: **COMPLETE for GitHub/code evidence**.
- Whole-product Flutter release engineering: **COMPLETE — #139 GREEN**.
- Stable upstream detector: **CORRECTED + VALIDATED**.
- Current work: **reviewed Smart-TV 2.8.2 port staging on isolated `update/webos-2.8.2`**.

## Locked invariants

- production Android certificate `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604` — never replace.
- Smart-TV app ID `org.moonfin.webos`, entry `index.html`, Node 20 legacy-TV compatibility.
- accepted Smart-TV source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, #52 GREEN, artifact `10137277340`.
- rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e` untouched.
- no physical/live acceptance is implied by CI.

## Stable upstream evidence

Detector source `f1c8b6d68e559a3ba3192f1c2df605bd51cc57a4`.

- Impact #2 / `34578894538`: GREEN.
- Core Discovery #141 / `34578894678`: GREEN.
- artifact `10190766738`, digest `sha256:300441223b24a440604929c0b5c35e1d4238b61aca0c7f2a6859607411e71d05`.
- Core stable `2.5.1 -> 2.5.1`: **NO update**, 0 overlap.
- Smart-TV stable `2.7.0 -> 2.8.2`: **UPDATE AVAILABLE**.
- accepted Smart-TV source base remains `384d7cab3642f846463a4308e92d213e51507edf`; official 2.8.2 is `ed327948aeb8ef19098b810145ab6a3b76ccf372`.

## Smart-TV 2.8.2 port evidence

`update/webos-2.8.2` was created from official `2.8.2` and is not to be overwritten except by the reviewed staging gate.

Read-only analysis:

- Smart-TV #54 / `34578965395`: GREEN.
- Port Analysis #1 / `34578965427`: GREEN.
- port artifact `10190788565`, digest `sha256:f9bbed71dd7c08770748e749a45aaa75663e58da881c99c461dd4b340fa42f46`.
- exactly five merge conflicts:
  - `packages/app/src/context/SettingsContext.js`
  - `packages/app/src/utils/homeLayout.js`
  - `packages/app/src/utils/homeLayout.test.js`
  - `packages/app/src/utils/seerrTarget.js`
  - `packages/app/src/utils/seerrTarget.test.js`
- every other Home-Lab overlay path merged cleanly.

Reviewed resolution preserves upstream 2.8.2 settings/layout/plugin behaviour and IMDb/title Seerr fallback, while layering only Home-Lab custom destination-row plumbing plus owned-item `seerrSelectionMediaId` routing. Dependency-free merged utility tests, Settings structural checks, parse checks and marker scan passed locally.

Staging control source:

`f932addf2d533cafe3b513d0a1960c631078f124`

The staging workflow fails closed unless the stable tag/SHA, untouched target SHA and exact five-conflict set match review. It runs conflict-surface + Discovery tests under Node 20, builds webOS, verifies exact `org.moonfin.webos` / `2.8.2` / `index.html`, and only then may fast-forward the isolated update branch.

## Waiting — inspect once next continuation

- Port Staging #2 / `34580576176`: **IN PROGRESS** at first capture.
- accepted-branch regression #55 / `34580576157`: **IN PROGRESS** at first capture.

Do not poll either again in this cycle. Do not assume `update/webos-2.8.2` moved until staging #2 succeeds.

## Exact next action

1. Inspect staging #2 and regression #55 once.
2. If staging failed, inspect only the failing job/step and fix that defect.
3. If staging succeeded, fetch the new `update/webos-2.8.2` SHA and the update-branch Discovery workflow it triggered.
4. Validate tests/build/identity/version/IPK artifact and record the candidate evidence.
5. Update stable baselines only after the GitHub candidate is accepted by the protocol; accepted and rollback refs stay unchanged until deliberate promotion/live acceptance.
6. Create the explicit GitHub completion checkpoint only when no known stable-update/code blocker remains.

## Do not redo

Catalogue/compiler foundations, Web/mobile/TV implementation, Android-TV focus/deep paging, webOS old-TV hardening, parity work, #133–#139 release recovery, or live/physical acceptance.

## Live boundary

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
