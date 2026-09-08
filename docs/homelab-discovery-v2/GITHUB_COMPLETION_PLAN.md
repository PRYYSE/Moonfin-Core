# Home Lab Discovery v2 — GitHub Completion Plan

**Status:** authoritative implementation plan  
**Updated:** 2026-09-08 Australia/Adelaide

## Objective

Complete everything reasonably possible in GitHub/code for the entire Moonfin Home Lab Discovery product before beginning physical-device, live-service or production acceptance.

The product scope is:

- Web
- Android mobile/tablet
- Android TV / Google TV
- LG webOS
- shared catalogue/compiler/schema/semantic contracts
- personalisation and recommendation quality
- details/request/playback integration
- navigation/focus/back behaviour
- retained state/cache/error handling
- performance and constrained-device behaviour
- tests, CI, reproducible builds and candidate packaging
- cross-platform consistency
- release/update engineering and durable project documentation

A green package for one platform is not completion. Physical acceptance begins only after the repository state explicitly records that no known GitHub/code-side work remains.

## Authority / execution rule

Use this order when resuming work:

1. current repository/branch state
2. `docs/AI_PROJECT_STATE.md`
3. `docs/homelab-discovery-v2/CHECKPOINT_CURRENT.md`
4. this plan
5. older project history

Do not restart completed work. Each implementation batch should finish one substantial logical slice, run the relevant tests/builds, fix failures, update checkpoints, then stop.

## Phase 1 — Baseline and shared contract lock

- Reconcile current Moonfin-Core and Smart-TV branch HEADs and verified product sources.
- Keep preserved rollback refs and current production/live state untouched.
- Define the shared Discovery semantic contract for media identity, ownership, requestability, pagination, availability, artwork, errors/empty states and personalisation provenance.
- Remove semantic shortcuts that make a specialised label resolve to unrelated data.
- Unsupported semantics must fail closed until a truthful source/filter exists.

**Gate:** shared contract is explicit and regression-tested; no known arbitrary personalisation mapping remains.

## Phase 2 — Shared personalisation and recommendation architecture

Redesign the current Flutter personalisation layer so named strategies mean what they advertise.

Required outcomes:

- explicit strategy/source mapping instead of deterministic slot/hash selection
- real provenance for history/favourites/watchlist/likes/owned/requestable/anime-derived recommendations where the available APIs can prove it
- no fabricated fallback that changes the meaning of a row
- bounded pagination/request cost
- deterministic dedup and ordering rules
- truthful unknown totals during incremental paging
- clear unsupported-strategy behaviour
- tests for each supported semantic strategy and each fail-closed family

The archived accepted v1 personalisation implementation may be used as reference material, but it must not be blindly restored over newer upstream code.

## Phase 3 — Web completion pass

Finish everything code-testable for Web:

- catalogue and personalised semantics
- landing/deep browsing
- mouse, keyboard and touch
- responsive layouts and resize behaviour
- details and Seerr requests
- local Jellyfin item routing and playback hand-off
- browser history/back
- refresh, retained state and retry
- loading/error/genuine-empty distinction
- artwork failure and malformed identity handling
- recommendation diversity/dedup rules
- memory/performance
- guarded stock fallback
- reproducible candidate build

**Gate:** no known Web code-side defect/debt remains; automated tests/build are green.

## Phase 4 — Android mobile/tablet completion pass

Finish everything code-testable for Android phone/tablet:

- phone/tablet layouts
- portrait/landscape
- touch targets and scrolling
- details/request/local playback routing
- Android Back semantics
- lifecycle/resume and retained Discovery state
- refresh/error/empty/deep browse
- artwork and malformed identity handling
- recommendation quality rules
- performance and auth persistence logic
- update-safe local state
- existing signing identity preserved
- reproducible signed candidate

**Gate:** no known Android mobile/tablet code-side defect/debt remains; signing identity and CI/builds are green.

## Phase 5 — Android TV / Google TV completion pass

Treat TV interaction as a distinct product surface even when Flutter code is shared.

Finish:

- D-pad movement and deterministic focus
- navbar/toolbar edges and tab transitions
- row/grid transitions and partial final rows
- See All/deep paging
- detail return and Back
- request flow and owned/local playback routing
- remotely reachable retry/empty/error actions
- long text and 1080p/4K layout behaviour
- low-memory behaviour
- lifecycle/resume
- Android TV/Google TV compatibility

**Gate:** no known TV code-side defect/debt remains; targeted focus/navigation tests and candidate build are green.

## Phase 6 — Final LG webOS reconciliation

webOS already has an advanced isolated implementation. Do not redo it.

Reconcile only changes required by the final shared contract:

- semantic contract updates
- request/detail/local identity contracts
- recommendation policy
- failure/empty/identity handling
- old-TV request and memory limits
- 720p/1080p layout/performance policy
- legacy WebKit compatibility
- full Enact tests/lint/build/package/identity verification

Do not regress the existing constrained-TV optimisations merely to simplify parity.

**Gate:** final webOS candidate is green and no known webOS code-side work remains apart from physical acceptance.

## Phase 7 — Cross-platform parity and quality pass

Maintain a single parity matrix covering at least:

- catalogue
- personalised rows
- See All/deep browse
- owned/local details
- Seerr request flow
- playback routing
- refresh
- retry/error/empty state
- retained state
- recommendation semantics
- identity/provider handling
- artwork fallback
- pagination/exhaustion
- platform-native Back/focus/navigation behaviour

Continue until every difference is either fixed or explicitly justified as platform-specific behaviour.

Also revalidate:

- duplicate/recommendation policy
- sparse data behaviour
- malformed identity handling
- unsupported semantic lanes
- deterministic ordering
- compiler/schema validation
- request-budget limits
- cache/memory bounds

## Phase 8 — CI and release engineering

Before leaving GitHub work, CI must be able to prove the product without relying on chat history.

Required gates where applicable:

- catalogue compiler/schema validation
- semantic/personalisation tests
- membership/dedup tests
- detail/request/local identity routing
- pagination and retained state
- platform navigation/focus helpers
- Web build
- Android mobile build
- Android TV build
- webOS Enact build
- legacy webOS compatibility
- package/application identity
- Android signing certificate identity
- artifact generation

Prefer one higher-level whole-product Discovery gate/report over independent green platform workflows with no shared completion signal.

## Phase 9 — Official Moonfin update protocol

`docs/UPSTREAM_UPDATE_PROTOCOL.md` is mandatory project policy.

Every official Moonfin update must be integrated by starting from the new official upstream release and reapplying the narrow Home Lab overlay, not by continuously carrying an old fork forward.

The protocol must cover all supported platforms and protect signing/package identities, rollback candidates, semantic contracts and cross-platform regression gates.

## Phase 10 — GitHub completion checkpoint

Only after Phases 1–9 are complete may `docs/AI_PROJECT_STATE.md` state:

> No known GitHub/code-side work remains. Remaining work requires real devices, real services, deployment infrastructure, or subjective visual/recommendation acceptance.

Until that sentence is true, physical-device acceptance is not the next primary project phase.

## Physical/live work after GitHub completion

After the GitHub completion checkpoint, run controlled acceptance in this order as practical:

1. Web
2. Android mobile/tablet
3. Android TV / Google TV
4. LG OLED65C6PSA webOS
5. real Jellyfin/Seerr recommendation-quality capture
6. requests/details/local playback
7. lifecycle/resume/update compatibility
8. server cutover and rollback preparation
9. production deployment

The exact device order may change for convenience, but production remains gated on all required acceptance outcomes.

## Permanent safeguards

- Never delete or overwrite preserved recovery refs/candidates merely because a newer build passes CI.
- Never regenerate the accepted Android signing certificate.
- Never change `org.moonfin.webos` without a deliberate migration.
- Do not change the live server during GitHub-only work.
- Prefer a narrow isolated Home Lab overlay over broad upstream forks.
- Unsupported semantics fail closed.
- Green CI/package generation is evidence, not product completion.
- Real-device acceptance can only be claimed from real execution.
