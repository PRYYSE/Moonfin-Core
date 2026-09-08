# AI Project State

**Updated:** 2026-09-09 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across the Home Lab Moonfin Discovery product before physical-device, live-service or production acceptance.

Current phase: **Web completion pass final validation**. Shared source-aware personalisation is already complete and must not be redone. Android mobile/tablet work has not started.

Durable plan: `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`  
Mandatory official-update procedure: `docs/UPSTREAM_UPDATE_PROTOCOL.md`

## Moonfin-Core current state

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

Current validation commit:

- `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- `test(discovery-v2): restore Web media-card harness [full-build]`
- exact diff is limited to the Web test harness plus Discovery workflow trigger hygiene; runtime product code was not changed by this recovery fix

Current full workflow:

- run **#115** / ID `34291216084`
- exact source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- status at checkpoint: in progress

Per the long-CI rule, do not poll this run. On continuation inspect this exact run once.

## Web validation recovery evidence

### Run #111 — formatter-only failure

Run #111 / `34202952024` failed at the strict Dart format gate before analysis/tests/builds. Its only required change was the formatter output already committed in `6c9c7f8c524ac1ee0fe5bd8cdfe45a1cf6beea16`.

### Runs #112/#113 — superseded by checkpoint pushes

Run #112 / `34290442346` was cancelled during checkout when the first docs checkpoint commit advanced the same branch. Run #113 was then cancelled by the following docs checkpoint push. Neither cancellation is evidence of a code/test failure.

Root cause was workflow concurrency combined with every docs-only push triggering the Discovery workflow. `1ac1499a...` adds `paths-ignore: ['docs/**']` to branch push triggering so future durable checkpoint commits do not cancel an in-progress validation run.

### Run #114 — useful diagnostic failure

Run #114 / `34290494915` completed enough validation to prove:

- route overlay gate: PASS
- 486-lane catalogue/compiler gate: PASS
- catalogue Python tests: **8 passed**
- strict Dart format: PASS
- Flutter analyse: PASS / no issues
- normal Discovery Flutter suite: **93 passed, 5 Web-only tests skipped**
- Chrome entry/history tests: PASS
- Web tab-strip touch/mouse/keyboard test: PASS
- Chrome total: **8 passed, 4 failed**

All four Chrome failures were the tests that instantiate `HomeLabDiscoveryMediaCard`: missing-art fallback, touch activation, mouse activation and keyboard activation.

The common root cause is the test harness, not four separate product behaviours. Shared `MediaCard` renders `SeerrMediaTypeBadge` for movie/TV items; that badge requires `AppLocalizations.of(context)`. The Chrome `cardHarness()` used a bare `MaterialApp` without Moonfin's localisation delegate, so all four tests failed while building the same shared widget path before their individual assertions could prove anything.

`1ac1499a...` fixes the harness by installing:

- `AppLocalizations.localizationsDelegates`
- `AppLocalizations.supportedLocales`
- deterministic English locale for the test

Meaningful fallback/touch/mouse/keyboard coverage remains intact and isolated. Product `HomeLabDiscoveryMediaCard` / shared `MediaCard` behaviour was not weakened or bypassed.

## Web completion implementation already present

The Web pass covers:

- adaptive wide-Web grid density
- local Jellyfin vs external Seerr details routing, including malformed local-pointer fallback
- Web tab selection by touch, mouse and keyboard
- browser/deep-route history and landing restoration
- shared missing-art/title fallback contract (`Untitled` / `UNTITLED`)
- isolated media-card activation regressions for touch, mouse and keyboard
- retained source-aware Discovery semantics, filtering, deduplication and guarded fallback

Do not collapse the isolated Web input tests back into one compound test without a concrete reason.

## Last fully verified product/build acceptance point

Until #115 is green, the last fully green candidate remains:

- source `5d9f3e63d644f303db918b02d31bf55be7e92346`
- workflow `34189599805` / run #102 GREEN
- Discovery Flutter tests: 88 passed
- catalogue Python tests: 8 passed
- Web release + Android mobile-beta + Android-TV-beta candidate builds passed
- artifact `10042251886`

A green #115 will supersede this as the Web code/build acceptance point. Android APKs produced by this full candidate workflow are validation artefacts only; they do not mean the Android completion pass has started or completed.

## Shared personalisation contract — complete, do not redo

Truthful provenance-specific personalisation and explicit generic affinity strategies are already implemented and verified. Unknown structural/context semantics fail closed. Request cost, paging, caching, deduplication, identity preservation and force-refresh safeguards are already covered by the shared batch.

## Smart-TV / webOS

Do not redo Smart-TV work during this Web validation slice. Its advanced isolated implementation remains at its separately verified GitHub checkpoint; final reconciliation comes later in the completion order. No physical LG acceptance is claimed.

## Stable / recovery state

Live remains deliberately untouched as rollback:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Recovery refs remain intact. Accepted Android signing cert SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate signing.

## Completion order

1. shared semantic/personalisation contract — COMPLETE
2. Web completion pass — IMPLEMENTED, #115 FINAL VALIDATION IN PROGRESS
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

Inspect workflow **#115 (`34291216084`) once**.

- If green: verify focused-validation, exact Chrome/Flutter test evidence, full candidate build and artifact metadata; update this file and `CHECKPOINT_CURRENT.md` with the exact verified source/run/artifact; commit the docs-only Web-complete checkpoint; stop. **Do not start Android in that same run.**
- If red: diagnose only the specific remaining gate/test, fix the genuine root cause without weakening Web coverage, trigger the required full workflow, record its exact source/run here, and stop under the long-CI rule.
