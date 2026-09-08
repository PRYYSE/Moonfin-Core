# Home Lab Discovery v2 — Progress Ledger

`CHECKPOINT_CURRENT.md` is the authoritative resume point. This file records verified milestones and evidence. Do not infer physical-device acceptance from CI/build success.

## Architecture pivot — 2026-09-06

- Product model changed to current stable official Moonfin + isolated Home Lab Discovery overlay + server-driven catalogue.
- Stable base: Moonfin 2.5.1, `f18c45b1fbf9b63871b4f93237179f9706154763`.
- Recovery refs created before the reset.
- Live legacy Web/Moonbase deliberately left untouched as rollback.
- Maintained clients: Web, Android mobile/tablet, Google TV/Android TV, LG TV/webOS.
- Quality/maintainability/polish explicitly take priority over speed.

## Foundation

Verified on `homelab/discovery-v2`:

- strict catalogue schema/validation and migration compatibility
- network-first catalogue + server-scoped last-known-good cache
- guarded fallback to stock Seerr Discovery
- deterministic catalogue composer/session novelty/backfill
- feature-local Seerr bridge/request-plan mapping
- bounded cross-page paginator
- per-lane error isolation and sparse-lane hiding
- stock `RowDataSource.loadSinceYouWatchedRow` personalisation adapter
- 486-lane authoring catalogue/compiler tests

## Deterministic concurrent loading — 2026-09-07

A race-order defect was found during expert review: session novelty/shared dedup state was being mutated while lanes completed concurrently.

Corrected architecture:

`deterministic lane selection -> bounded concurrent I/O -> results keyed by lane ID -> catalogue-order novelty/dedup -> catalogue-order personal presentation`

Key verified work:

- lane loader made presentation/session-pure
- novelty/dedup moved post-fetch
- reverse-completion regression proof added
- feature-local tab controller added with failure/refresh/reset coverage
- strict CI changed to read-only and cancels superseded runs

## Runtime + landing UI — 2026-09-07

Verified source milestone: `56daef893ac3baa010532dcd33e7a35c5b411a31`  
Workflow: `34079224788` — GREEN

- feature-local runtime consumes official Moonfin services instead of broadening core DI
- one controller per catalogue tab
- bounded concurrent lane fetches retain deterministic final presentation
- real loading/retry/empty/partial-failure/refresh states
- real Moonfin `MediaCard` rows and stock Seerr media-detail routing
- guarded stock fallback unchanged

## Membership policy, executable catalogue and deep browse — 2026-09-07

Verified through the strict focused workflow on the branch leading to `5f601afe25c7b9e5950ce758d92de87e580695ab`.

Completed:

- availability modes enforced instead of merely existing in schema
- NSFW membership policy restored feature-locally
- curated authoring placeholders compiled to concrete executable queries
- unresolved semantic names fail closed rather than becoming unsafe runtime parameters
- independent `See All` controller with deep paging, cross-page dedup, terminal-page handling, retry and reset
- surfaced-lane rotation history persisted across launches
- rotation reset persists the cleared state

Representative commits:

- `84a8d7de5933d9c4ca9807b67f60b2fe2454e5e9` — availability/NSFW membership
- `7fc037902b3acfc928f384eddab7a65c6a81704e` — executable curated placeholders
- `f9c1e676866ca69b036468d56c5eb8ae898ed54b` — independent deep `See All`
- `40268e63c16a45e8255a508f74e8c37e2854a2ea` — terminal deep-page regression
- `ffdf1874dc3c3ed5195d7d62919bdbc2a23b4dc4` — persistent surfaced-lane rotation
- `5f601afe25c7b9e5950ce758d92de87e580695ab` — persistent cleared rotation state

## First reproducible client candidates — 2026-09-07

Verified product source: `cc4f03b1e9e4d80314f83a764944670460dd6c58`  
Workflow: `34086546081` — GREEN

Focused validation and the first full candidate build produced Web, Android `mobile-beta` and Android `androidTv-beta` artifacts with build metadata and checksums. This milestone established the reproducible build pipeline.

Artifact ID: `10005927276`  
Artifact digest: `sha256:2baccfb03a43bfb61ec5d82b7a5f9e75a63bea6630613b6652b167b045632713`

CI Android signing is deliberately debug fallback. These APKs prove builds only and must not replace the existing deployment identity. Production/beta installation must preserve cert SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`.

## TV interaction hardening and current rebuilt Flutter candidates — 2026-09-07

Current verified product source: `86acba1246ea5e9424fcc96c9729c1e474359c53`  
Workflow: `34104075134` / run #62 — GREEN

The focus work remained inside the Home Lab feature and reused current Moonfin primitives. Completed and tested:

- TV-only landing rows with upstream focus handling while Web/mobile keep the normal pointer/touch row path
- initial focus scheduling only for the active visible tab
- row focus memory and restoration after details/`See All`
- deterministic TV deep-browse grid with one focus owner
- D-pad horizontal/vertical traversal
- partial final-row clamping
- one-shot select and Back handling
- near-end load-more trigger once per item set
- focus-memory restoration after grid rebuild
- pointer tap regression coverage
- normal `MediaCard` focus visuals through externally-driven focus state

Run #62 passed route integration, catalogue generation, formatting, focused analysis/tests, narrow-scope validation, Web release build, `mobile-beta` build, `androidTv-beta` build, packaging and artifact upload.

Current candidate artifact:

- ID: `10012562778`
- name: `homelab-discovery-v2-candidates-86acba1246ea5e9424fcc96c9729c1e474359c53`
- digest: `sha256:1853f6960394fe902e8ac9b72d0d4709bd2ddfe87265bf64b2ea3695de4083e4`
- Android TV beta APK: `a56ccc1a12e9e7e34fa54ade4725d96e4979ec544f68f0cc5f5e2d2997092a71`
- Android mobile beta APK: `ab18aebdb5bbbf8a3ba3192960937c77850bbf9fbefe4ff0bb615083d9c579c0`
- Web tarball: `ec8ec792b32c6e4c1bdd69af0efbf2a26983bf544cb4c8aaddd3ad9dff1730a2`

App version remains `2.5.1+30000149`; Android TV version/build remains `2.5.1` / `2000016`. CI APKs remain debug-fallback signed and are not deployment candidates.

This is a strong implementation/build milestone, not final cross-platform product acceptance.

## LG/webOS Discovery v2 — service foundation — 2026-09-07

The preserved Smart-TV candidate remains untouched at `PRYYSE/Smart-TV:homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.

The isolated v2 branch `homelab/webos-discovery-v2` was created from that preserved candidate. Early verified source:

`439e64f7d396aca9c9774f8fcbea8af413ebfaaf`

Workflow `34106116784` / run #7 — GREEN.

That milestone proved the fail-closed query planner, network-first catalogue/LKG loader, authenticated Moonbase Seerr proxy, membership filtering, deterministic tab loading, focused service tests, isolated package build and identity verification.

It has now been superseded by the implemented UI/personalisation milestone below.

## LG/webOS Discovery v2 — guarded UI, deep browse and focus — 2026-09-07 to 2026-09-08

Repository history confirms that the desynchronised mobile run produced durable code beyond the old checkpoint:

- `008dc12a6b17ba861f1b18d6f54938c575f11f58` — guarded catalogue UI and deep browse
- `6bd1c73ab352dddebfa9facfda1f6465c2f9c669` — stable Discovery hook dependencies
- `38c3994dec38fa9861429a8633af4c535370f268` — safe virtual deep-browse focus restoration

Workflow `34170654218` / run #12 on `38c3994...` was GREEN and produced artifact ID `10035630833`.

Verified surviving implementation includes:

- feature-local six-tab catalogue Discovery with fallback to existing `SeerrDiscover`
- loading/retry/empty/partial-failure/refresh states
- Enact Spotlight row/card/tab navigation foundation
- active-tab and row focus memory
- navbar return and vertical row movement
- feature-local `See All` deep route/controller
- `VirtualGridList` deep browse with focus restoration and bounded paging/dedup
- existing detail/request routing preserved

These are completed implementation foundations and must not be treated as future work merely because the older Moonfin checkpoint predates them.

## LG/webOS Discovery v2 — Jellyfin personalisation + persistent rotation recovered — 2026-09-08

Desynchronised source `dd1b52eb5503ee37e74fbaba56f65360ad24f8a7` added substantial real functionality:

- real Jellyfin-backed personalisation reusing the existing Smart-TV Home recommendation engine
- sixteen deterministic personal strategy slots
- Jellyfin candidate hydration before provider-ID mapping when required
- movie/series filtering and explicit anime discrimination
- dynamic `Because You Watched ...` lane titles
- personal results through normal membership/dedup handling
- persistent server/user/tab-scoped surfaced-lane rotation
- refresh rotation plus personalised first-page refresh
- persistent rotation reset

Workflow `34176178067` / #13 failed before packaging because three new suites reached the Enact/Jellyfin runtime during Jest module initialisation. Eight suites passed and all 38 tests that actually initialised passed; the failure was the test/runtime import boundary, not failing assertions.

Batch 1 recovery repaired that boundary without removing production behaviour:

- `635574bac20bb0a8a75ddf6dab117d8bc2d5add1` — lazy production runtime adapters keep injected personalisation policy tests independent from Enact module evaluation;
- the service suite then reached **11/11 suites and 53/53 tests passing**;
- full production build subsequently exposed one strict `no-shadow` warning in the personalised lane path;
- `08df13b15bf0b5bd66fdf7dceb6359b18d67042b` — corrected the warning with no behaviour change;
- workflow `34178662792` / run **#15** — **GREEN** end-to-end.

Run #15 verified:

- dependency install
- all focused Discovery service tests
- strict lint
- legacy CSS/WebKit compatibility checks/patches
- production Enact compilation
- webOS IPK packaging
- preserved app identity/version/main
- isolated artifact upload

Current verified artifact:

- ID: `10038154398`
- name: `Moonfin-HomeLab-webOS-DiscoveryV2-08df13b15bf0b5bd66fdf7dceb6359b18d67042b`
- GitHub artifact digest: `sha256:8babd2765d40c5480acf765a186a673c648ec2c790f7d088d71b76ee3b611d3e`
- IPK manifest SHA-256: `ebceaf7da758c792eaf939102d76ceac9b2d3d1ae330d9bf69eea7960ca14018`
- app ID: `org.moonfin.webos`
- version: `2.7.0`
- main: `index.html`

No v1 branch/candidate was overwritten. No physical LG acceptance is claimed.

## Current implementation direction

webOS remains the current slice. Do not jump to deployment merely because run #15 is green.

Next webOS work should deliberately assess and improve:

- semantic regression against accepted legacy 481/486 and genuinely unsupported-lane accounting
- recommendation/lane quality and personal strategy diversity
- cross-row and title-family duplication
- remote focus/navigation/Back across tabs, rows, detail-return, See All, partial grids and load-more edges
- visual consistency/responsiveness and legacy-TV rendering constraints
- performance/caching/retained-state/stale-request behaviour
- loading/error/empty/partial-failure combinations
- request/detail/local-media/playback integration
- catalogue change, missing image/provider identity, sparse-lane and exhausted-paging edge cases
- real LG OLED65C6PSA launch/resume/remote/rendering/auth/update acceptance when code gates are ready

After webOS reaches a strong equivalent state, return to the whole Moonfin Discovery product and reassess Web, Android mobile/tablet and Android TV/Google TV alongside webOS. Remaining shared work explicitly includes correctness/architecture, navigation/focus/back, recommendation/lane quality, deep browse, visual consistency/responsiveness, performance/caching, error/loading states, request/detail/playback integration, edge cases/duplication, semantic consistency, real-device acceptance and final polish.

Packaging/cutover preparation remains required later but is not the next priority solely because artifacts now build.

## Physical acceptance not yet claimed

Still requires real execution later:

- Web mouse/touch/keyboard and responsive behaviour
- Android mobile touch/back/resume
- Android TV D-pad/focus/back
- LG OLED65C6PSA remote/focus/back/resume/rendering/update
- request/detail/local-media/playback flows
- production Android signing continuity
- final stock Moonbase/external-Web-root cutover and rollback
