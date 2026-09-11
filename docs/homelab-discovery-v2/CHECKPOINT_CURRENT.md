# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo state is authoritative. Do not restart completed platform work or touch live services during GitHub-only work.

## Boundary

- Shared Discovery catalogue/semantics: COMPLETE (`486 authored / 481 active`).
- Web, Android mobile/tablet, Android TV/Google TV: GITHUB/CODE COMPLETE.
- Smart-TV/webOS accepted Discovery parity: GITHUB/CODE COMPLETE (`468 executable / 481 active` intentionally).
- Cross-platform parity/recommendation semantics: COMPLETE for GitHub/code evidence.
- Whole-product Flutter release engineering: COMPLETE — #139 / `34571653740` GREEN.
- Stable-release update automation: corrected and GREEN.
- Current work: validate isolated Smart-TV `2.8.2` port.

## Locked evidence

Flutter release: source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`; artifact `10188826944`; ZIP digest `sha256:59f6678026ea665eceb74a2ed3fd3c43ae1d593c9c121b1d2ff2a81d29fc65e5`; CI signer `9590094799a3b051292ad54904df0d964815a871ef9f6238068607e7ee1202b9`; protected production cert `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`.

Smart-TV accepted source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`; #52 / `34439022624` GREEN; artifact `10137277340`; digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`. Preserve rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`, app ID `org.moonfin.webos`, `index.html`, Node 20.

## Stable update status

Detector source `f1c8b6d68e559a3ba3192f1c2df605bd51cc57a4`; impact #2 / `34578894538` GREEN.

- Core accepted/latest stable `2.5.1`: NO update, 0 overlap.
- Smart-TV accepted lineage `2.7.0`, real source-base `384d7cab3642f846463a4308e92d213e51507edf`; latest stable `2.8.2` at `ed327948aeb8ef19098b810145ab6a3b76ccf372`: update YES, five overlaps.

## Smart-TV 2.8.2 update

- isolated branch `update/webos-2.8.2` was rooted directly at official `2.8.2`.
- PR #1 is a conflict probe only — DO NOT MERGE.
- Smart-TV #54 / `34578965395` GREEN.
- Port Analysis #1 / `34578965427` GREEN; artifact `10190788565`; digest `sha256:f9bbed71dd7c08770748e749a45aaa75663e58da881c99c461dd4b340fa42f46`.
- exactly five conflict paths: `SettingsContext.js`, `homeLayout.js`, `homeLayout.test.js`, `seerrTarget.js`, `seerrTarget.test.js`.
- reviewed semantics preserve upstream 2.8.2 settings/layout + IMDb/title fallback and Home-Lab custom destination rows + owned-Jellyfin routing.

Staging #2 / `34580576176` failed only because its whitespace check was over-broad; exact release/target/conflict and resolver stages had passed, while tests/build/push were skipped. Accepted regression #55 / `34580576157` GREEN. The isolated update branch was not advanced by #2.

Repair source `8fb273c024c773d730bd22304fa3d12961db18a2` stores and verifies a fixed conflict-marker resolution patch (SHA-256 `23d7800c6d15812cea030a8e5329bea267a5dd17d18be9003efb9b4904f54848`), verifies reviewed product files did not change after `2c2a7627db8910752d587328cdacef6c76afb537`, scopes whitespace checks to the five conflict files, and retains all Node 20/test/build/exact-identity gates.

## Waiting — inspect once next continuation

- Port Staging #3 / `34582511512`, source `8fb273c024c773d730bd22304fa3d12961db18a2`: IN PROGRESS at first capture.
- accepted-branch regression #57 / `34582511474`, same source: IN PROGRESS at first capture.

Do not poll either again in this waiting cycle.

## Next actions

1. Inspect #3 and #57 once.
2. If #3 fails, inspect only its failing step.
3. If #3 is green, fetch the resulting `update/webos-2.8.2` SHA.
4. Because an Actions `GITHUB_TOKEN` push does not create the normal follow-on push workflow event, create an external same-tree GitHub commit on the isolated update branch solely to trigger the established webOS Discovery validation workflow; capture that run once.
5. When green, capture candidate IPK artifact metadata/hash and close the GitHub/code 2.8.2 update.
6. Keep accepted/rollback branches and live/device state untouched until deliberate later promotion/acceptance.

## Do not redo

Catalogue/compiler foundations, Web/mobile/TV implementation, Android TV focus/deep paging, old-TV hardening, parity/recommendation work, #133–#139 release recovery, or live/physical acceptance.

## Live boundary

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
