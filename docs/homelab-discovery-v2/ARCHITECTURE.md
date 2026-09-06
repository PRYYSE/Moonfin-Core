# Home Lab Moonfin — Base + Discovery v2 Architecture

**Decision date:** 2026-09-06

## 1. Decision

The production development model is now:

> **Official stable Moonfin + a deliberately small Home Lab Discovery overlay + server-driven Discovery catalogue.**

The current broad Home Lab fork is retained only as a rollback/reference source while the replacement is built and validated.

Maintained clients:

- Web
- Android mobile/tablet
- Google TV / Android TV

Retired:

- LG webOS

## 2. Why this replaces the old model

The accepted legacy Web source (`a9c789...`) sits 346 commits ahead of the old fork base and changes broad upstream areas, including Home, navigation, Seerr repository/client, DI, browse presentation and deployment tooling.

Current official Moonfin now contains much of the platform, Seerr, TV-focus and UI capability that the old project had to build itself. Continuing the old branch would make every upstream release a porting project rather than a small compatibility update.

The new design preserves the unique Discovery product while returning everything else to upstream ownership.

## 3. Upstream policy

At the architecture decision point:

- Moonfin stable: `2.5.1`
- stable commit: `f18c45b1fbf9b63871b4f93237179f9706154763`
- upstream `main`: `508f052f4da725b1f520f4a73b64330d43c86f92`
- Moonbase stable: `2.2.0`
- Flutter for Moonfin 2.5.1: `3.44.1`

Production is always based on a stable release tag.

Upstream `main` may be replayed in CI as a compatibility canary but never auto-deployed.

## 4. Git topology

Repository: `PRYYSE/Moonfin-Core`

- `main` — exact mirror of official upstream `main`.
- `homelab/discovery-v2` — production Home Lab overlay based on latest selected stable tag.
- optional `homelab/discovery-v2-canary` — warning-only compatibility replay on upstream `main`.
- `archive/*` — immutable historical references.

Custom work must never land directly on `main`.

## 5. Client code boundary

All Home Lab product code should live under:

```text
lib/features/homelab_discovery/
```

Preferred structure:

```text
lib/features/homelab_discovery/
├── bridge/
│   └── moonfin_discovery_bridge.dart
├── catalogue/
│   ├── discovery_catalogue.dart
│   ├── discovery_catalogue_loader.dart
│   └── discovery_catalogue_validator.dart
├── engine/
│   ├── discovery_composer.dart
│   ├── discovery_dedup.dart
│   ├── discovery_rotation.dart
│   └── discovery_personalisation.dart
├── data/
│   ├── discovery_lane_loader.dart
│   └── discovery_paginator.dart
├── ui/
│   ├── homelab_discovery_entry_screen.dart
│   ├── homelab_discovery_screen.dart
│   ├── discovery_catalogue_screen.dart
│   └── discovery_refinement_sheet.dart
└── README.md
```

### Anti-corruption bridge

Most custom code should depend on one narrow bridge instead of importing many Moonfin internals directly.

The bridge exposes only capabilities Discovery genuinely needs, for example:

- current Seerr availability/session state;
- trending/top/upcoming/search/discover movie/TV calls;
- similar/recommendation/person/collection calls where needed;
- current media details/request state;
- official route helpers for media details and requests;
- Jellyfin/session identity needed for per-user local caching.

If upstream changes internal APIs, the bridge should absorb the change first.

## 6. Upstream files allowed to differ

Target is one mandatory upstream integration change plus very small build/release integration if needed.

### Mandatory

`lib/ui/navigation/app_router.dart`

Change only the Seerr Discovery route from stock `SeerrDiscoverScreen` to a guarded `HomeLabDiscoveryEntryScreen`.

### Optional and only if proven necessary

- update-feed repository build-time selection;
- Home Lab beta version/build metadata;
- CI workflow files.

Do not modify official Home, navigation bars, player, standard Seerr repository/client, DI, themes or generic browse screens merely to implement Discovery.

## 7. Guarded fallback is mandatory

The Home Lab route must fail safe.

At startup:

1. load the Discovery catalogue;
2. validate schema/capabilities;
3. if valid, render Home Lab Discovery;
4. if missing, invalid, unsupported or unavailable, render official `SeerrDiscoverScreen`.

Individual bad lanes should be omitted/fallback-filled rather than breaking the entire page.

This means a catalogue outage or future schema incompatibility does not remove Seerr discovery from the app.

## 8. What official Moonfin owns

Use upstream implementations for:

- Jellyfin connection/session state;
- Seerr auth/session/bootstrap;
- requests and request status;
- media detail screens/routes;
- cards/artwork where suitable;
- platform detection;
- touch/keyboard input;
- Android TV D-pad/focus primitives;
- standard browse/filter capability where sufficient;
- themes;
- playback;
- downloads;
- general Home and navigation.

Do not port old modified copies of these systems unless a concrete gap is demonstrated.

## 9. What Home Lab Discovery retains

Preserve the unique product behaviour from the legacy system:

- 486-lane authoring catalogue;
- 481-lane accepted compiled semantic baseline;
- safe semantic compiler;
- For You / Movies / Series / Anime / New & Upcoming / Lists / All Categories;
- deep rows -> See All -> pagination;
- personalised lanes;
- title-family diversification;
- cross-row and session deduplication;
- deterministic session rotation;
- safe backfill;
- genre/theme/keyword/runtime/year/language/country/provider-style discovery where supported;
- curated/external lists;
- catalogue index/refinement/rabbit-hole navigation;
- request/availability overlays;
- local Jellyfin routing.

Port behaviour and tests, not old integration history.

## 10. Server-driven catalogue

The compiled Discovery catalogue is configuration/data, not client source.

Canonical server root:

```text
/srv/appdata/moonfin/
├── android-signing/
├── discovery/
│   ├── catalogue.authoring.json
│   ├── discovery.catalogue.json
│   └── diagnostics.json
├── web/
│   ├── current -> releases/<release>/
│   └── releases/
└── releases/
    ├── mobile/
    └── tv/
```

The Web release should include/copy the current compiled catalogue to:

```text
homelab/discovery.catalogue.json
```

which becomes available at:

```text
/Moonfin/Web/homelab/discovery.catalogue.json
```

The JSON contains no secrets and no per-user personal data.

Recommended metadata fields:

- `schemaVersion`
- `catalogueRevision`
- `generatedAt`
- optional `minimumDiscoveryCapability`

Client behaviour:

- validate before use;
- keep a last-known-good validated cache;
- background refresh;
- use cached catalogue during temporary server failure;
- fall back to stock Discovery if no valid custom catalogue exists.

Catalogue-only edits should not require rebuilding Web/mobile/TV.

## 11. Moonbase

Return to official stock Moonbase.

Official Moonbase supports `MOONFIN_WEB_ROOT`; use it rather than patching Moonbase to host a custom frontend.

Target Compose behaviour:

- bind `/srv/appdata/moonfin/web` into the Jellyfin/Moonbase container read-only;
- point `MOONFIN_WEB_ROOT` at the `current` release directory;
- keep each previous Web release intact for rollback;
- retain official bundled Web as emergency fallback.

No custom Moonbase catalogue endpoint should exist unless static serving later proves insufficient.

## 12. Android mobile + Google TV

Use official flavours:

- Android mobile/tablet: `mobile-beta`
- Google TV / Android TV: `androidTv-beta`

Never use the mobile APK as the final Google TV release.

Preserve the existing Home Lab signing key at `/srv/appdata/moonfin/android-signing` and its existing certificate. Never regenerate it.

Version codes must increase from the accepted Home Lab Android baseline `30000147`.

The official production Moonfin app may remain installed side-by-side as an emergency fallback because Home Lab builds use the beta namespace.

## 13. Update strategy

For each new official stable release:

1. fetch official release tag and paired Moonbase stable release;
2. create/update integration branch from that client tag;
3. replay/rebase the small Discovery overlay;
4. run upstream tests plus Home Lab Discovery tests;
5. build Web, `mobile-beta`, `androidTv-beta`;
6. perform three-client acceptance gates;
7. promote only exact tested artefacts.

If an update creates broad conflicts, do not solve it by expanding the fork. Shrink/rework the integration boundary.

## 14. APK updater caveat

The official APK updater currently targets official Moonfin release assets. A Home Lab beta should not silently replace itself with an official-production APK.

Initial safe behaviour: suppress/avoid upstream APK update prompts for Home Lab builds.

Preferred final implementation: make update repository/feed a build-time setting with official upstream as the default and PRYYSE/Home Lab release assets for custom beta builds.

Keep this patch generic and tiny; consider upstreaming it later.

## 15. CI gates

Before deployment:

### Source/upstream

- exact upstream stable tag recorded;
- custom diff narrow and explainable;
- no unexpected changes outside feature/integration files;
- no secrets committed.

### Discovery

- schema validation;
- missing/invalid catalogue fallback test;
- semantic compiler diagnostics;
- no unexplained lane regression below accepted 481 baseline;
- personalisation/dedup/family tests;
- pagination/See All tests;
- deterministic composition tests.

### Web

- pointer/touch tab activation;
- keyboard activation;
- all Discovery destinations;
- See All/deep browse;
- request route;
- local media route;
- stock fallback.

### Android mobile

- same signing certificate;
- higher versionCode;
- touch navigation;
- details/request/playback;
- resume/background;
- catalogue + fallback.

### Google TV

- correct TV flavour/launcher;
- D-pad navigation;
- no focus traps;
- focus restoration/back;
- horizontal rows;
- Discovery tabs and See All grids;
- request route;
- playback validation.

### Upgrade/rollback

- previous Web release retained;
- previous APKs retained;
- Moonbase/config backup;
- exact current symlink recorded;
- one-command Web rollback;
- bundled stock Web fallback retained.

## 16. Migration order

1. Archive/freeze legacy Git and artefact references.
2. Synchronise fork `main` to official upstream.
3. Create stable-tag `homelab/discovery-v2` branch.
4. Build keep/adapt/drop matrix.
5. Prove clean current stock baseline in CI.
6. Port isolated Discovery feature.
7. Add guarded fallback.
8. Move catalogue to server-driven static model.
9. Validate Web.
10. Build/validate Android mobile beta.
11. Build/validate Android TV beta.
12. Prepare official Moonbase + `MOONFIN_WEB_ROOT` cutover.
13. Execute controlled server migration only when user is available to run commands.
14. Publish/retain exact artefacts and update handover.

## 17. Long-term ideal

Make the custom catalogue integration generic enough to upstream.

If official Moonfin eventually supports a compatible server-driven custom Discovery catalogue, Home Lab can move to fully stock client binaries and retain only server-side catalogue/configuration.
