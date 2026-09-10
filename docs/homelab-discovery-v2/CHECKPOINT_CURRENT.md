# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this with `docs/AI_PROJECT_STATE.md` and `handover.md`. GitHub/current repo state is authoritative. Do not restart completed platform implementation or touch live services during GitHub-only work.

## Current boundary

- Shared semantics/personalisation: **COMPLETE**
- Web: **GITHUB/CODE COMPLETE**
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **GITHUB/CODE COMPLETE**
- Smart-TV/webOS: **GITHUB/CODE COMPLETE**
- Next stage: **CROSS-PLATFORM PARITY + RECOMMENDATION QUALITY**

## Android TV final gate

Final source `15ccc28b84727543ad714ef19dd318f907d1a1d8`; workflow #128 / `34429841034` GREEN.

- Discovery 107 passed / 5 skipped
- Chrome 12 passed
- route, 486-lane catalogue + 8 Python tests, format, analyse and scope PASS
- 1920x1080 + 3840x2160 off-screen TV focus/scroll regression PASS
- Web + mobile-beta + androidTv-beta release candidates built
- TV APK SHA-256 `39406273a5cf6d5cfb3d0a3316fb08b8cee6a5feec985056d51829096981279f`
- artifact `10134675199`, ZIP digest `sha256:c3f45b293d5d0b17b0e0086aa6f1724eaf6566d936e91840a0c23cbe0262014e`
- app `2.5.1+30000149`; TV `2.5.1` build `2000016`; Flutter `3.44.1`
- CI signing is debug fallback only; production certificate SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

## Smart-TV/webOS final gate

Repo `PRYYSE/Smart-TV`, branch `homelab/webos-discovery-v2`.

Final product source `42854590caf4dbf847696483d943a886d5ab8ed7`; workflow #51 / `34432674158` GREEN.

Final reconciliation corrected one genuine semantic mismatch: `high-ratings` now uses real Jellyfin `UserData.Rating >= 8` seeds rather than Likes + Favourites; anime inherits the same source and the dynamic label now truthfully says `Because You Rated ... Highly`.

Evidence:

- 16/16 Discovery/integration suites
- 86/86 tests
- strict Enact lint PASS
- legacy CSS/WebKit check PASS
- production Enact build PASS
- webOS IPK packaging PASS
- package identity `org.moonfin.webos` / `2.7.0` / `index.html` PASS
- IPK SHA-256 `80a54d415b99c813b893c6abc7b465fa8f383244be01aab791cd9aefd0a90d10`
- artifact `10135098617`, size `4,312,912` bytes
- artifact ZIP digest `sha256:7b7b1f60d05587a59fbd5913d0f3762fad150529c5e1a0a5f09bba09c8bd7c67`

Preserve `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e` as rollback/reference. The Enact/webOS client remains intentional.

webOS remains at a truthful static ceiling of 468 executable sections from 481 active. Thirteen structural/context lanes remain intentionally fail-closed until independently proven at acceptable old-TV cost. Do not re-enable them merely for nominal parity.

## Do not redo

- shared catalogue/compiler and semantics foundations
- request-cost, paging, caching, dedup and identity safeguards
- Web completion
- Android mobile/tablet adaptive/state work
- Android TV remote recovery, focus bridge, paging/retry and wide-TV work
- webOS Enact focus/deep/paging/legacy-WebKit/performance hardening
- final high-rating provenance correction
- preserved webOS v1 rollback branch/candidate
- live services

## Next stage: cross-platform parity + recommendation quality

Create an explicit platform matrix rather than assuming identical internals are required. Compare Web, Android mobile/tablet, Android TV and Enact/webOS on:

- personalisation source provenance/strategy support
- novelty/rotation/rewatch behaviour
- anime/not-owned semantics
- membership/availability/requestability
- identity/detail routing
- dedup/sparse/underfill behaviour
- refresh/reset/retained state
- deep paging/retry and bounded request cost
- platform presentation/interaction differences
- recommendation diversity/repeat/quality diagnostics

Use evidence to decide whether differences are intentional, stronger platform-specific implementations, or genuine defects. Keep structural/context semantics fail-closed until proven.

Do not tune recommendation quality from synthetic tests alone. Use the existing opt-in webOS aggregate quality diagnostics and equivalent real Home Lab evidence when practical, without exposing titles/Jellyfin IDs unnecessarily.

## Later stages

1. cross-platform parity + recommendation quality — **NEXT**
2. whole-product CI/release engineering
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance

## Live boundary

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Physical/device acceptance is still deferred.

## Exact next action

Start a new Home Lab chat. Read `handover.md` and `docs/AI_PROJECT_STATE.md`, reconcile both repositories against their current HEADs, then begin the cross-platform semantic/behaviour matrix. Do not reopen completed platform implementation unless parity evidence demonstrates a genuine defect.
