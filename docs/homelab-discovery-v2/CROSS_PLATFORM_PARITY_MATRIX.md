# Home Lab Discovery v2 — Cross-platform semantic/behaviour matrix

**Date:** 2026-09-10 Australia/Adelaide  
**Scope:** GitHub/code evidence only. No live-service or physical-device acceptance.  
**Platforms:** Moonfin-Core Web, Android mobile/tablet, Android TV/Google TV, Smart-TV Enact/webOS.

## Classification

- **INTENTIONAL** — platform-specific implementation is truthful and appropriate; do not force identical internals.
- **SHARE** — one platform has a stronger truthful behaviour worth adopting elsewhere where the same evidence/cost bounds exist.
- **DEFECT** — externally meaningful behaviour is weaker or inconsistent without a platform justification.

## Matrix

| Area | Web | Android mobile/tablet | Android TV / Google TV | Enact/webOS | Classification / action |
|---|---|---|---|---|---|
| Semantic core | Shared Flutter Discovery catalogue/runtime/policies | Same shared Flutter core | Same shared Flutter core | Independent Enact implementation | **INTENTIONAL.** Compare advertised behaviour, not source structure. |
| Personalisation provenance | Source adapters for history, favourites, watchlist, real high ratings, likes, mixed-positive, recently-added and trending anime; generic affinity policies remain separate | Same | Same | Equivalent truthful sources, including corrected real Jellyfin `UserData.Rating >= 8` high-rating seeds | **ALIGNED.** Previous webOS high-rating provenance defect is already fixed; do not reopen. |
| Unsupported semantic claims | Unknown/context/structural strategies fail closed | Same | Same | 13 structural/context strategies fail closed; 468 executable-section ceiling | **INTENTIONAL.** Keep unproven structural/context semantics disabled. |
| Eligibility | Personalised lanes admitted only when a truthful adapter/policy supports them | Same | Same | Independent executable-plan/personalisation support gate | **ALIGNED.** Dynamic capability gates are preferred to nominal lane-count parity. |
| Generic novelty | Authored `Something Different` currently fails closed because Flutter has no `novelty` source policy | Same | Same | Bounded Jellyfin random source (`SortBy=Random`, seed limit 60) | **SHARE.** Flutter already has a bounded local-query primitive that can request `SortBy=Random` with a 60-item snapshot, so equivalent truthful support is feasible without new ranking heuristics or unbounded cost. Implement only after the current focused gate is green. |
| Anime novelty | Authored lane is `Anime Outside Your Usual Genres`; Flutter currently fails `anime-novelty` closed | Same | Same | `anime-novelty` aliases generic random selection plus `animeOnly`; it does not derive or exclude the user's usual genres | **DEFECT in advertised semantics.** Random anime does not prove "outside your usual genres". Prefer a truthful catalogue label such as `Something Different in Anime` rather than inventing genre-preference inference during parity work. Then the same bounded random-anime source can be shared with Flutter. |
| Rotation/cooldown | Deterministic seed + refresh nonce + persisted section/session cooldown history | Same | Same | Equivalent deterministic composer + persisted rotation history | **ALIGNED.** Storage mechanics differ intentionally. |
| Rewatch | Dedicated `rewatch` strategy currently fails closed | Same | Same | `rewatch` is direct `positive` + `playedOnly`, but `positive` currently combines Likes + Favourites + all played History | **DEFECT in webOS source semantics / SHARE opportunity.** Because History already consists of played items, an arbitrary recently watched item can qualify as `Worth Rewatching` without a positive signal. Root fix should use positive evidence only, for example Likes + Favourites + real high ratings, then require played state. Flutter can implement the same semantics from its existing bounded/cached sources. |
| Anime detection | Tag/genre anime, or animation + Japanese language/origin | Same | Same | Equivalent tag/genre/language/origin test | **ALIGNED.** |
| Anime not-owned capability | Generic membership `notOwned` is supported when availability proves ownership; no current authored `anime-popular-but-not-in-your-library` lane was found | Same | Same | Adapter exists for popular anime with resolved-library exclusion, but no current authored catalogue lane uses that strategy | **DORMANT / no active parity gap.** Preserve the adapter, but do not add a lane merely for nominal parity. Revisit only if the product catalogue deliberately adds this behaviour later. |
| Availability/requestability | Blacklist/NSFW filtering; requested status 2/3; available 4/5 or resolved local ownership; requestable excludes available/requested | Same | Same | Same status semantics and filtering | **ALIGNED.** |
| Unwatched membership | Unknown watch state is treated as not-known-watched, preserving accepted v1 behaviour | Same | Same | Same | **ALIGNED.** This is an explicit compatibility choice, not proof that unknown means unwatched. |
| Identity | External identity is TMDB media-type key; local Jellyfin IDs are never promoted to TMDB IDs; local ID may accompany proven external identity | Same | Same | Same TMDB-first discovery identity with optional resolved Jellyfin ID | **ALIGNED.** |
| Detail routing | Flutter route/open helper selects the appropriate local/external detail path | Touch navigation mechanics | D-pad/focus restoration mechanics | Enact route/focus mechanics | **INTENTIONAL.** Navigation mechanics differ, identity contract should not. |
| Per-page dedup | Media type + TMDB ID | Same | Same | Same | **ALIGNED.** |
| Cross-row dedup | Deterministic post-fetch session dedup in catalogue order; backfills to lane minimum where possible | Same | Same | Equivalent session/shared-group dedup | **ALIGNED.** |
| Personal preview diversity | Preview-only title/family diversity; See All preserves full source ranking | Same | Same | Recommendation output kept bounded; independent TV presentation | **INTENTIONAL/ALIGNED outcome.** Do not make preview diversity redefine ranking. |
| Sparse/underfilled rows | Sparse successful rows hide below `minItems`; failed rows remain distinguishable | Same | Same | Same | **ALIGNED.** |
| Ordinary rebuild/resume | Successful Flutter tab result cached; concurrent callers share in-flight work | Same | Same | Enact state retained by independent runtime/view lifecycle | **INTENTIONAL.** |
| Explicit refresh | Rotates nonce and reloads; before parity slice 1 a total refresh failure could replace previously-good content | Same | Same | Has explicit retained-refresh fallback helper preserving previous ready/partial content and recording `refreshFailure` | **DEFECT in shared Flutter core, implementation committed.** Retain the last good tab only on total explicit-refresh failure; partial fresh results remain fresh. Focused CI validation is still pending after a format-only gate correction. |
| Reset | Clears nonce, session dedup, rotation history and retained tab result | Same | Same | Clears session/rotation and invalidates deep-state scope | **ALIGNED outcome.** Internal deep-state lifecycle differs by client. |
| Landing deep-scan cost | Non-personal lanes scan at most 6 source pages; personal landing preview uses bounded snapshots/recommendation seed caches | Same | Same | Non-personal max 6; personalised landing deliberately 1 logical page | **INTENTIONAL.** Both are bounded; webOS is stricter for old-TV cost. |
| Personal recommendation cost | Source snapshots capped; at most 2 recommendation seeds per source-specific recommendation lane; caches shared within runtime | Same | Same | Explicit upstream fetch budget/caches tuned for legacy TV | **INTENTIONAL.** Do not force identical budgets where device costs differ. |
| Lane concurrency | Max 6 concurrent selected-lane loads | Same | Same | Max 6 by controller | **ALIGNED.** |
| See All/deep paging | Feature-local deep controller; page-based loading/retry, preview-only diversity bypassed | Same | TV focus state restored around deep navigation | Independent deep controller/state with explicit scope invalidation | **INTENTIONAL/ALIGNED outcome.** |
| Retry/failure isolation | Lane exceptions isolated; failed initial tab is not cached so Retry can heal | Same | Same | Lane isolation plus refresh fallback | **ALIGNED after refresh-fallback implementation, pending focused CI confirmation.** |
| Aggregate recommendation diagnostics | Shared privacy-safe analyser added in parity slice 1 | Same | Same | Privacy-safe aggregate quality analyser: duplicates, missing artwork/identity, ownership ratio, underfill/failures | **SHARE implementation committed.** The Flutter analyser is presentation-output-only, changes no ranking, and serialises no title or media identity. Focused CI confirmation is pending. |
| Ranking/quality tuning | Upstream/source ranking remains authoritative; deterministic composition selects rows, not media ranking | Same | Same | Same principle; diagnostics available | **INTENTIONAL.** No ranking changes from synthetic tests. Real Home Lab diagnostic evidence is required before tuning. |

## Current parity decisions

1. **No completed platform stage is broadly reopened.** Web, mobile/tablet and Android TV continue to share one semantic core. webOS may be touched only for the two parity-proven semantic defects described above.
2. **Finish validation of parity slice 1 before stacking product changes.** Run #129 failed only because two new test files were not committed in `dart format` form. Format-only commit `9ccb89927ca23bb4d3f00043f70ba138a6239beb` corrected exactly that output; run #130 / `34436806830` is the authoritative pending focused gate.
3. **Next bounded semantic slice after that gate:** make the anime novelty label truthful; add bounded generic/anime novelty source support to Flutter; change webOS rewatch to positive signals only; add equivalent bounded Flutter rewatch support. Do not alter ranking weights.
4. **Do not create a popular-anime-not-library lane during parity work.** The webOS adapter is currently dormant and there is no authored lane to make parity with.
5. **Keep structural/context strategies fail-closed.** The 468 webOS ceiling and Flutter capability gates remain truthful differences, not defects.

## Recommendation-quality evidence boundary

Synthetic unit tests may verify counting, dedup, privacy, provenance and state transitions. They must not be used to tune ranking weights or source preference. The quality pass should compare aggregate diagnostics from real Home Lab Discovery output only when such evidence is available without crossing the current no-live-service boundary. Useful fields are duplicate ratio, underfilled-lane count, missing-poster ratio, owned ratio, hidden/failed lanes and per-section aggregate counts. Titles and media identifiers are unnecessary for that decision.
