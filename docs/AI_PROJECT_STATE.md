# AI Project State

**Updated:** 2026-09-08 Australia/Adelaide

## Current objective

Home Lab Discovery v2: produce one polished Discovery experience across Web, Android mobile/tablet, Android TV/Google TV and LG webOS while keeping the custom Moonfin diff narrow and maintainable.

Current implementation slice is **LG/webOS**. Green builds/packages are milestones only. After webOS reaches a strong equivalent state, return to all four clients for semantic validation, UX/performance/integration refinement, real-device acceptance and final polish.

## Repositories / branches

- `PRYYSE/Moonfin-Core:homelab/discovery-v2`
  - current product source milestone: `86acba1246ea5e9424fcc96c9729c1e474359c53`
  - latest recovery/checkpoint docs are newer than that product source; trust branch state and `docs/homelab-discovery-v2/CHECKPOINT_CURRENT.md`
- `PRYYSE/Smart-TV:homelab/webos-discovery-v2`
  - verified product source: `08df13b15bf0b5bd66fdf7dceb6359b18d67042b`
  - Smart-TV checkpoint doc commit follows that source
- preserved Smart-TV baseline: `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`

## Completed milestones

### Moonfin Flutter/Web/Android

- isolated Home Lab Discovery architecture and guarded stock fallback
- deterministic concurrent loading/post-fetch presentation
- full 486-lane authoring catalogue/compiler validation
- personalisation adapter, membership filtering and persistent rotation
- polished implementation foundation for landing + deep `See All`
- TV focus/navigation hardening
- reproducible Web/mobile/Android-TV candidate builds
- latest source milestone workflow `34104075134` / #62 GREEN

These clients are **not** considered product-finished; real semantic/UX/integration/device acceptance remains.

### webOS

Verified through Smart-TV source `08df13b15bf0b5bd66fdf7dceb6359b18d67042b`:

- guarded six-tab catalogue UI + stock `SeerrDiscover` fallback
- Enact Spotlight navigation/focus foundation
- deep `See All` virtual browse and focus restoration
- deterministic tab/lane loading, membership and server-scoped catalogue/LKG
- Jellyfin-backed personalisation with sixteen deterministic slots
- explicit anime filtering and dynamic `Because You Watched ...` titles
- persistent surfaced-lane rotation and refresh/reset behaviour
- recovered Jest/runtime boundary without weakening production personalisation
- strict lint warning fixed
- workflow `34178662792` / #15 GREEN: 11 suites / 53 tests, build, legacy compatibility, IPK, identity and artifact upload
- artifact `10038154398`, digest `sha256:8babd2765d40c5480acf765a186a673c648ec2c790f7d088d71b76ee3b611d3e`
- IPK manifest SHA-256 `ebceaf7da758c792eaf939102d76ceac9b2d3d1ae330d9bf69eea7960ca14018`
- identity preserved: `org.moonfin.webos`, version `2.7.0`, main `index.html`

## Known issues / blockers

- no physical LG acceptance yet
- semantic regression accounting against accepted legacy 481/486 remains open
- recommendation/lane quality, duplication, UX/focus/back, performance/caching and integration need deliberate product review
- Web/Android/Android TV still require equivalent shared-product review and physical acceptance after the webOS slice
- live server/cutover remains deliberately untouched

## Important decisions / quirks

- quality/maintainability/polish over speed
- do not fake unsupported catalogue semantics
- do not overwrite preserved webOS v1 or change `org.moonfin.webos`
- do not regenerate Android signing certificate
- do not equate green CI/package generation with completion
- production live legacy state stays rollback until replacement passes acceptance

## Tests/builds

- Smart-TV workflow `34178662792` / #15: GREEN
  - 11/11 focused Discovery suites
  - 53/53 tests
  - strict lint/build
  - legacy WebKit compatibility path
  - Enact production build
  - IPK package/identity verification
  - isolated artifact upload
- Moonfin Flutter source milestone workflow `34104075134` / #62: GREEN

## Exact next actions

1. Continue webOS product-quality hardening as one substantial batch: semantic regression accounting plus recommendation/duplication quality and remote/deep-browse integration review, fixing worthwhile defects discovered.
2. Continue webOS UX/performance/error/integration hardening and then controlled physical LG acceptance when appropriate.
3. Return to the whole Moonfin Discovery product and perform the remaining shared/cross-platform semantic, UX, performance, request/detail/playback, edge-case and consistency work.
4. Perform real-device acceptance across Web, Android mobile/tablet, Android TV/Google TV and LG webOS.
5. Only after product gates are credible, prepare/finalise atomic server cutover/rollback and production deployment.
