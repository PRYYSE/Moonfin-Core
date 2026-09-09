# AI Project State

**Updated:** 2026-09-09 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

**Current phase:** Android TV / Google TV completion — first remote-recovery/focus slice implemented; focused validation #121 in progress. Android mobile/tablet is GitHub/code complete.

## Android mobile/tablet — COMPLETE

Final source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`; workflow #120 / `34326151119` GREEN.

Final evidence:

- route + 486-lane catalogue/compiler PASS
- catalogue Python tests: 8 passed
- format: 53 files, 0 changed
- analyse: no issues
- Discovery suite: 100 passed, 5 skipped
- Chrome Web/entry-route: 12 passed
- full Web + `mobile-beta` + `androidTv-beta` candidate PASS
- artifact `10094778627`
- digest `sha256:27e01f5d5db575ee8d853e9808bbee7a2595dfa453be9ccd086ea0b3313cb421`
- mobile SHA256 `4d968b1ee2a27dddfdba8c2aa117f7301323dee3d3ce861f075b015992aced8e`
- TV baseline SHA256 `2c7ece2f5042f93d247b89d490d57de844d8d5b80f1ee05634128d7930e63621`
- Web SHA256 `8f17099b4668300f763d246a6db96ddc7938962b4cad1712171c30dff48b4b73`

Physical mobile/tablet acceptance remains deferred.

## Android TV / Google TV — ACTIVE

### Existing verified foundations — do not redo

- `HomeLabDiscoveryTvLane` uses the locked-focus row primitive
- `HomeLabDiscoveryTvGrid` has deterministic single focus ownership
- existing regressions cover Select, horizontal/vertical D-pad movement, partial final rows, Back, near-end paging, pointer activation and focus memory
- landing restores lane focus after details and See All return
- deep browse restores grid focus after details and paging retry
- local Jellyfin vs Seerr routing is shared and already verified
- #120 proves the current `androidTv-beta` flavor compiles and packages successfully, but is not TV product-completion proof

TV/update identity remains:

- production app ID `org.moonfin.androidtv`; beta `.beta`
- TV version `2.5.1`, build `2000016`
- forced-TV build uses `MOONFIN_FORCE_TV=true`
- TV flavors disable Impeller
- production signing certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- never regenerate production signing material
- CI APKs remain `debug-fallback-not-for-deployment`

### TV Slice 1 — IMPLEMENTED; #121 PENDING

Defect review found a real remote-only recovery gap: a genuine-empty deep collection exposed explicit Refresh on Web and pull-refresh on touch, but no TV remote action. Failure/empty action buttons also lacked deterministic initial TV focus.

Source:

`9788338cb27a86cb4024ee8dbe57b82bfcf68f21`

Commit:

`feat(discovery-v2): make TV recovery remote-safe`

Exact source diff:

- `homelab_discovery_see_all_screen.dart`: deep genuine-empty now exposes Refresh on TV as well as Web and TV recovery actions autofocus; deep Retry has a stable regression key
- `homelab_discovery_screen.dart`: landing/runtime/tab failure and genuine-empty action autofocuses on TV
- new `homelab_discovery_tv_recovery_test.dart`

New TV integration regressions cover:

- TV tab strip reachable and selectable through keyboard/D-pad focus semantics
- genuine-empty deep browse Refresh via remote Select, followed by TV-grid recovery
- failed deep load Retry via remote Select, followed by TV-grid recovery

No shared controller/catalogue/routing, Android Gradle/package/signing or Smart-TV/live code changed.

Focused workflow:

- **#121 / `34331824783`**
- exact source `9788338cb27a86cb4024ee8dbe57b82bfcf68f21`
- status at checkpoint: **in progress**
- no `[full-build]`; candidate build is not part of this first TV slice

Per the long-CI rule, do not poll #121. Inspect it once on continuation.

### Remaining Android TV completion scope after #121

If #121 is green, continue the narrow TV defect/review pass over:

- navbar/tab/lane transitions and re-entry
- populated deep-grid paging-error reachability/focus restoration
- Back/detail return
- off-screen focus/scroll behaviour at 1080p/4K
- lifecycle/resume and retained state inherited from shared controllers
- package/version/signing/update safety
- final targeted tests and required full candidate build

Physical TV acceptance remains deferred.

## Completed foundations — do not redo

- shared semantics/personalisation and request-cost/paging/cache/dedup/identity safeguards
- 486-lane catalogue/compiler
- local-vs-Seerr details routing
- Web completion `1ac1499a0d43d404fa46d1e1abf49a433f972ea9` / #115
- Android mobile/tablet completion `4af01af054d9b7cbe8e230b7ded482cb8fea330c` / #120
- docs-only CI trigger hygiene

Unsupported structural/context semantics remain fail-closed.

## Smart-TV / webOS and live

Do not inspect or modify Smart-TV/webOS until Android TV / Google TV is complete. Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. Existing recovery refs remain intact.

## Completion order

1. shared semantics/personalisation — COMPLETE
2. Web — COMPLETE
3. Android mobile/tablet — COMPLETE
4. Android TV / Google TV — **ACTIVE; #121 PENDING**
5. final webOS reconciliation
6. cross-platform parity/recommendation quality
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance

## Exact next action

Inspect workflow #121 (`34331824783`) exactly once. If green, record its focused evidence and continue Android-TV-specific review only. If red, inspect only the failing gate, fix the root cause without weakening TV regressions, launch a replacement focused run, checkpoint exact source/run, and stop under the long-CI rule.
