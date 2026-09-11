# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code for Home Lab Moonfin Discovery v2 before physical-device, live-service or production acceptance.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`  
Smart-TV repo/branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`

**Current phase:** whole-product CI / release engineering.

## Completed foundations — do not redo

- Shared Discovery catalogue/compiler and Flutter semantics/personalisation foundations: COMPLETE.
- Authoring catalogue: **486 lanes**; accepted compiled baseline: **481 active**.
- Web: code complete, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`, workflow #115.
- Android mobile/tablet: code complete, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN.
- Android TV / Google TV: code complete, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, workflow #128 / `34429841034` GREEN.
- Smart-TV/webOS parity candidate: source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, workflow #52 / `34439022624` GREEN.
- webOS intentionally remains **468 executable / 481 active**; 13 structural/context strategies fail closed.
- Cross-platform parity/recommendation semantics are COMPLETE for GitHub/code evidence; do not tune ranking from synthetic fixtures.
- Preserve Smart-TV rollback branch `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.
- Production Android signing certificate SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate/replace it.

## Smart-TV release candidate — validated

- artifact ID `10137277340`
- name `Moonfin-HomeLab-webOS-DiscoveryV2-a9dfa657a220a3f8f77753261bd7d8e902c0d837`
- size `4,312,826` bytes
- ZIP digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`

## Flutter whole-product release gate — CURRENT

Required gate: focused validation + Web release build + mobile-beta APK + androidTv-beta APK + package identity + Leanback contract + CI signing checks + packaging + artifact upload.

Recovery sequence:

- #133 / `34440033993`: verifier contract bug after all three candidate builds passed.
- #134 / `34442473966`: verifier whitespace bug after all three candidate builds passed.
- #135 / `34448096121`: genuine beta packaging defect; built `androidTv-beta` APK reported Leanback optional because sibling flavour `androidTv-beta` did not inherit `src/androidTv/AndroidManifest.xml`.
- `e655545cbbc9902e24bf30c5aa8a43a86b39ce9d`: fixed Gradle source-set wiring so `mobile-beta` reuses the mobile manifest and `androidTv-beta` reuses the Android-TV manifest.
- #136 / `34466334114`: **FAILED only in `Verify custom scope stays narrow`**. Route/catalogue/format/analyse/focused tests/Web tests all passed; build job was skipped. Exact rejected path was the intentional `android/app/build.gradle.kts` packaging fix.
- `90f3c7f2176751841729700acbda8ca21f75e4d3`: scope-gate-only correction adding exactly `android/app/build.gradle.kts` to the Discovery v2 allowlist. No additional product code changed.

Authoritative replacement full-build:

- workflow **#137 / `34557174599`**
- source `90f3c7f2176751841729700acbda8ca21f75e4d3`
- captured status: **IN PROGRESS**

Do not poll #137 again in this waiting cycle.

Current release checks still require:

- both beta APKs identify as `org.moonfin.androidtv.beta`
- mobile Leanback optional
- Android-TV Leanback required
- same CI signer on both APKs
- CI signer differs from production SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- `BUILD_INFO.txt` records source/build/flavour/signing/Leanback metadata
- SHA-256 values generated for Web/mobile/Android-TV candidates
- candidate bundle uploads successfully

CI APKs are debug-fallback candidates and are **not deployment APKs**.

## Known non-blocking CI debt

Runner warnings remain for Node-20-targeted GitHub Action runtimes (`actions/checkout@v4`, `actions/setup-java@v4`) and setup-java v4 deprecation. They have not caused the release-gate failures. Keep this maintenance separate until the release gate is green.

## Exact next actions

1. Next continuation: inspect **#137 / `34557174599` once**.
2. If failed, inspect only the failing job/step and fix the genuine failure.
3. If green, capture artifact ID/digest, `BUILD_INFO.txt`, actual CI signer SHA-256 and Web/mobile/Android-TV candidate SHA-256 values; mark whole-product CI/release engineering COMPLETE.
4. Then move directly to **upstream-update automation/protocol integration**.

## Later stages

1. cross-platform parity + recommendation quality — **COMPLETE for GitHub/code evidence**
2. whole-product CI/release engineering — **CURRENT; replacement full build #137 running**
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
