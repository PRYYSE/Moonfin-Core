# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read with `docs/AI_PROJECT_STATE.md`, `handover.md` and `CROSS_PLATFORM_PARITY_MATRIX.md`. GitHub/current repo state is authoritative. Do not restart completed platform implementation or touch live services during GitHub-only work.

## Current boundary

- Shared semantics/personalisation foundations: **COMPLETE**
- Web: **GITHUB/CODE COMPLETE**
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **GITHUB/CODE COMPLETE**
- Smart-TV/webOS: **GITHUB/CODE COMPLETE + PARITY VALIDATED**
- Cross-platform parity + recommendation quality: **COMPLETE for current GitHub/code evidence**
- Whole-product CI / release engineering: **CURRENT**

## Parity closure

### Moonfin-Core

Parity slice 1:

- implementation `572e32d54d14d0d50ba8066cd817d8938ffae572`
- format correction `9ccb89927ca23bb4d3f00043f70ba138a6239beb`
- workflow #130 / `34436806830` GREEN

Parity slice 2:

- product `b800e5be18109963e4ae00b3739550b924c7204f`
- format-only follow-up `e654668f89af49470df417d4fcc444e73c53121e`
- workflow **#132 / `34439296054` GREEN**
- route, catalogue + 8 Python tests, format, analyse, Flutter Discovery tests, Chrome interaction tests and scope verification all passed

### Smart-TV/webOS

- parity product `a9dfa657a220a3f8f77753261bd7d8e902c0d837`
- workflow **#52 / `34439022624` GREEN**
- Discovery service tests, webOS package build, app identity/package verification and candidate upload passed
- artifact `10137277340`
- ZIP digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`

## Final parity decisions

- Generic novelty: aligned with bounded random-source semantics.
- Anime novelty: truthful `Something Different in Anime`; no unsupported usual-genre claim.
- Rewatch: positive played evidence only; neutral history excluded.
- Anime detection: aligned for tag/genre and Animation + Japanese language/origin.
- Popular anime not in library: dormant adapter only; no authored lane, so no parity lane added.
- Structural/context strategies: intentionally fail-closed.
- Ranking/source weights: unchanged; real Home Lab aggregate evidence required before tuning.

Recommendation-quality tuning is deferred because real aggregate evidence would cross the current no-live boundary.

## Whole-product CI / release engineering

Scope is Web + Android mobile/tablet + Android TV/Google TV + webOS only. Do not expand into unrelated upstream platform release work.

Current Flutter candidate workflow already supports `[full-build]` and builds Web, `mobile-beta`, and `androidTv-beta` candidates after focused validation.

Release hardening to apply before the fresh full build:

- verify both Android beta APK package IDs are `org.moonfin.androidtv.beta`
- verify mobile candidate does not expose Leanback launcher semantics
- verify Android TV candidate does expose Leanback launcher semantics
- record actual CI APK signer SHA-256
- assert CI signer is not production certificate `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- preserve debug-fallback CI status; these candidates are not deployment APKs

## Exact next actions

1. Patch `.github/workflows/homelab-discovery-v2.yml` with the narrow Android candidate identity/signing gate.
2. Commit with `[full-build]` to trigger focused validation + Web/mobile-beta/androidTv-beta candidate build.
3. Record the exact new workflow run ID in the durable checkpoint.
4. Do not continuously poll the long build.
5. Next continuation: inspect that exact run once; fix genuine failure or, if green, capture artifact ID/digest/candidate SHA-256 values and close release engineering.
6. Then move to upstream-update automation/protocol integration.

## Do not redo

- platform completion passes
- catalogue/compiler foundations
- Android TV focus/deep-paging work
- webOS old-TV hardening
- high-rating provenance correction
- parity slices 1/2
- live services or physical-device acceptance

## Live boundary

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Physical/device/live acceptance remains deferred.
