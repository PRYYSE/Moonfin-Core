# Official Moonfin Update Protocol

**Applies to:** Web, Android mobile/tablet, Android TV / Google TV, LG webOS and shared Home Lab Discovery tooling  
**Updated:** 2026-09-11 Australia/Adelaide

## Purpose

Keep Home Lab Moonfin maintainable as:

> official Moonfin + a narrow isolated Home Lab overlay

An upstream release is never merged directly into production and never treated as safe merely because it builds. Every official update follows the controlled process below across all supported platforms.

Implementation companion for the current detector/reporting and isolated-update tooling: `docs/homelab-discovery-v2/UPSTREAM_UPDATE_AUTOMATION.md`. This protocol remains authoritative if companion tooling and policy ever differ.

## Permanent identities and rollback rules

Before any update work, preserve the currently accepted source refs and candidate artifacts.

Never regenerate or casually replace:

- Android application/package identity
- accepted Android signing certificate
- webOS app ID `org.moonfin.webos`
- required Web deployment/catalogue paths
- last accepted Web, Android mobile, Android TV and webOS candidates
- archive/recovery refs used by Home Lab rollback

The previous accepted release remains the rollback target until the replacement passes the full update gate and real-device acceptance.

## 1. Detect and record the upstream release

Track official Moonfin upstream releases/tags for the Flutter/Core product and the Smart-TV/webOS upstream where applicable.

Record in the update branch/checkpoint:

- current accepted upstream base version/tag/commit
- new official upstream version/tag/commit
- current Home Lab overlay branch/commit
- current accepted candidate artifact references
- known upstream release notes or migrations relevant to Home Lab

Detection may be automated by GitHub Actions, but detection must only create/report update work. It must not automatically merge, deploy or promote production.

## 2. Create an isolated update branch from the new official base

Use an update branch such as:

`update/moonfin-<version>`

Start from the **new official release** wherever practical. Do not simply merge the new release into an old long-lived modified fork and assume conflicts are the only risk.

For Smart-TV/webOS, use the equivalent new official Smart-TV base when that upstream project has moved. If only the Flutter/Core upstream changed, keep the webOS codebase on its appropriate upstream lineage and reconcile shared contracts separately.

## 3. Generate an upstream impact report

Compare:

1. old official base -> new official base
2. old official base -> accepted Home Lab overlay

Classify changed areas into at least:

- files untouched by Home Lab
- files changed by both upstream and Home Lab
- dependencies/build tooling
- navigation/routing
- authentication/session handling
- Jellyfin APIs/models
- Seerr/Moonbase integration
- playback
- Web
- Android mobile/tablet
- Android TV / Google TV
- Smart-TV/webOS
- application/package identity and versioning
- Home Lab Discovery catalogue/compiler/schema

Files changed by **both upstream and Home Lab** require explicit review even when Git produces no textual conflict.

The impact report must be stored in the update branch or its associated GitHub issue/checkpoint.

## 4. Reapply the narrow Home Lab overlay

Port only the Home Lab-specific feature surface required by the product, including as applicable:

- `lib/features/homelab_discovery/`
- catalogue/schema/compiler integration
- guarded Discovery routing hooks
- Moonbase/Seerr adapters
- platform-specific Home Lab adapters
- required configuration/build hooks
- Smart-TV/webOS Home Lab Discovery implementation

Prefer adapting the overlay to new upstream APIs over copying entire historical source files into the new release.

If upstream now provides equivalent functionality, evaluate whether the Home Lab custom code can be reduced or removed while preserving required behaviour.

## 5. Revalidate the shared semantic contract

Every official update must re-run semantic validation, especially for:

- TMDB/Jellyfin identity and media type
- ownership/availability/request state
- provider mappings
- personalisation seed provenance
- recommendation semantics
- catalogue filter/sort/date-token behaviour
- pagination and total-result meaning
- duplicate handling
- artwork fallback
- errors vs genuine empty results
- stock fallback behaviour

An upstream API/model change must not silently convert a truthful specialised row into a generic approximation. Unsupported semantics fail closed until corrected.

## 6. Revalidate each platform

### Web

Verify code/tests for:

- mouse, keyboard and touch navigation
- responsive layout
- browser history/back
- details/request/local playback routing
- retained state/error/empty behaviour
- Web build and deployment paths

### Android mobile/tablet

Verify:

- phone/tablet layouts
- portrait/landscape
- touch and scrolling
- Android Back
- lifecycle/resume/auth persistence
- details/request/local playback routing
- update-safe state
- signed package generation

### Android TV / Google TV

Verify:

- D-pad/focus behaviour
- navbar/toolbar/grid edges
- See All/deep pagination
- detail return/back
- request/local playback
- TV candidate build

### LG webOS

Verify:

- Enact/legacy-WebKit compatibility
- constrained-TV performance policy
- 720p/1080p layout logic
- remote focus/back helpers
- details/request/local identity integration
- IPK package identity/update compatibility

## 7. Protect application and signing identity

The update workflow must explicitly assert these invariants.

### Android

- package/application ID unchanged unless a deliberate migration was approved
- signing certificate SHA-256 matches the accepted certificate
- versionCode increases appropriately
- upgrade path does not require uninstall/reinstall

### webOS

- app ID remains `org.moonfin.webos`
- package version advances compatibly when promoted
- required entry point/manifest structure remains valid
- update installs over the accepted application rather than creating a separate app

### Web

- expected Web deployment root and catalogue URL remain compatible
- stock fallback remains available when the Home Lab catalogue is unavailable/incompatible

## 8. Run the cross-platform regression gate

An upstream update is not considered GitHub-integrated until all applicable gates pass:

- catalogue/schema/compiler validation
- semantic/personalisation tests
- identity/provider/request/playback routing tests
- pagination/dedup/retained-state tests
- platform navigation/focus tests
- Web build
- Android mobile build
- Android TV build
- webOS lint/legacy compatibility/build/IPK
- Android signing identity verification
- webOS identity verification
- candidate artifact publication

A green subset of platforms does not promote the update.

## 9. Produce isolated candidates

Every update creates new isolated artifacts without overwriting the previous accepted ones:

- Web candidate
- Android mobile/tablet candidate
- Android TV / Google TV candidate
- webOS IPK candidate

Record artifact IDs/digests and exact source commits in `docs/AI_PROJECT_STATE.md` or the update checkpoint.

## 10. Physical/service acceptance after GitHub integration

Only after the GitHub update gate is green should the candidate proceed to real acceptance:

- Web browser acceptance
- Android phone/tablet acceptance
- Android TV / Google TV acceptance
- LG webOS acceptance
- real Jellyfin/Seerr data/recommendation quality
- request/detail/local playback
- launch/resume/auth persistence
- in-place update compatibility

Do not infer physical acceptance from CI.

## 11. Promotion and rollback

Promote only when all required product gates pass.

Before cutover:

- preserve the previous accepted branch/ref/artifacts
- document rollback commands/procedure
- ensure server-side changes are atomic/reversible where practical
- record the new accepted upstream base and Home Lab overlay commits

If acceptance fails, keep production on the previous accepted candidate and fix the update branch. Do not patch production manually in a way that will be overwritten by the managed source/configuration.

## Automation policy

Automation is encouraged for:

- checking upstream releases
- producing impact reports
- running semantic/platform regression suites
- verifying signing/package identity
- generating candidate artifacts
- creating a GitHub issue/report when a new upstream release is available

Automation must **not** automatically:

- merge an upstream release into production branches
- change signing identity
- deploy to live servers/devices
- promote artifacts to production
- remove rollback refs/candidates

## Completion record for every upstream update

A completed update should leave a concise durable record containing:

- old/new official upstream versions and commits
- Home Lab overlay source commit
- reviewed overlapping upstream/Home Lab files
- semantic changes/migrations
- Web/Android mobile/Android TV/webOS workflow results
- package/signing identity verification
- candidate artifact IDs/digests
- physical acceptance results
- production cutover and rollback reference

This protocol remains mandatory even after Discovery v2 reaches production.
