# AI Project State

**Updated:** 2026-09-09 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code across Home Lab Moonfin Discovery before physical-device, live-service or production acceptance.

Repository: `PRYYSE/Moonfin-Core`  
Branch: `homelab/discovery-v2`

**Current phase:** Android mobile/tablet **GitHub/code COMPLETE**; Android TV / Google TV completion is next. Smart-TV/webOS remains later.

## Android mobile/tablet — COMPLETE

### Verified implementation

- Slice 1 source `086a41b0092f388d82c98ca2803e37b89dc6e46d`; #116 / `34320947110` GREEN
- Slice 2 functional source `0aeadfb6ef948502c5e64bface0374fe2ed66ceb`; formatter recovery `3cab6c5430eb6175320c4f16c4932218b41d42b8`; #118 / `34322882024` GREEN
- final source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`
- #119 / `34323556542` failed only formatting in the final paging regression; exact formatter output was applied with no logic change
- #120 / `34326151119` — **GREEN**

Final mobile behaviour covered in code/tests includes adaptive phone/tablet sizing, minimum native touch targets, retained Discovery state across ordinary reconstruction/orientation/resume, retry-safe failure handling, explicit refresh/reset semantics, safe deep paging/refresh sequencing, duplicate near-end paging coalescing, loading/error/empty handling, pull-refresh, artwork/title fallback, local-vs-Seerr routing and Android Back behaviour.

### #120 final evidence

Focused validation passed:

- route integration
- 486-lane catalogue/compiler + 8 catalogue Python tests
- Dart format
- Flutter analyse
- focused Discovery tests, including the final overlapping `loadMore()` regression
- Chrome Web/entry-route interaction tests
- narrow custom-scope gate

Full candidate build passed:

- Web release: PASS
- Android `mobile-beta`: PASS, generated `app-mobile-beta-release.apk` (128.1 MB)
- Android `androidTv-beta`: PASS, generated `app-androidtv-beta-release.apk` (127.1 MB); this is only the TV phase build baseline, not Android TV completion proof

Candidate metadata:

- source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`
- Flutter `3.44.1`
- app `2.5.1+30000149`
- Android TV `2.5.1`, build `2000016`
- artifact `10094778627`
- artifact size `304608904` bytes
- artifact digest `sha256:27e01f5d5db575ee8d853e9808bbee7a2595dfa453be9ccd086ea0b3313cb421`
- Android mobile SHA256 `4d968b1ee2a27dddfdba8c2aa117f7301323dee3d3ce861f075b015992aced8e`
- Android TV SHA256 `2c7ece2f5042f93d247b89d490d57de844d8d5b80f1ee05634128d7930e63621`
- Web SHA256 `8f17099b4668300f763d246a6db96ddc7938962b4cad1712171c30dff48b4b73`

### Signing / update identity

- production app ID remains `org.moonfin.androidtv`; beta remains `org.moonfin.androidtv.beta`
- no Gradle/manifest/auth/secure-storage/signing configuration changed during the mobile pass
- accepted production signing certificate SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`
- never regenerate or replace production signing material
- CI candidate signing is `debug-fallback-not-for-deployment`; production deployment must continue using the existing Home Lab release keystore

Physical phone/tablet acceptance remains deliberately deferred.

## Completed foundations — do not redo

- shared semantics/personalisation and bounded request-cost/paging/cache/dedup/identity safeguards
- 486-lane catalogue/compiler
- local-vs-Seerr details routing
- Web completion at `1ac1499a0d43d404fa46d1e1abf49a433f972ea9` / #115
- Android mobile/tablet completion through `4af01af...` / #120
- existing TV focus/D-pad foundations; Android TV product completion has not yet been performed
- docs-only CI trigger hygiene

## Other platforms / live

Do not inspect or modify Smart-TV/webOS until after Android TV / Google TV. Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled.

## Completion order

1. shared semantics/personalisation — COMPLETE
2. Web — COMPLETE
3. Android mobile/tablet — **COMPLETE**
4. Android TV / Google TV — **ACTIVE NEXT**
5. final webOS reconciliation
6. cross-platform parity/recommendation quality
7. whole-product CI/release engineering
8. upstream-update automation/protocol integration
9. explicit GitHub completion checkpoint
10. physical/live acceptance

## Exact next action

Begin Android TV / Google TV completion from the verified #120 baseline. Inspect only TV-specific focus/D-pad/navigation tests and code plus the Android-TV requirements in `GITHUB_COMPLETION_PLAN.md`; fix real code-testable gaps, add focused regressions, trigger focused CI, and checkpoint the exact source/run. Do not touch Smart-TV/webOS or live services.