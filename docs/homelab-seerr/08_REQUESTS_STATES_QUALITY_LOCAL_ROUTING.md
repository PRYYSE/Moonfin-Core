# 08 - Requests, Quality, States and Local Routing

## Main decision

**Do not redesign Moonfin's request/profile/quality system for Discovery.** Reuse the existing Seerr detail and request widgets from every new discovery surface.

## Existing request capability to preserve

Current `seerr_request_dialog.dart` already provides:

- HD/normal versus 4K track selection where permitted;
- TV all-seasons request;
- selected-season request;
- unavailable/already-requested season disabling;
- advanced request options;
- Seerr server selection;
- quality profile selection;
- root-folder selection;
- saved preferences per track;
- Movie/TV request quota display and blocking;
- continuing-series request handling.

This is already the quality/profile experience the Discovery project needs.

## Existing request-management capability

Current Requests UI already includes:

- All / Pending / Approved / Processing / Available / Failed filters;
- request pagination;
- approval/decline/retry management when permitted;
- issues tab;
- download progress support through `seerr_download_progress.dart` and `SeerrDownloadProgressBar`;
- detail navigation back into the same media detail path.

Do not build a parallel Discovery request queue.

## Discovery state model

Every poster/item should resolve a consistent user-facing state:

1. **Available locally** - Jellyfin item is resolvable/playable.
2. **Requested** - Seerr has a pending/approved request.
3. **Processing/downloading** - request is active and *arr/download progress is available.
4. **Partially available** - TV seasons/4K track has partial state.
5. **Requestable** - no local/request ownership and user has request permission.
6. **Unavailable/not requestable** - user lacks permission, title blocked or no viable request path.
7. **Failed** - request exists in a failed state when Seerr exposes it.

The UI can use existing Seerr status widgets rather than inventing a second badge system.

## Important change from request-oriented Discovery

Current `SeerrDiscoverViewModel._filterItems` removes items that are already available locally. That is appropriate for a request-only discovery page but wrong for the new deep-discovery product.

### New policy

Availability behaviour becomes **lane-specific**:

- general discovery lane: show available + requestable + requested items, with clear state;
- `Find Something New` lane: optionally exclude local/watched items;
- `Available to Watch Now` lane: local/available only;
- `Request Something New` lane: requestable only;
- `Your Requests` lane: requested/processing only;
- `Rewatch` lane: local watched/favourite items only.

Add a schema property equivalent to `availabilityMode` rather than globally filtering available content.

Suggested values:

- `all`
- `requestable`
- `available`
- `requested`
- `notOwned`
- `unwatched`

The exact implementation may combine upstream Seerr status with Jellyfin resolution.

## Local resolution

When a discovery result has a TMDb ID:

1. attempt existing local Jellyfin resolution;
2. if a local item exists, detail/playback routes locally;
3. otherwise remain a Seerr/TMDb detail item;
4. request action uses existing Seerr request dialog;
5. if a request later becomes available, refresh state and local resolution normally.

Do not duplicate the media in the UI as separate local and Seerr cards.

## Movie request flow from Discovery

Discovery poster -> detail -> existing request action -> existing `SeerrRequestDialog` -> existing server/profile/root-folder choice -> submit -> same detail/status updates.

No new profile picker is required.

## TV/Anime request flow from Discovery

Discovery poster -> detail -> select all seasons or one/more seasons using the existing request sheet -> choose existing advanced server/profile/root-folder option when permission allows -> submit.

Anime uses the same Sonarr/Seerr request machinery. Anime-specific quality profiles already configured in Sonarr/Recyclarr/Seerr should appear through the existing profile list; Discovery should not hardcode quality-profile names.

## Download progress

Discovery cards do not need live progress on every poster by default because that would create excessive polling and visual noise.

Recommended presentation:

- poster state: compact Requested/Downloading/Available badge;
- detail screen: richer progress when available;
- Requests screen: full existing download progress;
- optional focused-card progress on TV/desktop only if data is already cached.

## Permissions

Respect current Seerr user permissions for:

- request Movie;
- request TV;
- request 4K;
- advanced request options;
- approval/manage requests;
- recently added visibility;
- quotas.

A discovery lane can remain visible even when the user cannot request, but the action state must be correct.

## Manual exact-release selection - separate future work

This is not the same as choosing an existing Seerr quality profile.

A future `Choose Release` feature would:

- perform Radarr/Sonarr interactive release search;
- present exact releases/custom-format scores/rejection reasons;
- grab one selected release;
- keep *arr API credentials server-side;
- respect the short-lived *arr release search cache.

It should be its own later workstream after endless Discovery v1, unless the user explicitly brings it forward.

## Acceptance gates

1. Existing Movie request flow opens unchanged from a new discovery item.
2. Existing TV/Anime season/profile selection opens unchanged.
3. Available local item opens Jellyfin playback/detail rather than a request-only dead end.
4. Requested/downloading item shows state and can open request detail/progress.
5. General discovery no longer silently removes all locally available titles.
6. Request-only lanes can deliberately exclude local items.
7. No client stores new Radarr/Sonarr credentials.
8. Permission/quota failures are shown through existing request logic, not duplicated checks.
