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
- Whole-product CI / release engineering: **CURRENT — FULL BUILD RUNNING**

## Parity closure

Moonfin slice 1:

- `572e32d54d14d0d50ba8066cd817d8938ffae572`
- formatter correction `9ccb89927ca23bb4d3f00043f70ba138a6239beb`
- workflow #130 / `34436806830` GREEN

Moonfin slice 2:

- product `b800e5be18109963e4ae00b3739550b924c7204f`
- formatter-only follow-up `e654668f89af49470df417d4fcc444e73c53121e`
- workflow **#132 / `34439296054` GREEN**
- route, catalogue + 8 Python tests, format, analyse, Flutter Discovery tests, Chrome tests and custom-scope verification all passed

Smart-TV/webOS parity:

- product `a9dfa657a220a3f8f77753261bd7d8e902c0d837`
- workflow **#52 / `34439022624` GREEN**
- Discovery service tests, webOS package build, preserved identity/package verification and candidate upload passed
- candidate artifact `10137277340`
- ZIP digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`

Final parity decisions:

- novelty aligned and bounded
- anime novelty truthfully labelled `Something Different in Anime`
- rewatch uses positive played evidence only
- anime detection aligned
- popular-anime-not-library remains dormant
- structural/context strategies remain fail-closed
- ranking/source weights unchanged pending real Home Lab aggregate evidence

## Whole-product CI / release engineering

Scope is Web + Android mobile/tablet + Android TV/Google TV + webOS only.

Release-hardening source:

`de783e5af94f528d319c6f469e977d129bbc4435` — `ci(discovery): harden release candidate verification [full-build]`

The Home Lab full-build workflow now additionally verifies:

- both beta APK package IDs are `org.moonfin.androidtv.beta`
- mobile beta has no Leanback launcher
- Android TV beta has Leanback launcher
- both APKs have the same CI signing certificate
- CI certificate is not production SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- CI and production fingerprints are recorded in `BUILD_INFO.txt`

CI candidates remain debug-fallback and are not deployment APKs.

### Authoritative full-build gate

- workflow **#133 / `34440033993`**
- source `de783e5af94f528d319c6f469e977d129bbc4435`
- captured status: **IN PROGRESS**

Do not poll #133 again in this waiting cycle.

## Exact next actions

1. Next continuation: inspect **#133 / `34440033993` once**.
2. If failed, inspect only the failing job/step and fix the genuine failure.
3. If green, capture its artifact ID/digest, `BUILD_INFO.txt`, CI signer and Web/mobile/Android-TV SHA-256 values.
4. Mark whole-product CI/release engineering complete.
5. Move directly to **upstream-update automation/protocol integration**.

## Do not redo

- shared catalogue/compiler foundations
- Web completion
- Android mobile/tablet completion
- Android TV focus/deep-paging work
- webOS old-TV hardening
- high-rating provenance correction
- parity slices 1/2
- live services or physical-device acceptance

## Live boundary

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Physical/device/live acceptance remains deferred.
