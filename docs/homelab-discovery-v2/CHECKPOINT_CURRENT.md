# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-09 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

Read this file with `docs/AI_PROJECT_STATE.md`. Do not restart completed work or touch live services during GitHub-only completion.

## Current boundary

- Shared semantics/personalisation: **COMPLETE**
- Web: **COMPLETE**
- Android mobile/tablet: **GITHUB/CODE COMPLETE**
- Android TV / Google TV: **ACTIVE NEXT**
- Smart-TV/webOS: do not reconcile until Android TV is complete

## Android mobile/tablet closure

Final source: `4af01af054d9b7cbe8e230b7ded482cb8fea330c`  
Final workflow: **#120 / `34326151119` — GREEN**

Focused validation passed route integration, 486-lane catalogue/compiler + 8 Python tests, format, analyse, focused Discovery tests, Chrome interaction tests and custom-scope validation.

Full candidate passed:

- Web release
- `mobile-beta` APK, 128.1 MB
- `androidTv-beta` APK, 127.1 MB — shared build baseline only, not TV completion proof

Artifact evidence:

- artifact ID `10094778627`
- artifact size `304608904` bytes
- artifact digest `sha256:27e01f5d5db575ee8d853e9808bbee7a2595dfa453be9ccd086ea0b3313cb421`
- mobile APK SHA256 `4d968b1ee2a27dddfdba8c2aa117f7301323dee3d3ce861f075b015992aced8e`
- Android TV APK SHA256 `2c7ece2f5042f93d247b89d490d57de844d8d5b80f1ee05634128d7930e63621`
- Web SHA256 `8f17099b4668300f763d246a6db96ddc7938962b4cad1712171c30dff48b4b73`
- app `2.5.1+30000149`; TV `2.5.1` build `2000016`; Flutter `3.44.1`
- CI signing `debug-fallback-not-for-deployment`

Production/update invariants remain unchanged:

- application ID `org.moonfin.androidtv`; beta `.beta`
- production signing certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- never regenerate production signing; deployment must use the existing release keystore

Physical mobile/tablet acceptance remains deferred.

## Do not redo

Shared semantic/personalisation work, catalogue/compiler, request-cost/paging/cache/dedup/identity safeguards, local-vs-Seerr routing, verified Web pass, Android mobile/tablet completion, docs-only workflow hygiene. Existing recovery refs remain intact.

## Android TV / Google TV — next slice

Use the green #120 Android-TV APK only as a compile/build baseline. Product completion still requires a TV-specific code/test pass over focus memory, D-pad navigation, selection, Back/re-entry, async loading/paging/refresh and TV-specific routing behaviour.

### Acceptance gate

All code-testable Android TV / Google TV focus, D-pad navigation, selection, Back/re-entry and TV-specific grid defects found in the first pass are fixed with focused regressions; verified Web/mobile behaviour remains unchanged; no physical-device, live-service or Smart-TV work starts.

## Exact next action

Inspect the TV-specific requirements in `GITHUB_COMPLETION_PLAN.md`, current `discovery_tv_grid.dart`, landing/deep TV integration and existing TV regression tests. Implement only genuine gaps, launch focused CI from the exact source, record its run/source, then stop under the long-CI rule if the run remains in progress.