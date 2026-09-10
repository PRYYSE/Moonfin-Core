# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

**Current phase:** final Smart-TV/webOS semantic reconciliation. Android TV / Google TV is GitHub/code complete. A narrow webOS high-rating provenance correction is under its required Smart-TV CI gate.

## Completed foundations — do not redo

- Shared semantics/personalisation, request-cost, paging, cache, dedup and identity safeguards: COMPLETE.
- 486-lane catalogue/compiler; unsupported structural/context semantics fail closed.
- Web: COMPLETE, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`, workflow #115.
- Android mobile/tablet: GITHUB/CODE COMPLETE, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN.
- Android TV / Google TV: GITHUB/CODE COMPLETE. Remote-safe recovery, deterministic focus/navigation, deep Refresh/Retry More, retained-state behaviour and wide-TV focus scrolling are verified.

Physical mobile/tablet/TV acceptance remains deferred.

## Android TV / Google TV — CLOSED

Final wide-TV/full-build source `15ccc28b84727543ad714ef19dd318f907d1a1d8`.

Required full candidate workflow **#128 / `34429841034`** was GREEN:

- focused job `102722801700` GREEN
- Web + mobile-beta + androidTv-beta job `102723571678` GREEN
- Web release built
- mobile-beta release APK 128.1 MB built
- androidTv-beta release APK 127.1 MB built
- Flutter `3.44.1`
- app `2.5.1+30000149`
- Android TV `2.5.1`, build `2000016`
- Android TV uses `MOONFIN_FORCE_TV=true`
- CI signing remains `debug-fallback-not-for-deployment`

Candidate SHA-256:

- Android TV APK `39406273a5cf6d5cfb3d0a3316fb08b8cee6a5feec985056d51829096981279f`
- Android mobile APK `a9aaa9b32735e59c2ff9530a7a52c27d6a22c8b8fbbbd608da095c511fa88819`
- Web tar.gz `97084634a83e2d4ddf84976d0176bcf35d3ebea3ba11e04c6621af02f7e768e1`

Artifact ID `10134675199`, size `304720354` bytes, ZIP digest `sha256:c3f45b293d5d0b17b0e0086aa6f1724eaf6566d936e91840a0c23cbe0262014e`.

Production signing certificate invariant remains SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate or replace it.

## Smart-TV / webOS — current gate

Repo `PRYYSE/Smart-TV`, branch `homelab/webos-discovery-v2`.

Narrow reconciliation confirmed the pre-correction Smart-TV branch HEAD `7f2fc28c8224ffe426645ed28dc35651eec31fa3` differed from its last verified product source `a3a3317894a90bbab8b12cc7764187a8c5591369` only by the checkpoint document. There were no hidden unverified source changes.

The established #50 candidate remains the last verified webOS package until the current gate completes:

- workflow `34184420915` / #50 GREEN
- 16/16 focused suites, 85/85 tests
- strict Enact lint, legacy CSS checks, production build and IPK packaging passed
- artifact `10040048352`
- artifact digest `sha256:6e765d2ad65fcd0cfb487bfc13075da209332e3f5004ea3e14a434b8d2661eef`
- IPK manifest SHA-256 `24e7a3af27c6ddf77d747b9990780073edb692ad6cef6453957d3afc45ee8e06`
- identity remains `org.moonfin.webos` / `2.7.0` / `index.html`

### Narrow high-rating provenance correction — CI PENDING

Catalogue semantics explicitly advertise `Based on Your Highest Ratings` and `Similar to Anime You Rated Highly`. The webOS source still used Likes + Favourites for `high-ratings`, while Jellyfin exposes numeric per-user `UserData.Rating` and Moonfin-Core's newer proven source logic uses ratings >=8/10.

Smart-TV product source:

`42854590caf4dbf847696483d943a886d5ab8ed7` — `fix(discovery-v2): use real Jellyfin high-rating seeds`

Changes:

- `high-ratings` now uses one bounded Jellyfin query with `Limit: 100`, recent played Movie/Series candidates and `UserData.Rating >= 8`
- `anime-high-ratings` inherits the same true rating source plus existing anime filtering
- dynamic title corrected from `Because You Liked ...` to `Because You Rated ... Highly`
- focused regression covers source query, numeric filtering, chosen recommendation seed and anime alias policy
- request fan-out is reduced from two parallel Jellyfin source requests to one
- no catalogue, structural semantics, UI/focus, package identity or live changes

Required Smart-TV workflow:

- **#51 / `34432674158`**
- exact source `42854590caf4dbf847696483d943a886d5ab8ed7`
- status when checkpointed: **in progress**

Do not poll #51 repeatedly. Next continuation inspects this exact run once.

## Cross-platform parity debt after webOS closes

Do not regress webOS to Flutter's old slot/hash behaviour. Current evidence instead calls for an explicit semantic matrix: keep truthful real-source implementations on each platform, reconcile webOS-proven novelty/rewatch/anime-not-owned behaviour with current Flutter fail-closed handling, preserve stronger Moonfin-Core provenance sources where applicable, and keep the 13 structural/context lanes fail-closed until independently proven. Real-data recommendation-quality tuning remains a later evidence-driven step.

## Live

Untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Existing archive/recovery refs remain intact.

## Completion order

1. shared semantics/personalisation — COMPLETE
2. Web — COMPLETE
3. Android mobile/tablet — COMPLETE
4. Android TV / Google TV — COMPLETE
5. final webOS reconciliation — **ACTIVE: #51 pending**
6. cross-platform parity/recommendation quality
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance

## Exact next action

Inspect Smart-TV workflow **#51 / `34432674158` once**. If green, record exact tests/build/package/identity/artifact hashes, mark webOS GitHub reconciliation complete and continue into cross-platform parity. If red, inspect only the failing gate and fix that root cause. Do not re-audit completed Moonfin-Core work or touch live services.