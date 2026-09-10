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
- Whole-product CI / release engineering: **CURRENT — REPLACEMENT FULL BUILD RUNNING**

## Parity closure

Moonfin slice 1:

- `572e32d54d14d0d50ba8066cd817d8938ffae572`
- formatter correction `9ccb89927ca23bb4d3f00043f70ba138a6239beb`
- workflow #130 / `34436806830` GREEN

Moonfin slice 2:

- product `b800e5be18109963e4ae00b3739550b924c7204f`
- formatter-only follow-up `e654668f89af49470df417d4fcc444e73c53121e`
- workflow **#132 / `34439296054` GREEN**

Smart-TV/webOS parity:

- product `a9dfa657a220a3f8f77753261bd7d8e902c0d837`
- workflow **#52 / `34439022624` GREEN**
- candidate artifact `10137277340`
- ZIP digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`

Final parity decisions remain locked: bounded novelty, truthful anime novelty title, positive-only rewatch, aligned anime detection, dormant popular-anime-not-library adapter, structural/context fail-closed semantics, and no synthetic ranking tuning.

## Whole-product CI / release engineering

Scope is Web + Android mobile/tablet + Android TV/Google TV + webOS only.

Initial release-hardening source:

`de783e5af94f528d319c6f469e977d129bbc4435` — `ci(discovery): harden release candidate verification [full-build]`

### Verifier recovery

Workflow **#133 / `34440033993`** failed only at the new Android candidate verifier after focused validation and Web/mobile/TV builds passed. Its verifier tested the wrong Leanback distinction.

Verifier-contract correction:

`4f8dbec00b51800d7bf8d0ec321807207623bbfc` — `ci(discovery): verify leanback requirement split [full-build]`

Workflow **#134 / `34442473966`** also failed only at `Verify Android candidate identity and signing`; focused validation and all three builds passed again.

Exact observed #134 output:

`Observed mobile Leanback badging:   uses-feature-not-required: name='android.software.leanback'`

This proves the mobile APK already had the expected optional Leanback semantic. `aapt` added leading whitespace and the verifier compared from column 1.

Whitespace-only verifier correction:

`41cfa0f33a392706a37c3c9ade13c575484597c1` — `ci(discovery): normalise aapt leanback badging [full-build]`

Only the workflow changed; no app code or manifests changed. Current release checks still require:

- beta package ID `org.moonfin.androidtv.beta`
- mobile Leanback optional
- Android-TV Leanback required
- same CI signer on both APKs
- CI signer different from production SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- truthful BUILD_INFO signing/Leanback metadata

CI candidates remain debug-fallback and are not deployment APKs.

### Authoritative replacement gate

- workflow **#135 / `34448096121`**
- source `41cfa0f33a392706a37c3c9ade13c575484597c1`
- captured status: **IN PROGRESS**

Do not poll #135 again in this waiting cycle.

## Known non-blocking CI debt

Runner logs warn about Node-20-targeted action runtimes (`actions/checkout@v4`, `actions/setup-java@v4`) and setup-java v4 deprecation. These warnings did not cause #133 or #134. Keep that maintenance separate until the current release gate is green.

## Exact next actions

1. Next continuation: inspect **#135 / `34448096121` once**.
2. If failed, inspect only the failing job/step and fix the genuine failure.
3. If green, capture artifact ID/digest, `BUILD_INFO.txt`, CI signer and Web/mobile/Android-TV SHA-256 values.
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
