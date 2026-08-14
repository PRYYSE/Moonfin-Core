# 12 - Reference Project Research

## Purpose

Use maintained upstream projects to identify proven features and API patterns. Do not blindly embed or copy a web-only project into Moonfin's Flutter/Enact clients.

## 1. Current Seerr upstream

### What Seerr already proves

Seerr's own Discover UI demonstrates the core pattern we want:

- preview slider backed by a discover/search query;
- corresponding expanded discover/search route;
- admin-reorderable/enableable sliders;
- custom sliders based on keyword, genre, studio, network, search and streaming provider;
- Trending, Popular, Genres, Upcoming, Studios, Networks, Watchlist/Recent content.

This validates the row -> full filtered screen model.

### Rich current discover filters

Current Seerr server source accepts significantly more filters than Moonfin currently forwards:

- release/air-date ranges;
- studio;
- genre;
- keywords and excluded keywords;
- original language;
- runtime bounds;
- vote-average bounds;
- vote-count bounds;
- network;
- provider/region;
- status;
- certification ranges/country.

**Adopt:** expand Moonfin's repository/client wrappers to the current filter surface.

### What Seerr does not solve for Home Lab

- a truly large rotating taxonomy;
- Home Lab cross-lane/session dedup;
- user-specific Jellyfin history/favourite/rating seed blending;
- native LG/Android TV UI;
- Home Lab Anime taxonomy depth;
- one shared server catalogue for all Moonfin clients.

## 2. SeerrFin

Current SeerrFin describes itself as a way to discover/request Movies and TV directly in Jellyfin and exposes several useful product patterns.

### Relevant features

- Movie and TV discovery tabs;
- category carousels;
- Seerr search integration;
- request modals;
- quality-profile/season selection;
- quality recommendations;
- Requests tab;
- Radarr/Sonarr download progress;
- Letterboxd watchlist sync;
- Letterboxd bulk request;
- display customisation;
- optional native-looking Jellyfin web UI.

Its server controller also exposes normalised discovery rows and a Seerr proxy, reinforcing the value of keeping upstream credentials/server access behind the Jellyfin plugin boundary.

### Useful ideas to adapt

1. **Download progress presentation** - Moonfin already has this in its Requests screen; reuse, do not rebuild.
2. **Letterboxd discovery/list integration** - Moonfin already has external-list plumbing; expose it properly in Discovery.
3. **Quality guidance** - only consider supplemental human-readable recommendations if it adds value beyond Moonfin's existing profile picker. It is not a prerequisite for endless discovery.
4. **Discovery tabs + carousels + expanded grids** - matches the desired UX, but Moonfin can drive it from the shared schema.
5. **Server-side proxying** - reinforces the Moonbase/Jellyfin plugin boundary.

### Do not adopt wholesale

SeerrFin itself states that its main implementation targets Jellyfin Web/web-client contexts and that native clients need their own implementations. Installing it would not produce cross-platform feature parity for Moonfin Flutter, Android TV or the separate LG Enact client.

Therefore:

- no SeerrFin web injection as the Home Lab architecture;
- no dependency on its browser DOM/UI;
- use its behaviour as reference and reuse equivalent existing Moonfin capabilities where present.

## 3. Jellyfin Enhanced

Current Jellyfin Enhanced has a broad Jellyfin Web enhancement suite.

### Relevant Seerr/discovery ideas

- Seerr search/request integration;
- recommendations/similar items on detail pages;
- discovery by genre/network/person/tag;
- issue reporting;
- watchlist sync;
- Requests page;
- *arr integration/quick links/calendar concepts;
- availability/Elsewhere information;
- quality tags;
- genre/language/rating metadata tags;
- richer people metadata.

### Useful ideas to adapt

1. Treat detail pages as discovery hubs, not dead ends.
2. Make person/network/tag navigation first-class rabbit holes.
3. Keep request/issues/progress accessible from discovery detail.
4. Consider richer focused-card/detail metadata without overcrowding poster rails.
5. Consider a later release/calendar/upcoming view using existing Seerr/*arr data.

### Do not adopt wholesale

Its compatibility model is also web/embedded-web focused; native Android TV and third-party clients do not receive the full injected UI. Moonfin still needs shared Flutter/native and LG implementations.

## 4. Base Moonfin is already ahead in several areas

Do not regress by replacing current Moonfin functionality with plugin equivalents.

Moonfin already has:

- Seerr detail routing;
- request/quality/season/server/profile/root-folder selection;
- request quotas;
- request management and issues;
- download progress UI;
- local Jellyfin resolution;
- similar/recommendation repository calls;
- person and collection screens;
- MDBList ratings proxy;
- external custom-list service and local cache;
- TV/D-pad-aware components in Flutter.

The Discovery project should connect these pieces coherently.

## 5. Feature adoption matrix

| Feature | Source inspiration | Home Lab action |
|---|---|---|
| Row -> full filtered browse | Seerr | implement through shared query identity |
| Rich filter surface | Seerr API | expose in Moonfin repository + browse UI |
| Custom keyword/genre/studio/network/provider lanes | Seerr | expand dramatically through server catalogue |
| Request profile/season controls | Base Moonfin / SeerrFin reference | already exists; reuse |
| Download progress | Base Moonfin / SeerrFin reference | already exists; surface state consistently |
| Letterboxd lists | Base Moonfin / SeerrFin reference | expose current server list service in Discovery |
| Similar/recommendations | Base Moonfin / Enhanced reference | make first-class rabbit holes |
| Person/network/tag discovery | Enhanced/Seerr | deepen current routes |
| External availability/provider lenses | Seerr/Enhanced | discovery filter, AU region, informational only |
| Server-side Seerr proxy | current Moonfin + SeerrFin pattern | preserve/extend |
| Huge rotating taxonomy | Home Lab-specific | build new |
| Cross-session dedup/novelty | Home Lab-specific | build new |
| Native LG/Android TV parity | Home Lab-specific | build new shared-schema consumers |

## 6. Research items still worth revisiting during implementation

- exact current Seerr status values/semantics before using `status` in authored lanes;
- current provider-list endpoint/region payload before compiling AU provider lanes;
- reliability of TMDb company metadata for Anime studios;
- keyword search ambiguity for Anime themes;
- best way to batch/bound local Jellyfin resolution for large expanded pages;
- whether Moonbase source is available in a maintainable repo or must be patched from the ServerBox build source for the catalogue endpoint.

These are implementation questions, not blockers for the content/UX architecture.
