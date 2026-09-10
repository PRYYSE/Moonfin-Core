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

### Flutter candidate gate

Initial hardening source:

`de783e5af94f528d319c6f469e977d129bbc4435` — `ci(discovery): harden release candidate verification [full-build]`

Workflow **#133 / `34440033993` FAILED only in the new Android candidate verifier**. Its focused-validation job passed completely, and the release job successfully built Web, mobile-beta APK and androidTv-beta APK before the verifier failed. Packaging/upload were skipped after that gate.

Root cause was a verifier-contract mistake, not an application defect:

- the shared Android manifest intentionally contains both `LAUNCHER` and `LEANBACK_LAUNCHER`
- mobile keeps `android.software.leanback` **optional**
- the Android-TV flavour makes `android.software.leanback` **required**
- the failed verifier incorrectly expected a mobile-vs-TV launcher-category split and searched for a non-authoritative `leanback-launcher:` badging line

Verifier-only correction:

`4f8dbec00b51800d7bf8d0ec321807207623bbfc` — `ci(discovery): verify leanback requirement split [full-build]`

The corrected gate now verifies:

- both beta APKs identify as `org.moonfin.androidtv.beta`
- mobile APK reports Leanback as optional
- Android-TV APK reports Leanback as required
- both APKs have the same CI signing certificate
- CI certificate is not production SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- BUILD_INFO records the actual Leanback requirement split and both signing identities
- CI candidates remain debug-fallback and are not deployment APKs

Authoritative replacement full-build:

- workflow **#134 / `34442473966`**
- source `4f8dbec00b51800d7bf8d0ec321807207623bbfc`
- status at the single capture: **IN PROGRESS**

Do not poll #134 again in this waiting cycle.

### Release-engineering acceptance gate

Before closing this phase, #134 must pass focused validation plus Web/mobile-beta/androidTv-beta build, Android identity/Leanback/signing verification, packaging and artifact upload. Then record artifact ID/digest, `BUILD_INFO.txt`, and generated candidate SHA-256 values. No deployment or physical/live acceptance belongs to this phase.

## Known non-blocking CI debt

Current GitHub runner logs warn that `actions/checkout@v4` / `actions/setup-java@v4` target deprecated Node 20 action runtimes and that setup-java v4 should move to v5. These warnings did not cause #133. Do not mix that maintenance into the verifier recovery; assess it after the authoritative release gate is green so a tooling migration is separately attributable.

## Environment limitation

The current execution container cannot resolve `github.com` and has no useful local Flutter checkout. GitHub Actions remains the authoritative Flutter/analyse/build gate. GitHub API writes must remain narrow and current branch state is authoritative.

## Exact next actions

1. On the next continuation inspect **#134 / `34442473966` once**.
2. If failed, inspect only the failing job/step and fix the genuine failure.
3. If green, capture artifact ID/digest, build metadata, signing identity and Web/mobile/Android-TV candidate hashes; mark whole-product CI/release engineering complete.
4. Then move to **upstream-update automation/protocol integration**.

## Later stages

1. cross-platform parity + recommendation quality — **COMPLETE for GitHub/code evidence**
2. whole-product CI/release engineering — **CURRENT; replacement full build running**
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
