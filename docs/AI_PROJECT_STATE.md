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

Canonical semantic evidence remains `docs/homelab-discovery-v2/CROSS_PLATFORM_PARITY_MATRIX.md`.

### Parity slice 1

Implementation `572e32d54d14d0d50ba8066cd817d8938ffae572`; format-only correction `9ccb89927ca23bb4d3f00043f70ba138a6239beb`.

Workflow #130 / `34436806830` GREEN.

Validated:

- explicit-refresh total-failure fallback retains last good Flutter tab while partial fresh results stay authoritative
- privacy-safe aggregate recommendation-quality diagnostics
- state/privacy regression coverage
- no ranking/source-weight changes

### Parity slice 2

Moonfin product source `b800e5be18109963e4ae00b3739550b924c7204f`; formatter-only follow-up `e654668f89af49470df417d4fcc444e73c53121e`.

Workflow **#132 / `34439296054` GREEN**. Its focused-validation job passed route integration, authoring catalogue + 8 Python tests, format, analyse, Flutter Discovery tests, Chrome interaction tests and custom-scope verification. Candidate build was intentionally skipped because this was not a full-build trigger.

Smart-TV parity source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`.

Workflow **#52 / `34439022624` GREEN**. `validate-and-package` passed Discovery service tests, webOS package build, preserved app identity/package verification and candidate upload.

Resolved parity semantics:

- generic novelty uses bounded random-source semantics on both clients
- anime novelty is truthfully presented as `Something Different in Anime`; neither client claims proven exclusion of the user's usual genres
- rewatch requires positive played evidence rather than neutral recent history
- Flutter source anime detection includes tags/genre or Animation + Japanese language/origin
- dormant popular-anime-not-library support remains dormant; no lane was added merely for parity
- unsupported structural/context strategies remain fail-closed

### Recommendation-quality boundary

No ranking weights or source preferences were tuned from synthetic fixtures. Real Home Lab privacy-safe aggregate evidence is required for ranking changes. Because obtaining that evidence crosses the current no-live-service boundary, recommendation tuning is deferred rather than guessed.

## Whole-product CI / release engineering — CURRENT

Project release scope is the four implemented client surfaces: Web, Android mobile/tablet, Android TV/Google TV and Smart-TV/webOS. Do not broaden this stage into unrelated upstream iOS/macOS/Windows/Linux release work.

Existing Home Lab workflow `.github/workflows/homelab-discovery-v2.yml` is the authoritative Flutter candidate path. A `[full-build]` push runs focused validation and then builds:

- Web release candidate
- Android `mobile-beta` release APK
- Android `androidTv-beta` release APK with `MOONFIN_FORCE_TV=true`
- `BUILD_INFO.txt` and SHA-256 sums

CI Android candidates intentionally use debug fallback signing and are **not deployment APKs**. Production signing identity must remain untouched.

Smart-TV workflow #52 already produced the current webOS candidate artifact:

- artifact ID `10137277340`
- artifact name `Moonfin-HomeLab-webOS-DiscoveryV2-a9dfa657a220a3f8f77753261bd7d8e902c0d837`
- size `4,312,826` bytes
- ZIP digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`

### Release-engineering acceptance gate

Before closing this phase:

1. Harden the Flutter candidate workflow so the built Android beta APKs verify expected package identity, mobile-vs-TV Leanback distinction and actual CI signing certificate.
2. Assert the CI certificate is not the preserved production certificate.
3. Trigger the Home Lab workflow with `[full-build]` from the current parity-complete branch.
4. Require focused validation and Web/mobile-beta/androidTv-beta candidate build/package/upload to pass.
5. Record exact workflow/run, artifact ID/digest and generated candidate SHA-256 values.
6. Do not deploy or perform physical/live acceptance in this phase.

## Environment limitation

The current execution container cannot resolve `github.com` and has no useful local Flutter checkout. GitHub Actions remains the authoritative Flutter/analyse/build gate. GitHub API writes must remain narrow and branch state is authoritative.

## Exact next actions

1. Apply the narrow candidate identity/signing verification hardening to `.github/workflows/homelab-discovery-v2.yml`.
2. Commit it with `[full-build]` so the parity-complete branch produces fresh Web/mobile/Android TV candidates.
3. Record the exact run ID, update this checkpoint, then stop polling if the run is still active.
4. On continuation, inspect that exact run once. Fix only genuine failures.
5. If green, capture artifact metadata/hashes and mark whole-product CI/release engineering complete.
6. Then move to **upstream-update automation/protocol integration**.

## Later stages

1. cross-platform parity + recommendation quality — **COMPLETE for GitHub/code evidence**
2. whole-product CI/release engineering — **CURRENT**
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
