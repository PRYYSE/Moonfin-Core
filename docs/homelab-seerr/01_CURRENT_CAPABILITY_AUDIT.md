# 01 - Current Capability Audit

## Goal

Establish what already exists before adding anything. This prevents the Seerr phase from rebuilding mature Moonfin request/detail/list functionality and keeps changes focused on discovery depth.

## Accepted product boundaries

- Existing Home/Movies/TV/Anime hubs remain working product surfaces.
- Moonbase/user settings remain authoritative for Home row availability/order.
- Jellyfin remains authoritative for local library identity, playback, history, favourites and ratings.
- Seerr remains authoritative for discovery/request/availability state.
- Existing TMDb/MDBList/external-list integrations should be reused rather than replaced.

## Existing Moonfin Seerr UI

Current source already contains:

- `lib/ui/screens/seerr/seerr_discover_screen.dart`
- `lib/ui/screens/seerr/seerr_browse_screen.dart`
- `lib/ui/screens/seerr/seerr_collection_screen.dart`
- `lib/ui/screens/seerr/seerr_person_screen.dart`
- `lib/ui/screens/seerr/seerr_requests_screen.dart`
- `lib/data/viewmodels/seerr_discover_view_model.dart`
- `lib/data/viewmodels/seerr_browse_view_model.dart`
- `lib/data/repositories/seerr_repository.dart`
- `lib/data/services/seerr/seerr_http_client.dart`

### Already-working discovery behaviour

`SeerrDiscoverScreen` already has:

- horizontal media rows;
- near-end horizontal pagination via `loadMore`;
- poster/request status integration through existing `MediaCard`;
- genre cards;
- network cards;
- studio cards;
- D-pad row focus logic;
- detail routing through the normal Seerr/Jellyfin resolution path.

`SeerrBrowseScreen` already has:

- responsive full-screen poster grid;
- vertical infinite loading when approaching the end;
- TV/mobile/desktop layouts;
- sorting;
- availability/requested filters;
- alphabetical filtering;
- media-detail routing;
- request-state attachment.

**Gap:** ordinary media rows on the discovery landing page do not yet carry an arbitrary exact filter into this browser. The new shared query contract is intended to close that gap.

## Existing Seerr API surface in Moonfin

Moonfin already exposes repository/client methods for:

- Trending (mixed)
- Trending/popular Movies
- Trending/popular TV
- Top Movies/TV
- Upcoming Movies/TV
- Watchlist
- Movie discovery
- TV discovery
- Search
- Movie/TV detail
- Similar Movies/TV
- Movie/TV recommendations
- Person detail/credits
- Movie/TV genre sliders
- requests/current-user state
- Radarr/Sonarr server settings used by Seerr advanced request options

Current Moonfin `discoverMovies`/`discoverTv` wrappers only forward a subset of what current Seerr accepts. The shared discovery expansion should extend these wrappers, not create a parallel HTTP stack.

## Current Seerr discover filters confirmed from upstream source

Current Seerr `/api/v1/discover/movies` and `/api/v1/discover/tv` parse these useful query fields:

- `page`
- `sortBy`
- `primaryReleaseDateGte`
- `primaryReleaseDateLte`
- `firstAirDateGte`
- `firstAirDateLte`
- `studio`
- `genre`
- `keywords`
- `excludeKeywords`
- `language`
- `withRuntimeGte`
- `withRuntimeLte`
- `voteAverageGte`
- `voteAverageLte`
- `voteCountGte`
- `voteCountLte`
- `network`
- `watchProviders`
- `watchRegion`
- `status`
- `certification`
- `certificationGte`
- `certificationLte`
- `certificationCountry`

This is enough to build much richer lanes than Trending/Popular without a third-party recommendation service.

## Seerr's own custom-slider model

Current Seerr supports admin-customisable discovery sliders including:

- Movie keyword
- TV keyword
- Movie genre
- TV genre
- Studio
- Network
- TMDb search
- Movie streaming service/provider
- TV streaming service/provider

Seerr's UI uses the same discover endpoints for a preview slider and links the slider to a corresponding expanded discover/search page. Moonfin should preserve that key idea while going beyond Seerr's relatively small slider set.

## Request/profile/quality flow is already mature

This is **not** a greenfield workstream.

Current `seerr_request_dialog.dart` already supports:

- normal and 4K tracks;
- a quality-track toggle when the user can request both;
- all-seasons versus selected-season TV requests;
- unavailable/requested-season exclusion;
- request quotas;
- advanced Seerr request overrides;
- saved server/profile/root-folder preferences;
- server ID selection;
- quality profile selection;
- root-folder selection;
- continuation requests.

The new Discovery surfaces should open the same detail/request path. Do not build a separate Discovery-specific quality/profile picker.

### Separate future option: manual release choice

A future "Choose release" function would be genuinely new because it means querying Radarr/Sonarr release-search APIs and grabbing an exact release rather than selecting a Seerr quality profile. It is outside the core endless-discovery requirement and must not delay Discovery v1.

## Existing external-list capability

`CustomExternalListsService` already supports server-proxied custom rows with local cache/fallback and recognises:

- IMDb user lists/events;
- TMDb lists/collections;
- Letterboxd user source configuration;
- MDBList lists.

It also supports list-side sorting by:

- source/default order;
- title;
- year;
- popularity;
- rating;
- shuffle.

The existing service retrieves data through authenticated `/Moonfin/CustomRows/Items`, so external-list discovery can reuse the same server-side credential boundary.

## Existing ratings/metadata support

`MdbListRepository` already uses the Moonfin server proxy for MDBList ratings and caches/negative-caches results. Discovery does not need a second MDBList ratings implementation.

## What is genuinely missing

1. A large, well-organised discovery taxonomy.
2. Server-delivered catalogue/config for that taxonomy.
3. Rich arbitrary Seerr filter forwarding.
4. Dynamic keyword/name resolution where IDs should not be hardcoded into product config.
5. Landing-page lane rotation and session diversity.
6. Cross-lane/session deduplication that does not empty rows.
7. Exact row-to-expanded-query parity for ordinary media lanes.
8. More personalised lane strategies and seed diversity.
9. Deep rabbit-hole navigation as a first-class Discovery interaction.
10. External curated lists exposed as a proper Discovery destination rather than isolated Home custom rows.
11. Shared cross-platform Discovery schema consumption, especially LG webOS.
12. Failure isolation/caching so one bad lane does not block the page.

These are the real targets of this phase.
