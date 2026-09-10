# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

**Current phase:** final Smart-TV / webOS reconciliation. Android TV / Google TV is now GitHub/code complete.

## Completed foundations — do not redo

- Shared semantics/personalisation, request-cost, paging, cache, dedup and identity safeguards: COMPLETE.
- 486-lane catalogue/compiler; unsupported structural/context semantics fail closed.
- Web: COMPLETE, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`, workflow #115.
- Android mobile/tablet: GITHUB/CODE COMPLETE, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN.
- Android TV / Google TV: GITHUB/CODE COMPLETE. Remote-safe recovery, deterministic focus/navigation, deep Refresh/Retry More, retained-state behaviour and wide-TV focus scrolling are verified.

Physical mobile/tablet/TV acceptance remains deferred.

## Android TV / Google TV — CLOSED

Primary deterministic-focus source:

`2a204646fd296df1f57bd4dc4d7d3d1f969d7e6a`

Paging-error root-cause fix:

`5e0886a114dc1ee7ba783512e80e648634b915a7`

Final wide-TV/full-build source:

`15ccc28b84727543ad714ef19dd318f907d1a1d8`

Final focused pre-candidate gate #127 / `34422202215` was GREEN with route integration PASS, catalogue 486 + 8 Python tests PASS, format 54 files/0 changed, analyse no issues, Discovery 106 passed/5 skipped, Chrome 12 passed and custom-scope PASS.

### Final required full candidate — #128 GREEN

Workflow **#128 / `34429841034`**, exact source `15ccc28b84727543ad714ef19dd318f907d1a1d8`:

- focused validation job `102722801700`: **GREEN**
- Web + `mobile-beta` + `androidTv-beta` build job `102723571678`: **GREEN**
- Web release built successfully
- mobile-beta release APK built successfully, 128.1 MB
- androidTv-beta release APK built successfully, 127.1 MB
- Flutter `3.44.1`
- app `2.5.1+30000149`
- Android TV `2.5.1`, build `2000016`
- Android TV uses `MOONFIN_FORCE_TV=true`
- CI signing remains `debug-fallback-not-for-deployment`; production signing remains the existing Home Lab certificate

Candidate hashes:

- Android TV APK SHA-256 `39406273a5cf6d5cfb3d0a3316fb08b8cee6a5feec985056d51829096981279f`
- Android mobile APK SHA-256 `a9aaa9b32735e59c2ff9530a7a52c27d6a22c8b8fbbbd608da095c511fa88819`
- Web tar.gz SHA-256 `97084634a83e2d4ddf84976d0176bcf35d3ebea3ba11e04c6621af02f7e768e1`

Uploaded candidate artifact:

- ID `10134675199`
- size `304720354` bytes
- ZIP digest `sha256:c3f45b293d5d0b17b0e0086aa6f1724eaf6566d936e91840a0c23cbe0262014e`

Production signing certificate invariant remains SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate or replace it.

## Smart-TV / webOS and live

Smart-TV/webOS may now be inspected/reconciled. Do a narrow recovery from its live branch/current checkpoint; do not restart prior webOS work.

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Existing archive/recovery refs remain intact.

## Completion order

1. shared semantics/personalisation — COMPLETE
2. Web — COMPLETE
3. Android mobile/tablet — COMPLETE
4. Android TV / Google TV — COMPLETE
5. final webOS reconciliation — **ACTIVE**
6. cross-platform parity/recommendation quality
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance

## Exact next action

Inspect the live `PRYYSE/Smart-TV` webOS Discovery branch and its newest current-state/checkpoint material, reconcile it against the already-complete shared Discovery semantics and accepted live webOS baseline, and continue only the remaining webOS work. Do not re-audit Moonfin-Core or touch live services.