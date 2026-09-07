# Home Lab Discovery v2 — Progress Ledger

`CHECKPOINT_CURRENT.md` is the authoritative resume point. This file records verified milestones and evidence.

## Architecture pivot — 2026-09-06

- Production model changed to current stable official Moonfin + isolated Home Lab Discovery overlay + server-driven catalogue.
- Stable base: Moonfin 2.5.1, commit `f18c45b1fbf9b63871b4f93237179f9706154763`.
- Fork `main` synchronised to official upstream main at `508f052f4da725b1f520f4a73b64330d43c86f92`.
- Legacy recovery refs created before reset.
- Live legacy Web/Moonbase deliberately left untouched as rollback.

## Foundation completed

Verified on `homelab/discovery-v2`:

- strict catalogue schema/validation and migration compatibility;
- network-first catalogue loading with per-server last-known-good cache;
- guarded fallback to stock Seerr Discovery;
- deterministic catalogue composer and session novelty/backfill;
- feature-local Seerr bridge/request-plan mapping;
- bounded cross-page paginator;
- per-lane error isolation and sparse-lane hiding;
- stock `RowDataSource.loadSinceYouWatchedRow` personalisation adapter;
- 486-lane authoring catalogue and compiler tests.

## Recovery / deterministic presentation — 2026-09-07

Previous broken head: `d03534042b49ab479829862bf81e266f670cb9ae`.

Repair sequence:

- `0e33e6d8e98f2062a4f79b55eaf4c6bd17e1b625` — repaired post-fetch personalisation refactor without restoring race-order mutable state.
- workflow `34076786844` — GREEN: route, catalogue, format, analysis, focused tests and narrow-scope gate all passed.
- `f2de6fc4804dacc9c5bb06a51e4121be5831c89c` — added deterministic tab-level personal presentation composition.
- GitHub Actions formatter persisted bot commit `5181232cefc6df403e491ee52dea9faa1107e967`.
- run `34077055464` exposed only two `prefer_collection_literals` lints in the new test.
- `ca786ca6571f65b63443144738df1814d8d7f6b9` — fixed those lints without weakening reversed-result-order coverage.
- workflow `34077193024` — GREEN: all gates passed.

The deterministic stage consumes completed lane results by catalogue order rather than completion/insertion order. Tests prove reversed result insertion cannot change personal titles or family-diversification output.

## webOS scope restored — 2026-09-07

LG webOS is a first-class maintained client again.

Recovered source of truth:

- repository: `PRYYSE/Smart-TV`
- branch: `homelab/webos-v1-staging`
- branch/candidate commit: `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`
- candidate tag: `homelab-webos-v1-candidate` -> same commit
- beta tag: `homelab-webos-beta-latest` -> `264988874b330b11b5ca54fbf2115e42b5662d34`
- app ID: `org.moonfin.webos`
- candidate version: `2.7.0`
- build package: `packages/build-webos/`
- existing CI builds `Moonfin_HomeLab_webOS.ipk` with checksum/manifest and publishes the staging candidate prerelease.

The Smart-TV wrapper remains separate from Flutter Moonfin-Core. Preserve app identity/update compatibility and do not replace that architecture merely to make Discovery work.

## CI hardening — 2026-09-07

After run `34077193024` proved the branch clean, commit `22c2712adbd4c2fda3d03f9582437bea925924fa` converted Discovery v2 CI from bootstrap mutation to strict validation:

- `permissions: contents: read`;
- removed automatic `dart format`, route overlay application, bot commit and branch push;
- route overlay must already pass `--check`;
- formatting must already be correct;
- catalogue, analysis, tests and narrow-scope checks remain mandatory.

The workflow for the strict-CI commit must be green before this hardening is marked fully verified.

## Still open

- feature-local tab controller/view-model for deterministic selection, concurrent loads and post-fetch presentation;
- polished Moonfin-native Discovery rows/cards/states replacing temporary shell;
- full `See All` deep paging/refinement/back behaviour;
- semantic regression validation against accepted 481-lane live baseline;
- Web mouse/touch/keyboard acceptance;
- Android mobile touch/back/resume acceptance;
- Android TV D-pad/focus/back acceptance;
- webOS integration + real LG TV acceptance;
- reproducible Web/mobile-beta/androidTv-beta/webOS artefacts;
- server cutover/rollback runbook and exact-ref scripts;
- controlled stock Moonbase + external Web-root migration.
