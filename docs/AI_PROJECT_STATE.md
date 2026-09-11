# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

Complete all reasonable GitHub/code work for Home Lab Moonfin Discovery v2 before physical-device, live-service or production acceptance.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`  
Smart-TV accepted branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`  
Smart-TV isolated update branch: `update/webos-2.8.2`

**Current phase:** validate the reviewed Smart-TV `2.8.2` upstream port.

## Completed foundations — do not redo

- Discovery catalogue/compiler + shared semantics/personalisation: **COMPLETE** (`486 authored / 481 active`).
- Web: GitHub/code complete, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: complete, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, #120 / `34326151119` GREEN.
- Android TV / Google TV: complete, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, #128 / `34429841034` GREEN.
- Smart-TV/webOS Discovery parity: complete at accepted source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, #52 / `34439022624` GREEN; intentionally `468 executable / 481 active`, 13 structural/context strategies fail closed.
- Cross-platform parity/recommendation semantics: **COMPLETE for GitHub/code evidence**.
- Whole-product Flutter release engineering: **COMPLETE**, #139 / `34571653740` GREEN, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.

Locked Flutter release artifact `10188826944`, ZIP digest `sha256:59f6678026ea665eceb74a2ed3fd3c43ae1d593c9c121b1d2ff2a81d29fc65e5`. CI signer `9590094799a3b051292ad54904df0d964815a871ef9f6238068607e7ee1202b9`; protected production Android certificate remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`.

Preserve Smart-TV rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`, app ID `org.moonfin.webos`, entry `index.html`, and Node 20 legacy LG C6 compatibility.

## Stable upstream automation

Detector correction source `f1c8b6d68e559a3ba3192f1c2df605bd51cc57a4`; impact #2 / `34578894538` GREEN, artifact `10190766738`, digest `sha256:300441223b24a440604929c0b5c35e1d4238b61aca0c7f2a6859607411e71d05`.

Stable evidence:

- Core: accepted/latest `2.5.1`; **NO update**, 0 overlap.
- Smart-TV: accepted release lineage `2.7.0`; accepted real source base `384d7cab3642f846463a4308e92d213e51507edf`; latest stable `2.8.2` at `ed327948aeb8ef19098b810145ab6a3b76ccf372`; **UPDATE AVAILABLE**, five overlaps.
- unreleased upstream `main` drift is not an update signal.

## Smart-TV 2.8.2 port — CURRENT

`update/webos-2.8.2` was created directly from official `2.8.2`. Draft PR #1 is a conflict probe only — **DO NOT MERGE**.

Read-only evidence:

- Smart-TV #54 / `34578965395`: GREEN.
- Port Analysis #1 / `34578965427`: GREEN.
- artifact `10190788565`, digest `sha256:f9bbed71dd7c08770748e749a45aaa75663e58da881c99c461dd4b340fa42f46`.
- exactly five conflicts: `SettingsContext.js`, `homeLayout.js`, `homeLayout.test.js`, `seerrTarget.js`, `seerrTarget.test.js`; all other overlay paths merged cleanly.
- reviewed result preserves upstream 2.8.2 settings/layout and IMDb/title Seerr fallback plus Home-Lab custom destination rows and owned-Jellyfin selection routing.

Staging #2 / `34580576176` at `f932addf2d533cafe3b513d0a1960c631078f124` failed **only** because an over-broad `git diff --check` examined unrelated workflow/Markdown whitespace. Exact release/target/conflict checks and conflict resolution had passed; tests/build/push were skipped. Accepted regression #55 / `34580576157` was GREEN, and #2 did not advance the update branch.

Repair source `8fb273c024c773d730bd22304fa3d12961db18a2`:

- stores a fixed reviewed conflict-marker patch at `tooling/webos-2.8.2-reviewed-conflicts.patch`, SHA-256 `23d7800c6d15812cea030a8e5329bea267a5dd17d18be9003efb9b4904f54848`.
- patch dry-apply with `--whitespace=error` reproduces the reviewed five files byte-for-byte and preserves clean auto-merged hunks inside conflicted files.
- fails closed if product/package files changed after reviewed source `2c2a7627db8910752d587328cdacef6c76afb537`, if stable release/target SHA changes, if conflict set changes, or if patch digest changes.
- whitespace checking is scoped to the five resolved product files.
- still requires Node 20 focused tests, webOS build, exact `org.moonfin.webos` / `2.8.2` / `index.html`, then pushes only `update/webos-2.8.2`.

## Waiting — inspect ONCE next continuation

- Port Staging #3 / `34582511512`, source `8fb273c024c773d730bd22304fa3d12961db18a2`: captured **IN PROGRESS**.
- accepted-branch regression #57 / `34582511474`, same source: captured **IN PROGRESS**.

Do not poll either again this cycle.

## Exact next actions

1. Inspect #3 and #57 once.
2. If #3 failed, inspect only its failing staging step and fix that defect.
3. If #3 is green, fetch `update/webos-2.8.2` once and capture the merge-candidate SHA.
4. Actions `GITHUB_TOKEN` pushes do not create the normal follow-on push workflow run. Create one external **same-tree** GitHub commit on the isolated update branch to trigger the established `.github/workflows/homelab-webos-discovery-v2.yml`, then capture that exact run once.
5. When established validation is green, capture IPK artifact ID/name/size/digest and IPK SHA-256; mark the 2.8.2 GitHub/code update integrated.
6. Do **not** promote the accepted branch or cross into physical/live acceptance yet.

## Non-blocking debt

Action-runtime deprecation warnings and future Flutter Built-in Kotlin migration remain separate. Smart-TV application runtime stays Node 20 unless legacy LG C6 compatibility is independently proven with a newer runtime. Upstream cron remains dormant while its workflow is not on the default branch; do not contaminate the clean/default upstream mirror just to activate scheduling.

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
