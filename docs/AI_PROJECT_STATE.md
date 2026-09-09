# AI Project State

**Updated:** 2026-09-09 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across the Home Lab Moonfin Discovery product before physical-device, live-service or production acceptance.

**Current phase:** Android mobile/tablet completion pass — **Slice 1 implemented, focused validation pending**.

Durable implementation order: `docs/homelab-discovery-v2/GITHUB_COMPLETION_PLAN.md`  
Mandatory official-update procedure: `docs/UPSTREAM_UPDATE_PROTOCOL.md`

## Moonfin-Core current state

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

Current source-changing commit:

- `086a41b0092f388d82c98ca2803e37b89dc6e46d`
- `feat(discovery-v2): harden Android adaptive touch baseline`

Focused workflow:

- run **#116** / ID `34320947110`
- exact source `086a41b0092f388d82c98ca2803e37b89dc6e46d`
- status at checkpoint: **in progress**

Per the long-CI rule, do not poll #116. On continuation inspect this exact run once.

## Android mobile/tablet pass — 3 slices

### Slice 1 — adaptive/touch baseline — IMPLEMENTED, VALIDATION PENDING

Implemented:

- explicit compact / medium / expanded window classes at `<600`, `600–839`, `>=840` px
- lane cards now use `124 / 140 / 148` px across those classes, giving phone-landscape and medium-tablet layouts a distinct density instead of jumping directly from compact to wide-Web sizing
- wide Web behaviour remains unchanged at `148` px for `>=840` px
- non-Web Discovery tabs explicitly preserve the Material minimum interactive height (`48` px)
- new native/mobile regressions cover:
  - compact/medium/expanded breakpoints and safe invalid-width fallback
  - representative phone/tablet deep-grid column density
  - full-height tab touch targets and tap selection
  - shared missing-art fallback plus exactly-once card activation by touch

Exact source diff is limited to:

- `lib/features/homelab_discovery/ui/discovery_adaptive_layout.dart`
- `lib/features/homelab_discovery/ui/discovery_tab_strip.dart`
- `test/homelab_discovery/homelab_discovery_mobile_test.dart`

### Slice 2 — mobile UX/state robustness — NEXT AFTER #116 GREEN

Target code-testable work:

- phone/tablet portrait/landscape spacing and deep-browse ergonomics
- scrolling/refresh/paging behaviour on touch surfaces
- loading/error/genuine-empty actions
- Android Back behaviour through landing, detail and See All paths
- lifecycle/resume and retained Discovery/deep-browse state
- malformed identity/artwork regressions where Android-specific coverage is still missing

### Slice 3 — Android final validation

- defect/review pass over the mobile/tablet surface
- focused Android regressions
- auth/local-state/update-safety and signing/build checks that are code/CI-testable
- required full candidate workflow
- exact artifact/signing/build evidence
- durable Android-complete checkpoint

Physical phone/tablet acceptance remains deferred.

## Last fully verified product/build baseline

Web/shared product baseline remains:

- source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- workflow **#115** / ID `34291216084` — GREEN
- normal Discovery suite: **93 passed, 5 Web-only skipped**
- Chrome Web/route suite: **12 passed**
- catalogue Python tests: **8 passed**
- Web release + Android `mobile-beta` + Android `androidTv-beta` candidate builds passed
- artifact `10082137559`
- artifact digest `sha256:f2a7fc6b32667d3f4d38cf3a8e4165c2cce46d39facbd6dccb029687365e2abc`

Production Android signing must continue to preserve accepted cert SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate it. CI candidate signing may remain debug fallback until the final Android signing/release gate explicitly verifies production identity.

## Completed foundations — do not redo

- shared semantic/personalisation contract
- truthful source-specific personalisation adapters
- bounded request cost, caching, paging, deduplication and identity handling
- guarded stock fallback
- landing + deep `See All` foundations
- details/local-vs-Seerr routing foundations
- TV focus/D-pad foundations
- **Web completion pass verified at `1ac1499a...` / #115**
- docs-only workflow trigger hygiene

Unsupported structural/context semantics remain fail-closed.

## Smart-TV / webOS

Do not redo Smart-TV during Android work. Final webOS reconciliation comes after Android TV / Google TV. No physical LG acceptance is claimed yet.

## Stable / rollback state

Live remains deliberately untouched:

- custom Moonbase 2.0.3.1
- Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery 481/486
- Seerr enabled

Existing recovery refs remain intact. Do not modify live services during GitHub-only completion work.

## Completion order

1. shared semantic/personalisation contract — **COMPLETE**
2. Web completion pass — **COMPLETE**
3. Android mobile/tablet completion pass — **SLICE 1 IMPLEMENTED; #116 VALIDATION PENDING**
4. Android TV / Google TV completion pass
5. final webOS reconciliation
6. cross-platform parity/recommendation-quality pass
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance and cutover

## Exact next action

Inspect workflow **#116 (`34320947110`) once**.

- If green: record Slice 1 as verified, then begin **Slice 2 — mobile UX/state robustness** without revisiting Web/shared work.
- If red: inspect only the failing gate/test, fix the genuine root cause without weakening the new mobile coverage, trigger the appropriate focused workflow, checkpoint its exact source/run, and stop under the long-CI rule.
