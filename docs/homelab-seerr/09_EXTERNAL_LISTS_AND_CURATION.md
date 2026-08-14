# 09 - External Lists and Curation

## Goal

External lists provide editorial depth that pure TMDb filters cannot express cleanly, especially for Anime themes, awards, seasonal collections, "best of" lists and user watchlists.

Moonfin already has a server-proxied external-list path. Reuse it.

## Existing supported sources

Current `CustomExternalListsService` recognises server configurations for:

- IMDb user lists;
- IMDb event/year pages;
- TMDb lists;
- TMDb Movie collections;
- Letterboxd user sources;
- MDBList lists.

Items are fetched through authenticated `/Moonfin/CustomRows/Items`, then cached locally as a fallback. Existing sorting supports title, year, popularity, rating and shuffle.

## Product surfaces

### Lists tab

A dedicated Discovery `Lists` destination should group:

- Home Lab editorial lists;
- personal/user lists where configured;
- seasonal lists;
- awards/festival lists;
- Anime curated lists;
- Movie/Series topic lists;
- recently refreshed lists;
- favourite/pinned lists later.

### Landing-page lanes

A small rotating selection of list-backed lanes can appear on Movies/Series/Anime/For You. The entire list catalogue should not be mounted as rows at once.

### Expanded list screen

Every list lane opens a full list browser preserving source order unless the user selects a supported local sort.

## Server catalogue definition

List-backed discovery sections should carry:

- stable Home Lab section ID;
- display title/subtitle;
- source (`mdblist`, `letterboxd`, `imdb`, `tmdb`, etc.);
- source type;
- source parameters;
- media-type constraint if known;
- sort mode/order;
- cache TTL;
- optional seasonal activation dates;
- pool/rotation metadata;
- expansion enabled;
- explicit-content policy/category tags.

Secrets/API keys stay in server/plugin configuration and never appear in the catalogue payload.

## Suggested initial editorial list families

### Movies

- Award Winners / Nominees
- Best Picture Winners
- Modern Classics
- Essential Sci-Fi
- Essential Horror
- Essential Crime
- Essential Animation
- Family Favourites
- Great Films Under Two Hours
- Australian Cinema Spotlight
- Korean Cinema Essentials
- A24 Essentials
- Directors/filmmaker spotlights when maintained externally

### Series

- Prestige TV Essentials
- Limited Series Essentials
- Best Crime Series
- Best Sci-Fi Series
- Best Comedy Series
- Best Documentary Series
- International Series Essentials
- Australian Series Spotlight
- Recent Critical Breakouts

### Anime

- Seasonal Staff Picks
- Anime Starter Pack
- Modern Anime Essentials
- Classic Anime Essentials
- Best Anime Movies
- Best Mecha Anime
- Best Sports Anime
- Best Romance Anime
- Best Psychological Anime
- Best Sci-Fi Anime
- Best Fantasy Anime
- Best Comedy Anime
- Studio/creator spotlights where TMDb company metadata is unreliable

## Personal lists

### Letterboxd

Current Moonfin list plumbing already recognises Letterboxd user configuration. SeerrFin's Letterboxd feature is therefore useful as a product reference, not a reason to add a second direct Letterboxd client.

Potential Discovery uses:

- personal Letterboxd watchlist lane;
- expanded watchlist browser;
- request/local status overlay;
- bulk request remains a separate explicit action and should not happen automatically while browsing.

### MDBList

Use for:

- curated lists;
- user-owned lists;
- highly specific topic lists;
- dynamic lists maintained outside Moonfin.

Existing MDBList ratings integration is separate and should continue to provide ratings rather than being conflated with list fetching.

### TMDb collections

Collections are better treated as franchise rabbit holes than normal editorial lists when a discovery item has `belongs_to_collection`. However manually configured TMDb list/collection sources can also appear in Lists.

## Sync/cache behaviour

### Server

- canonical source fetch and credentials;
- normalise IDs/provider IDs;
- cache source results;
- expose last successful refresh time;
- refresh on TTL/manual admin refresh;
- keep last-known-good data when the external source temporarily fails.

### Client

- cache the normalised list payload for offline/failure fallback where current service already supports it;
- do not hammer `/Moonfin/CustomRows/Items` on focus changes;
- preserve source order unless sort/shuffle is explicitly configured.

## Expansion and pagination

Some external lists may return a large complete payload rather than upstream page metadata.

For expanded browsing, support one of:

1. server endpoint pagination over the cached normalised list; preferred for large lists and TV memory;
2. client-side windowing over a bounded complete list when the source is already small.

Do not render hundreds/thousands of list cards at once.

## ID resolution

Normalise external items to:

- TMDb ID where available;
- IMDb ID fallback;
- media type;
- title/year;
- artwork URLs;
- optional rating/popularity.

Then reuse existing Moonfin local Jellyfin resolution and Seerr detail/request routing. External lists must not create a third media-detail type.

## List dedup

- remove exact duplicate IDs within one list;
- preserve first occurrence/source ordering;
- landing-page preview uses session dedup against nearby lanes;
- expanded list shows the complete normalised list without cross-lane hiding.

## Seasonal activation

Catalogue entries can have optional active windows, for example:

- Halloween lists in October;
- Christmas/holiday lists in November-December;
- awards lists around awards season;
- current Anime season lists.

Outside the window they remain accessible from Lists if desired but receive zero landing-page rotation weight.

## Failure handling

- one failed list never fails a tab;
- use last-known-good cached content when safe;
- stale content should be marked internally/diagnostically, not necessarily with noisy user UI;
- invalid IDs/items are skipped individually;
- source authentication errors are surfaced in admin diagnostics without exposing secrets.

## Acceptance gates

1. At least one configured list from each already-supported source type can load through the server path where credentials/public access allow it.
2. A list item resolves to local Jellyfin when owned and Seerr detail/request when not owned.
3. Expanded list browsing handles at least several hundred items without mounting them all.
4. Source outage falls back to last-known-good cache where available.
5. No API key/source secret appears in client logs or catalogue JSON.
6. External lists can be added/removed/reordered server-side without an app rebuild after the shared schema is deployed.
