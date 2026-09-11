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
- Whole-product CI / release engineering: **CURRENT — REPLACEMENT FULL BUILD #138 QUEUED**

## Locked platform evidence

- Moonfin parity: workflow #132 / `34439296054` GREEN.
- Smart-TV parity: source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, workflow #52 / `34439022624` GREEN.
- Smart-TV candidate artifact `10137277340`, ZIP digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`.
- Production Android certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604` must not change.

## Whole-product CI / release engineering

Release gate covers Web + Android mobile/tablet + Android TV/Google TV; Smart-TV candidate is already validated separately.

Recent recovery:

- #135 / `34448096121`: all three candidates built; verifier exposed missing TV-manifest inheritance in `androidTv-beta`.
- `e655545cbbc9902e24bf30c5aa8a43a86b39ce9d`: explicitly maps beta flavours to the corresponding mobile/TV manifests.
- #136 / `34466334114`: failed only because the custom-scope allowlist rejected that intentional Gradle packaging change.
- `90f3c7f2176751841729700acbda8ca21f75e4d3`: adds exactly `android/app/build.gradle.kts` to the narrow scope allowlist.
- #137 / `34557174599`: focused validation, scope gate, Web release build, mobile-beta APK and androidTv-beta APK all **PASSED**. It failed only in `Verify Android candidate identity and signing`; no Leanback error was emitted, so the beta manifest wiring advanced past that contract check. Packaging/upload were skipped.
- The #137 failure occurred during the old signer extraction/check pipeline and produced no diagnostic under `set -e`, making the precise signer parse/check failure opaque.
- `3169a39c834c5b5e3bead0578449dd0453f55b99`: hardens only signer verification/diagnostics. It captures `apksigner` output explicitly, accepts leading whitespace on the SHA-256 line, requires a valid 64-hex digest, and reports verification, parse or signer-mismatch failures while retaining the production-certificate inequality guard.

### Authoritative replacement gate

- workflow **#138 / `34559041907`**
- source `3169a39c834c5b5e3bead0578449dd0453f55b99`
- captured status: **QUEUED**

Do not poll #138 again in this waiting cycle.

Acceptance still requires:

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

GitHub runner warnings remain for older Node-targeted action versions and setup-java v4 deprecation. Flutter also warns about future Built-in Kotlin migration. Keep this maintenance separate until the current release gate is green.

## Exact next actions

1. Next continuation: inspect **#138 / `34559041907` once**.
2. If failed, inspect only its failing job/step and use the explicit signer diagnostic to fix the genuine failure.
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
