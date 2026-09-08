# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-08 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

This is the primary resume point. Read this file and `docs/AI_PROJECT_STATE.md`, then use `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md` for the remaining implementation order and `docs/UPSTREAM_UPDATE_PROTOCOL.md` for future official Moonfin releases.

Do not restart completed work or modify the live server during GitHub-only completion work.

## Objective / quality lock

Complete everything reasonably possible in GitHub/code across Web, Android mobile/tablet, Android TV / Google TV and LG webOS before physical-device, live-service or production acceptance.

Green CI/packages are milestones, not completion. The project does not move to physical-device acceptance until `docs/AI_PROJECT_STATE.md` explicitly records that no known GitHub/code-side work remains.

## Stable / rollback state

Live remains deliberately untouched:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Recovery refs remain intact:

- `archive/pre-v2-main-2026-09-06` -> `cfe9c5c1a4c32d1c0828eff5ed41ea3a2947d126`
- `archive/seerr-discovery-v1-2026-09-06` -> `aa604b6cdc0083cebe8762f85ede896024f88725`
- `archive/live-web-a9c789-2026-09-06` -> `a9c789fff317b41bba268d3a213439e23b8d1af5`
- `archive/android-accepted-e7e5ab-2026-09-06` -> `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`

Accepted Android signing certificate SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`. Never regenerate it.

## Current verified Flutter/Web/Android product milestone

**Verified source:** `e88fd308521287b326ba58e31c1e4457fba62c60`  
**Workflow:** `34186256083` / run **#95 — GREEN**

Passed:

- route integration gate
- 486-lane authoring catalogue/compiler gate and 8 catalogue tests
- strict Dart format gate
- overlay analysis
- complete `test/homelab_discovery` suite
- narrow custom-scope gate
- Web release build
- Android `mobile-beta` APK build
- Android `androidTv-beta` APK build
- isolated candidate bundle upload

Artifact:

- ID `10041082791`
- name `homelab-discovery-v2-candidates-e88fd308521287b326ba58e31c1e4457fba62c60`
- size `304511071` bytes
- digest `sha256:20a85a58060ed22862f0b2b69ab1c7c2891d7da0646be8c7a21c1a74bf4372d6`
- expires `2026-09-22`

CI Android artifacts use debug-fallback signing and are not deployment packages. The accepted production signing certificate remains unchanged and protected.

Documentation-only commits may be newer than the verified product source. `e88fd308...` remains the code/build acceptance point until another source-changing full build passes.

## Current verified webOS milestone

Repository `PRYYSE/Smart-TV`, branch `homelab/webos-discovery-v2`.

**Verified source:** `a3a3317894a90bbab8b12cc7764187a8c5591369`  
**Workflow:** `34184420915` / run #50 — GREEN

- 16/16 suites
- 85/85 tests
- strict Enact lint
- legacy WebKit compatibility
- production Enact build/IPK
- artifact `10040048352`
- digest `sha256:6e765d2ad65fcd0cfb487bfc13075da209332e3f5004ea3e14a434b8d2661eef`
- IPK manifest SHA-256 `24e7a3af27c6ddf77d747b9990780073edb692ad6cef6453957d3afc45ee8e06`
- identity `org.moonfin.webos` / `2.7.0` / `index.html`

Preserved Smart-TV v1 baseline/candidate remain untouched. No physical LG acceptance is claimed.

## Shared personalisation semantic correction completed

Do not redo this slice.

### Removed invalid slot/hash semantics

The prior Flutter adapter could hash any named `personalised` strategy into one of the generic `RowDataSource.loadSinceYouWatchedRow` slots. That allowed a specialised catalogue label to display unrelated data.

At `e88fd308...`:

- the arbitrary `_stableSlot`/hash fallback is gone
- a new explicit `discovery_personal_policy.dart` defines executable generic affinity semantics
- a deterministic row index only chooses a repeatable recommendation seed; it no longer defines the meaning of a lane
- authored Discovery titles remain authoritative rather than being replaced by an unrelated upstream seed title

### Currently truthful generic affinities

Current upstream `Since You Watched` data can support a bounded set of generic affinity rows with explicit result filters, including:

- movie / series / anime affinity
- short-runtime affinity
- older / recent affinity
- highly-rated unseen
- anime action / fantasy / romance-drama / highly-rated-unseen / recent / older / movie / short variants

### Source-specific strategies now fail closed

Until a real source adapter proves their provenance, Flutter no longer pretends to support source-specific or structural semantics such as:

- recent history
- favourites
- watchlist
- high ratings
- likes
- mixed positive signals
- novelty/random
- rewatch
- recently added
- trending/popular anime direct sources
- limited-series / one-season / completed / continuing / binge/context structural lanes

Unsupported personal sections are excluded before tab composition and I/O, so they do not consume lane budget/network slots. Landing rows hide cleanly; direct deep requests fail explicitly.

### External identity bug fixed

External Seerr recommendations no longer receive fabricated Jellyfin ownership:

- real local item -> status available + real Jellyfin item ID
- external Seerr item -> Seerr status + no local Jellyfin ID
- malformed/non-positive TMDB identity -> omitted

This prevents external recommendations being routed as fake local media.

### Regression tests added

Coverage now proves:

- source-specific/structural strategies fail closed without source I/O
- supported affinity policies are explicit and deterministic rather than hash-derived
- anime/genre/rating/unseen filtering
- external vs local identity preservation
- invalid TMDB omission
- clean unsupported-lane hiding
- explicit unsupported deep failure
- ineligible sections never enter composition or lane loading

## Important: shared personalisation is not finished

Fail-closed behaviour is the correct safety state but is not feature parity.

Before starting the Web-specific completion pass, implement real Flutter source adapters for the source semantics current APIs can truthfully provide, using the webOS implementation and archived v1 code only as references:

- history
- favourites
- watchlist
- high-ratings
- likes
- positive-signal mixing
- direct recently-added / rewatch / trending-popular anime sources where appropriate

Requirements remain:

- genuine source provenance
- bounded request cost
- deterministic dedup/order
- truthful paging/totals
- correct local/external identity
- unsupported structural/context semantics remain fail closed

## Semantic accounting

Accepted shared reference remains **486 authored / 481 active**.

Current truthful webOS static capability ceiling remains **468 executable active sections** before runtime sparse/error hiding. Its 13 deliberately unsupported active lanes remain unchanged and must not be faked.

## Whole-product GitHub completion order

1. finish shared source-specific personalisation semantics
2. Web completion pass
3. Android mobile/tablet completion pass
4. Android TV / Google TV completion pass
5. final webOS reconciliation
6. cross-platform parity/recommendation-quality pass
7. whole-product CI/release engineering
8. official upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance and production cutover

Full plan: `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`.

## Official Moonfin update protocol

`docs/UPSTREAM_UPDATE_PROTOCOL.md` is mandatory for all supported platforms.

Every official update must start from the new official upstream base, generate an upstream/Home-Lab overlap report, reapply/adapt only the narrow Home Lab overlay, rerun semantic/platform gates, protect Android signing/package identity and webOS app identity, create isolated candidate artifacts and preserve the previous accepted rollback.

Release detection/reporting/build automation is allowed. Automatic production merge, promotion or deployment is prohibited.

## Exact next action

Continue the **shared source-specific personalisation implementation**. Build truthful history/favourites/watchlist/high-ratings/likes/positive/direct source adapters using current Jellyfin/Seerr APIs, keep structural/context strategies fail closed, add source/paging/dedup/identity tests, then rerun focused validation plus Web/mobile/Android-TV full candidate builds.

Only after that shared layer is credible should the project enter the Web-specific completion pass.

## Do not

- delete recovery refs/candidates
- modify the live server during GitHub-only work
- regenerate Android signing
- change `org.moonfin.webos` without deliberate migration
- fake unsupported semantics
- treat CI/package generation as product completion
- claim physical acceptance without real execution
