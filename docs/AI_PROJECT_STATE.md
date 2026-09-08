# AI Project State

**Updated:** 2026-09-09 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across the Home Lab Moonfin Discovery product before physical-device, live-service or production acceptance.

Current phase: **Web completion pass final validation**. Shared source-aware personalisation is already complete and must not be redone. Android work has not started in this continuation.

Durable plan: `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`  
Mandatory official-update procedure: `docs/UPSTREAM_UPDATE_PROTOCOL.md`

## Moonfin-Core current state

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

Latest source commit:

- `6c9c7f8c524ac1ee0fe5bd8cdfe45a1cf6beea16`
- `style(discovery-v2): format Web regression test [full-build]`

Current full workflow:

- run **#112** / ID `34290442346`
- source `6c9c7f8c524ac1ee0fe5bd8cdfe45a1cf6beea16`
- queued at checkpoint time; inspect this exact run once on continuation

Previous run #111 / ID `34202952024` failed before tests at the strict Dart format gate only. The formatter required one line in `test/homelab_discovery/homelab_discovery_web_test.dart` to collapse. No Web behaviour regression was executed in that run. The exact formatter output was applied in `6c9c7f8c...` without changing test semantics.

### Web completion implementation already present

The Web pass added/covered:

- adaptive wide-Web grid density
- local Jellyfin vs external Seerr details routing, including malformed local-pointer fallback
- Web tab strip touch, mouse and keyboard selection
- shared missing-art/title fallback contract (`Untitled` / `UNTITLED`)
- isolated media-card activation regressions for touch, mouse and keyboard
- retained source-aware Discovery behaviour from the verified shared contract

The media-input tests were deliberately split so each input contract fails independently rather than sharing focus/input state in one compound test.

### Last fully verified product/build acceptance point

Until #112 passes, the last green full candidate remains:

- source `5d9f3e63d644f303db918b02d31bf55be7e92346`
- workflow `34189599805` / run #102 GREEN
- Discovery Flutter tests: 88 passed
- catalogue Python tests: 8 passed
- Web release + Android mobile-beta + Android-TV-beta builds passed
- artifact `10042251886`

A green #112 will supersede this as the code/build acceptance point for the Web pass.

## Shared personalisation contract — complete, do not redo

Supported provenance-specific strategies:

- recent-history
- favourites
- watchlist
- high-ratings
- likes
- mixed-positive
- anime-recent-history
- anime-favourites
- anime-watchlist
- anime-high-ratings
- recently-added
- trending-anime

Existing explicit generic affinity strategies remain supported. Unknown structural/context semantics fail closed. Request cost, paging, caching, deduplication, identity preservation and force-refresh safeguards are already covered by the shared batch.

## Smart-TV / webOS

Do not redo Smart-TV work during this Web validation slice. Its advanced isolated implementation remains at its separately verified GitHub checkpoint; final reconciliation comes after Android TV in the completion order. No physical LG acceptance is claimed.

## Stable / recovery state

Live remains deliberately untouched as rollback:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Recovery refs remain intact. Accepted Android signing cert SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate signing.

## Completion order

1. shared semantic/personalisation contract — COMPLETE
2. Web completion pass — IMPLEMENTED, #112 FINAL VALIDATION PENDING
3. Android mobile/tablet completion pass
4. Android TV / Google TV completion pass
5. final webOS reconciliation
6. cross-platform parity/recommendation-quality pass
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance and cutover

## Known acceptance-only work

Still deferred:

- subjective Web browser acceptance
- Android phone/tablet device acceptance
- Android TV / Google TV device acceptance
- physical LG rendering/performance/remote/Back/lifecycle/update acceptance
- live Jellyfin/Seerr recommendation-quality capture
- real request/detail/local playback acceptance
- production deployment/cutover

## Exact next action

Inspect workflow #112 (`34290442346`) once.

- If green: verify its candidate artifact/build evidence, update this file and `CHECKPOINT_CURRENT.md` with the exact verified source/run/artifact, commit the docs-only checkpoint, and stop. Do **not** start Android in that same run.
- If red: diagnose only the specific failing gate/test, fix the root cause without weakening meaningful Web coverage, trigger the required full workflow, record its run/source here, and stop under the long-CI rule.
