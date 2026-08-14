# 06 - Personalisation, Diversity and Deduplication

## Goal

Personalisation should make Discovery feel specific to each user without collapsing into the same few franchises or creating an echo chamber.

The accepted Home Lab baseline already has seed sources from history, favourites, likes, watchlist and library and passed cold-start tests with mixed Movie/Series output. Discovery should reuse and deepen that work rather than creating a separate identity system.

## User signals

### Strong positive signals

- explicit favourite;
- high personal rating / like;
- completed or substantially watched title;
- watchlist additions;
- repeated engagement with a franchise/genre/person over time.

### Medium signals

- recently watched;
- opened detail pages from Discovery;
- played enough to establish interest but not complete;
- repeated browsing of the same genre/network/studio/category.

### Weak/context signals

- library ownership;
- shared cold-start library seeds;
- current Discovery tab/context;
- one-off detail visit.

### Negative/avoid signals

- user/server blocklist;
- explicit-content filter;
- user-hidden content if supported;
- recently surfaced repeatedly in the same session;
- disliked/low-rated content when a reliable personal signal exists.

Do not treat "watched" as a permanent negative. Rewatch/favourite discovery is a valid separate use case.

## Seed strategies

The shared schema should support strategies such as:

1. `recent-history`
2. `favourites`
3. `high-ratings`
4. `likes`
5. `watchlist`
6. `mixed-positive`
7. `library-cold-start`
8. `recent-discovery-context`
9. `genre-affinity`
10. `novelty`
11. `rewatch`
12. `anime-affinity`
13. `movie-affinity`
14. `series-affinity`
15. `person-affinity` (later)
16. `network-studio-affinity` (later)

## Because You Watched

This should be a family of dynamic rows, not a single generic recommendation lane.

### Selection

Choose 2-5 recent/high-affinity seeds with enough recommendation/similar results. Avoid making several rows from the same franchise or near-identical genre unless user behaviour strongly supports it.

Example session:

- Because You Watched *Dune: Part Two*
- Because You Watched *Severance*
- Because You Watched *Frieren*

Another session can use different seeds.

### Source blend

For each seed, combine:

- Seerr/TMDb recommendations;
- Seerr/TMDb similar items;
- optional genre/person/studio affinities derived from details;
- remove local/request-state duplicates only where the row's intent demands unseen discovery.

Recommendations and Similar are different signals and should not be treated as identical lists.

## Mixed For You lanes

### More Like Your Favourites

- select several favourites across Movie/Series/Anime;
- fetch recommendations for each;
- round-robin/interleave rather than appending one seed's whole page;
- weight higher-rated/recent favourites slightly more;
- dedup across seed outputs.

### Inspired by Your Watchlist

- use unrequested/unwatched watchlist items as taste seeds;
- do not simply echo the watchlist itself;
- prefer related content not already in the same visible page.

### Highly Rated and Unseen

- start from broad high-rated catalogue;
- remove/penalise watched titles;
- boost genres/languages/persons that match positive signals;
- retain some exploration diversity.

### Something Different

- calculate high-affinity genres/tags from positive signals;
- deliberately sample outside the top one or two clusters;
- keep a quality floor so "different" does not mean random low-quality content.

### Rediscover / Rewatch

- separate from new discovery;
- use completed/favourite/high-rated local titles;
- optionally focus on titles not watched recently.

## Cold start

A new/quiet user must never get an empty For You tab.

Fallback order:

1. favourites/ratings/watchlist if any;
2. user's local library subset as seeds;
3. shared high-quality library seeds;
4. broadly popular/high-rated catalogue;
5. rotating novelty lanes.

Cold-start results can initially overlap across users. They should naturally diverge as user-specific signals accumulate. Never copy another user's activity/history/favourites/ratings to manufacture diversity.

## Seed diversity

Before choosing recommendation seeds, cluster or constrain by:

- media type;
- Anime versus normal Series;
- genre overlap;
- franchise/title similarity;
- recency;
- user affinity weight.

Rule of thumb: a session's seed set should not contain five Marvel films or five near-identical Anime seasons unless the user has an unusually concentrated profile and even then novelty should occupy some lanes.

## Result mixing

Given multiple seed result lists:

1. normalise IDs/media types;
2. score by source confidence (recommendation > similar where useful), user affinity and result quality;
3. round-robin across seeds;
4. apply exact-item dedup;
5. apply session novelty penalty;
6. enforce media-type/category constraints;
7. retain enough candidates to fill the row.

Do not simply sort all results by global popularity after mixing or the same famous titles will keep winning every personal row.

## Dedup levels

### Exact lane

No duplicate TMDb ID within one lane.

### Adjacent lanes

Strong penalty for an item shown in the previous 2-3 visible lanes.

### Tab/session

Prefer unseen-in-session items. Allow reuse if otherwise the row would be sparse.

### Cross-tab

Weaker penalty. A title appearing once in Movies and once in a targeted For You row can be legitimate.

### Multi-day

Store a bounded recent-surface history (for example the most recent few hundred IDs per user/device). Apply a novelty penalty, not a ban.

## Franchise-aware dedup

For previews only, optionally normalise obvious franchise/season variants using:

- collection ID for Movies where available;
- Series identity for seasons/episodes;
- conservative title normalisation for Anime variants.

Do not apply franchise collapsing to the expanded full result screen.

## Rotation history

Store only lightweight IDs/timestamps needed for novelty:

- recently selected optional lane IDs;
- recently surfaced media IDs by dedup group;
- recent recommendation seed IDs;
- current refresh nonce/session seed.

This can be local initially. Server persistence becomes useful if cross-device personalisation consistency is desired later.

## Request/local-state interaction

Personalisation scoring should not erase ownership state.

A candidate can still appear when:

- already available locally, if the lane is recommendation/rewatch oriented;
- already requested/downloading, if the lane intent is broad discovery and state is clearly shown;
- unavailable/requestable, with normal request action.

Some specific lanes such as `Highly Rated and Unseen` should explicitly exclude watched/local-owned items as part of their stated intent.

## Acceptance gates

1. Active users get multiple distinct seed-derived lanes.
2. Quiet users get useful non-empty fallback content.
3. Two users with distinct histories increasingly diverge.
4. Adjacent rows show substantially fewer repeated top titles.
5. Refreshing Discovery changes optional seeds/rows without deleting user data.
6. A sparse seed never causes the whole For You tab to fail.
7. Anime recommendation seeds produce Anime-aware output rather than indiscriminate TV.
8. Expanded result screens are not over-filtered by landing-page session dedup.
