# Home Lab Discovery v2 — Cross-platform semantic/behaviour matrix

**Date:** 2026-09-10 Australia/Adelaide  
**Scope:** GitHub/code evidence only. No live-service or physical-device acceptance.  
**Platforms:** Moonfin-Core Web, Android mobile/tablet, Android TV/Google TV, Smart-TV Enact/webOS.

## Classification

- **ALIGNED** — externally meaningful behaviour matches closely enough; internals may differ.
- **INTENTIONAL** — platform-specific difference is truthful and appropriate; do not force identical internals.
- **DORMANT** — capability exists but no current authored lane depends on it.

## Matrix

| Area | Web / Android mobile-tablet / Android TV (shared Flutter core) | Enact/webOS | Classification / action |
|---|---|---|---|
| Semantic core | Shared Flutter catalogue/runtime/policies | Independent Enact implementation | **INTENTIONAL.** Compare behaviour, not source structure. |
| Personalisation provenance | History, favourites, watchlist, real high ratings, likes, mixed-positive, recently-added, trending anime, novelty and rewatch use explicit source policies | Equivalent explicit sources; high-ratings uses real Jellyfin `UserData.Rating >= 8` | **ALIGNED.** Unknown strategies still fail closed. |
| Eligibility | Personalised lane admitted only when an adapter/policy supports it | Independent support gate | **ALIGNED.** Capability gates beat nominal lane-count parity. |
| Unsupported semantic claims | Structural/context strategies fail closed | 13 structural/context strategies fail closed; 468 executable-section ceiling | **INTENTIONAL.** Do not invent data to reach nominal 481/481. |
| Generic novelty | Bounded Jellyfin `Random` snapshot supplies at most two recommendation seeds through existing cached transport | Bounded Jellyfin random source and recommendation transport | **ALIGNED after SHARE adoption.** No synthetic ranking model added. |
| Anime novelty | Same bounded random source constrained to anime; title `Something Different in Anime` | Same random-anime semantics and truthful title | **ALIGNED after defect fix.** Neither client claims proven exclusion of the user's usual genres. |
| Rotation / cooldown | Deterministic session seed + refresh nonce + persisted section/session cooldown | Equivalent composer + persisted rotation history | **ALIGNED.** Storage mechanics intentionally differ. |
| Rewatch | Direct played-positive source from favourites + real high ratings + likes; neutral history excluded | Direct played-positive source from Likes + Favourites + real high ratings | **ALIGNED after webOS defect fix.** |
| Anime detection | Tags/genre anime, or Animation + Japanese original language/origin | Equivalent tags/genres/language/location logic | **ALIGNED.** |
| Anime not-owned | Generic `notOwned` membership where ownership is proven; no authored popular-anime-not-library lane | Dedicated popular-anime-not-library adapter exists but no current authored lane uses it | **DORMANT.** Preserve capability; do not add a lane merely for parity. |
| Availability / requestability | Blacklist/NSFW filtering; requested status 2/3; available 4/5 or resolved local ownership; requestable excludes available/requested | Same status semantics/filtering | **ALIGNED.** |
| Unwatched membership | Unknown watch state remains not-known-watched for accepted v1 compatibility | Same | **ALIGNED.** This is compatibility semantics, not proof unknown means unwatched. |
| Identity | TMDB media-type key is external identity; Jellyfin ID only accompanies proven external identity | Same TMDB-first contract with optional resolved Jellyfin ID | **ALIGNED.** Never promote a local Jellyfin ID to TMDB. |
| Detail routing | Same identity contract; Web uses web route, mobile touch navigation, TV D-pad/focus restoration | Enact route/focus mechanics | **INTENTIONAL.** Routing mechanics differ by platform. |
| Per-page dedup | Media type + TMDB identity | Same | **ALIGNED.** |
| Cross-row dedup | Deterministic session dedup in catalogue order; backfill where possible | Equivalent shared/session dedup | **ALIGNED.** |
| Personal preview diversity | Preview-only family/title diversity; See All preserves source ranking | Bounded recommendation output with TV-specific presentation | **INTENTIONAL/ALIGNED outcome.** Preview diversity must not redefine ranking. |
| Sparse / underfilled rows | Successful rows below `minItems` hide; failures remain distinguishable | Same outcome | **ALIGNED.** |
| Explicit refresh | Total failed explicit refresh retains last good tab; partial fresh result remains authoritative | Equivalent retained-refresh fallback | **ALIGNED.** |
| Reset | Clears nonce, session dedup, rotation history and retained tab | Clears session/rotation and invalidates deep state | **ALIGNED outcome.** |
| Landing/deep scan | Non-personal lanes scan max 6 source pages; personal source snapshots/recommendation seeds bounded | Non-personal max 6; personal landing deliberately one logical page | **INTENTIONAL.** webOS remains stricter for old-TV cost. |
| Personal request cost | Snapshot max 60, rated candidates max 100, watchlist max 2 pages, max 2 recommendation seeds; caches shared | Seed limit 60, high-rating 100, cache max 24 rows, upstream fetch budget 4 | **INTENTIONAL/BOUNDED.** Do not force identical budgets. |
| Lane concurrency | Max 6 concurrent selected-lane loads | Max 6 | **ALIGNED.** |
| See All / deep paging | Feature-local deep controller, retry, preview-diversity bypass; TV restores focus | Independent deep controller/state and scope invalidation | **INTENTIONAL/ALIGNED outcome.** |
| Retry / failure isolation | Per-lane exceptions isolated; failed initial tab not cached; retained refresh fallback | Per-lane isolation + retained refresh fallback | **ALIGNED.** |
| Aggregate quality diagnostics | Privacy-safe duplicate/identity/art/ownership/underfill/failure aggregate report | Equivalent aggregate quality analyser | **ALIGNED.** No titles or media IDs need to be serialised. |
| Ranking / recommendation quality | Upstream/source ranking remains authoritative; composer selects lanes rather than re-ranking media | Same principle | **INTENTIONAL.** No ranking changes from synthetic tests; real Home Lab aggregate evidence is required before tuning. |

## Validation status

### Slice 1 — validated

Moonfin implementation `572e32d54d14d0d50ba8066cd817d8938ffae572`; formatter recovery `9ccb89927ca23bb4d3f00043f70ba138a6239beb`; workflow **#130 / `34436806830` GREEN**.

### Slice 2 — validated

Moonfin product `b800e5be18109963e4ae00b3739550b924c7204f`; formatter-only follow-up `e654668f89af49470df417d4fcc444e73c53121e`; workflow **#132 / `34439296054` GREEN**.

Smart-TV product `a9dfa657a220a3f8f77753261bd7d8e902c0d837`; workflow **#52 / `34439022624` GREEN**.

Cross-platform parity correctness is therefore complete for the current GitHub-only/no-live boundary.

## Decisions that remain locked

1. Do not reopen completed Web/mobile/Android-TV/webOS platform passes without new defect evidence.
2. Keep the 13 structural/context webOS strategies and equivalent unproven Flutter semantics fail-closed.
3. Do not add an authored popular-anime-not-library lane merely because webOS has a dormant adapter.
4. Do not tune ranking/source preference from synthetic tests. Use real privacy-safe Home Lab aggregate diagnostics when live evidence is explicitly allowed.
5. Current work has advanced to whole-product CI/release engineering; parity itself is not an open stage.
