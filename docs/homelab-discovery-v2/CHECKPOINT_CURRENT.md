# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-09 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file and `docs/AI_PROJECT_STATE.md` first. Use `GITHUB_COMPLETION_PLAN.md` for implementation order and `docs/UPSTREAM_UPDATE_PROTOCOL.md` for official Moonfin updates.

Do not restart completed work or modify the live server during GitHub-only completion work.

## Current boundary

Shared personalisation and the Web completion pass are verified complete. Android mobile/tablet is now active and intentionally split into three slices to reduce timeout risk.

Current source:

- `086a41b0092f388d82c98ca2803e37b89dc6e46d`
- `feat(discovery-v2): harden Android adaptive touch baseline`

Current focused workflow:

- **#116** / ID `34320947110`
- exact source `086a41b0092f388d82c98ca2803e37b89dc6e46d`
- status at checkpoint: **in progress**

Do not poll it. Inspect #116 once on continuation.

## Android Slice 1 — adaptive/touch baseline

Implemented:

- explicit compact/medium/expanded window classes: `<600`, `600–839`, `>=840` px
- lane-card widths: `124`, `140`, `148` px across those classes
- wide Web sizing remains unchanged at `148` px for `>=840` px
- non-Web Discovery tabs explicitly use the Material minimum interactive height (`48` px)
- added `homelab_discovery_mobile_test.dart` covering:
  - breakpoint classification and invalid-width fallback
  - representative phone/tablet grid densities
  - 48 px tab touch target + tap selection
  - missing-art fallback + exactly-once touch activation

Source diff is only:

- `lib/features/homelab_discovery/ui/discovery_adaptive_layout.dart`
- `lib/features/homelab_discovery/ui/discovery_tab_strip.dart`
- `test/homelab_discovery/homelab_discovery_mobile_test.dart`

Slice 1 is not called verified until #116 passes.

## Android slices remaining

### Slice 2 — mobile UX/state robustness

After #116 is green:

- refine phone/tablet portrait/landscape ergonomics where code evidence shows a gap
- touch scrolling, pull-to-refresh and deep paging
- loading/error/genuine-empty actions
- Android Back semantics across landing/details/See All
- lifecycle/resume and retained tab/deep state
- Android-specific malformed identity/artwork regressions still missing after shared coverage

### Slice 3 — final Android validation

- final defect/review pass
- focused Android tests
- auth persistence/update-safe state/signing checks that are testable in GitHub/CI
- one required full candidate workflow
- exact build/artifact/signing evidence
- Android mobile/tablet complete checkpoint

Physical-device acceptance remains deferred.

## Last fully green product/build baseline

Until an Android source-changing full build supersedes it:

- source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- workflow **#115** / ID `34291216084` — GREEN
- normal Discovery suite: **93 passed, 5 Web-only skipped**
- Chrome suite: **12 passed**
- catalogue Python tests: **8 passed**
- Web + `mobile-beta` + `androidTv-beta` candidate builds passed
- artifact `10082137559`
- digest `sha256:f2a7fc6b32667d3f4d38cf3a8e4165c2cce46d39facbd6dccb029687365e2abc`

Production Android signing certificate SHA-256 must remain `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate it.

## Completed work that must not be redone

- shared semantic/personalisation contract
- 486-lane catalogue/compiler validation
- guarded stock fallback
- request-cost/paging/cache/dedup/identity safeguards
- landing + deep See All foundations
- local-vs-Seerr details routing
- TV focus/D-pad foundations
- verified Web completion at `1ac1499a...` / #115
- advanced Smart-TV implementation at its separate checkpoint

## Exact next action

Inspect **#116 (`34320947110`) once**.

### If green

1. mark Slice 1 verified;
2. begin **Slice 2 — mobile UX/state robustness**;
3. do not redo shared/Web work;
4. keep physical-device testing deferred.

### If red

1. inspect only the exact failing gate/test;
2. fix the root cause without weakening mobile coverage;
3. trigger the appropriate focused workflow;
4. record exact source/run here and in `docs/AI_PROJECT_STATE.md`;
5. stop under the long-CI rule.
