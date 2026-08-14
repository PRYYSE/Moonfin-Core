# 07 - Browse, Filters, Search and Rabbit Holes

## Goal

The landing page creates routes into discovery. The expanded browser is what makes each route deep enough to explore for a long time.

Moonfin already has `SeerrBrowseScreen` with grid pagination, basic sorting, availability/requested filtering and alphabetical filtering. Extend that screen and its view model rather than creating another browser.

## Row -> expanded collection

Every deterministic media lane should expose `See All`/title activation.

The navigation payload must contain the **same `SeerrDiscoveryQuery` identity** used by the preview lane:

- source;
- media type;
- sort;
- all base filters;
- list provider/list ID where applicable;
- personal seed strategy/seed ID for generated rows.

The expanded screen can add user-selected refinements, but it must never silently discard the row's base filter.

## Expanded screen header

Show:

- lane title;
- optional short explanation/subtitle;
- result count when trustworthy;
- active filter chips;
- sort button;
- filter button;
- refresh/retry state where needed.

On TV, avoid a dense desktop toolbar. Use a focusable header/filter sheet and return focus to the previously focused poster.

## Pagination

Use page-based Seerr/TMDb fetching with:

- initial page 1;
- near-end prefetch;
- duplicate-ID suppression between pages;
- `currentPage/totalPages` state;
- bounded read-ahead when local/request/letter filtering rejects most of a page;
- no arbitrary first-page-only cap for expanded collections.

Current `SeerrBrowseViewModel` already reads ahead up to several pages for filtered results. Generalise this behaviour for the new base query.

## Base filter versus user refinements

Example:

Base lane: **Hidden Gems**

- rating >= 7.0
- votes 150-1500

User refinement:

- Horror
- 2010-2026
- runtime < 120 min

Final query keeps the Hidden Gems constraints and adds the user's Horror/date/runtime constraints.

The UI should provide `Reset refinements`, not `Reset base lane`.

## Rich filter sheet

### Universal

- availability: All / Available / Requested / Requestable where state permits;
- sort;
- release/first-air year range;
- rating range;
- minimum vote count;
- runtime range;
- genre selection;
- original language;
- hide watched / only unwatched when Jellyfin overlay data exists;
- local-only / not-in-library where useful.

### Movies

- studio;
- certification/rating;
- streaming provider + AU region;
- upcoming/released date controls.

### Series

- network;
- status once Seerr/TMDb status semantics are validated;
- streaming provider + AU region;
- first-air date controls.

### Anime

- Anime classification stays locked as a base condition;
- Anime theme/tag filters;
- seasonal/date window;
- TV versus Movie Anime selection where the base lane allows both;
- explicit-content safety remains active unless a future explicit user setting says otherwise.

## Genre/Network/Studio indexes

The landing page can rotate genre/network/studio lanes, but users also need deterministic category indexes:

- All Movie Genres
- All Series Genres
- Movie Studios
- Series Networks
- Providers/Streaming Services
- Languages/Regions
- Anime Themes
- Eras/Decades

These indexes are navigation surfaces, not hundreds of simultaneous poster lanes.

## Search

### Unified search behaviour

Existing Moonfin/Jellyfin search should continue to find local items. Seerr search can add requestable/unowned media as it already does where integrated.

Inside Discovery, search should additionally support:

- title/media search;
- person search;
- keyword/tag search;
- studio/network lookup;
- external curated list search later.

### Search-to-rabbit-hole

Search results should not be dead ends. From a result the user can open:

- detail;
- person/credits;
- similar;
- recommendations;
- collection/franchise;
- genre;
- studio/network;
- tag/keyword where exposed.

## Detail-page rabbit holes

Moonfin already has Seerr detail routing and repository methods for:

- Similar Movies/TV;
- Movie/TV recommendations;
- person details/combined credits;
- collection screens.

Discovery should surface these deliberately.

### Proposed detail sections

- More Like This
- Recommended Because You Viewed This
- Part of the Collection
- Cast & Crew
- More From <person>
- From <studio/network>
- Explore <genre>
- Related tags/themes where reliable

Selecting `More Like This` can either horizontally browse on detail or open the full expanded collection.

## Person rabbit holes

Person screen should support:

- known-for/combined credits;
- Movie versus Series filters;
- sort by popularity/date/rating where possible;
- request/local status overlays;
- opening any credit into normal detail.

## Collection/franchise rabbit holes

For TMDb collections:

- ordered collection items;
- local/request state;
- open/request individual entries;
- related/similar discovery after the collection list.

## Context persistence

When returning from detail:

- expanded grid scroll offset restores;
- focused item restores on D-pad platforms;
- landing page lane position and focused poster restore;
- session rotation must not recompose just because the user opened/closed a detail page.

A manual refresh/new session can recompose lanes; normal back navigation cannot.

## Failure handling

- failed next page -> inline retry at end, preserve loaded items;
- failed optional metadata/rabbit-hole section -> hide that section only;
- failed base query -> retry state for that expanded screen;
- request state lookup failure -> still display media, but do not falsely label ownership;
- never route an unowned Seerr item directly to Jellyfin playback.

## Acceptance gates

1. Tap/click/activate `See All` from a lane and compare preview query key to expanded base query key: identical.
2. Load at least five pages on a large lane and verify no page-boundary duplicates.
3. Add/remove user refinements without losing the base lane constraints.
4. Open detail -> similar -> another detail -> back repeatedly and preserve useful focus/scroll state.
5. Person and collection rabbit holes work without leaving the Moonfin ownership/request model.
6. One failed metadata section does not break the detail screen.
7. TV filter UI is fully D-pad reachable and escapable.
