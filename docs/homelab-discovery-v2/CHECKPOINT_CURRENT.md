# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this with `docs/AI_PROJECT_STATE.md`. Do not restart completed work or touch live services during GitHub-only completion.

## Current boundary

- Shared semantics/personalisation: COMPLETE
- Web: COMPLETE
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **GITHUB/CODE COMPLETE**
- Smart-TV/webOS: **ACTIVE — one semantic CI gate pending**

## Android TV closure

Final source `15ccc28b84727543ad714ef19dd318f907d1a1d8`; required full candidate workflow #128 / `34429841034` GREEN.

Evidence:

- focused job `102722801700` GREEN
- Web + mobile-beta + androidTv-beta job `102723571678` GREEN
- TV APK SHA-256 `39406273a5cf6d5cfb3d0a3316fb08b8cee6a5feec985056d51829096981279f`
- mobile APK SHA-256 `a9aaa9b32735e59c2ff9530a7a52c27d6a22c8b8fbbbd608da095c511fa88819`
- Web tar.gz SHA-256 `97084634a83e2d4ddf84976d0176bcf35d3ebea3ba11e04c6621af02f7e768e1`
- artifact ID `10134675199`, ZIP digest `sha256:c3f45b293d5d0b17b0e0086aa6f1724eaf6566d936e91840a0c23cbe0262014e`
- app `2.5.1+30000149`; TV `2.5.1` build `2000016`; Flutter `3.44.1`
- CI Android signing is debug fallback only

Production Android signing certificate invariant remains SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate it.

## Smart-TV/webOS reconciliation

Repo `PRYYSE/Smart-TV`, branch `homelab/webos-discovery-v2`.

The pre-correction branch HEAD `7f2fc28c8224ffe426645ed28dc35651eec31fa3` was exactly one documentation-only commit ahead of verified product source `a3a3317894a90bbab8b12cc7764187a8c5591369`; no hidden source changes existed.

Last verified webOS candidate remains #50 / `34184420915` GREEN with 16/16 suites, 85/85 tests, strict Enact lint, legacy CSS checks, production build, IPK packaging and preserved `org.moonfin.webos` / `2.7.0` / `index.html` identity. Artifact `10040048352`, digest `sha256:6e765d2ad65fcd0cfb487bfc13075da209332e3f5004ea3e14a434b8d2661eef`, IPK manifest SHA-256 `24e7a3af27c6ddf77d747b9990780073edb692ad6cef6453957d3afc45ee8e06`.

### Current product source — CI PENDING

`42854590caf4dbf847696483d943a886d5ab8ed7` — `fix(discovery-v2): use real Jellyfin high-rating seeds`

Reason: catalogue lanes explicitly advertise highest user ratings, while webOS was sourcing `high-ratings` from Likes + Favourites. The correction now uses one bounded recent-played Jellyfin candidate query and filters `UserData.Rating >= 8`, including the anime alias, and fixes the dynamic `Because You Rated ... Highly` title. Focused regression added. Initial source-request fan-out decreases from two Jellyfin calls to one.

Required workflow:

- **#51 / `34432674158`**
- exact source `42854590caf4dbf847696483d943a886d5ab8ed7`
- status when checkpointed: **in progress**

Do not poll this run repeatedly.

## Do not redo

Shared semantics/personalisation foundations, catalogue/compiler, request-cost/paging/cache/dedup/identity safeguards, verified Web, Android mobile/tablet, Android TV recovery/focus/paging/wide-screen work, existing webOS focus/deep/paging/legacy-WebKit hardening, preserved v1 branch/candidate, or live services.

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled.

## After #51 green

Mark webOS GitHub/code reconciliation complete, then begin cross-platform semantic parity. Do not copy old Flutter slot/hash behaviour back into webOS. Reconcile truthful source implementations instead, especially webOS-proven novelty/rewatch/anime-not-owned strategies versus current Flutter fail-closed handling; keep the 13 structural/context lanes fail-closed until proven. Recommendation-quality tuning from actual Home Lab data remains later.

## Exact next action

Inspect Smart-TV workflow **#51 / `34432674158` once**. If green, capture exact test/build/package/identity/artifact/hash evidence and advance immediately to cross-platform parity. If red, inspect only its failing gate and make the narrow root-cause correction.