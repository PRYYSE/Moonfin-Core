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
- #135 / `34448096121`: genuine beta packaging defect; `androidTv-beta` did not inherit the TV manifest and reported Leanback optional.
- `e655545cbbc9902e24bf30c5aa8a43a86b39ce9d`: fixed Gradle source-set wiring so beta flavours explicitly reuse their mobile/TV manifests.
- #136 / `34466334114`: failed only because the narrow scope gate rejected the intentional `android/app/build.gradle.kts` packaging fix; focused validation passed.
- `90f3c7f2176751841729700acbda8ca21f75e4d3`: allowed exactly `android/app/build.gradle.kts` in the Discovery v2 scope gate.
- #137 / `34557174599`: focused validation, scope gate, Web, mobile-beta and androidTv-beta builds all passed; failed only in signing verifier before packaging/upload.
- `3169a39c834c5b5e3bead0578449dd0453f55b99`: added explicit `apksigner` diagnostics while retaining package/Leanback/same-signer/non-production gates.
- #138 / `34559041907`: **FAILED only in signer SHA-256 parsing** after focused validation and all three candidate builds passed. Exact current `apksigner` evidence: `V2 Signer: certificate SHA-256 digest: e2f6179d4bf86c09eaa512a6533e256a464086a60239a097695263585c2113cd`. The hardened verifier was still tied to the older `Signer #1 ...` prefix. The observed mobile CI signer is already distinct from production.
- `fd06ec5602351e53f0eacb56b2457ad0e80f169e`: changed only the digest parser to accept arbitrary signer prefixes ending in `certificate SHA-256 digest:` while still requiring a valid 64-hex digest, same signer on both APKs and a signer different from protected production signing.

Authoritative replacement full-build:

- workflow **#139 / `34571653740`**
- source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- captured status: **IN PROGRESS**

Do not poll #139 again in this waiting cycle.

Current release checks still require:

- both beta APKs identify as `org.moonfin.androidtv.beta`
- mobile Leanback optional
- Android-TV Leanback required
- both APKs use the same CI signing certificate
- CI signer differs from production SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- `BUILD_INFO.txt` records source/build/flavour/signing/Leanback metadata
- SHA-256 values generated for Web/mobile/Android-TV candidates
- candidate bundle uploads successfully

CI APKs are debug-fallback candidates and are **not deployment APKs**.

## Known non-blocking CI debt

Runner warnings remain for Node-20-targeted GitHub Action runtimes (`actions/checkout@v4`, `actions/setup-java@v4`) and setup-java v4 deprecation. Android also warns that future Flutter versions will require Built-in Kotlin migration. None caused #133–#138. Keep this maintenance separate until the release gate is green.

## Exact next actions

1. Next continuation: inspect **#139 / `34571653740` once**.
2. If failed, inspect only the failing job/step and fix the genuine release-gate issue.
3. If green, capture artifact ID/digest, `BUILD_INFO.txt`, actual CI signer SHA-256 and Web/mobile/Android-TV candidate SHA-256 values; mark whole-product CI/release engineering COMPLETE.
4. Then move directly to **upstream-update automation/protocol integration**.

## Later stages

1. cross-platform parity + recommendation quality — **COMPLETE for GitHub/code evidence**
2. whole-product CI/release engineering — **CURRENT; replacement full build #139 running**
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
