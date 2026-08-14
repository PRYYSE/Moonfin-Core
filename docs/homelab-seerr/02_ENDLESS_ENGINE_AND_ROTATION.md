# 02 - Endless Engine and Rotation

## Product requirement

A page with 100 static rows is not meaningfully endless. It becomes slow, repetitive and difficult to navigate. The Discovery engine therefore needs a **large catalogue pool** but renders a smaller changing selection of lanes at once, while every lane can expand into paginated results.

## Three layers

### Layer A - Catalogue

The complete server-owned set of possible discovery sections. Target catalogue size for the first full Home Lab version:

- For You / personal: 15-25 strategies
- Movies: 70+ possible lanes
- Series: 70+ possible lanes
- Anime: 80+ possible lanes
- New/Upcoming/Seasonal: 20+ possible lanes
- Studios/Networks/Providers: 30+ possible lanes
- Lists/Collections: unbounded external/server-curated entries

This is a pool, not a promise to display every lane simultaneously.

### Layer B - Session composition

Each tab composes a session from:

1. **Anchors** - always present and stable in position.
2. **Priority lanes** - usually present but may move slightly.
3. **Rotating pools** - choose N from a much larger group.
4. **Context lanes** - generated from current user/media context.
5. **External/editorial lanes** - server-fed and time-sensitive.

Example Movies session:

- 5 anchors
- 5 personalised/context lanes
- 4 genre/mix lanes chosen from ~35
- 3 era/runtime/rating lanes chosen from ~20
- 3 studio/provider/language lanes chosen from ~30
- 2 editorial/list lanes

Result: roughly 22 visible lanes, selected from a catalogue of 90+ routes into Movie discovery.

## Anchor lanes

Anchor lanes should be predictable so the page never feels random or loses core functionality.

### Movies anchors

- Trending Movies
- Popular Movies
- Critically Acclaimed
- New Releases
- Coming Soon

### Series anchors

- Trending Series
- Popular Series
- Acclaimed Series
- New & Returning
- Currently Hot / Recent Premieres

### Anime anchors

- Popular Anime
- New This Season
- Top Rated Anime
- Fresh Discoveries
- Anime Movies

### For You anchors

- Because You Watched ...
- More Like Your Favourites
- Inspired by Your Watchlist
- Highly Rated and Unseen
- Continue Exploring / Recently Opened Discovery Contexts

## Rotation model

### Session seed

Use a stable session seed composed from:

- user identity (hashed/non-secret stable ID);
- local date or session start bucket;
- tab ID;
- optional explicit refresh nonce.

This gives stable layout during a visit but changes on a future visit/day or manual refresh.

### Weighted pools

Each optional section carries:

- `pool`: e.g. `movie-genres`, `movie-era`, `movie-studios`, `anime-themes`;
- `weight`: how likely it is to appear;
- `cooldownSessions`: avoid selecting it again immediately;
- `minItems`: hide when the filter produces too little usable content;
- `maxPreviewItems`: default 20;
- `priority`: anchor/high/normal/low;
- `audience`: movie/tv/anime/all;
- optional user/context conditions.

Selection should avoid taking several near-identical lanes from one pool. Example: do not surface Action, Action Adventure, Action Thriller, High-Octane Action and Superhero Action next to each other.

## Manual refresh

Discovery gets a refresh action that:

- increments a local/session nonce;
- recomposes rotating lanes;
- resets their preview pagination;
- keeps anchors;
- does **not** delete user history/preferences;
- does not necessarily invalidate server cache for expensive upstream calls.

This makes "show me something else" explicit and cheap.

## Lane depth

Every media lane with a deterministic query is expandable.

Preview:

- fetch enough pages to produce approximately 20 useful items after filtering/deduplication;
- display a horizontal row;
- prefetch the next page only when useful.

Expanded screen:

- exact same source/query/filter definition;
- vertical/grid infinite pagination;
- local/request/download state attached to every result;
- optional sort/filter controls layered on top without losing the base query;
- back restores lane and focused item.

## Page-level endless behaviour

The landing page itself should not require truly infinite vertical row generation. That would make TV navigation poor. Instead:

- render a curated session of ~18-26 lanes;
- provide refresh/rotate;
- allow expansion of each lane into deep pagination;
- allow rabbit holes from every item;
- optionally load another small group of rotating lanes when the user reaches the end on touch/desktop, but cap total mounted lanes for TV clients.

This gives endless exploration without an endless widget tree.

## Result exhaustion

If a query has many pages, continue normally.

If a query is shallow:

1. read ahead up to a bounded page count;
2. deduplicate/filter;
3. if `minItems` is met, show it;
4. if not, hide that optional lane for the session;
5. never block the rest of the tab.

Anchor lane failure should produce a compact retry/fallback state, not crash the page.

## Dedup interaction

Deduplication is preference, not destructive filtering.

For each preview lane:

1. first choose items not seen in adjacent/earlier lanes for the same dedup group;
2. then choose items not already shown elsewhere in the current tab;
3. then permit previously seen items if needed to maintain a useful row;
4. never reduce a 20-item upstream result to 2 cards merely to achieve perfect uniqueness.

Expanded screens should **not** apply cross-lane dedup. They represent the full result set for that filter.

## Persistence levels

- **Current lane:** avoid duplicate IDs entirely.
- **Current tab/session:** strong dedup preference.
- **Current app session:** moderate novelty preference.
- **Across days:** short cooldown history for optional lanes, not a permanent blocklist.
- **Permanent:** only explicit blocklist/NSFW/user-hidden rules.

## Caching

Recommended server/client cache layers:

- catalogue config: long TTL + ETag/version;
- query result page: 10-30 minutes depending on source;
- trending/upcoming: shorter TTL;
- genres/networks/studios/keyword resolution: long TTL;
- per-user request/local-state overlay: short TTL or live refresh;
- failed lane negative cache: 1-3 minutes;
- explicit user refresh may bypass client result cache but should not stampede upstream APIs.

## Schema changes required

Extend `SeerrDiscoverySection` with fields equivalent to:

- `pool`
- `weight`
- `priority`
- `cooldownSessions`
- `minItems`
- `conditions`
- `tags`

Extend `SeerrDiscoveryTab` with:

- `initialLaneBudget`
- `anchorIds`
- per-pool selection budgets
- TV-specific maximum mounted lane count where needed

Keep the exact query object independent from composition metadata.

## Acceptance gates

1. A Movie session shows at least 18 useful lanes while being chosen from a catalogue much larger than the visible set.
2. Reopening/refreshing produces materially different optional lanes while anchors remain.
3. Adjacent rows do not repeat the same top titles heavily.
4. Every media lane's expanded screen has the same base filter as its preview.
5. An expanded lane can load several pages without duplicating page results.
6. One failed/empty optional lane does not affect other lanes.
7. TV clients never create an unbounded vertical focus tree.
