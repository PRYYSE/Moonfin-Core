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
- Whole-product CI / release engineering: **CURRENT — REPLACEMENT FULL BUILD #139 RUNNING**

## Locked platform evidence

- Moonfin parity: workflow #132 / `34439296054` GREEN.
- Smart-TV parity: source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, workflow #52 / `34439022624` GREEN.
- Smart-TV candidate artifact `10137277340`, ZIP digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`.
- Production Android certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604` must not change.

## Whole-product CI / release engineering

Release gate covers Web + Android mobile/tablet + Android TV/Google TV; Smart-TV candidate is already validated separately.

Recent recovery:

- #135 / `34448096121`: all three candidates built; verifier exposed missing TV-manifest inheritance in `androidTv-beta`.
- `e655545cbbc9902e24bf30c5aa8a43a86b39ce9d`: explicitly maps beta flavours to corresponding mobile/TV manifests.
- #136 / `34466334114`: failed only because custom-scope allowlist rejected the intentional Gradle packaging change.
- `90f3c7f2176751841729700acbda8ca21f75e4d3`: adds exactly `android/app/build.gradle.kts` to the narrow scope allowlist.
- #137 / `34557174599`: focused validation, scope gate, Web, mobile-beta and androidTv-beta builds all passed; signing verifier failed before packaging/upload.
- `3169a39c834c5b5e3bead0578449dd0453f55b99`: added explicit signer diagnostics.
- #138 / `34559041907`: focused validation and all three builds again passed; only signer parsing failed. Current `apksigner` emitted: `V2 Signer: certificate SHA-256 digest: e2f6179d4bf86c09eaa512a6533e256a464086a60239a097695263585c2113cd`. This signer differs from protected production signing.
- `fd06ec5602351e53f0eacb56b2457ad0e80f169e`: parser now accepts the current signer prefix while preserving 64-hex validation, same-CI-signer equality and production-certificate inequality.

### Authoritative replacement gate

- workflow **#139 / `34571653740`**
- source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- captured status: **IN PROGRESS**

Do not poll #139 again in this waiting cycle.

Acceptance still requires:

- focused validation passes
- Web release builds
- `mobile-beta` and `androidTv-beta` APKs build
- beta package ID is `org.moonfin.androidtv.beta`
- mobile Leanback optional; Android-TV Leanback required
- both APKs share a CI signer different from protected production certificate
- candidate packaging succeeds
- artifact upload succeeds
- `BUILD_INFO.txt`, candidate SHA-256 values and artifact metadata are captured

CI APKs remain debug-fallback candidates, not deployment APKs.

## Known non-blocking CI debt

GitHub runner warnings remain for older Node-targeted action versions and setup-java v4 deprecation. Flutter also warns about future Built-in Kotlin migration. Keep this maintenance separate until the current release gate is green.

## Exact next actions

1. Next continuation: inspect **#139 / `34571653740` once**.
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
