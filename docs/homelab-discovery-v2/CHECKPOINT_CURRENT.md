# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read with `docs/AI_PROJECT_STATE.md`, `handover.md` and `CROSS_PLATFORM_PARITY_MATRIX.md`. GitHub/current repo state is authoritative. Do not restart completed platform implementation or touch live services during GitHub-only work.

## Current boundary

- Shared semantics/personalisation foundations: **COMPLETE**
- Web: **GITHUB/CODE COMPLETE**
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **GITHUB/CODE COMPLETE**
- Smart-TV/webOS: **GITHUB/CODE COMPLETE + PARITY VALIDATED**
- Cross-platform parity + recommendation quality: **COMPLETE for current GitHub/code evidence**
- Whole-product CI / release engineering: **CURRENT — REPLACEMENT FULL BUILD #137 RUNNING**

## Locked platform evidence

- Moonfin parity: workflow #132 / `34439296054` GREEN.
- Smart-TV parity: source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, workflow #52 / `34439022624` GREEN.
- Smart-TV candidate artifact `10137277340`, ZIP digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`.
- Production Android certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604` must not change.

## Whole-product CI / release engineering

Release gate covers Web + Android mobile/tablet + Android TV/Google TV; Smart-TV candidate is already validated separately.

Recent recovery:

- #135 / `34448096121`: all three candidates built; verifier proved `androidTv-beta` exposed Leanback as optional.
- Root cause: `androidTv-beta` is a sibling product flavour and did not automatically inherit `src/androidTv/AndroidManifest.xml`.
- `e655545cbbc9902e24bf30c5aa8a43a86b39ce9d`: explicitly maps beta flavour manifests to their mobile/TV source manifests.
- #136 / `34466334114`: **FAILED only in the custom-scope allowlist**. Route integration, catalogue, format, analyse, 114 focused tests and 12 Chrome tests passed. The build job was skipped because the gate rejected the intentional `android/app/build.gradle.kts` change.
- `90f3c7f2176751841729700acbda8ca21f75e4d3`: adds exactly `android/app/build.gradle.kts` to the narrow allowed scope; no further product code changed.

### Authoritative replacement gate

- workflow **#137 / `34557174599`**
- source `90f3c7f2176751841729700acbda8ca21f75e4d3`
- captured status: **IN PROGRESS**

Do not poll #137 again in this waiting cycle.

Acceptance requires:

- focused validation passes
- Web release builds
- `mobile-beta` and `androidTv-beta` APKs build
- beta package ID is `org.moonfin.androidtv.beta`
- mobile Leanback optional; Android-TV Leanback required
- both APKs share a CI signer that differs from production certificate
- candidate packaging succeeds
- artifact upload succeeds
- `BUILD_INFO.txt`, candidate SHA-256 values and artifact metadata are captured

CI APKs remain debug-fallback candidates, not deployment APKs.

## Known non-blocking CI debt

GitHub runner warnings remain for older Node-targeted action versions and setup-java v4 deprecation. Keep this maintenance separate until the release gate is green.

## Exact next actions

1. Next continuation: inspect **#137 / `34557174599` once**.
2. If failed, inspect only its failing job/step and fix the genuine failure.
3. If green, capture release artifact/signing/hash evidence and mark release engineering COMPLETE.
4. Move directly to **upstream-update automation/protocol integration**.

## Do not redo

- shared catalogue/compiler foundations
- Web completion
- Android mobile/tablet completion
- Android TV focus/deep-paging work
- webOS old-TV hardening
- high-rating provenance correction
- parity slices
- live services or physical-device acceptance

## Live boundary

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Physical/device/live acceptance remains deferred.
