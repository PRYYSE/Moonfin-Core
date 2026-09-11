# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read with `docs/AI_PROJECT_STATE.md`, `handover.md`, `CROSS_PLATFORM_PARITY_MATRIX.md` and `UPSTREAM_UPDATE_AUTOMATION.md`. GitHub/current repo state is authoritative. Do not restart completed platform implementation or touch live services during GitHub-only work.

## Current boundary

- Shared semantics/personalisation foundations: **COMPLETE**
- Web: **GITHUB/CODE COMPLETE**
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **GITHUB/CODE COMPLETE**
- Smart-TV/webOS: **GITHUB/CODE COMPLETE + PARITY VALIDATED**
- Cross-platform parity + recommendation quality: **COMPLETE for GitHub/code evidence**
- Whole-product CI / release engineering: **COMPLETE — #139 GREEN**
- Upstream-update automation / protocol integration: **CURRENT — VALIDATION RUNS LAUNCHED**

## Locked release evidence

Smart-TV candidate:

- source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`
- workflow #52 / `34439022624` GREEN
- artifact `10137277340`
- ZIP digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`

Flutter whole-product candidate:

- workflow **#139 / `34571653740`** GREEN
- source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- artifact `10188826944`
- size `304,690,594` bytes
- ZIP digest `sha256:59f6678026ea665eceb74a2ed3fd3c43ae1d593c9c121b1d2ff2a81d29fc65e5` — independently rechecked
- CI Android signer `9590094799a3b051292ad54904df0d964815a871ef9f6238068607e7ee1202b9`
- production Android certificate remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- Web SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- mobile APK SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`
- Android TV APK SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`

All #139 focused validation, Web/mobile/TV builds, beta package identity, Leanback split, signer checks, packaging and artifact upload passed. CI APKs remain debug-fallback candidates, not deployment APKs. Physical/live acceptance remains deferred.

## Upstream-update integration

Official lineages/baselines:

- Core: `Moonfin-Client/Moonfin-Core` / `main`; accepted base `f18c45b1fbf9b63871b4f93237179f9706154763`; observed official head `3b7c07865b9ac9378606d267fcd35faed4ee5b89`.
- Smart-TV: `Moonfin-Client/Smart-TV` / `main`; accepted base `384d7cab3642f846463a4308e92d213e51507edf`; observed official head `c7e1ff570ace275871f8c63589c30cfb58106edb`.

Core integration source:

`6f0a333774ca430531f06e3985a968fcb7b4b645`

Implemented:

- machine-readable upstream baseline/identity registry
- fail-closed upstream impact/overlap generator
- read-only Core + Smart-TV impact workflow
- implementation operating contract
- `update/moonfin-*` support in the proven Discovery release workflow
- branch-aware narrow-scope base using official-upstream merge-base on update branches

Smart-TV integration source:

`a4e0a3251bf3a987e6c92ad4c1575e5c528401e0`

Implemented:

- `update/webos-*` workflow support
- Node 20 retained
- app ID `org.moonfin.webos` / `index.html` preserved
- accepted branch remains exactly `2.7.0`; update branches can advance semver but cannot regress below `2.7.0`
- rollback branch `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e` untouched

Local validation before push: Python compile, JSON/YAML parse, overlap fixture, fail-closed ancestry fixture and webOS version guard fixtures all PASS.

### Validation runs — captured once; do not poll again this cycle

- Core Discovery **#140 / `34576497402`**, source `6f0a333774ca430531f06e3985a968fcb7b4b645`, **QUEUED**
- Upstream Impact **#1 / `34576497458`**, source `6f0a333774ca430531f06e3985a968fcb7b4b645`, **QUEUED**
- Smart-TV webOS **#53 / `34576558771`**, source `a4e0a3251bf3a987e6c92ad4c1575e5c528401e0`, **IN PROGRESS**

The impact workflow's cron is intentionally dormant while the control workflow lives only on the non-default Home Lab overlay branch, because GitHub schedules execute from the default branch. Do not merge product overlay code into the upstream-mirror/default branch merely to enable cron; manual dispatch remains safe.

## Exact next actions

1. Inspect #140 / `34576497402` once.
2. Inspect impact #1 / `34576497458` once; if green, download its report artifact and record current Core/Smart-TV drift + overlap counts.
3. Inspect Smart-TV #53 / `34576558771` once.
4. Fix only genuine failing integration gates, launch/record replacements if required, and do not continuously poll.
5. When all three are green, mark upstream automation/protocol integration COMPLETE and create the explicit GitHub completion checkpoint.
6. Stop before physical/live acceptance unless explicitly instructed to cross that boundary.

## Do not redo

- shared catalogue/compiler foundations
- Web/mobile/TV platform implementation
- Android TV focus/deep paging
- webOS old-TV hardening
- parity/recommendation semantics
- #133–#139 release-gate recovery
- live services or physical-device acceptance

## Live boundary

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
