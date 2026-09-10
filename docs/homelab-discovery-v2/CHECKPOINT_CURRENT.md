# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-10 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this with `docs/AI_PROJECT_STATE.md`, `handover.md` and `CROSS_PLATFORM_PARITY_MATRIX.md`. GitHub/current repo state is authoritative. Do not restart completed platform implementation or touch live services during GitHub-only work.

## Current boundary

- Shared semantics/personalisation: **COMPLETE**
- Web: **GITHUB/CODE COMPLETE**
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **GITHUB/CODE COMPLETE**
- Smart-TV/webOS: **GITHUB/CODE COMPLETE**
- Cross-platform parity + recommendation quality: **IN PROGRESS — first evidence/fix slice committed**

## Verified platform gates — do not redo

### Android TV / Google TV

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

### Smart-TV/webOS

Repo `PRYYSE/Smart-TV`, branch `homelab/webos-discovery-v2`.

Final product source `42854590caf4dbf847696483d943a886d5ab8ed7`; workflow #51 / `34432674158` GREEN.

Final reconciliation corrected one genuine semantic mismatch: `high-ratings` now uses real Jellyfin `UserData.Rating >= 8` seeds rather than Likes + Favourites; anime inherits the same source and the dynamic label truthfully says `Because You Rated ... Highly`.

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

## Cross-platform parity slice 1

Implementation source commit: `572e32d54d14d0d50ba8066cd817d8938ffae572` (`feat(discovery): align refresh fallback and quality diagnostics`).

Evidence matrix: `docs/homelab-discovery-v2/CROSS_PLATFORM_PARITY_MATRIX.md`.

### Findings

- Web, Android mobile/tablet and Android TV share one Flutter Discovery semantic core. Their meaningful platform differences are primarily input/presentation mechanics, not separate recommendation semantics.
- Flutter and webOS are aligned on truthful source provenance for history/favourites/watchlist/high-ratings/likes/mixed-positive, membership/requestability/availability, TMDB/Jellyfin identity rules, dedup, rotation, sparse rows, bounded lane concurrency and deep-scan limits.
- Structural/context strategies remain intentionally fail-closed on both clients.
- webOS is truthfully stronger for dedicated `novelty`, `rewatch` and `anime-popular-but-not-in-your-library` sources. These are **share candidates**, not Flutter defects: do not enable them in Flutter until equivalent bounded source/library-resolution evidence exists.
- One genuine shared-Flutter parity defect was found: a total explicit refresh failure could replace previously-good tab content, while webOS already had retained-refresh fallback semantics.
- webOS also had stronger privacy-safe aggregate recommendation diagnostics.

### Changes

- Shared Flutter `HomeLabDiscoveryTabController` now retains the last good tab only when an explicit refresh totally fails; partial fresh results are never replaced with stale data.
- Added focused regression tests for total refresh fallback and partial refresh behaviour.
- Added shared Flutter aggregate recommendation-quality diagnostics analogous to webOS: duplicate ratio, missing artwork/identity, ownership ratio, underfill, hidden/failed lanes and per-section aggregate counts.
- Diagnostic serialisation deliberately excludes media titles, TMDB IDs and Jellyfin IDs.
- No recommendation source/ranking weights were changed.

### Validation status

Push workflow **#129 / `34436206490`** for source `572e32d54d14d0d50ba8066cd817d8938ffae572` was **IN PROGRESS** when this checkpoint was written.

Do not continuously poll it. On continuation, inspect this exact run once. If green, record the focused gate as passed. If failed, diagnose only the genuine failing step and fix that failure.

Local shell checkout was unavailable in the current execution environment because external GitHub DNS resolution failed; implementation was committed atomically through the GitHub API. CI is therefore the authoritative focused validation for this slice.

## Recommendation-quality boundary

Do not tune rankings from synthetic tests. The new aggregate analyser is instrumentation only and does not alter recommendation ranking. Real Home Lab diagnostic evidence should drive any later diversity/source/ranking changes when it becomes available without violating the current no-live-service boundary.

Useful privacy-safe evidence: duplicate ratio, underfilled-lane count, missing-poster ratio, owned ratio, hidden/failed lanes and per-section aggregate counts. Titles and media IDs are unnecessary.

## Do not redo

- shared catalogue/compiler and semantics foundations
- Web completion
- Android mobile/tablet completion
- Android TV completion
- webOS completion/hardening
- final webOS high-rating provenance correction
- preserved webOS v1 rollback branch/candidate
- platform physical acceptance
- live services

## Next actions

1. Inspect Moonfin-Core workflow #129 / `34436206490` **once**.
2. If green, mark parity slice 1 validated; if failed, fix only the actual failure and rerun the required focused gate.
3. Continue parity/recommendation-quality work from `CROSS_PLATFORM_PARITY_MATRIX.md`, prioritising evidence collection rather than enabling unproven lanes.
4. Do not port webOS novelty/rewatch/anime-not-owned merely for lane-count parity; first prove equivalent bounded Flutter adapters.
5. If no real Home Lab aggregate recommendation evidence is available without crossing the live boundary, defer ranking tuning and advance to the next GitHub-only stage rather than guessing from synthetic fixtures.

## Later stages

1. cross-platform parity + recommendation quality — **CURRENT**
2. whole-product CI/release engineering
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance

## Live boundary

Live remains custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Physical/device acceptance remains deferred.
