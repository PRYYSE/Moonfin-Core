# AI Project State

**Updated:** 2026-09-08 Australia/Adelaide

## Current objective

Complete **everything reasonably possible in GitHub/code across the entire Home Lab Moonfin Discovery product before physical-device, live-service or production acceptance**.

Platforms and shared scope:

- Web
- Android mobile/tablet
- Android TV / Google TV
- LG webOS
- shared catalogue/compiler/schema/semantic contracts
- personalisation/recommendation quality
- details/request/playback integration
- navigation/focus/back
- state/cache/error handling
- performance/constrained-device behaviour
- tests, CI, reproducible builds/packages
- cross-platform parity
- official Moonfin update/release engineering

The durable implementation plan is `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`. The mandatory official update procedure is `docs/UPSTREAM_UPDATE_PROTOCOL.md`.

**Do not move to physical LG acceptance merely because webOS is green.** Physical acceptance becomes the primary phase only when this file explicitly records that no known GitHub/code-side work remains.

## Repositories / branches

### Moonfin-Core

- repository: `PRYYSE/Moonfin-Core`
- branch: `homelab/discovery-v2`
- current documentation/plan commits are newer than substantive Flutter product code
- current verified Flutter/Web/Android product source milestone: `86acba1246ea5e9424fcc96c9729c1e474359c53`
- workflow `34104075134` / #62: GREEN
- candidate artifact `10012562778`

### Smart-TV / webOS

- repository: `PRYYSE/Smart-TV`
- branch: `homelab/webos-discovery-v2`
- current verified product source: `a3a3317894a90bbab8b12cc7764187a8c5591369`
- workflow `34184420915` / #50: GREEN
- 16/16 suites, 85/85 tests
- artifact `10040048352`
- artifact digest `sha256:6e765d2ad65fcd0cfb487bfc13075da209332e3f5004ea3e14a434b8d2661eef`
- IPK manifest SHA-256 `24e7a3af27c6ddf77d747b9990780073edb692ad6cef6453957d3afc45ee8e06`
- identity remains `org.moonfin.webos` / `2.7.0` / `index.html`

Preserved Smart-TV rollback baseline remains `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.

## Completed foundations that must not be redone

### Shared / Flutter-Web-Android foundation

- isolated Home Lab Discovery architecture with guarded stock fallback
- deterministic concurrent loading/post-fetch presentation
- accepted 486-lane authoring catalogue/compiler validation
- membership/NSFW filtering
- persistent lane rotation
- landing + deep `See All`
- TV focus/D-pad hardening
- reproducible Web/mobile/Android-TV candidates

These clients are not product-finished. Green workflow #62 predates the semantic correction now required for shared personalisation.

### webOS foundation

webOS is code-side advanced and should be reconciled later, not rebuilt:

- guarded six-tab catalogue UI + stock Seerr fallback
- aligned fail-closed planner/filter/sort/date-token behaviour
- authenticated narrow Moonbase Seerr proxy
- bounded lane loading, deterministic composition, membership/dedup and persistent rotation
- truthful Jellyfin/Seerr personalisation sources with unsupported semantics failing closed
- incremental personalised deep paging while landing remains one logical page
- bounded retained deep-state LRU, refresh invalidation and stale-load generation guards
- exact landing/deep focus restoration and remotely reachable retry/Load More actions
- owned Discovery results preserve Jellyfin identity and route to real local detail/playback
- refresh failure preserves usable rows
- code-reviewed landing/detail/deep Back history
- performance-tier-aware old-TV visual policy
- low-tier cheaper backdrop/no blur/no animation policy
- compact <=800 px deep-grid behaviour with VirtualGrid positioning preserved
- poster failure fallback
- invalid/non-positive TMDB identities filtered before presentation
- explicit exhausted-list state
- opt-in privacy-safe aggregate recommendation-quality diagnostics

No physical LG acceptance is claimed.

## Semantic accounting

Shared accepted reference remains **486 authored / 481 active**.

Current truthful webOS static capability ceiling remains **468 executable active sections** before runtime sparse/error hiding. Thirteen active lanes remain deliberately unsupported because current data does not prove the advertised semantics:

- For You: Continue Exploring
- Series: Limited-Series Spotlight; Continue Exploring Series; One-Season Wonders; Long-Running Favourites; Weekend Binge
- Anime: Anime Specials & TV Movies; One-Season Anime; Long-Running Anime; Bingeable Anime; Completed Anime; Continuing Anime; Anime Miniseries & Short Runs

Do not re-enable these by approximation.

## Current highest-priority code debt

`lib/features/homelab_discovery/engine/discovery_personalisation.dart` currently chooses generic RowDataSource loaders for named `personalised` strategies by deterministic slot/hash.

That means a specialised label can resolve to unrelated generic content. This is semantically invalid even though the Flutter/Web/Android builds are green.

The current stable `RowDataSource.loadSinceYouWatchedRow` is also materially simpler than the archived accepted v1 personalisation engine.

Archived reference implementation remains available at `archive/seerr-discovery-v1-2026-09-06`, including:

- `lib/data/services/seerr/seerr_discovery_personalisation_service.dart`
- `lib/data/services/seerr/seerr_discovery_seed_selector.dart`
- `lib/data/services/seerr/seerr_discovery_recommendation_mixer.dart`
- archived `row_data_source.dart`

Use these as semantic/reference material only. Adapt to current upstream architecture rather than restoring old broad files.

## GitHub completion order

1. **Shared semantic/personalisation contract**
   - remove arbitrary Flutter slot/hash personalisation
   - explicitly support truthful strategies and fail closed otherwise
   - standardise identity/availability/request/pagination/artwork/error contracts
2. **Web completion pass**
3. **Android mobile/tablet completion pass**
4. **Android TV / Google TV completion pass**
5. **Final webOS reconciliation against the corrected shared contract**
6. **Cross-platform parity/recommendation-quality pass**
7. **Whole-product CI/release engineering**
8. **Official Moonfin upstream-update automation/protocol integration**
9. **GitHub completion checkpoint**
10. Only then begin physical/live acceptance and cutover

See `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md` for the full gate definitions.

## Official Moonfin update policy

`docs/UPSTREAM_UPDATE_PROTOCOL.md` is mandatory for every official Moonfin update.

Core rule: start from the new official upstream release, generate an impact report, then reapply/adapt the narrow Home Lab overlay. Do not simply carry an old modified fork forward.

Every update must protect:

- Web deployment/catalogue paths
- Android package ID and accepted signing certificate
- Android versionCode/update compatibility
- Android TV candidate compatibility
- webOS ID `org.moonfin.webos` and in-place update identity
- rollback refs/candidates
- semantic/personalisation contract
- full cross-platform regression gates

Automation may detect/report upstream releases and build candidates, but must not automatically merge/promote/deploy production.

## Known blockers / acceptance-only work

These are real future gates but are deliberately **not the next primary phase while GitHub-side work remains**:

- physical LG C6 rendering/performance/remote/Back/lifecycle/update acceptance
- Android phone/tablet real-device acceptance
- Android TV / Google TV real-device acceptance
- Web browser subjective/interactive acceptance
- actual Home Lab Jellyfin/Seerr recommendation-quality capture
- real request/detail/local playback acceptance
- live server/cutover/deployment

## Important decisions / safeguards

- quality, maintainability and truthful semantics over nominal lane count
- unsupported semantics fail closed
- preserve real Jellyfin identity whenever ownership is proven
- preserve old-TV request/memory limits
- existing diagnostic logging remains opt-in; no new always-on telemetry
- preserve recovery refs and accepted candidates
- never regenerate Android signing
- never change `org.moonfin.webos` without a deliberate migration
- do not modify the live server during GitHub-only work
- green CI/package generation is evidence, not completion

## Tests / verified milestones

- Moonfin Flutter/Web/Android workflow `34104075134` / #62: GREEN at source `86acba1246ea5e9424fcc96c9729c1e474359c53`
- Smart-TV workflow `34184420915` / #50: GREEN at source `a3a3317894a90bbab8b12cc7764187a8c5591369`
  - 16/16 suites
  - 85/85 tests
  - strict lint
  - legacy WebKit compatibility
  - production build/IPK
  - identity verification and isolated artifact

## Exact next actions

1. Complete the first shared semantic slice: replace the arbitrary Flutter `personalised` slot/hash mapping with explicit truthful strategy handling/fail-closed behaviour.
2. Add targeted regression tests proving specialised names cannot silently resolve to unrelated generic rows.
3. Run the relevant Moonfin-Core test/build workflow and fix any failures.
4. Update this checkpoint to the exact verified source/workflow.
5. Continue through Web -> Android mobile/tablet -> Android TV/Google TV -> final webOS reconciliation -> cross-platform CI/update automation until no known GitHub/code-side work remains.
