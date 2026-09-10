# AI Project State

**Updated:** 2026-09-10 Australia/Adelaide

## Current objective

Complete Home Lab Moonfin Discovery v2 GitHub/code work before any physical-device, live-service or production acceptance.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`  
Smart-TV repo/branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`

**Current phase:** cross-platform parity + recommendation quality.

Platform-specific implementation is complete. Do not restart Web, Android mobile/tablet, Android TV/Google TV or webOS work unless current parity evidence proves a genuine defect.

## Verified foundations — do not redo

- Shared catalogue/compiler and Flutter semantics/personalisation foundations: COMPLETE.
- Authoring catalogue: **486 lanes**; accepted compiled baseline: **481 active**.
- Web: code complete, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`, workflow #115.
- Android mobile/tablet: code complete, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN.
- Android TV / Google TV: code complete, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, workflow #128 / `34429841034` GREEN.
- Smart-TV/webOS: code complete baseline, final product source `42854590caf4dbf847696483d943a886d5ab8ed7`, workflow #51 / `34432674158` GREEN, 86/86 tests.
- webOS high-rating provenance defect is already fixed: real Jellyfin `UserData.Rating >= 8` seeds and truthful `Because You Rated ... Highly` label. Do not reopen it.
- webOS intentionally remains at **468 executable sections** from 481 active. Thirteen structural/context strategies remain fail-closed.
- Preserve Smart-TV rollback branch `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.
- Production Android signing certificate SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate/replace it.

## Cross-platform parity matrix

Canonical evidence: `docs/homelab-discovery-v2/CROSS_PLATFORM_PARITY_MATRIX.md`.

Web, Android mobile/tablet and Android TV use one shared Flutter Discovery semantic/runtime core. Platform differences are mostly presentation/input/focus. Enact/webOS is intentionally independent and has stricter legacy-TV request-cost constraints.

Aligned outcomes include provenance for history/favourites/watchlist/high-ratings/likes/mixed-positive, membership/requestability/availability, TMDB/Jellyfin identity, dedup, rotation, sparse-row handling, bounded concurrency, deep paging/retry and fail-closed unsupported structural/context semantics.

## Parity slice 1 — implementation + validation recovery

Implementation source: `572e32d54d14d0d50ba8066cd817d8938ffae572`.

Implemented:

- shared Flutter total explicit-refresh fallback: retain the last good tab only when a refresh totally fails; partial fresh results remain authoritative
- privacy-safe shared Flutter aggregate recommendation-quality analyser
- focused tests for refresh fallback, partial refresh, aggregate counting and no media-identity leakage
- no ranking/source-weight changes

Workflow #129 / `34436206490` failed only at the **Format gate**. `dart format` changed exactly the two newly-added test files; route/catalogue gates had already passed. No product-code failure was reported because later analyse/tests were skipped after formatting failed.

Format-only correction commit: `9ccb89927ca23bb4d3f00043f70ba138a6239beb`. It contains exactly the formatter output for:

- `test/homelab_discovery/discovery_quality_test.dart`
- `test/homelab_discovery/discovery_refresh_fallback_test.dart`

Replacement focused workflow: **#130 / `34436806830`**, source `9ccb89927ca23bb4d3f00043f70ba138a6239beb`. It was still **IN PROGRESS** at the single permitted check in this continuation. Do not continuously poll it. The next continuation must inspect this exact run once.

## Refined parity findings for the next semantic slice

### 1. Generic novelty — SHARE

The authored For You lane `Something Different` maps to `novelty`. webOS implements this truthfully as a bounded Jellyfin random source (`SortBy=Random`, limit 60).

Flutter currently fails `novelty` closed, but its existing personal-source `_queryLocal` primitive already supports arbitrary `sortBy` with a bounded 60-item snapshot. Therefore a truthful bounded Flutter novelty adapter is feasible without ranking heuristics or unbounded request cost.

### 2. Anime novelty label — GENUINE SEMANTIC DEFECT

The authored anime lane is currently `Anime Outside Your Usual Genres` mapped to `anime-novelty`.

webOS implements `anime-novelty` as generic random selection plus `animeOnly`. It does **not** derive the user's normal genres or exclude them. Therefore the current label overclaims what the source proves.

Preferred root fix: make the catalogue label truthful, e.g. `Something Different in Anime`, then use the same bounded random-anime semantics on webOS and Flutter. Do not invent a synthetic "usual genres" model during parity work.

### 3. Rewatch — GENUINE webOS SEMANTIC/QUALITY DEFECT + SHARE opportunity

webOS defines `rewatch` as direct `positive` + `playedOnly`. Its current `positive` seed pool combines **Likes + Favourites + all played History**. Since History itself is played content, arbitrary recently watched items can qualify for `Worth Rewatching` without any positive signal.

Preferred root fix: use positive evidence only, such as Likes + Favourites + real high ratings, then require played state. This keeps the meaning truthful and remains bounded. Flutter can implement equivalent rewatch semantics efficiently from its existing cached favourites/high-ratings/likes sources.

### 4. Popular anime not in library — DORMANT, not an active gap

webOS has an `anime-popular-but-not-in-your-library` adapter with library-resolution filtering, but no current authored catalogue lane using that strategy was found. Preserve the adapter; do not add a lane merely for parity.

## Recommendation-quality rule

Do not tune recommendation ranking from synthetic fixtures. Unit tests may prove provenance, privacy, state transitions and bounded behaviour only.

Use real Home Lab privacy-safe aggregate evidence before changing ranking/diversity/source preference. Useful metrics: duplicate ratio, underfilled-lane count, missing-poster ratio, owned ratio, hidden/failed lanes and per-section counts. If obtaining such evidence requires crossing the current no-live-service boundary, defer ranking tuning.

## Exact next actions

1. Inspect Moonfin-Core run **#130 / `34436806830` once**.
2. If failed, inspect/fix only the failing job/step. If green, mark parity slice 1 validated.
3. Then implement parity slice 2 as one bounded semantic unit:
   - correct the anime novelty catalogue label to truthful random-anime semantics
   - add bounded generic + anime novelty support to the shared Flutter source adapter
   - correct webOS rewatch to positive signals only
   - add equivalent bounded Flutter rewatch support
   - add focused tests on both repos
   - keep structural/context semantics fail-closed and do not change ranking weights
4. Run focused CI for the affected repos and record exact run IDs. Do not continuously poll long CI.
5. If parity correctness is green and real ranking evidence is unavailable under the current boundary, advance to whole-product CI/release engineering rather than guessing.

## Later stages

1. cross-platform parity + recommendation quality — **CURRENT**
2. whole-product CI/release engineering
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device acceptance is claimed by CI.
