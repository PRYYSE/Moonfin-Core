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

## LG/webOS Discovery v2 — current engine/package milestone — 2026-09-07

The preserved Smart-TV candidate remains untouched at `PRYYSE/Smart-TV:homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.

The isolated v2 branch `homelab/webos-discovery-v2` was created from that preserved candidate. Current verified source:

`439e64f7d396aca9c9774f8fcbea8af413ebfaaf`

Workflow `34106116784` / run #7 — GREEN.

Verified v2 service/controller foundation:

- fail-closed catalogue query planner matching Moonfin-Core filter/sort/date-token policy
- network-first server-scoped catalogue/LKG loader
- narrow authenticated Moonbase Seerr proxy client with path/query allow-lists
- membership filtering and feature-local lane loading
- catalogue composition
- deterministic tab loading with focused tests
- isolated package build and identity verification

Current isolated webOS artifact:

- ID: `10012493825`
- name: `Moonfin-HomeLab-webOS-DiscoveryV2-439e64f7d396aca9c9774f8fcbea8af413ebfaaf`
- digest: `sha256:d60f07fe926baa240152c58057c9a0650351759a0055ad2f22dc9e50ce20d7a9`

App identity remains `org.moonfin.webos`; baseline version remains 2.7.0. No preserved v1 branch, candidate or release/tag was overwritten.

## Still open

- build the six-tab catalogue-driven webOS Discovery UI behind the preserved `SeerrDiscover` fallback
- reuse existing Enact Spotlight/card/navigation patterns for remote focus, left-edge navbar return, vertical row movement and Back
- add deep webOS `See All`/browse while preserving existing detail/request routing
- determine a real supported Jellyfin strategy for webOS personalisation; unsupported `personalised` semantics must fail closed until proven
- package and verify the completed webOS UI candidate without changing app identity or publishing over v1
- semantic regression accounting against the accepted legacy 481/486 result
- prepare atomic server cutover/rollback and `SERVER_RUNBOOK.md`
- controlled live/server/device acceptance

## Physical acceptance not yet claimed

Still requires real execution later:

- Web mouse/touch/keyboard
- Android mobile touch/back/resume
- Android TV D-pad/focus/back
- LG OLED65C6PSA remote/focus/back/resume/rendering/update
- request/detail/local-media flow
- production Android signing continuity
- final stock Moonbase/external-Web-root cutover and rollback
