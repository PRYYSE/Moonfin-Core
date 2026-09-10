# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

Primary repository: `PRYYSE/Moonfin-Core`  
Primary branch: `homelab/discovery-v2`  
Smart-TV repository: `PRYYSE/Smart-TV`  
Smart-TV branch: `homelab/webos-discovery-v2`

**Current phase:** platform-specific Discovery v2 implementation is complete across Web, Android mobile/tablet, Android TV/Google TV and webOS. **Next stage: cross-platform parity + recommendation quality.**

## Completed platform foundations — do not redo

- Shared semantics/personalisation, bounded request cost, paging, cache, dedup and identity safeguards: COMPLETE.
- Catalogue/compiler: **486 authored / 481 active**; unsupported structural/context semantics fail closed.
- Web: GITHUB/CODE COMPLETE — source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`, workflow #115.
- Android mobile/tablet: GITHUB/CODE COMPLETE — source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN.
- Android TV / Google TV: GITHUB/CODE COMPLETE — final source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, workflow #128 / `34429841034` GREEN.
- Smart-TV/webOS: GITHUB/CODE COMPLETE — final product source `42854590caf4dbf847696483d943a886d5ab8ed7`, workflow #51 / `34432674158` GREEN.

Physical acceptance for all platforms remains deferred.

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

Final semantic reconciliation found one genuine defect: lanes advertised highest user ratings but webOS sourced `high-ratings` from Likes + Favourites. Source `42854590caf4dbf847696483d943a886d5ab8ed7` now uses one bounded Jellyfin candidate query with real `UserData.Rating >= 8` seeds, including the anime alias, and corrects the dynamic heading to `Because You Rated ... Highly`. This reduces source fan-out from two Jellyfin calls to one.

Required workflow **#51 / `34432674158`** GREEN:

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

webOS intentionally remains at a truthful static ceiling of **468 executable sections**. Thirteen structural/context lanes remain fail-closed until their semantics can be independently proven at acceptable old-LG cost; do not chase 481/481 for its own sake.

## Next stage — cross-platform parity + recommendation quality

Build an explicit semantic/behaviour matrix across:

- Moonfin-Core Web
- Android mobile/tablet
- Android TV / Google TV
- Smart-TV Enact/webOS

Compare advertised behaviour rather than demanding identical implementation internals. Priority areas:

- personalisation strategy support and source provenance
- novelty, rotation and rewatch behaviour
- anime/not-owned semantics
- membership, availability and requestability
- TMDB/Jellyfin identity and detail routing
- dedup, sparse-row handling and underfill behaviour
- refresh/reset/retained-state semantics
- deep paging/retry and bounded request cost
- presentation parity where platform mechanics differ
- recommendation diversity/repeat/quality diagnostics

Preserve stronger truthful platform-specific source implementations. Do not copy obsolete slot/hash behaviour into webOS. Keep unsupported structural/context semantics fail-closed until proven.

Recommendation-quality tuning should be evidence-driven. Synthetic tests establish correctness; actual Home Lab catalogue/diagnostic data should drive ranking/diversity tuning when available.

## Later stages

1. cross-platform parity + recommendation quality — **NEXT**
2. whole-product CI/release engineering
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance

## Live / physical boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Existing archive/recovery refs remain intact.

No physical-device acceptance is claimed by CI. Actual phone/tablet, Android TV and LG webOS installation/update/playback/request/lifecycle checks belong to the later live acceptance stage.

## Non-blocking release/tooling debt

The Smart-TV #51 build reports legacy dependency audit/deprecation warnings, including Node 20 action warnings and old browser compatibility metadata. Do not blindly upgrade the legacy Enact/WebKit stack during parity work; assess this deliberately in the whole-product CI/release-engineering stage.

## Exact next actions

1. Read `handover.md`, this file and the current platform checkpoint files.
2. Reconcile them against current GitHub HEADs; repo state wins.
3. Start the cross-platform semantic/behaviour matrix from the verified platform sources above.
4. Fix only evidence-backed parity defects; do not reopen completed platform implementation by default.
5. Use real Home Lab recommendation diagnostics when available for quality tuning, while keeping live services unchanged until the later acceptance phase.
