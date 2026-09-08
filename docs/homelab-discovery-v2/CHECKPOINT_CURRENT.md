# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-09 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file and `docs/AI_PROJECT_STATE.md` first. Use `GITHUB_COMPLETION_PLAN.md` for implementation order and `docs/UPSTREAM_UPDATE_PROTOCOL.md` for official Moonfin updates.

Do not restart completed work or modify the live server during GitHub-only completion work.

## Current boundary

The shared source-aware personalisation batch is complete and verified. The **Web completion pass is implemented and awaiting one definitive full-workflow result**.

Current validation source:

- `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- `test(discovery-v2): restore Web media-card harness [full-build]`
- workflow **#115** / ID `34291216084`
- status at checkpoint: in progress

Per the long-CI rule, do not poll it. Inspect #115 once on continuation.

## Narrow recovery since the previous checkpoint

### #112/#113 were cancelled, not failed

#112 (`34290442346`) was cancelled during checkout by the next docs-only checkpoint push; #113 was then cancelled by another docs-only push. The workflow used branch-wide `cancel-in-progress`, so every checkpoint commit superseded the in-progress run.

`1ac1499a...` corrects this workflow-level root cause by ignoring `docs/**` for push-triggered Discovery validation. Docs-only durable checkpoint commits therefore no longer start/cancel this workflow.

### #114 isolated the real Chrome test-harness defect

#114 (`34290494915`) passed:

- route integration
- 486-lane catalogue/compiler validation
- 8 catalogue Python tests
- strict Dart formatting
- Flutter analyse with no issues
- normal Discovery suite: **93 passed, 5 Web-only skipped**
- Web tab-strip touch/mouse/keyboard test
- all Chrome entry/history tests

Chrome finished **8 passed, 4 failed**. The four failures were exactly the four `HomeLabDiscoveryMediaCard` tests: missing-art fallback plus touch, mouse and keyboard activation.

They shared one harness defect. `HomeLabDiscoveryMediaCard` uses shared `MediaCard`, which renders `SeerrMediaTypeBadge` for movie/TV items. That badge requires `AppLocalizations.of(context)`, while the Chrome `cardHarness()` had a bare `MaterialApp` with no Moonfin localisation delegate.

`1ac1499a...` fixes only that test environment by installing:

- `AppLocalizations.localizationsDelegates`
- `AppLocalizations.supportedLocales`
- English locale

The missing-art, touch, mouse and keyboard assertions remain independent and unchanged. Runtime media-card logic was not altered to make tests pass.

## Web pass coverage now in source

- adaptive Web grid density
- owned Jellyfin vs external Seerr routing
- malformed local Jellyfin pointer safely falls back to external details
- Web tab selection by touch, mouse and keyboard
- browser/deep-route history and landing restoration
- shared missing-art/title fallback (`Untitled` / `UNTITLED`)
- media-card activation independently covered for touch, mouse and keyboard
- shared source-aware Discovery semantics and guarded fallback retained

Do not collapse the isolated media input tests back into one compound regression without a concrete reason.

## Last fully green product/build acceptance point

Until #115 is green, the accepted full candidate remains:

- source `5d9f3e63d644f303db918b02d31bf55be7e92346`
- workflow `34189599805` / #102 GREEN
- 88 Discovery Flutter tests passed
- 8 catalogue Python tests passed
- Web release + Android mobile-beta + Android-TV-beta candidate builds passed
- artifact `10042251886`

A green #115 supersedes that as the Web code/build acceptance point. Android APKs produced by the candidate job are validation artefacts only; the Android completion pass has not started.

## Completed work that must not be redone

- isolated Home Lab Discovery architecture and guarded stock fallback
- deterministic concurrent loading/presentation
- 486-lane authoring/compiler validation
- membership/NSFW filtering
- persistent lane rotation
- landing + deep `See All`
- TV focus/D-pad hardening
- external/local identity correction
- explicit generic affinity personalisation
- truthful source-aware personalisation adapters
- bounded request cost, paging, caching, dedup, identity and force-refresh safeguards
- Web completion implementation listed above
- existing advanced webOS implementation at its separate verified checkpoint

Unsupported structural/context semantics remain fail-closed. Do not re-enable them by approximation.

## Stable / rollback state

Live remains untouched:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Recovery refs remain intact. Production Android signing must preserve cert SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`.

## Exact next action

Inspect workflow **#115 (`34291216084`) once**.

### If green

1. verify focused-validation and exact Flutter/Chrome test evidence;
2. verify Web + mobile-beta + Android-TV-beta candidate build conclusion;
3. verify candidate artifact metadata and source SHA;
4. record final Web evidence here and in `docs/AI_PROJECT_STATE.md`;
5. commit docs-only Web-complete checkpoint;
6. stop. **Do not start Android in the same run.**

### If red

1. inspect only the exact failing gate/test;
2. fix the genuine root cause without weakening meaningful Web coverage;
3. trigger the required full workflow;
4. record exact source/run in both checkpoints;
5. stop under the long-CI rule.

## Following batch after Web is checkpointed green

Android mobile/tablet completion pass.
