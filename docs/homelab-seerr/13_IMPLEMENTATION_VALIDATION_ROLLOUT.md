# 13 - Implementation, Validation and Rollout

## Branch safety

Active work branch:

`homelab/seerr-discovery-v1-staging`

Base was the accepted Android product commit `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`.

Do not deploy this branch directly to live Web/Android/LG. It contains incomplete Discovery foundation work until the gates below pass.

## Current staging foundation

Already added before this workstream split:

- serialisable `SeerrDiscoveryCatalogue/Tab/Section/Query` schema;
- first small fallback catalogue;
- session dedup helper;
- safe filter allow-list/date-token resolver;
- focused tests for schema/query identity/dedup/date filters.

The small fallback catalogue is now explicitly treated as a recovery scaffold rather than the full content target.

## Implementation order

### Phase A - document/audit and schema v2

1. Finish the numbered workstream docs.
2. Extend schema with composition metadata:
   - pool;
   - priority/anchor;
   - rotation weight;
   - cooldown;
   - minimum usable items;
   - availability mode;
   - activation/season rules;
   - optional semantic keyword/provider resolution metadata.
3. Extend schema tests/round-trip validation.

### Phase B - rich Seerr query execution

1. Expand `seerr_http_client.dart` discover methods to forward the current safe filter surface.
2. Expand `seerr_repository.dart` wrappers.
3. Add a generic discovery-query executor mapping `SeerrDiscoverySource` -> existing repository methods.
4. Resolve dynamic dates before request.
5. Do not forward unknown filters.
6. Tests for Movie/TV query construction.

### Phase C - expanded browse parity

1. Generalise `SeerrBrowseViewModel` to accept `SeerrDiscoveryQuery` rather than only `filterId/filterType`.
2. Preserve existing genre/network/studio routes through compatibility adapters.
3. Add arbitrary filter query route decoding.
4. Make every eligible Discovery media lane expose `See All`.
5. Test preview query key == expanded base query key.
6. Keep existing infinite-grid pagination.

### Phase D - availability/local-state behaviour

1. Replace global `isAvailable` exclusion in general discovery with lane `availabilityMode`.
2. Preserve explicit blocklist/NSFW rules.
3. Attach local/request/download state consistently.
4. Validate local item routes locally and requestable item routes through Seerr.

### Phase E - session composition/rotation

1. Implement anchor + weighted rotating pool selection.
2. Add stable session seed and explicit refresh nonce.
3. Add lane cooldown history.
4. Use existing/new dedup session for previews.
5. Ensure expanded views are not cross-lane-deduped.
6. Add lane budget per tab/device class.

### Phase F - personalisation

1. Reuse accepted seed sources.
2. Add multi-seed round-robin mixing.
3. Add Because You Watched dynamic lanes.
4. Add Watchlist/Favourites/Rating/Novelty strategies.
5. Keep cold-start fallback.
6. Add media-type/Anime-aware diversity.

### Phase G - server-delivered catalogue

1. Locate/prepare maintainable Moonbase server source.
2. Add versioned Discovery catalogue endpoint or equivalent server-owned delivery path.
3. Add compiler/validation/last-known-good storage.
4. Add keyword resolver and AU provider resolver.
5. Keep built-in client fallback.
6. Prove a server-only lane change propagates to supported clients.

### Phase H - external lists

1. Reuse `CustomExternalListsService`/server endpoint.
2. Add list sections to shared catalogue.
3. Add expanded list window/pagination behaviour.
4. Validate local/Seerr routing for list items.
5. Add initial Home Lab curated Movie/Series/Anime list set.

### Phase I - Flutter product UI

One shared implementation can cover Web + Android phone/tablet + Android TV content model, but layouts/focus need separate acceptance:

1. Discovery tab shell.
2. landing lanes + category indexes.
3. See All affordance.
4. richer filter sheet.
5. refresh/recomposition.
6. rabbit-hole navigation.
7. phone/tablet responsive pass.
8. Android TV ten-foot/focus pass.

### Phase J - LG webOS port

1. Add shared catalogue fetch/parser to Smart-TV.
2. Add session composition compatible with server schema.
3. Add Enact/Spotlight lane and expanded-grid UI.
4. Reuse current local-first/Seerr-fallback routing.
5. Validate memory/focus with constrained mounted lane count.

## Test layers

### Pure/unit tests

- schema round trip;
- catalogue validation;
- dynamic dates;
- keyword resolver exact/ambiguous behaviour;
- provider resolver region behaviour;
- rotation determinism by seed;
- refresh changes optional selection;
- cooldown;
- dedup fallback retains useful row size;
- availability mode;
- query allow-list;
- Movie/TV filter mapping.

### Integration tests

Against configured Home Lab services without printing secrets:

- Seerr Movie discover filters;
- Seerr TV discover filters;
- multi-page pagination;
- Movie/TV/Anime classification samples;
- request status overlay;
- local Jellyfin resolution;
- external list fetch/cache;
- server catalogue endpoint;
- keyword/provider resolution.

### Product/runtime gate

For each top-level tab:

- anchors load;
- minimum useful rotating-lane count loads;
- refresh changes optional lanes;
- no severe adjacent duplication;
- See All query matches preview;
- at least five pages load on a deep lane;
- one lane failure does not block page;
- local/requestable/requested/downloading states route correctly.

### Physical platform gates

Web:
- mouse/keyboard/scroll/hover and browser responsiveness.

Android phone/tablet:
- touch, orientation, bottom nav, filter sheets, in-place update signed with existing durable key.

Android TV:
- launcher/banner, D-pad, focus restore, remote request flow, playback/return.

LG:
- Magic Remote/D-pad, Spotlight focus, memory/performance, local/Seerr routing, playback/return.

## Build discipline

- implement/test shared core before producing multiple platform builds;
- do not build after every small Dart edit;
- run `flutter pub get` before formatter/analyser when cache may be incomplete;
- respect Docker VM memory constraints and existing Android build procedure;
- never regenerate Android signing identity;
- never overwrite LG known-good rollback release;
- use separate candidate artefacts until physical acceptance.

## Promotion order for Discovery

Recommended once shared core is stable:

1. Web staging/runtime validation - fastest feedback.
2. Android phone/tablet candidate - reuse accepted signing/deployment path.
3. Android TV candidate - dedicated TV gate.
4. LG webOS candidate - separate repo/Enact implementation.
5. Cross-client parity check.
6. Promote exact validated artefacts/commits, not rebuilds that merely claim to be equivalent.

## Do not redo

- accepted Web redesign;
- accepted Android baseline/signing;
- existing Seerr request/profile/season controls;
- existing Requests/issues/download-progress screens;
- existing Jellyfin local routing;
- existing 33 Moonbase Home/destination editorial rows;
- existing external-list and MDBList rating foundations.

## Definition of done

The Seerr phase is complete only when:

- the server catalogue is materially larger than what any one session displays;
- Movie/Series/Anime each have deep varied content pools;
- visible lanes rotate without chaos;
- every eligible lane expands into its full filtered collection;
- personalised lanes use real user data with good cold start;
- local/request/status routing is consistent;
- external lists are integrated;
- one failing lane/source does not break Discovery;
- Web, Android, Android TV and LG all consume the same content semantics and pass their platform interaction gates.
