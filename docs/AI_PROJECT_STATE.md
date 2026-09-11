# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

Complete all reasonable GitHub/code work for Home Lab Moonfin Discovery v2 before physical-device, live-service or production acceptance.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`  
Smart-TV accepted branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`  
Smart-TV isolated update branch: `update/webos-2.8.2`

**Current phase:** stage and validate the reviewed Smart-TV `2.8.2` Home-Lab port.

## Completed foundations — do not redo

- Discovery catalogue/compiler + shared semantics/personalisation: **COMPLETE** (`486 authored / 481 accepted active`).
- Web: **GITHUB/CODE COMPLETE**, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: **GITHUB/CODE COMPLETE**, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, #120 / `34326151119` GREEN.
- Android TV / Google TV: **GITHUB/CODE COMPLETE**, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, #128 / `34429841034` GREEN.
- Smart-TV/webOS Discovery parity: **GITHUB/CODE COMPLETE**, accepted product source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, #52 / `34439022624` GREEN. webOS intentionally remains `468 executable / 481 active`; 13 structural/context strategies fail closed.
- Cross-platform parity/recommendation semantics: **COMPLETE for GitHub/code evidence**.
- Whole-product Flutter release engineering: **COMPLETE**, #139 / `34571653740` GREEN, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.

## Locked identity / rollback evidence

- Flutter candidate artifact `10188826944`, ZIP digest `sha256:59f6678026ea665eceb74a2ed3fd3c43ae1d593c9c121b1d2ff2a81d29fc65e5`.
- protected production Android certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate/replace.
- accepted Smart-TV artifact `10137277340`, digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`.
- preserve Smart-TV app ID `org.moonfin.webos`, entry `index.html`, Node 20 legacy-TV compatibility.
- preserve rollback branch `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.
- CI candidates are not production deployment artifacts; no physical/live acceptance is implied.

## Stable upstream automation — corrected and validated

Policy: `docs/UPSTREAM_UPDATE_PROTOCOL.md`.

Stable-release detector source `f1c8b6d68e559a3ba3192f1c2df605bd51cc57a4` separates accepted source ancestry from accepted release tags. Unreleased `main` drift is not treated as an available update.

Validated:

- Upstream Impact #2 / `34578894538`: **GREEN**.
- Core Discovery #141 / `34578894678`: **GREEN**.
- impact artifact `10190766738`, digest `sha256:300441223b24a440604929c0b5c35e1d4238b61aca0c7f2a6859607411e71d05`.
- Core: accepted/latest stable `2.5.1`, **NO update**, **0 stable overlap**.
- Smart-TV: accepted lineage `2.7.0`, latest stable `2.8.2`, **UPDATE AVAILABLE**, five overlap paths.

Smart-TV accepted source base remains `384d7cab3642f846463a4308e92d213e51507edf`; do not replace it with the older 2.7.0 tag commit. Official `2.8.2` is `ed327948aeb8ef19098b810145ab6a3b76ccf372`.

## Smart-TV 2.8.2 isolated update — CURRENT

`update/webos-2.8.2` was created directly from official `2.8.2` `ed327948aeb8ef19098b810145ab6a3b76ccf372`. Accepted/rollback branches remain untouched.

Port analysis:

- Smart-TV validation #54 / `34578965395`: **GREEN**.
- read-only Port Analysis #1 / `34578965427`: **GREEN**.
- artifact `10190788565`, digest `sha256:f9bbed71dd7c08770748e749a45aaa75663e58da881c99c461dd4b340fa42f46`.
- merge status: conflicts in exactly five reviewed paths:
  - `packages/app/src/context/SettingsContext.js`
  - `packages/app/src/utils/homeLayout.js`
  - `packages/app/src/utils/homeLayout.test.js`
  - `packages/app/src/utils/seerrTarget.js`
  - `packages/app/src/utils/seerrTarget.test.js`
- every other Home-Lab overlay path merged cleanly onto official 2.8.2.

Reviewed merge intent and local dependency-free checks:

- preserve upstream 2.8.2 settings/layout changes and plugin-section passthrough.
- add Home-Lab `customHomeRowsFromProfile`/destination-row plumbing without serialising derived `customHomeRows` as an authoritative standalone server field.
- preserve upstream Seerr IMDb/title fallback, search matching and library helpers.
- preserve Home-Lab `seerrSelectionMediaId` so known-owned Discovery items open the real Jellyfin detail/playback path.
- merged utility behaviour checks: **PASS**.
- Settings merge structural checks: **PASS**.
- conflict-marker scan + JS parse checks: **PASS**.

Staging control commit:

`f932addf2d533cafe3b513d0a1960c631078f124` — `ci(webos): stage reviewed 2.8.2 port`

Its fail-closed workflow requires:

- latest stable tag still exactly `2.8.2` and SHA still `ed327948...`.
- target `update/webos-2.8.2` still untouched at the official release SHA.
- exactly the five reviewed conflict paths above.
- upstream 2.8.2 versions used as the conflict bases; only the reviewed Home-Lab semantics are layered back.
- conflict-surface + Discovery tests pass under Node 20.
- `npm run build:webos` passes.
- package identity is exactly `org.moonfin.webos` / `2.8.2` / `index.html`.
- only then may it fast-forward the isolated update branch with a merge commit. It cannot touch the accepted or rollback branches.

## Waiting runs — DO NOT POLL AGAIN THIS CYCLE

Source `f932addf2d533cafe3b513d0a1960c631078f124`:

- Smart-TV Port Staging #2 / `34580576176`: captured **IN PROGRESS**.
- Smart-TV accepted-branch regression #55 / `34580576157`: captured **IN PROGRESS**.

The update branch has **not** been claimed as moved yet. Do not infer a candidate SHA until staging #2 proves it.

## Exact next actions

1. Next continuation: inspect exact staging #2 / `34580576176` once.
2. Inspect exact regression #55 / `34580576157` once.
3. If staging failed, inspect only its failing job/step; fix the actual reviewed-port defect and launch/record one replacement.
4. If staging succeeded, read the resulting `update/webos-2.8.2` branch SHA and capture the automatically triggered update-branch Discovery workflow once.
5. Validate the update candidate tests/build/app ID/version/IPK artifact; preserve accepted + rollback refs.
6. Only after the stable 2.8.2 candidate leaves no GitHub/code blocker, update stable baselines/protocol evidence and create the explicit GitHub completion checkpoint.
7. Stop before physical/live acceptance unless explicitly instructed to cross that boundary.

## Non-blocking debt

- GitHub Action runtime deprecation warnings and future Flutter Built-in Kotlin migration remain separate maintenance work.
- Smart-TV application remains Node 20 unless legacy LG C6 compatibility is independently proven with a newer runtime.
- upstream-impact cron remains dormant while its workflow is not on the default branch; do not contaminate the clean upstream mirror merely to enable scheduling.

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
