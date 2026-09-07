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

Focused validation passed and the full candidate job successfully produced:

- Web release tarball
- Android `mobile-beta` APK
- Android `androidTv-beta` APK
- source/build metadata
- SHA-256 manifest

Artifact ID: `10005927276`  
Artifact digest: `sha256:2baccfb03a43bfb61ec5d82b7a5f9e75a63bea6630613b6652b167b045632713`

Independent post-CI archive verification:

- Android TV APK: `a81e091f5fa458711a233983f495657dd9a01157bfa7de0b806cf58cdbda1df8`
- Android mobile APK: `f732133d4bdbb4a90bc429091760448e772c5a20e5bfc63cd6878da455bb194c`
- Web tarball: `469bc0acdf9179726683c58e29a7061767585873e8d934a8c8a4e481fbe6d78f`

All three manifest checksums matched the downloaded files. The Web archive opens and contains expected application assets; both APKs are structurally recognised as Android packages.

CI Android signing is deliberately debug fallback. These APKs prove builds only and must not replace the existing deployment identity. Production/beta installation must preserve cert SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`.

Checkpoint-only follow-up `045a138526403ad2f4a5d06e52b8c70f059ac3ef` passed workflow `34088720989` fully green; the full build job correctly skipped because no product code changed.

## LG/webOS Discovery v2 branch — 2026-09-07

The preserved Smart-TV candidate remains untouched at `PRYYSE/Smart-TV:homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.

A new branch `homelab/webos-discovery-v2` was created from that exact candidate for the new work. The first foundation slice adds:

- a fail-closed catalogue query planner matching Moonfin-Core's filter/sort/date-token policy
- a network-first server-scoped catalogue/LKG loader
- a narrow authenticated Moonbase Seerr proxy client with path/query allow-lists
- 15 focused service tests
- an isolated CI/package workflow that never publishes over the known-good webOS candidate

First workflow `34088375809` proved all 15 service tests passed. Its package stage then correctly exposed one lint-only defect in the test (`Buffer` no-undef); product code had not failed. Commit `367e5a776efec8fd3a775dfbbb31c89b46d883ae` replaced that Node-only test helper with browser-native `window.btoa`. Follow-up workflow `34088757515` is the current verification run at the time of this ledger update.

App identity remains `org.moonfin.webos`; baseline version remains 2.7.0. No release/tag was overwritten.

## Still open

- finish the current webOS foundation/package gate and checkpoint it green
- harden Flutter landing TV/D-pad focus without changing Web/mobile pointer/touch behaviour
- add TV focus/selection/edge regression coverage
- build six-tab catalogue-driven webOS Discovery behind preserved stock fallback
- implement or explicitly fail closed for webOS personalisation only after verifying a real supported Jellyfin strategy
- semantic regression accounting against the accepted legacy 481/486 result
- rerun reproducible candidate builds after interaction/focus work
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
