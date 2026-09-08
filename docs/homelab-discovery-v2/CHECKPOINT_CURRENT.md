# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-09 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file and `docs/AI_PROJECT_STATE.md` first. Use `GITHUB_COMPLETION_PLAN.md` for order and `docs/UPSTREAM_UPDATE_PROTOCOL.md` for official Moonfin updates.

Do not restart completed work or modify the live server during GitHub-only completion work.

## Current boundary

The shared source-aware personalisation batch is complete and verified. The **Web completion pass is implemented and awaiting final full-workflow validation**.

Latest source-changing commit:

- `6c9c7f8c524ac1ee0fe5bd8cdfe45a1cf6beea16`
- `style(discovery-v2): format Web regression test [full-build]`

Current validation:

- workflow run **#112**
- run ID `34290442346`
- exact source `6c9c7f8c524ac1ee0fe5bd8cdfe45a1cf6beea16`
- status at checkpoint: queued

Per the long-CI rule, do not poll this run continuously. On continuation inspect this exact run once.

## Why #112 exists

Run #111 (`34202952024`) failed at the strict Dart format gate before analysis/tests/builds. CI showed exactly one formatter-only delta in `test/homelab_discovery/homelab_discovery_web_test.dart`:

```dart
await tester.pumpWidget(cardHarness(() => activations++, autofocus: true));
```

That exact formatting output was committed in `6c9c7f8c...`. No test semantics or product behaviour were changed.

## Web pass coverage now in source

- adaptive Web grid density on narrow/wide displays
- correct owned Jellyfin vs external Seerr routing
- malformed local Jellyfin pointer fails safely to external details
- Web Discovery tab selection by touch, mouse and keyboard
- shared missing-art/title fallback (`Untitled` and `UNTITLED`)
- media-card activation tested independently for touch, mouse and keyboard
- media input regressions are split into isolated tests so shared focus/state cannot obscure the failing contract

Do not collapse these back into one compound regression unless there is a concrete reason.

## Last fully green product/build acceptance point

Until #112 is green, the last accepted full candidate remains:

- source `5d9f3e63d644f303db918b02d31bf55be7e92346`
- workflow `34189599805` / run #102 GREEN
- focused validation GREEN
- 88 Discovery Flutter tests passed
- 8 catalogue Python tests passed
- Web release + Android mobile-beta + Android-TV-beta candidate builds passed
- artifact `10042251886`

A green #112 supersedes that source as the Web code/build acceptance point. The Android APKs produced by the full candidate job are validation artefacts only; Android platform completion work remains separate and has not started.

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
- current Web completion implementation listed above
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

Inspect workflow #112 (`34290442346`) once.

### If green

1. verify focused-validation and full candidate job conclusions;
2. verify the candidate artifact metadata and exact source SHA;
3. record final Web test/build evidence here and in `docs/AI_PROJECT_STATE.md`;
4. commit the docs-only Web-complete checkpoint;
5. stop. **Do not start Android in the same run.**

### If red

1. inspect only the failing gate/test logs;
2. fix the genuine root cause without weakening Web coverage;
3. trigger the required full workflow;
4. record its exact run ID/source in both durable checkpoints;
5. stop under the long-CI rule.

## Following batch after Web is checkpointed green

Android mobile/tablet completion pass.
