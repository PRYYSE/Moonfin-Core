# Home Lab Moonfin — Base + Discovery v2 Architecture

**Decision date:** 2026-09-06  
**Updated:** 2026-09-07

## 1. Decision

Production development model:

> **Official stable Moonfin + a deliberately small Home Lab Discovery overlay + server-driven Discovery catalogue.**

The broad legacy Home Lab fork remains only as rollback/reference while the replacement is built and validated.

Maintained clients:

1. Web
2. Android mobile/tablet
3. Google TV / Android TV
4. LG TV / webOS

LG webOS was temporarily considered retired during the pivot, but that decision was reversed on 2026-09-07. It is a first-class maintained target.

## 2. Quality principle

The v2 architecture exists to improve maintainability without sacrificing Discovery quality. Do not choose a smaller or faster implementation merely because it is quicker. Prefer the implementation that is correct, polished, testable and resilient to upstream updates.

Earlier work may be replaced when there is a concrete correctness, UX, architecture or maintainability improvement.

## 3. Why this replaces the old model

The accepted legacy Web source `a9c789fff317b41bba268d3a213439e23b8d1af5` accumulated broad changes across Home, navigation, Seerr integration, DI, browse presentation and deployment tooling. Current official Moonfin now owns much of the platform/UI/Seerr/TV capability the old fork had to build itself.

V2 keeps the unique Discovery product while returning unrelated behaviour to upstream ownership.

## 4. Upstream policy

Selected production baseline:

- Moonfin stable 2.5.1
- stable commit `f18c45b1fbf9b63871b4f93237179f9706154763`
- upstream `main` at decision `508f052f4da725b1f520f4a73b64330d43c86f92`
- Moonbase stable 2.2.0
- Flutter 3.44.1

Production follows stable release tags. Upstream `main` is compatibility-canary only and is never auto-deployed.

## 5. Git topology

### Moonfin Flutter client

Repository: `PRYYSE/Moonfin-Core`

- `main`: mirror of official upstream main.
- `homelab/discovery-v2`: Home Lab overlay based on selected stable tag.
- `archive/*`: immutable recovery refs.
- legacy Home Lab branches remain available as historical/reference sources.

Custom work does not land directly on `main`.

### LG webOS wrapper

Repository: `PRYYSE/Smart-TV`

- maintained branch `homelab/webos-v1-staging`
- current candidate source `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`
- candidate tag `homelab-webos-v1-candidate` -> same commit
- beta tag `homelab-webos-beta-latest` -> `264988874b330b11b5ca54fbf2115e42b5662d34`

Do not collapse the Smart-TV wrapper into Moonfin-Core merely for convenience. It is a separate platform package with different compatibility constraints.

## 6. Flutter client code boundary

Home Lab Flutter product code lives under:

`lib/features/homelab_discovery/`

Preferred responsibilities:

- `catalogue/`: schema, validation, loading/cache;
- `engine/`: deterministic composition, session policy, personalisation/presentation;
- `data/`: lane loading, request plans, pagination;
- `bridge/`: narrow adapter into stock Moonfin/Seerr capabilities;
- `ui/`: Discovery entry, landing tabs/lanes and deep browse.

The only mandatory core Moonfin product integration point is:

`lib/ui/navigation/app_router.dart`

The Seerr Discovery route is replaced with guarded `HomeLabDiscoveryEntryScreen`. The route change is generated/checkable by `tooling/homelab-discovery-v2/apply_route_overlay.py`.

Optional non-feature changes are limited to small build/release integration that is proven necessary.

Do not modify stock Home, player, themes, generic navigation, standard Seerr repository/client or DI merely to implement Discovery.

## 7. Anti-corruption bridge

Discovery depends on a narrow bridge rather than broad Moonfin internals. The bridge absorbs upstream API churn and exposes only what Discovery needs: authenticated Seerr access, request-plan execution, active server/session identity, media details/request routing and other proven capabilities.

Stock Moonfin remains authoritative for:

- Jellyfin session/auth;
- Seerr bootstrap/session/request handling;
- media detail routes;
- playback/downloads;
- cards/design system where suitable;
- platform detection;
- touch/keyboard input;
- Android TV focus/D-pad primitives;
- themes and general navigation.

## 8. Guarded fallback

The custom route must fail safe:

1. load catalogue;
2. validate schema/capabilities;
3. valid -> render Home Lab Discovery;
4. missing/invalid/unsupported/unavailable -> render stock `SeerrDiscoverScreen`.

Individual bad lanes fail independently. A bad catalogue or one failed lane must not remove stock Seerr discovery from the app.

## 9. Discovery product behaviour retained

Preserve and improve the useful legacy behaviour:

- 486-lane authoring catalogue;
- accepted 481-lane semantic regression baseline;
- For You, Movies, Series, Anime, New & Upcoming, Lists;
- Jellyfin-driven personalisation;
- deterministic session composition/rotation;
- cross-row novelty/dedup with graceful backfill;
- personalised row-title uniqueness;
- title-family diversification;
- landing previews plus deep `See All` pagination;
- curated filters/lists where semantically supported;
- request/availability status;
- local Jellyfin routing;
- catalogue index/refinement/rabbit-hole navigation where it improves discovery.

Port behaviour and tests, not old integration history.

## 10. Deterministic concurrency rule

Lane network/personalisation fetches may execute concurrently. Cross-row presentation state must never be mutated inside those concurrent fetches.

Required sequence:

1. deterministic composer selects lane order;
2. lane fetches execute, potentially concurrently;
3. results are stored by section ID;
4. a pure post-fetch stage walks the selected catalogue order;
5. title uniqueness/family diversity/cross-row presentation is applied there.

Visible output must not depend on network completion order.

## 11. Server-driven catalogue

Canonical future root:

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

Web exposes the current compiled catalogue at:

`/Moonfin/Web/homelab/discovery.catalogue.json`

Catalogue data contains no secrets or per-user personal data. Client validates it, keeps per-server last-known-good data and falls back to stock Discovery if no valid catalogue exists.

Catalogue-only edits should not require rebuilding clients.

## 12. Moonbase

Return to official stock Moonbase. Use official `MOONFIN_WEB_ROOT` to serve an external persistent Web release rather than maintaining a custom Moonbase frontend fork.

Cutover must retain:

- previous Web releases;
- exact current symlink target;
- official bundled Web emergency fallback;
- one-command rollback.

## 13. Android mobile + Android TV

Official flavours:

- mobile/tablet: `mobile-beta`
- Google TV / Android TV: `androidTv-beta`

Never use the mobile APK as the final TV package.

Preserve signing root `/srv/appdata/moonfin/android-signing` and certificate SHA-256 `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`. Never regenerate signing. Version code must increase from accepted baseline `30000147`.

## 14. LG webOS architecture

webOS remains in `PRYYSE/Smart-TV`, not Flutter Moonfin-Core.

Recovered candidate facts:

- branch/tag commit `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`
- tree SHA of that commit `7424826381c91d3293f44bd1d41e65024c595fb9`
- app ID `org.moonfin.webos`
- version 2.7.0
- build package `packages/build-webos/`
- existing Home Lab CI produces `Moonfin_HomeLab_webOS.ipk` plus checksum/manifest and publishes the staging candidate prerelease
- `appinfo.json` retains `disableBackHistoryAPI: true` and `handlesRelaunch: true`.

Preservation rules:

- do not change `org.moonfin.webos` merely to make deployment easier;
- do not regenerate an incompatible package/update identity;
- retain existing launch/install route and candidate release path;
- treat legacy WebKit/rendering, remote focus, Back, relaunch/resume and playback behaviour as platform-specific gates;
- real-device acceptance on the LG OLED65C6PSA is required before promotion.

The replacement webOS package may consume the new Web/Discovery experience only through an integration compatible with this wrapper architecture. Do not assume Android TV behaviour proves webOS behaviour.

## 15. CI policy

Discovery v2 CI is a validator, not a source mutator.

Required source gates:

- route overlay check;
- authoring catalogue generation/check + tests;
- Dart format check;
- focused analysis;
- focused Discovery tests;
- narrow custom-scope check against stable base.

CI uses read-only contents permission. Formatting and generated route changes must be committed deliberately before CI.

Later release pipelines add reproducible Web, `mobile-beta`, `androidTv-beta` and webOS package builds without weakening the focused source gates.

## 16. Client acceptance

### Web

- mouse/touch/keyboard tabs and cards;
- responsive layout;
- deep See All;
- details/request/local media routes;
- stock fallback;
- back/refresh behaviour.

### Android mobile/tablet

- touch/scroll;
- portrait/landscape;
- back gesture/button;
- background/resume;
- details/request/playback;
- catalogue/fallback.

### Google TV / Android TV

- correct TV flavour/launcher;
- D-pad focus traversal;
- no focus traps;
- focus restoration/back;
- horizontal rows and See All grids;
- request/details/playback.

### LG webOS

- package installs/upgrades under existing app ID;
- remote navigation and visible focus;
- Back semantics;
- app launch/relaunch/resume;
- Web rendering compatibility;
- auth persistence;
- Discovery tabs/rows/deep browse;
- request/details/playback behaviour.

## 17. Upgrade strategy

For each new official stable Moonfin release:

1. record exact client tag and paired Moonbase stable;
2. replay/rebase the narrow Discovery overlay onto the stable client;
3. run source/catalogue/Discovery tests;
4. build Web, `mobile-beta`, `androidTv-beta`;
5. feed the tested compatible Web experience into the preserved Smart-TV webOS packaging path;
6. perform four-client acceptance;
7. promote only exact tested artefacts.

If an upstream update causes broad conflicts, reduce/rework the integration boundary instead of expanding the fork.

## 18. Migration order

1. Preserve legacy refs/artefacts.
2. Keep fork main aligned with upstream.
3. Build/verify Discovery v2 on stable tag.
4. Complete controller/data integration and polished UI.
5. Complete See All/deep browse and semantic regression testing.
6. Build/validate Web.
7. Build/validate Android mobile beta.
8. Build/validate Android TV beta.
9. Integrate/build/validate webOS candidate through Smart-TV wrapper.
10. Prepare stock Moonbase + external Web-root cutover and rollback.
11. Execute controlled server migration only when the user is available.
12. Perform physical-client acceptance before retiring the legacy live installation.

## 19. Long-term ideal

Keep the Discovery integration generic and narrow enough that upstream could eventually support the same server-driven catalogue contract. The best end state is fully stock client binaries plus Home Lab server-side catalogue/configuration, but only if that preserves the desired Discovery product quality.
