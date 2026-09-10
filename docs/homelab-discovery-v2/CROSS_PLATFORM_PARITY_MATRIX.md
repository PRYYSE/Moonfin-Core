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
| Novelty lane | Dedicated `novelty` personal source remains unsupported/fail-closed; session composition still rotates lane selection | Same | Same | Truthful random Jellyfin source (`SortBy=Random`) supports novelty | **SHARE candidate, not defect.** Port only if Flutter can prove the same bounded random-source semantics without degrading request cost. |
| Rotation/cooldown | Deterministic seed + refresh nonce + persisted section/session cooldown history | Same | Same | Equivalent deterministic composer + persisted rotation history | **ALIGNED.** Storage mechanics differ intentionally. |
| Rewatch | Dedicated rewatch strategy remains fail-closed | Same | Same | Truthful positive-source direct lane constrained to played items | **SHARE candidate, not defect.** Do not substitute generic recommendations for rewatch semantics. |
| Anime detection | Tag/genre anime, or animation + Japanese language/origin | Same | Same | Equivalent tag/genre/language/origin test | **ALIGNED.** |
| Anime not-owned | Generic membership `notOwned` supported when availability proves ownership; dedicated popular-anime-not-library strategy remains fail-closed | Same | Same | Dedicated popular-anime source with anime constraint and resolved-library exclusion | **SHARE candidate, not defect.** Keep Flutter lane closed until equivalent source + library-resolution evidence is bounded and proven. |
| Availability/requestability | Blacklist/NSFW filtering; requested status 2/3; available 4/5 or resolved local ownership; requestable excludes available/requested | Same | Same | Same status semantics and filtering | **ALIGNED.** |
| Unwatched membership | Unknown watch state is treated as not-known-watched, preserving accepted v1 behaviour | Same | Same | Same | **ALIGNED.** This is an explicit compatibility choice, not proof that unknown means unwatched. |
| Identity | External identity is TMDB media-type key; local Jellyfin IDs are never promoted to TMDB IDs; local ID may accompany proven external identity | Same | Same | Same TMDB-first discovery identity with optional resolved Jellyfin ID | **ALIGNED.** |
| Detail routing | Flutter route/open helper selects the appropriate local/external detail path | Touch navigation mechanics | D-pad/focus restoration mechanics | Enact route/focus mechanics | **INTENTIONAL.** Navigation mechanics differ, identity contract should not. |
| Per-page dedup | Media type + TMDB ID | Same | Same | Same | **ALIGNED.** |
| Cross-row dedup | Deterministic post-fetch session dedup in catalogue order; backfills to lane minimum where possible | Same | Same | Equivalent session/shared-group dedup | **ALIGNED.** |
| Personal preview diversity | Preview-only title/family diversity; See All preserves full source ranking | Same | Same | Recommendation output kept bounded; independent TV presentation | **INTENTIONAL/ALIGNED outcome.** Do not make preview diversity redefine ranking. |
| Sparse/underfilled rows | Sparse successful rows hide below `minItems`; failed rows remain distinguishable | Same | Same | Same | **ALIGNED.** |
| Ordinary rebuild/resume | Successful Flutter tab result cached; concurrent callers share in-flight work | Same | Same | Enact state retained by independent runtime/view lifecycle | **INTENTIONAL.** |
| Explicit refresh | Rotates nonce and reloads; before this parity slice, a total refresh failure could replace previously-good content | Same | Same | Has explicit retained-refresh fallback helper that preserves previous ready/partial content and records `refreshFailure` | **DEFECT in shared Flutter core. FIXED in this parity slice:** retain the last good tab only on total explicit-refresh failure; partial fresh results remain fresh. |
| Reset | Clears nonce, session dedup, rotation history and retained tab result | Same | Same | Clears session/rotation and invalidates deep-state scope | **ALIGNED outcome.** Internal deep-state lifecycle differs by client. |
| Landing deep-scan cost | Non-personal lanes scan at most 6 source pages; personal landing preview uses bounded snapshots/recommendation seed caches | Same | Same | Non-personal max 6; personalised landing deliberately 1 logical page | **INTENTIONAL.** Both are bounded; webOS is stricter for old-TV cost. |
| Personal recommendation cost | Source snapshots capped; at most 2 recommendation seeds per source-specific recommendation lane; caches shared within runtime | Same | Same | Explicit upstream fetch budget/caches tuned for legacy TV | **INTENTIONAL.** Do not force identical budgets where device costs differ. |
| Lane concurrency | Max 6 concurrent selected-lane loads | Same | Same | Max 6 by controller | **ALIGNED.** |
| See All/deep paging | Feature-local deep controller; page-based loading/retry, preview-only diversity bypassed | Same | TV focus state restored around deep navigation | Independent deep controller/state with explicit scope invalidation | **INTENTIONAL/ALIGNED outcome.** |
| Retry/failure isolation | Lane exceptions isolated; failed initial tab is not cached so Retry can heal | Same | Same | Lane isolation plus refresh fallback | **ALIGNED after refresh-fallback fix.** |
| Aggregate recommendation diagnostics | Previously absent from shared Flutter core | Same | Same | Privacy-safe aggregate quality analyser: duplicates, missing artwork/identity, ownership ratio, underfill/failures | **SHARE. ADDED in this parity slice** as a shared, presentation-output-only analyser. It does not change ranking and serialises no title or media identity. |
| Ranking/quality tuning | Upstream/source ranking remains authoritative; deterministic composition selects rows, not media ranking | Same | Same | Same principle; diagnostics available | **INTENTIONAL.** No ranking changes from synthetic tests. Real Home Lab diagnostic evidence is required before tuning. |

## Current parity decisions

1. **No platform stage is reopened.** Web, mobile/tablet, Android TV and webOS remain code-complete at their verified source gates.
2. **Fix the shared Flutter total-refresh regression only.** A failed explicit refresh must not blank an already-good Discovery tab; partial fresh results must not be replaced by stale data.
3. **Share diagnostics, not ranking guesses.** Add the webOS-style aggregate quality report to the shared Flutter core so future real Home Lab evidence can be compared without leaking titles or Jellyfin/TMDB identifiers.
4. **Do not enable Flutter novelty, rewatch or popular-anime-not-owned yet.** webOS proves these can be implemented truthfully, but Flutter needs equivalent bounded source/library-resolution adapters before those catalogue strategies become eligible.
5. **Keep structural/context strategies fail-closed.** The 468 webOS ceiling and Flutter capability gates are truthful differences, not defects.

## Recommendation-quality evidence boundary

Synthetic unit tests may verify counting, dedup, privacy and state transitions. They must not be used to tune ranking weights or source preference. The next quality pass should compare aggregate diagnostics from real Home Lab Discovery output when such evidence is available without crossing the current no-live-service boundary. Useful fields are duplicate ratio, underfilled-lane count, missing-poster ratio, owned ratio, hidden/failed lanes and per-section aggregate counts. Titles and media identifiers are unnecessary for that decision.
