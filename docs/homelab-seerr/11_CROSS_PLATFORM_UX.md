# 11 - Cross-Platform Discovery UX

## Shared content, platform-specific interaction

All clients should consume the same Discovery catalogue/query semantics. They do **not** need pixel-identical layouts.

- Web desktop: Flutter Moonfin-Core.
- Android phone/tablet: Flutter Moonfin-Core.
- Android TV: Flutter Moonfin-Core, dedicated TV release/layout rules.
- LG webOS: separate React/Enact Smart-TV repository.

## Shared product structure

Top-level Discovery destinations:

- For You
- Movies
- Series
- Anime
- New & Upcoming
- Lists

Optional category-index entries inside tabs:

- Genres
- Themes/Tags
- Studios
- Networks
- Providers
- Languages
- Eras

A client may represent tabs as top navigation, chips, side navigation or focusable TV tabs depending on space/input.

## Shared lane anatomy

Each lane can provide:

- title;
- optional subtitle;
- poster/landscape card rail;
- status badges;
- `See All`/expand action;
- loading/error skeleton/state;
- optional refresh for generated/context lane.

The exact query is content state, not UI state.

## Web desktop

### Interaction

- left navigation remains consistent with accepted Home Lab web design;
- mouse wheel/trackpad vertical tab scrolling;
- horizontal row mouse wheel/drag/buttons where current components support it;
- lane title + visible `See All` affordance;
- hover/focus can update backdrop/info panel;
- filter controls can use a full toolbar/dialog.

### Performance

- lazy mount rows below viewport;
- image caching/current card sizing reused;
- do not preload 20 pages per lane;
- hover must not trigger uncached per-card API storms.

## Android phone/tablet

### Interaction

- touch-first;
- horizontal swipe rails;
- `See All` via title/chevron/text button with sufficiently large touch target;
- full-screen expanded grid;
- filter/sort in bottom sheet or adaptive dialog;
- pull-to-refresh can recompose current tab/session where appropriate;
- maintain existing bottom-navigation behaviour.

### Tablet

- more columns/larger landscape use;
- can expose more filter controls inline but should stay the same navigation model.

## Android TV

Android TV must not be treated as the phone UI at larger scale.

### Focus rules

- deterministic initial focus;
- D-pad left/right within a lane;
- up/down moves between corresponding/nearby card positions where current locked-row behaviour supports it;
- Back from content returns to useful parent focus;
- returning from detail restores the exact lane/item where possible;
- header tabs/filter controls are reachable and escapable;
- no focus trap in infinite grid/footer loader.

### See All

Prefer either:

- a dedicated focusable `See All` card at the end of a lane; or
- a reachable title/header action with predictable Up navigation.

Do not make a tiny text link the only TV expansion control.

### Mount budget

- anchors + selected rotating lanes only;
- cap mounted vertical lanes;
- unload/lazy-build far-off lanes if safe;
- expanded screen uses virtualised grid/slivers;
- no infinite vertical row generator on TV landing page.

### Filtering

Use a full-screen or large TV-friendly filter panel with simple D-pad groups. Preserve base filter and return focus to the triggering control.

## LG webOS

LG is a separate Enact app and must consume the shared schema explicitly.

### Existing foundation to preserve

Current LG Home Lab candidate already:

- decodes Moonbase dynamic rows;
- resolves local Jellyfin items before Seerr fallback;
- preserves request/ownership routing;
- uses existing playback and D-pad navigation.

Discovery expansion should build on that rather than embedding Flutter or a Seerr website.

### Enact/Spotlight rules

- each horizontal lane has stable Spotlight containers/IDs;
- focus restoration keyed by tab + section ID + media ID/index;
- dynamic rotation must not reorder sections while user is actively navigating the tab;
- `See All` is spottable;
- expanded grid uses bounded rendering/pagination;
- loading/removal of a failed optional lane must not cause focus to jump unpredictably;
- Magic Remote pointer interaction can coexist, but D-pad remains the acceptance baseline.

### Performance

LG TV resources are more constrained than desktop/phone:

- lower initial lane concurrency;
- stricter mounted lane/card budgets;
- lower backdrop/image prefetch;
- no expensive per-focus fetch unless cached/debounced;
- use server-normalised catalogue/query data so the TV does minimal transformation.

## Back/return contract

Across all clients:

Landing tab -> expanded lane -> detail -> rabbit hole/detail -> Back should unwind without losing the underlying session composition.

Store navigation context using stable IDs, not only list indexes:

- tab ID;
- section ID;
- media identity;
- expanded query key;
- scroll position/page state.

If an item disappears due to refresh after a long return, fall back to nearest valid item in the same section rather than jumping to top/home.

## Loading behaviour

### Landing

- anchors skeleton/load first;
- optional lanes fill progressively;
- failed optional lane collapses cleanly;
- no whole-page spinner waiting for 20 lanes.

### Expanded

- initial grid spinner/skeleton;
- next-page footer loader;
- retry next page without clearing loaded cards.

## Status UI

Reuse consistent state colours/icons/text across platforms for:

- available;
- requested;
- processing/downloading;
- partial;
- failed;
- requestable.

Cards should not become visually overloaded. Rich state/progress belongs in focused info/detail/request screens.

## Accessibility/input

- respect reduced motion where current app does;
- touch targets remain large enough on mobile;
- keyboard works on web/desktop where existing focus system supports it;
- TV focus ring remains visible with selected theme;
- text labels are not replaced entirely by ambiguous icons for important actions.

## Cross-platform acceptance matrix

For each of Web, Android, Android TV and LG:

1. open every top-level Discovery tab;
2. verify at least anchor + rotating lanes;
3. expand a Movie, Series and Anime lane;
4. paginate several pages;
5. open local item and return;
6. open requestable item and existing request flow;
7. open requested/downloading item and state/progress path;
8. open similar/person/collection rabbit hole and return;
9. trigger refresh/recomposition and confirm no crash/focus corruption;
10. simulate one failed optional lane;
11. verify client uses server catalogue and fallback behaviour.
