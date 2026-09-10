# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this with `docs/AI_PROJECT_STATE.md`. Do not restart completed work or touch live services during GitHub-only completion.

## Current boundary

- Shared semantics/personalisation: COMPLETE
- Web: COMPLETE
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **GITHUB/CODE COMPLETE**
- Smart-TV/webOS: **ACTIVE — final reconciliation next**

## Android TV closure

Final product/focus chain:

- Slice 1 remote recovery gate #124 / `34416882794` GREEN
- deterministic focus/navigation source `2a204646fd296df1f57bd4dc4d7d3d1f969d7e6a`
- paging-error root fix `5e0886a114dc1ee7ba783512e80e648634b915a7`
- focused gate #127 / `34422202215` GREEN: route PASS; catalogue 486 + 8 Python PASS; format 54/0; analyse clean; Discovery 106 passed/5 skipped; Chrome 12; custom-scope PASS
- final wide-TV candidate source `15ccc28b84727543ad714ef19dd318f907d1a1d8`

### Required full candidate #128 — GREEN

Workflow **#128 / `34429841034`**, exact source `15ccc28b84727543ad714ef19dd318f907d1a1d8`:

- focused job `102722801700` GREEN
- Web + mobile-beta + androidTv-beta job `102723571678` GREEN
- Web release built
- mobile-beta APK 128.1 MB built
- androidTv-beta APK 127.1 MB built
- app `2.5.1+30000149`; TV `2.5.1` build `2000016`; Flutter `3.44.1`
- Android TV force define `MOONFIN_FORCE_TV=true`
- CI signing is debug fallback only, never production signing

Candidate SHA-256:

- TV APK `39406273a5cf6d5cfb3d0a3316fb08b8cee6a5feec985056d51829096981279f`
- mobile APK `a9aaa9b32735e59c2ff9530a7a52c27d6a22c8b8fbbbd608da095c511fa88819`
- Web tar.gz `97084634a83e2d4ddf84976d0176bcf35d3ebea3ba11e04c6621af02f7e768e1`

Artifact ID `10134675199`, size `304720354` bytes, ZIP digest `sha256:c3f45b293d5d0b17b0e0086aa6f1724eaf6566d936e91840a0c23cbe0262014e`.

Production signing certificate invariant remains SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate it.

## Do not redo

Shared semantics/personalisation, catalogue/compiler, request-cost/paging/cache/dedup/identity safeguards, verified Web, verified Android mobile/tablet, Android TV recovery/focus/paging/wide-screen work, docs-only CI hygiene, or separately advanced Smart-TV work.

Live remains untouched: Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled.

## Exact next action

Perform a narrow reconciliation of the live `PRYYSE/Smart-TV` webOS Discovery branch and its newest checkpoint/current-state material against the completed shared semantics and accepted webOS baseline. Continue only remaining webOS work; do not re-audit Moonfin-Core or touch live services.