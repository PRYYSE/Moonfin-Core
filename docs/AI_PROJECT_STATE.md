# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

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
- Smart-TV/webOS pre-parity baseline: `42854590caf4dbf847696483d943a886d5ab8ed7`, workflow #51 / `34432674158` GREEN.
- Earlier webOS high-rating provenance correction is complete; do not reopen.
- webOS intentionally remains at **468 executable / 481 active**; 13 structural/context strategies remain fail-closed.
- Preserve Smart-TV rollback branch `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.
- Production Android signing certificate SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate/replace it.

## Cross-platform parity + recommendation quality — COMPLETE for GitHub/code evidence

Canonical semantic evidence: `docs/homelab-discovery-v2/CROSS_PLATFORM_PARITY_MATRIX.md`.

Parity slice 1:

- implementation `572e32d54d14d0d50ba8066cd817d8938ffae572`
- format correction `9ccb89927ca23bb4d3f00043f70ba138a6239beb`
- workflow #130 / `34436806830` GREEN

Parity slice 2:

- Moonfin product `b800e5be18109963e4ae00b3739550b924c7204f`
- Moonfin format-only follow-up `e654668f89af49470df417d4fcc444e73c53121e`
- Moonfin workflow **#132 / `34439296054` GREEN**
- Smart-TV product `a9dfa657a220a3f8f77753261bd7d8e902c0d837`
- Smart-TV workflow **#52 / `34439022624` GREEN**

Resolved semantics remain locked: bounded novelty, truthful `Something Different in Anime`, positive-only rewatch, aligned anime detection, dormant popular-anime-not-library support, structural/context fail-closed semantics and no ranking/source-weight tuning from synthetic fixtures.

Real recommendation-quality tuning is deferred because privacy-safe production aggregate evidence would cross the current no-live boundary.

## Whole-product CI / release engineering — CURRENT

Scope is Web + Android mobile/tablet + Android TV/Google TV + Smart-TV/webOS. Do not broaden this phase into unrelated upstream iOS/macOS/Windows/Linux release work.

Smart-TV release candidate is already validated by workflow #52:

- artifact ID `10137277340`
- name `Moonfin-HomeLab-webOS-DiscoveryV2-a9dfa657a220a3f8f77753261bd7d8e902c0d837`
- size `4,312,826` bytes
- ZIP digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`

### Flutter candidate gate recovery

Initial hardening source:

`de783e5af94f528d319c6f469e977d129bbc4435` — `ci(discovery): harden release candidate verification [full-build]`

Workflow **#133 / `34440033993` FAILED only in the new Android candidate verifier** after focused validation and all three candidate builds passed. The verifier initially tested the wrong Leanback distinction.

Verifier-contract correction:

`4f8dbec00b51800d7bf8d0ec321807207623bbfc` — `ci(discovery): verify leanback requirement split [full-build]`

Workflow **#134 / `34442473966` also FAILED only in the verifier** after focused validation and all three builds passed. Its mobile APK already reported the intended optional Leanback semantic, but `aapt dump badging` prefixed the valid line with whitespace.

Whitespace-normalisation correction:

`41cfa0f33a392706a37c3c9ade13c575484597c1` — `ci(discovery): normalise aapt leanback badging [full-build]`

Workflow **#135 / `34448096121` FAILED only in `Verify Android candidate identity and signing`**. Focused validation, Web release, mobile-beta APK and androidTv-beta APK all built successfully before packaging/upload were skipped.

Exact #135 TV evidence:

`Observed TV Leanback badging: uses-feature-not-required: name='android.software.leanback'`

This exposed a genuine beta flavour packaging/source-set defect rather than another verifier formatting problem:

- Gradle defines four sibling product flavours in the same `device` dimension: `mobile`, `mobile-beta`, `androidTv`, `androidTv-beta`.
- `src/androidTv/AndroidManifest.xml` correctly declares `android.software.leanback` required and the TV-specific launcher/device semantics.
- Android Gradle Plugin source sets are selected by the exact product-flavour name; sibling `androidTv-beta` therefore did not automatically inherit `src/androidTv/AndroidManifest.xml`.
- Likewise, `mobile-beta` did not automatically inherit `src/mobile/AndroidManifest.xml`, although that source file is currently intentionally empty.

Root-cause wiring fix:

`e655545cbbc9902e24bf30c5aa8a43a86b39ce9d` — `fix(android): share device manifests with beta flavours [full-build]`

The fix changes only `android/app/build.gradle.kts` source-set wiring so:

- `mobile-beta` explicitly reuses `src/mobile/AndroidManifest.xml`
- `androidTv-beta` explicitly reuses `src/androidTv/AndroidManifest.xml`

No Dart application code, Discovery catalogue/recommendation semantics, production signing material or live systems changed.

Current release checks still require:

- both beta APKs identify as `org.moonfin.androidtv.beta`
- mobile reports Leanback optional
- Android TV reports Leanback required
- both APKs use the same CI signing certificate
- CI certificate differs from production SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- `BUILD_INFO.txt` records the requirement split and signing identities
- CI candidates remain debug-fallback and are not deployment APKs

Authoritative replacement full-build:

- workflow **#136 / `34466334114`**
- source `e655545cbbc9902e24bf30c5aa8a43a86b39ce9d`
- status at the single capture: **IN PROGRESS**

Do not poll #136 again in this waiting cycle.

### Release-engineering acceptance gate

Before closing this phase, #136 must pass focused validation, Web/mobile-beta/androidTv-beta builds, Android identity/Leanback/signing verification, packaging and artifact upload. If green, record artifact ID/digest, `BUILD_INFO.txt`, actual CI signer SHA-256 and generated Web/mobile/Android-TV candidate SHA-256 values. No deployment or physical/live acceptance belongs to this phase.

## Known non-blocking CI debt

Current runner logs warn that `actions/checkout@v4` / `actions/setup-java@v4` target deprecated Node 20 action runtimes and that setup-java v4 is deprecated. These warnings did not cause #133–#135. Keep that maintenance separate from release-gate recovery so any tooling migration remains separately attributable.

## Exact next actions

1. On the next continuation inspect **#136 / `34466334114` once**.
2. If failed, inspect only the failing job/step and fix the genuine release-gate failure.
3. If green, capture artifact ID/digest, build metadata, signing identity and Web/mobile/Android-TV candidate hashes; mark whole-product CI/release engineering complete.
4. Then move directly to **upstream-update automation/protocol integration**.

## Later stages

1. cross-platform parity + recommendation quality — **COMPLETE for GitHub/code evidence**
2. whole-product CI/release engineering — **CURRENT; replacement full build #136 running**
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
