# 10 - Server-Driven Configuration, Cache and Authentication

## Decision

Deep Discovery should use a **versioned global/server catalogue**, not hundreds of `pluginDynamic` Home rows copied across every user/device profile.

The existing 33 Moonbase Home/Movies/TV/Anime editorial rows remain exactly where they are. Deep Discovery gets a separate config domain.

## Why

Per-profile Home rows are good for a small curated Home layout. They are a poor storage model for 300+ possible rotating Discovery routes because:

- Moonbase whole-profile saves can propagate metadata across Global/Desktop/Mobile/TV;
- old profile definitions can overwrite newer ones;
- most deep-discovery taxonomy is shared by all users;
- user differences should be personal seeds/overrides, not duplicate copies of the whole catalogue;
- server-driven catalogue changes should not require app rebuilds.

## Preferred server contract

Target endpoint concept:

`GET /Moonfin/Discovery/Catalogue`

Authenticated with the normal Jellyfin user session/token.

Response shape:

```json
{
  "schemaVersion": 2,
  "catalogueVersion": "2026.08.14.1",
  "generatedAt": "...",
  "tabs": [...],
  "capabilities": {...},
  "userOverrides": {...}
}
```

The exact route can change during Moonbase implementation, but the ownership boundary should remain.

## Catalogue layers

### 1. Authoring catalogue

Human-readable server config can contain:

- stable IDs;
- titles/subtitles;
- media type;
- source;
- high-level filters;
- **keyword names/aliases** rather than opaque IDs;
- provider names/region intent;
- studio/network IDs when already validated;
- pool/weight/priority/cooldown;
- seasonal activation rules;
- list provider/parameters;
- availability mode;
- explicit-content category;
- client hints.

### 2. Compiled catalogue

Before serving, resolve authoring data into executable queries:

- date tokens -> actual dates;
- keyword names -> exact cached TMDb keyword IDs;
- AU provider names -> current provider IDs where needed;
- invalid optional lanes -> disabled with diagnostic reason;
- external-list definitions -> normalised source references.

Clients receive validated executable filters plus optional authoring metadata for display/diagnostics.

### 3. User/session composition

Clients or server composition use:

- user identity;
- per-user history/favourites/ratings/watchlist;
- recent lane/media cooldown state;
- device class;
- explicit refresh nonce;

to select the visible subset from the global catalogue.

## User overrides

Keep small and separate from the catalogue:

- hidden/pinned lanes later;
- preferred Discovery landing tab;
- optional provider/language preferences later;
- explicit refresh/cooldown history if cross-device persistence is desired.

Do not copy the entire catalogue into every user profile.

## Built-in client fallback

Every client should keep a **small recovery fallback catalogue**, not the full Home Lab authoring catalogue.

Purpose:

- server endpoint temporarily unavailable;
- server catalogue schema too new for client;
- corrupt config rejected.

Fallback should provide core Trending/Popular/Genres/Upcoming/Watchlist and a few personal rows. It is a safety net, not the primary endless catalogue.

## Schema negotiation

Catalogue response includes:

- `schemaVersion`;
- optional `minimumClientSchema`;
- capabilities such as `dynamicKeywords`, `externalLists`, `rotationV2`, `availabilityMode`.

Client behaviour:

1. known compatible schema -> use server catalogue;
2. unknown newer schema but backwards-compatible fields -> parse supported subset if explicitly allowed;
3. incompatible -> fallback locally and record diagnostic;
4. never crash Discovery because one optional field is unknown.

## Authentication

### Catalogue endpoint

Use existing Jellyfin authenticated session. No Seerr API key is returned.

### Seerr calls

Continue using current Moonfin/Seerr repository/proxy/session mechanism. The handover already established that raw Jellyfin auth alone cannot call Seerr and server tooling safely obtains configured Seerr credentials without printing them. Do not expose those credentials to LG/Android/Web clients beyond the existing authenticated proxy/session model.

### External list calls

Continue server-side `/Moonfin/CustomRows/Items` or equivalent server proxy. Source credentials never appear in catalogue JSON.

### MDBList ratings

Continue existing `/Moonfin/MdbList/Ratings` proxy. Do not place MDBList API credentials in Discovery config.

## Query allow-list

Only pass known current Seerr discovery filters. Unknown authoring keys fail catalogue validation before serving.

Current allow-list includes:

- date ranges;
- studio/genre/keywords/excluded keywords;
- language;
- runtime;
- vote averages/counts;
- network;
- watch provider/region;
- status;
- certification filters.

The allow-list is versioned with the compiler. Upstream Seerr changes can be added server-side after validation.

## Keyword resolver

Use Seerr's keyword search endpoint as the upstream source.

Algorithm:

1. normalise requested keyword/alias;
2. look up long-lived cache;
3. if absent, query keyword search;
4. prefer exact case-insensitive name match;
5. allow explicit alias mapping to a known exact name;
6. reject ambiguous fuzzy-only results;
7. cache successful ID for long TTL;
8. negative-cache failures briefly;
9. disable only the affected optional lane.

This is critical for Anime subgenre/theme rows.

## Provider resolver

Provider rows are region-sensitive.

- Discovery default region: AU for Home Lab.
- Resolve provider name -> provider ID from current Seerr/TMDb provider data.
- Store compiled provider ID + region in served catalogue.
- If a provider is unavailable in AU, disable that lane rather than silently using US data.

## Cache layers

### Catalogue/compiled config

- long TTL;
- ETag/version;
- atomic replace after successful validation;
- last-known-good copy.

### Keyword/provider dictionaries

- long TTL;
- manual/admin refresh path;
- negative cache for lookup failures.

### Discovery query pages

Suggested defaults:

- trending: 5-15 min;
- popular/general discover: 15-30 min;
- upcoming: 15-60 min;
- static genre/studio/network pages: 30-120 min;
- personal recommendation outputs: shorter and keyed per user/seed;
- external lists: source-specific, generally hours rather than minutes.

### Request/local state

Do not freeze ownership state inside long-lived discovery page cache. Overlay/refresh Seerr/Jellyfin state separately or use shorter state TTL.

## Failure isolation

Every section fetch is independently cancellable/failable.

- one lane fails -> hide/retry that lane;
- optional compile failure -> disable that lane with diagnostic;
- catalogue endpoint fails -> use last-known-good then built-in fallback;
- external list fails -> use list last-known-good where available;
- Seerr unavailable -> keep local discovery where possible and show one concise service state;
- Jellyfin local-resolution failure -> do not falsely mark item unavailable/requestable.

## Performance/concurrency

- bounded concurrent lane fetches, e.g. 3-4 rather than firing 24 upstream requests simultaneously;
- prioritise visible/top lanes;
- lazy-load lower lanes;
- cancel work when tab/session is abandoned;
- coalesce identical query pages by `cacheKey`;
- avoid per-card network calls for ownership/ratings when batch/state data can be reused.

## Configuration deployment

Once clients support schema v2, most future changes become server-only:

- add/remove/rename lanes;
- adjust filters/weights/pools;
- add external lists;
- change seasonal windows;
- adjust provider/keyword resolutions;
- change default visible lane budgets.

New APK/IPK/web builds are still required when introducing a brand-new schema/source type or UI behaviour clients cannot parse.

## Acceptance gates

1. A valid server catalogue loads on Web/Android and has the same stable section IDs.
2. Corrupt/unsupported catalogue falls back without losing core Discovery.
3. Change a server lane title/filter and see it propagate without app rebuild.
4. No credential/token appears in catalogue response or logs.
5. Keyword exact resolution is cached and ambiguous matches are rejected.
6. AU provider lane is disabled when provider cannot be resolved for AU.
7. One invalid lane does not invalidate the whole catalogue.
8. Last-known-good config survives a failed update.
