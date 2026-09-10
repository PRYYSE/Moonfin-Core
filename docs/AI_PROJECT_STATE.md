# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

Primary repository: `PRYYSE/Moonfin-Core`  
Primary branch: `homelab/discovery-v2`  
Smart-TV repository: `PRYYSE/Smart-TV`  
Smart-TV branch: `homelab/webos-discovery-v2`

**Current phase:** cross-platform parity + recommendation quality. Platform-specific implementation remains complete and must not be reopened without evidence of a genuine defect.

## Completed platform foundations — do not redo

- Shared semantics/personalisation, bounded request cost, paging, cache, dedup and identity safeguards: COMPLETE.
- Catalogue/compiler: **486 authored / 481 active**; unsupported structural/context semantics fail closed.
- Web: GITHUB/CODE COMPLETE — source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`, workflow #115.
- Android mobile/tablet: GITHUB/CODE COMPLETE — source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN.
- Android TV / Google TV: GITHUB/CODE COMPLETE — final source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, workflow #128 / `34429841034` GREEN.
- Smart-TV/webOS: GITHUB/CODE COMPLETE — final product source `42854590caf4dbf847696483d943a886d5ab8ed7`, workflow #51 / `34432674158` GREEN.

Physical acceptance for all platforms remains deferred.

## Current parity evidence

Canonical matrix: `docs/homelab-discovery-v2/CROSS_PLATFORM_PARITY_MATRIX.md`.

Moonfin-Core Web, Android mobile/tablet and Android TV share the same Flutter Discovery semantic/runtime core. Platform-specific work is primarily presentation/input/focus behaviour. Enact/webOS is an independent implementation with old-TV-specific cost constraints.

### Aligned behaviour

- truthful personalisation provenance for history, favourites, watchlist, real high ratings, likes and mixed-positive sources
- generic affinity lanes separated from source-provenance claims
- membership/availability/requestability status semantics and blacklist/NSFW filtering
- TMDB-first Discovery identity with optional proven Jellyfin identity; local Jellyfin IDs are not promoted to TMDB IDs
- per-page and cross-row deduplication
- deterministic lane composition/rotation/cooldown
- sparse/underfilled row hiding and lane failure isolation
- bounded lane concurrency and deep-scan request cost
- unsupported structural/context semantics fail closed

The earlier webOS `high-ratings` mismatch is already fixed at `42854590caf4dbf847696483d943a886d5ab8ed7`: real Jellyfin `UserData.Rating >= 8` seeds, including anime alias, with truthful dynamic label. Do not reopen it.

### Intentional/stronger platform differences

- webOS remains at a truthful ceiling of **468 executable sections** from 481 active. Thirteen structural/context lanes are intentionally fail-closed; do not chase nominal parity.
- webOS truthfully supports dedicated `novelty`, `rewatch` and `anime-popular-but-not-in-your-library` source strategies that the Flutter client currently fails closed.
- These are **stronger implementations worth sharing only after equivalent Flutter source/library-resolution adapters are proven truthful and bounded**. Their current absence in Flutter is not a defect.
- webOS has stricter old-TV request-budget/cache mechanics; do not force identical internals where outcome/cost guarantees already align.

## Parity slice 1 — implementation committed

Moonfin-Core source commit: `572e32d54d14d0d50ba8066cd817d8938ffae572` (`feat(discovery): align refresh fallback and quality diagnostics`).

Changes:

- fixed one genuine shared-Flutter parity defect: a total explicit refresh failure now retains the last good tab rather than replacing it with failure state; partial fresh results remain authoritative and are not replaced by stale data
- added focused regression tests for total-refresh fallback and partial-refresh behaviour
- added shared Flutter privacy-safe aggregate recommendation-quality diagnostics equivalent in purpose to webOS diagnostics
- aggregate metrics cover duplicate ratio, unique/repeated cards, missing poster/backdrop/identity, owned ratio, underfilled lanes, hidden/failed lanes, refresh failure and per-section counts
- diagnostic serialisation contains no media titles, TMDB IDs or Jellyfin IDs
- no recommendation source/ranking weights changed

Push workflow **#129 / `34436206490`** for source `572e32d54d14d0d50ba8066cd817d8938ffae572` was **IN PROGRESS** when this state was written. Do not continuously poll it. On the next continuation inspect that exact run once, then either fix a genuine failure or record success.

Local shell checkout was unavailable in the execution environment because GitHub DNS resolution failed, so CI is the authoritative focused validation for this slice. The GitHub API commit itself succeeded atomically.

## Recommendation-quality rule

Do not tune ranking from synthetic fixtures. Unit tests may validate state transitions, dedup/counting and privacy only. The aggregate analyser is instrumentation, not ranking logic.

Use real Home Lab aggregate diagnostic evidence before changing recommendation diversity/source/ranking behaviour. Privacy-safe evidence is sufficient: duplicate ratio, underfilled-lane count, missing-poster ratio, owned ratio, hidden/failed lanes and per-section counts. Avoid exposing titles/Jellyfin IDs unnecessarily.

If real evidence cannot be obtained without crossing the current no-live-service boundary, defer ranking tuning rather than guess, and continue to the next GitHub-only stage after parity correctness is validated.

## Android TV / Google TV final evidence

Final full candidate workflow **#128 / `34429841034`**:

- focused job `102722801700` GREEN
- Web + mobile-beta + androidTv-beta job `102723571678` GREEN
- Discovery **107 passed / 5 skipped**
- Chrome **12 passed**
- route, 486-lane catalogue + 8 Python tests, format, analyse and scope gates PASS
- representative 1920x1080 and 3840x2160 off-screen focus/scroll regression PASS
- Web release, mobile-beta APK and androidTv-beta APK built successfully
- app `2.5.1+30000149`; TV `2.5.1` build `2000016`; Flutter `3.44.1`
- Android TV APK SHA-256 `39406273a5cf6d5cfb3d0a3316fb08b8cee6a5feec985056d51829096981279f`
- mobile APK SHA-256 `a9aaa9b32735e59c2ff9530a7a52c27d6a22c8b8fbbbd608da095c511fa88819`
- Web tar.gz SHA-256 `97084634a83e2d4ddf84976d0176bcf35d3ebea3ba11e04c6621af02f7e768e1`
- artifact `10134675199`, ZIP digest `sha256:c3f45b293d5d0b17b0e0086aa6f1724eaf6566d936e91840a0c23cbe0262014e`
- CI Android signing remains `debug-fallback-not-for-deployment`

Production Android signing certificate SHA-256 invariant remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate or replace it.

## Smart-TV/webOS final evidence

Final product source `42854590caf4dbf847696483d943a886d5ab8ed7`; required workflow **#51 / `34432674158`** GREEN:

- 16/16 Discovery/integration suites
- **86/86 tests**
- strict Enact lint PASS
- legacy CSS/WebKit check PASS
- legacy compatibility patch stage: 17 files modified, 0 skipped
- optimized production Enact build PASS
- webOS IPK packaging PASS
- identity verification PASS: `org.moonfin.webos` / `2.7.0` / `index.html`
- IPK SHA-256 `80a54d415b99c813b893c6abc7b465fa8f383244be01aab791cd9aefd0a90d10`
- artifact `10135098617`, size `4,312,912` bytes
- artifact ZIP digest `sha256:7b7b1f60d05587a59fbd5913d0f3762fad150529c5e1a0a5f09bba09c8bd7c67`

Preserve Smart-TV rollback/reference branch `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`. Do not replace the Enact client with Flutter Web.

## Live / physical boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Existing archive/recovery refs remain intact.

No physical-device acceptance is claimed by CI. Actual phone/tablet, Android TV and LG webOS installation/update/playback/request/lifecycle checks belong to the later live acceptance stage.

## Non-blocking release/tooling debt

The Smart-TV #51 build reports legacy dependency audit/deprecation warnings, including Node 20 action warnings and old browser compatibility metadata. Do not blindly upgrade the legacy Enact/WebKit stack during parity work; assess this deliberately in the whole-product CI/release-engineering stage.

## Exact next actions

1. Inspect Moonfin-Core workflow #129 / `34436206490` once.
2. If green, record parity slice 1 as validated. If failed, inspect only its failing job/step and fix the genuine failure.
3. Continue from `CROSS_PLATFORM_PARITY_MATRIX.md` without reopening completed platform stages.
4. Do not enable Flutter novelty/rewatch/anime-not-owned until equivalent truthful bounded adapters are proven.
5. Use real privacy-safe Home Lab aggregate diagnostics before any ranking/diversity tuning; if those are unavailable under the no-live boundary, defer ranking tuning and advance to whole-product CI/release engineering.

## Later stages

1. cross-platform parity + recommendation quality — **CURRENT**
2. whole-product CI/release engineering
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance
