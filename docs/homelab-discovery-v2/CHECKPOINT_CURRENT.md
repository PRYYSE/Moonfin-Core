# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this with `docs/AI_PROJECT_STATE.md`, `handover.md` and `CROSS_PLATFORM_PARITY_MATRIX.md`. GitHub/current repo state is authoritative. Do not restart completed platform implementation or touch live services during GitHub-only work.

## Current boundary

- Shared semantics/personalisation foundations: **COMPLETE**
- Web: **GITHUB/CODE COMPLETE**
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **GITHUB/CODE COMPLETE**
- Smart-TV/webOS: **GITHUB/CODE COMPLETE baseline + parity slice 2 committed**
- Cross-platform parity + recommendation quality: **IMPLEMENTATION COMPLETE FOR CURRENT EVIDENCE; CI PENDING**

## Verified platform gates — do not redo

- Web source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`, workflow #115.
- Android mobile/tablet source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN.
- Android TV final source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, workflow #128 / `34429841034` GREEN.
- Smart-TV/webOS pre-parity baseline `42854590caf4dbf847696483d943a886d5ab8ed7`, workflow #51 / `34432674158` GREEN, 86/86 tests.
- Earlier webOS high-rating provenance correction is complete; do not reopen.
- webOS stays at truthful **468 executable / 481 active**. Thirteen structural/context strategies stay fail-closed.
- Preserve Smart-TV `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.
- Production Android signing certificate SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`.

## Parity slice 1 — VALIDATED

Implementation `572e32d54d14d0d50ba8066cd817d8938ffae572`:

- total explicit-refresh failure retains the last good Flutter tab; partial fresh results remain authoritative
- privacy-safe aggregate recommendation diagnostics added to Flutter
- focused state/privacy tests
- no ranking/source-weight changes

Workflow #129 / `34436206490` failed only on formatting. Format-only correction `9ccb89927ca23bb4d3f00043f70ba138a6239beb`; replacement workflow **#130 / `34436806830` GREEN**.

## Parity slice 2 — IMPLEMENTED

### Moonfin-Core

Product commit `b800e5be18109963e4ae00b3739550b924c7204f`:

- bounded generic novelty using a local Jellyfin `Random` snapshot and existing recommendation transport
- bounded anime novelty using the same source constrained to anime
- anime novelty display title truthfully normalised to `Something Different in Anime`
- direct positive-only rewatch from favourites + real high ratings + likes; neutral history excluded
- source anime detection aligned for tags/genre or Animation + Japanese language/origin
- focused tests added
- no ranking weights changed

Workflow #131 / `34438702403` failed at **Format gate only**; route/catalogue passed and later checks were skipped. Exact `dart format` output was reproduced and Git-hash verified.

Format-only follow-up `e654668f89af49470df417d4fcc444e73c53121e`; authoritative workflow **#132 / `34439296054` IN PROGRESS** at the single permitted check. Do not poll it again in this waiting cycle.

### Smart-TV/webOS

Product commit `a9dfa657a220a3f8f77753261bd7d8e902c0d837`:

- anime novelty display title normalised to `Something Different in Anime`
- rewatch positive source tightened to Likes + Favourites + real high ratings, removing neutral History
- direct played-only semantics retained
- focused tests verify positive-only rewatch and truthful anime novelty
- local `node --check` passed; exact source/test blob hashes verified before publication

Workflow **#52 / `34439022624` IN PROGRESS** at the single permitted check. Do not poll it again in this waiting cycle.

## Current parity classifications

- **Generic novelty:** aligned after SHARE adoption; both clients now have bounded random-source semantics.
- **Anime novelty:** previous advertised-semantic defect corrected at user-facing presentation; neither client claims actual usual-genre exclusion.
- **Rewatch:** previous webOS defect corrected; both implementations now require positive played evidence rather than neutral history.
- **Anime detection:** aligned, including local Animation + Japanese language/origin in Flutter source adapters.
- **Popular anime not in library:** dormant webOS capability, not an active parity gap; no authored lane. Do not add one merely for parity.
- **Structural/context strategies:** intentionally fail-closed.
- **Ranking/quality:** no synthetic tuning performed.

## Recommendation-quality boundary

Use real privacy-safe Home Lab aggregate evidence before changing ranking/diversity/source preference. Useful fields: duplicate ratio, underfilled-lane count, missing-poster ratio, owned ratio, hidden/failed lanes and per-section counts. If obtaining these requires crossing the current no-live boundary, defer tuning.

## Exact next actions

1. Inspect Moonfin-Core **#132 / `34439296054` once**.
2. Inspect Smart-TV **#52 / `34439022624` once**.
3. Fix only genuine failing steps if required.
4. If both green, mark cross-platform parity correctness complete under the GitHub-only/no-live boundary.
5. If real recommendation-quality evidence is still out of scope, advance to **whole-product CI/release engineering** rather than guessing.

## Do not redo

- shared catalogue/compiler foundations
- Web completion
- Android mobile/tablet completion
- Android TV completion/focus work
- webOS old-TV hardening
- high-rating provenance correction
- live services or physical-device acceptance

## Live boundary

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Physical/device acceptance remains deferred.
