# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this with `docs/AI_PROJECT_STATE.md`, `handover.md` and `CROSS_PLATFORM_PARITY_MATRIX.md`. GitHub/current repo state is authoritative. Do not restart completed platform implementation or touch live services during GitHub-only work.

## Current boundary

- Shared semantics/personalisation foundations: **COMPLETE**
- Web: **GITHUB/CODE COMPLETE**
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **GITHUB/CODE COMPLETE**
- Smart-TV/webOS: **GITHUB/CODE COMPLETE baseline**
- Cross-platform parity + recommendation quality: **IN PROGRESS**

## Verified platform gates — do not redo

### Android TV / Google TV

Final source `15ccc28b84727543ad714ef19dd318f907d1a1d8`; workflow #128 / `34429841034` GREEN.

- Discovery 107 passed / 5 skipped
- Chrome 12 passed
- route, 486-lane catalogue + 8 Python tests, format, analyse and scope PASS
- 1920x1080 + 3840x2160 off-screen TV focus/scroll regression PASS
- Web + mobile-beta + androidTv-beta release candidates built
- production Android signing certificate SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

### Smart-TV/webOS

Final product baseline `42854590caf4dbf847696483d943a886d5ab8ed7`; workflow #51 / `34432674158` GREEN, 86/86 tests.

The earlier `high-ratings` provenance defect is already fixed: real Jellyfin `UserData.Rating >= 8` seeds and truthful dynamic labelling. Do not reopen it.

webOS remains at a truthful ceiling of **468 executable sections** from 481 active. Thirteen structural/context strategies remain intentionally fail-closed. Preserve `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.

## Parity slice 1

Implementation source: `572e32d54d14d0d50ba8066cd817d8938ffae572`.

Implemented in shared Flutter core:

- total explicit-refresh failure retains the last good tab; partial fresh results remain authoritative
- privacy-safe aggregate recommendation diagnostics equivalent in purpose to webOS
- focused regression tests
- no ranking/source-weight changes

### Validation recovery

Workflow #129 / `34436206490` **FAILED at Format gate only**. Route and 486-lane catalogue gates passed first. `dart format` changed exactly two newly-added tests, so analyse/tests were skipped rather than reporting a product-code failure.

Format-only correction: `9ccb89927ca23bb4d3f00043f70ba138a6239beb`.

Replacement workflow: **#130 / `34436806830`**, source `9ccb89927ca23bb4d3f00043f70ba138a6239beb`. It was **IN PROGRESS** at the single permitted check during this continuation. Do not poll it again in the same waiting cycle; inspect this exact run once on the next continuation.

## Refined parity findings

Canonical matrix: `docs/homelab-discovery-v2/CROSS_PLATFORM_PARITY_MATRIX.md`.

1. **Generic novelty is a SHARE candidate.** webOS truthfully uses bounded Jellyfin `SortBy=Random` with a 60-item seed limit. Flutter's existing bounded local-query primitive can support the same semantics without new ranking logic.
2. **Anime novelty has a genuine advertised-semantic defect.** The catalogue says `Anime Outside Your Usual Genres`, but webOS only does random anime. Preferred fix is a truthful label such as `Something Different in Anime`, not synthetic preference inference.
3. **webOS rewatch has a genuine semantic/quality defect.** `rewatch = positive + playedOnly`, while `positive` currently contains Likes + Favourites + all played History. This allows arbitrary recent history into `Worth Rewatching`. Preferred fix is positive signals only, e.g. Likes + Favourites + real high ratings, then require played state. Flutter can share the same bounded semantics.
4. **Popular-anime-not-library is dormant, not an active parity gap.** webOS has an adapter, but no current authored lane using it was found. Do not add a lane merely for parity.
5. **Unsupported structural/context strategies stay fail-closed.**

## Recommendation-quality boundary

The aggregate analyser is instrumentation, not ranking logic. Do not tune rankings from synthetic tests. Use real privacy-safe Home Lab aggregate evidence when it becomes available without crossing the current no-live-service boundary; otherwise defer ranking tuning.

## Exact next actions

1. Inspect run **#130 / `34436806830` once**.
2. If failed, fix only its actual failing step. If green, mark parity slice 1 validated.
3. Implement parity slice 2 as one coherent semantic unit:
   - rename the anime novelty lane to a truthful random-anime label
   - add bounded generic/anime novelty support in shared Flutter personal sources
   - correct webOS rewatch to positive signals only
   - add equivalent bounded Flutter rewatch support
   - add focused regression tests on both repos
4. Run focused CI for affected repos; record exact run IDs and do not continuously poll.
5. If correctness is green and real ranking evidence remains outside the no-live boundary, advance to whole-product CI/release engineering.

## Do not redo

- platform completion passes
- shared catalogue/compiler foundations
- Android TV focus/deep-paging work
- webOS old-TV hardening
- prior webOS high-rating correction
- live services or physical-device acceptance

## Live boundary

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Physical/device acceptance remains deferred.
