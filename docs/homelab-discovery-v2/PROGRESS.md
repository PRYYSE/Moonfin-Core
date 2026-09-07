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

- `0e33e6d8e98f2062a4f79b55eaf4c6bd17e1b625` repaired the post-fetch personalisation refactor without restoring race-order mutable state.
- workflow `34076786844` GREEN: route, catalogue, format, analysis, focused tests and narrow-scope gate all passed.
- `f2de6fc4804dacc9c5bb06a51e4121be5831c89c` added deterministic tab-level personal presentation composition.
- `ca786ca6571f65b63443144738df1814d8d7f6b9` fixed only two collection-literal lints without weakening reversed-result-order coverage.
- workflow `34077193024` GREEN: all gates passed.

## Critical concurrency defect found and fixed — 2026-09-07

Expert review found a second race-order dependency that earlier work had missed: `HomeLabDiscoveryLaneLoader` still mutated `HomeLabDiscoverySession` while lane requests could execute concurrently. That meant shared item novelty/deduplication could depend on network completion order even though personal title/family presentation had already moved post-fetch.

Fix sequence:

- `79a4130b24c512c653e00c70992034f917cf6ed4` made concurrent lane loads presentation-pure and removed session/shared-dedup mutation from the loader.
- `4caacb23697a436385f8cd6c4fa3f5dd87a76179` moved session novelty/shared dedup into the deterministic post-fetch presentation stage.
- `5efceccc1125a15b78e0e5156454866dc68d4d40` updated loader tests to assert raw preview order.
- `fa89efb72c09f7cbd0d2b63a638dd726fc691820` added regression proof that shared novelty is applied in catalogue order.
- `f42629138787fd2c71cb901719ca7ef757689ad0` added `HomeLabDiscoveryTabController`: deterministic selection, concurrent lane I/O keyed by section ID, isolated failures, then deterministic post-fetch presentation.
- `1c3a9fd5196c04bdb6a7ae2249d347e6f9755822` added controller tests including deliberately reversed async completion, isolated lane exceptions and refresh/reset behaviour.

Verified controller milestone: head `48e10844a4773b71e6aa444921b131b9c269911d`, workflow `34077891738`, GREEN across route/catalogue/format/analysis/tests/narrow-scope.

## Runtime + real landing UI — 2026-09-07

The temporary section-name shell was replaced with real runtime wiring and lane rendering.

- `720ac29f023c653c618c7ec0283ebbba4d6a7882`: added feature-local runtime, bounded controller I/O and real tab/lane/loading/error/refresh UI.
- expert review caught a multi-server correctness defect before release: `MediaServerClientFactory.getActiveClient()` is last-loaded-client based, so Discovery must use the authoritative registered `MediaServerClient`.
- `8c371c610b2ca20687e65d75133dfac64d62bd1c`: bridge, runtime and catalogue entry bound to the authoritative active client; late runtime resolution after unmount is disposed.
- `c363e9a6940b0dc8040e4bf8b7928ba3c8151e88`: removed stale factory dependency.
- run `34079062788` correctly rejected one formatter drift before analysis/tests.
- `56daef893ac3baa010532dcd33e7a35c5b411a31`: applied exact formatter output and removed a potential hash-based flaky identity from the bounded-concurrency test.
- workflow `34079224788`: **GREEN** route, 486-lane catalogue, format, focused analysis, focused tests and narrow custom-scope.

Current landing behaviour now has real Moonfin `MediaCard` rows, stock Seerr media-detail navigation, partial-failure handling and refresh. It remains pre-release: focus polish, external-list execution, availability membership and deep `See All` are still open.

## Expert-review gaps recorded — 2026-09-07

Review against the accepted v1 implementation identified concrete gaps rather than treating a green compile as completion:

- v2 schema `availabilityMode` is currently not enforced because runtime lane loading has no membership predicate;
- curated `externalList` queries are deliberately unsupported by the generic Seerr request planner and need an explicit adapter or explicit compile-time exclusion;
- `See All` needs independent deep paging so preview-only family/session diversification never corrupts the full list;
- current landing uses pointer-safe standard tabs but still needs selective upstream TV/keyboard focus primitives;
- accepted v1 persisted rotation history; v2 currently keeps selection history only for the runtime lifetime.

## webOS scope restored — 2026-09-07

LG webOS is a first-class maintained client again.

Recovered source of truth:

- repository `PRYYSE/Smart-TV`
- branch `homelab/webos-v1-staging`
- branch/candidate commit `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`
- candidate tag `homelab-webos-v1-candidate` -> same commit
- beta tag `homelab-webos-beta-latest` -> `264988874b330b11b5ca54fbf2115e42b5662d34`
- app ID `org.moonfin.webos`
- candidate version 2.7.0
- build package `packages/build-webos/`
- existing CI builds `Moonfin_HomeLab_webOS.ipk` with checksum/manifest and publishes the staging candidate prerelease.

The Smart-TV wrapper remains separate from Flutter Moonfin-Core. Preserve app identity/update compatibility and do not replace that architecture merely to make Discovery work.

## CI hardening — 2026-09-07

Discovery v2 CI is strict read-only validation:

- `permissions: contents: read`;
- no formatter/route bot commit or branch push;
- route overlay must already pass `--check`;
- formatter runs only in the ephemeral checkout and `git diff --exit-code` exposes exact formatting drift;
- superseded branch runs are cancelled via workflow concurrency;
- catalogue, analysis, tests and narrow-scope gates remain mandatory.

## Still open

- availability/NSFW membership policy;
- executable curated external-list strategy or explicit fail-closed compilation policy;
- full `See All` deep paging/refinement/back behaviour;
- persistent cross-launch rotation decision/implementation;
- semantic regression validation against accepted 481-lane live baseline;
- Web mouse/touch/keyboard acceptance;
- Android mobile touch/back/resume acceptance;
- Android TV D-pad/focus/back acceptance;
- webOS integration + real LG TV acceptance;
- reproducible Web/mobile-beta/androidTv-beta/webOS artefacts;
- server cutover/rollback runbook and exact-ref scripts;
- controlled stock Moonbase + external Web-root migration.
