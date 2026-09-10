# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code for Home Lab Moonfin Discovery v2 before physical-device, live-service or production acceptance.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`  
Smart-TV repo/branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`

**Current phase:** cross-platform parity + recommendation quality. Parity implementation slices 1 and 2 are committed; slice 2 CI is currently pending.

## Completed foundations — do not redo

- Shared catalogue/compiler and Flutter semantics/personalisation foundations: COMPLETE.
- Authoring catalogue: **486 lanes**; accepted compiled baseline: **481 active**.
- Web: code complete, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`, workflow #115.
- Android mobile/tablet: code complete, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN.
- Android TV / Google TV: code complete, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, workflow #128 / `34429841034` GREEN.
- Smart-TV/webOS pre-parity baseline: source `42854590caf4dbf847696483d943a886d5ab8ed7`, workflow #51 / `34432674158` GREEN, 86/86 tests.
- The earlier webOS `high-ratings` defect is already fixed: real Jellyfin `UserData.Rating >= 8` seeds and truthful dynamic label. Do not reopen it.
- webOS intentionally remains at **468 executable sections** from 481 active. Thirteen structural/context strategies remain fail-closed.
- Preserve Smart-TV rollback branch `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.
- Production Android signing certificate SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate/replace it.

## Canonical parity evidence

See `docs/homelab-discovery-v2/CROSS_PLATFORM_PARITY_MATRIX.md`.

Web, Android mobile/tablet and Android TV share one Flutter Discovery semantic/runtime core. Platform differences are mainly presentation, input, focus and route mechanics. Enact/webOS is intentionally independent and has stricter legacy-TV cost constraints.

Aligned behaviour includes personalisation provenance, membership/requestability/availability, TMDB/Jellyfin identity, dedup, sparse-row handling, rotation/cooldown, bounded concurrency, deep paging/retry and fail-closed unsupported structural/context semantics.

## Parity slice 1 — VALIDATED

Implementation source: `572e32d54d14d0d50ba8066cd817d8938ffae572`.

Implemented:

- shared Flutter total explicit-refresh fallback: retain the last good tab only when an explicit refresh totally fails; partial fresh results remain authoritative
- privacy-safe aggregate recommendation-quality analyser
- focused state/privacy tests
- no ranking/source-weight changes

Workflow #129 / `34436206490` failed only because two new tests were not committed in `dart format` form. Format-only correction: `9ccb89927ca23bb4d3f00043f70ba138a6239beb`.

Replacement workflow **#130 / `34436806830` GREEN**. Parity slice 1 is validated.

## Parity slice 2 — IMPLEMENTED, CI PENDING

### Moonfin-Core

Product source: `b800e5be18109963e4ae00b3739550b924c7204f` (`feat(discovery): align novelty and rewatch semantics`).

Implemented in the shared Flutter core:

- `novelty` / `something-completely-different`: bounded local Jellyfin random snapshot, then at most two recommendation seeds through the existing cached source adapter
- `anime-novelty` / `anime-something-different`: same bounded random source constrained to anime
- user-facing anime novelty title normalised to truthful `Something Different in Anime`; no unsupported claim that the source proves the user's usual genres
- `rewatch` / `comfort-rewatch-candidates`: direct positive played source built from favourites + real high ratings + likes, excluding neutral history
- source-specific anime recognition aligned with the generic policy by requesting/using `OriginalLanguage` and `ProductionLocations`; local Animation + Japanese language/origin now qualifies
- focused tests for strategy mapping, bounded novelty, positive-only direct rewatch and anime novelty filtering/title
- structural/context semantics remain fail-closed; no ranking weights changed

Workflow **#131 / `34438702403`** failed at the **Format gate only**. Route and catalogue gates passed; analyse/tests were skipped after formatting failed. CI's exact formatter output was reproduced and verified by Git blob hash before upload:

- formatted source blob `81238d8ad280508002834594958601e4d8f41d5c`
- formatted test blob `5c3bcc9faa4b657836d0496df12debfea2d3b45b`

Format-only follow-up source: `e654668f89af49470df417d4fcc444e73c53121e` (`style(discovery): apply dart format to parity slice`).

Authoritative replacement workflow: **#132 / `34439296054`**, source `e654668f89af49470df417d4fcc444e73c53121e`, **IN PROGRESS at the single permitted check**. Do not poll again in this waiting cycle.

### Smart-TV/webOS

Parity product source: `a9dfa657a220a3f8f77753261bd7d8e902c0d837` (`fix(discovery): tighten novelty and rewatch semantics`).

Implemented:

- anime novelty user-facing title normalised to `Something Different in Anime` while retaining bounded random-anime recommendation semantics
- shared `positive` personal source tightened from Likes + Favourites + all History to Likes + Favourites + real high ratings, preventing neutral history from satisfying `Worth Rewatching`
- rewatch remains direct and played-only
- focused Jest coverage verifies neutral played history is excluded, no recommendation transport is used for rewatch, and anime novelty filters output and reports the truthful title
- request-count class remains bounded; no ranking weights changed

Uploaded source/test blobs matched precomputed Git hashes exactly. Local `node --check` passed before publication.

Workflow **#52 / `34439022624`**, source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, was **IN PROGRESS at the single permitted check**. Do not poll again in this waiting cycle.

## Remaining parity / recommendation-quality boundary

- `anime-popular-but-not-in-your-library` remains a dormant webOS capability; no current authored lane uses it. Preserve it but do not add a lane merely for nominal parity.
- Unsupported structural/context strategies remain fail-closed on both implementations.
- Do not tune ranking, source weights or diversity from synthetic fixtures. The aggregate analyser is instrumentation only.
- Real Home Lab privacy-safe evidence is required before recommendation tuning: duplicate ratio, underfilled-lane count, missing-poster ratio, owned ratio, hidden/failed lanes and per-section counts.
- If obtaining that evidence requires crossing the current no-live-service boundary, defer tuning and advance to the next GitHub-only stage once parity correctness CI is green.

## Environment limitation

The current execution container cannot resolve `github.com` and has no Dart/Flutter toolchain. GitHub Actions is therefore the authoritative Dart/analyse/test gate. GitHub API writes were protected by exact base-blob and produced-blob hash checks before branch refs moved.

## Exact next actions

1. Inspect Moonfin-Core workflow **#132 / `34439296054` once**.
2. Inspect Smart-TV workflow **#52 / `34439022624` once**.
3. If either failed, inspect only its failing job/step and fix the genuine failure; do not reopen platform stages.
4. If both are green, mark GitHub/code cross-platform parity correctness complete under the current no-live boundary.
5. Do not tune recommendation ranking without real Home Lab aggregate evidence. If that evidence remains out of scope, advance directly to **whole-product CI/release engineering**.

## Later stages

1. cross-platform parity + recommendation quality — **CURRENT; implementation complete, CI pending**
2. whole-product CI/release engineering
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device acceptance is claimed by CI.
