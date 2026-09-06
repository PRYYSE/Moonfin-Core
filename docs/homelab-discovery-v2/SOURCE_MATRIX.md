# Home Lab Discovery v2 — Legacy Source Matrix

**Updated:** 2026-09-06  
**Legacy reference:** `archive/live-web-a9c789-2026-09-06` (`a9c789fff317b41bba268d3a213439e23b8d1af5`)  
**New base:** Moonfin `2.5.1` (`f18c45b1fbf9b63871b4f93237179f9706154763`)

## Legend

- **REUSE OFFICIAL** — do not port legacy modification; current upstream owns this capability.
- **ADAPT** — retain product behaviour, but reimplement under `lib/features/homelab_discovery/` against current upstream APIs.
- **PORT MOSTLY PURE** — legacy logic is sufficiently isolated/pure to use as a reference and selectively port with namespace/model changes and new tests.
- **DROP** — obsolete with the new architecture.
- **DEFER** — useful, but not required for the first clean replacement acceptance.

The rule is product behaviour over implementation history. No whole-branch cherry-picks.

---

## 1. Upstream integration files

| Legacy path | Decision | New owner / replacement | Reason |
|---|---|---|---|
| `lib/ui/navigation/app_router.dart` | **ADAPT, tiny patch only** | Official router + `HomeLabDiscoveryEntryScreen` | Current 2.5.1 route already points `/seerr/discover` to stock `SeerrDiscoverScreen`. Replace only that builder/import with guarded custom entry. |
| `lib/ui/navigation/destinations.dart` | **REUSE OFFICIAL initially** | Official destinations | Deep custom routes can be nested/local or query-driven first. Add global destinations only if a proven navigation requirement cannot be represented cleanly. |
| `lib/di/modules/app_module.dart` | **REUSE OFFICIAL** | Feature-local construction / bridge factory | Avoid global DI changes. Discovery should create narrow adapters from already-registered official services. |
| `android/app/build.gradle.kts` | **REUSE OFFICIAL** | Official `mobile-beta` / `androidTv-beta` flavours | Current upstream already has separate mobile/TV beta products, ABIs and TV behaviour. |
| `pubspec.yaml` legacy build changes | **REUSE OFFICIAL** | Stable-tag upstream versioning; Home Lab build metadata handled separately if required | Do not own upstream dependency/version surface. |

---

## 2. Seerr transport, session, request and official models

| Legacy path | Decision | Current official capability |
|---|---|---|
| `lib/data/repositories/seerr_repository.dart` | **REUSE OFFICIAL** | 2.5.1 repository already handles Moonbase proxy/session recovery, trending/top/upcoming, watchlist, discover filters, recommendations/similar, people/credits, collections, networks/studios, search, request state/actions, charts and blocklist. |
| `lib/data/services/seerr/seerr_http_client.dart` | **REUSE OFFICIAL** | Current upstream HTTP client is authoritative. Discovery bridge calls `SeerrRepository`, not raw private endpoints unless later proven necessary. |
| legacy edits to Seerr API/model classes | **REUSE OFFICIAL** | Official generated/current Seerr models | Avoid schema fork. Custom catalogue has its own feature-local schema. |
| request/auth helper patches | **REUSE OFFICIAL** | Current official session/bootstrap/request flows | Moonbase 2.2.0 also fixes Seerr reinstall/session recovery. |

**Hard rule:** if the v2 port appears to require adding general Seerr endpoints to core, first verify the method is genuinely absent from current stable and current upstream main. If absent and broadly useful, prefer a small upstreamable addition over a Home Lab-only fork patch.

---

## 3. Discovery catalogue/schema

| Legacy path | Decision | v2 destination |
|---|---|---|
| `lib/data/services/seerr/home_lab_discovery_catalogue.dart` | **ADAPT** | `lib/features/homelab_discovery/catalogue/` | Keep the product catalogue concept but remove compile-time ownership from client. |
| `seerr_discovery_schema.dart` | **PORT MOSTLY PURE** | `catalogue/discovery_catalogue.dart` + validator | Preserve explicit schema semantics; simplify around server-driven JSON and add `schemaVersion`, revision and capability fields. |
| `seerr_discovery_catalogue_loader.dart` | **ADAPT** | `catalogue/discovery_catalogue_loader.dart` | New loader must fetch static `/Moonfin/Web/homelab/discovery.catalogue.json`, validate, cache LKG and fail to stock. |
| `seerr_discovery_catalogue_service.dart` | **ADAPT / collapse** | loader/cache facade | Avoid another global service layer unless tests show value. |
| `seerr_discovery_catalogue_index.dart` | **PORT MOSTLY PURE** | `catalogue/discovery_catalogue_index.dart` | Valuable for All Categories/searching the lane catalogue. |
| `tooling/discovery/generate_home_lab_discovery_catalogue.py` | **ADAPT** | v2 catalogue tooling | Preserve the authoring catalogue generation capability but decouple from old source tree assumptions. |
| `tooling/discovery/compile_home_lab_discovery_catalogue.py` | **ADAPT** | v2 compiler | Preserve safe resolution/diagnostics. |
| `tooling/discovery/home_lab_discovery_compile_live.py` | **ADAPT** | v2 server-side compile command | Keep live metadata resolution, but output to `/srv/appdata/moonfin/discovery`. |
| `tooling/discovery/test_home_lab_discovery_catalogue.py` | **ADAPT** | v2 catalogue validation | Must become an explicit release gate. |
| old custom `MoonfinDiscoveryController.cs` | **DROP** | stock Moonbase static Web root | Official Moonbase + `MOONFIN_WEB_ROOT` serves the JSON; no custom controller required. |

### Catalogue baseline to preserve

- Authoring catalogue: **486 lanes**.
- Accepted live compile: **481 lanes**.
- Remaining five semantic drops are allowed and should stay omitted unless safely resolvable.
- Provider drops at accepted baseline: **0**.

481 is a regression reference, not a dishonest hard requirement if current external metadata genuinely changes. Any lower result must have diagnostics explaining every delta before release.

---

## 4. Composition, rotation and deduplication engine

| Legacy path | Decision | v2 destination / note |
|---|---|---|
| `seerr_discovery_composer.dart` | **PORT MOSTLY PURE** | `engine/discovery_composer.dart` | Preserve deterministic mixed hierarchy and pool/anchor budgets. |
| `seerr_discovery_session.dart` | **PORT MOSTLY PURE** | `engine/discovery_session.dart` | Preserve stable session seed/nonce semantics. |
| `seerr_discovery_rotation_history.dart` | **PORT MOSTLY PURE** | `engine/discovery_rotation_history.dart` | Keep history model. |
| `seerr_discovery_rotation_store.dart` | **ADAPT** | feature-local cache/store | Replace old storage coupling with current preference/storage APIs. |
| `seerr_discovery_seed_selector.dart` | **PORT MOSTLY PURE** | `engine/discovery_seed_selector.dart` | Retain deterministic seed selection. |
| `seerr_discovery_personal_presentation.dart` | **PORT MOSTLY PURE** | `engine/discovery_personal_presentation.dart` | Preserve family cap, neutral row labels, cross-row novelty and backfill. |
| `seerr_discovery_personalisation_service.dart` | **ADAPT** | `engine/discovery_personalisation.dart` using bridge | Reuse algorithmic value; replace old repository/history coupling. |
| `seerr_discovery_recommendation_mixer.dart` | **PORT/ADAPT** | `engine/discovery_recommendation_mixer.dart` | Keep only if upstream recommendation results still need combining. |
| `seerr_discovery_sort_policy.dart` | **PORT MOSTLY PURE or DROP if redundant** | feature policy | Current upstream discover calls support sort/filter. Keep only custom deterministic rules not expressible upstream. |
| `seerr_discovery_filter_policy.dart` | **PORT/ADAPT** | feature policy | Keep Home Lab semantic rules; map to official repository parameters. |
| `seerr_discovery_refinement_policy.dart` | **PORT/ADAPT** | feature policy | Same principle. |
| `seerr_discovery_availability_policy.dart` | **ADAPT** | bridge-backed availability policy | Use official request/media state instead of duplicate transport logic. |
| `seerr_discovery_request_plan.dart` | **ADAPT or DROP** | official request route/state | Preserve only planning logic not already represented by official request UI. |

---

## 5. Lane loading, paging and external lists

| Legacy path | Decision | v2 destination / note |
|---|---|---|
| `seerr_discovery_lane_loader.dart` | **ADAPT** | `data/discovery_lane_loader.dart` | Core v2 adapter from catalogue recipe -> official bridge call. |
| `seerr_discovery_tab_loader.dart` | **PORT/ADAPT** | `data/discovery_tab_loader.dart` | Keep orchestration and lazy loading; use new catalogue models. |
| `seerr_discovery_paginator.dart` | **PORT MOSTLY PURE** | `data/discovery_paginator.dart` | Preserve See All pagination behaviour. |
| `seerr_discovery_external_list_paginator.dart` | **PORT/ADAPT** | external list source | Keep if current configured list design survives gap review. |
| `seerr_discovery_configured_lists_service.dart` | **ADAPT** | feature-local list source | Server-driven list definitions; avoid core DI. |
| external-list expansion patch family | **DROP as patch scripts** | behaviour folded into v2 data layer | No runtime patching. |
| `seerr_discovery_browse_refinements.dart` | **PORT/ADAPT** | `data/` or `engine/` refinements | Map into official discover filter vocabulary. |
| legacy general `row_data_source.dart` modifications | **DROP** | official row system + isolated Discovery lane loader | Do not re-own Home/global row loading. |

### External lists

Retain architecture support for curated lists (MDBList/TMDb/etc.) but keep credentials/server secrets out of client catalogue. If a provider requires a secret, resolve through an existing server-side integration or add a server-side proxy/cached materialisation later. Do not embed API secrets in Web/APKs.

---

## 6. View models/controllers

| Legacy path | Decision | v2 destination |
|---|---|---|
| `seerr_deep_discovery_view_model.dart` | **ADAPT / split** | feature-local controller/view model | Useful orchestration, but remove old DI/repository assumptions and split catalogue/session/loading responsibilities. |
| `seerr_discovery_collection_controller.dart` | **PORT/ADAPT** | feature-local collection controller | Retain only if All Categories/index needs it after current upstream browse review. |
| modifications to `seerr_browse_view_model.dart` | **DROP** | official browse viewmodel | For deep custom catalogue results, use feature-local paginator/refinement rather than patching standard Seerr browse. |

---

## 7. UI

| Legacy path | Decision | v2 destination / replacement |
|---|---|---|
| modified `lib/ui/screens/seerr/seerr_discover_screen.dart` | **DROP as replacement** | leave official screen untouched; new `ui/homelab_discovery_screen.dart` | Stock screen remains fallback and upstream-owned. |
| `seerr_discovery_catalogue_screen.dart` | **ADAPT** | `ui/discovery_catalogue_screen.dart` | Preserve All Categories capability using current upstream cards/focus primitives. |
| `seerr_discovery_refinement_dialog.dart` | **ADAPT** | `ui/discovery_refinement_sheet.dart` | Responsive mobile/Web/TV UI built with current primitives. |
| modified `seerr_browse_screen.dart` | **DROP** | official browse + feature custom deep-results UI only where needed | Do not globally fork standard Seerr browse. |
| legacy Home screen/viewmodel | **DROP** | official Home | User explicitly wants base Moonfin outside custom Discovery. |
| `homelab_home_composer.dart` | **DROP** | official Home | No longer product scope. |
| Home Lab hub screens/routes | **DROP** | official app/navigation | No longer product scope. |
| `left_sidebar.dart` modifications | **DROP** | official navigation | Upstream-owned. |
| `mobile_bottom_nav_bar.dart` modifications | **DROP** | official navigation | Upstream-owned. |
| `media_bar.dart` modifications | **DROP** | official media bar | Upstream-owned. |
| `top_toolbar.dart` legacy no-op/customisation | **DROP** | official toolbar | Upstream-owned. |
| old Home Lab themes | **DROP from v2 product patch** | official themes | Can be revisited independently later; not Discovery architecture. |

### UI input requirements

The custom UI must deliberately use current official components/primitives so the same code is testable on:

- Web mouse/touch/keyboard;
- Android phone/tablet touch;
- Android/Google TV D-pad/focus.

The old Web tab pointer regression is an explicit regression test to add; do not carry its cause into v2.

---

## 8. Build/release/update tooling

| Legacy path/group | Decision | v2 replacement |
|---|---|---|
| `.github/workflows/homelab-android-beta.yml` | **DROP/rewrite** | v2 CI/release workflow using official build paths/flavours | Old workflow was tied to legacy branch/build scripts. |
| `.github/workflows/homelab-mobile-safe-area-fix.yml` | **DROP** | upstream | Not Discovery scope. |
| `.github/workflows/homelab-hubs-prototype.yml` | **DROP** | none | Obsolete. |
| `.github/workflows/homelab-seerr-discovery-validation.yml` | **ADAPT** | v2 focused CI | Preserve useful catalogue/unit gates but rebuild against stable base. |
| `tooling/build_android_release_v1.sh` | **DROP/rewrite** | v2 exact-ref build/release script | Preserve signing/ABI verification concepts only. |
| old Web deploy/finalise/resume scripts | **DROP/rewrite** | atomic external-Web-root release script | Old scripts mutate current legacy frontend. |
| old Discovery rollout/hotfix scripts | **DROP** | v2 staged release/cutover/rollback scripts | No source patching or live hotfix generation. |
| `setup_docker01_dev.sh` | **DEFER** | optional clean v2 builder bootstrap | Server already has working build environment; do not reinstall unless needed. |
| safe auth/signing helper concepts | **ADAPT only if needed** | server-only build scripts | Never print secrets; retrieve existing signing locally. |

---

## 9. Tests

### High-value legacy tests to port/adapt

- `seerr_discovery_schema_test.dart`
- `seerr_discovery_schema_v2_test.dart`
- `seerr_discovery_composer_test.dart`
- `seerr_discovery_lane_loader_test.dart`
- `seerr_discovery_tab_loader_test.dart`
- `seerr_discovery_paginator_test.dart`
- `seerr_discovery_personal_presentation_test.dart`
- `seerr_discovery_personalisation_service_test.dart`
- `seerr_discovery_recommendation_mixer_test.dart`
- `seerr_discovery_rotation_history_test.dart`
- `seerr_discovery_rotation_store_test.dart`
- `seerr_discovery_rotation_view_model_test.dart`
- `seerr_discovery_seed_selector_test.dart`
- `seerr_discovery_shared_dedup_test.dart`
- `seerr_discovery_catalogue_loader_test.dart`
- `seerr_discovery_catalogue_index_test.dart`
- `seerr_discovery_external_list_paginator_test.dart`
- `seerr_discovery_configured_lists_service_test.dart`
- `seerr_discovery_browse_refinements_test.dart`
- `seerr_discovery_refinement_policy_test.dart`
- `seerr_discovery_availability_policy_test.dart`
- `seerr_discovery_semantic_resolution_test.dart`

### New mandatory v2 regression tests

1. valid supported catalogue selects Home Lab Discovery;
2. missing catalogue selects stock `SeerrDiscoverScreen`;
3. malformed JSON selects stock;
4. unsupported schema selects stock;
5. cached last-known-good catalogue is accepted after temporary fetch failure;
6. bad individual lane does not crash whole page;
7. Web pointer/touch activation works for each top-level tab;
8. keyboard selection works;
9. TV D-pad focus order/back restoration works where widget testing can prove it;
10. deterministic composition remains stable for same session seed;
11. title-family cap and cross-row novelty regression cases remain;
12. See All bypasses preview-only family limiting while preserving full ranking;
13. no secrets are accepted/required in catalogue schema.

---

## 10. Documentation disposition

The old `docs/homelab-seerr/00`–`13` files remain valuable product/reference material on archived branches.

Do not copy them wholesale into the clean branch. The v2 docs should summarise current architecture and link to archive refs for historical detail.

Required v2 docs:

- `ARCHITECTURE.md`
- `SOURCE_MATRIX.md`
- `CHECKPOINT_CURRENT.md`
- `SERVER_RUNBOOK.md`
- `PROGRESS.md`
- `HANDOVER.md`

---

## 11. First implementation boundary

The first clean code slice should prove the architecture before porting hundreds of lanes:

1. feature-local catalogue model + validator;
2. feature-local loader with fetch/cache/fallback contract;
3. narrow official `SeerrRepository` bridge;
4. guarded `HomeLabDiscoveryEntryScreen`;
5. one-line router ownership change;
6. stock fallback tests;
7. focused CI.

Only once this passes do we port composer/lane loading/UI progressively.

This prevents rebuilding the legacy fork in a new directory by accident.
