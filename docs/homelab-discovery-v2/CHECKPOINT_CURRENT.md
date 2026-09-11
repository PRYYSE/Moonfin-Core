# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-12 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed implementation must not be restarted without current fault evidence.

## Status

**Discovery v2 server cutover PASSED.** Android mobile functional acceptance has broadly passed, but two physical UI defects were found and a corrected mobile candidate is building. A separate `Family Favourites` lane-semantics defect remains to fix before final mobile sign-off.

## Live server cutover — complete

- `=== CUTOVER PASSED ===`
- `/moonfin-web/current -> releases/fd06ec560235`
- product source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- semantic compiler source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`
- Web tar SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- served catalogue schema v2 / 481 lanes / SHA-256 `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`
- Moonbase `2.2.0.0` Active; authenticated Moonbase -> Seerr proxy PASS
- rollback `/srv/appdata/moonfin/rollback/server-migration-20260912-015401`
- rollback command `sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

Locked catalogue baseline: 486 authored / 481 compiled / 5 semantic drops / 0 provider drops. Workflow #145 / `34598425336` GREEN.

## Android mobile acceptance — current evidence

The #139 beta candidate proved the live schema-v2 product flow. Initial connection failure was only Tailscale split tunnelling excluding `org.moonfin.androidtv.beta` and is resolved.

User reports the requested functional slice is working. Screenshots and manual checks cover:

- all Discovery tabs: For You, Movies, Series, Anime, New & Upcoming, Lists;
- personalised/rotating rows;
- session/reopen behaviour;
- `See all` + Back;
- owned-Jellyfin detail/playback;
- external Seerr request path;
- orientation/background/reopen;
- normal artwork/status rendering.

## Physical UI defects — repair implemented

### 1. Carousel offset inheritance

Observed rows can appear/jump at a later horizontal position. Non-TV landing carousels previously had no unique PageStorage identity, so lazy row recycling/rotation could reuse another lane's offset.

Repair: horizontal state is now isolated by **tab + section + refresh generation**. The same lane may retain its position during ordinary rebuild/vertical recycling; explicit refresh gets a fresh scroll identity and starts refreshed content from the beginning.

### 2. Discovery/top-toolbar spacing

The Discovery title occupied the same visual band as the fixed mobile top toolbar/back control. The page now reserves the top-toolbar height plus **8 dp** only when mobile navigation is positioned at the top; bottom/left layouts retain normal page padding.

Relevant commits:

- `62b5851c715e16d404aa7d59d8efbb44853bd589`
- `bdcf16d985172dd631559a4027380d00c5a64e54`
- `1d16eb8885ded0de9fd886a73823cdd3cee7c389`
- tests `63925bd4e42f6546fb599a94202e4c63a9ef8112`
- full-build trigger `d736adf2565bb3a82fdce661d72fc4296c9f89c9`

### Long CI checkpoint

Workflow #150 / run **`34627434968`**, source **`d736adf2565bb3a82fdce661d72fc4296c9f89c9`**, was pending when recorded. Do not continuously poll it. On continuation inspect this exact run once. If green, extract/hash the new mobile-beta APK and retest only the repaired UI behaviours.

## Recommendation-quality defect still open

`Lists -> Family Favourites` showed animation-only/non-family results because the authoritative generator uses `genre: "10751|16"` (Family OR Animation). Fix the authoritative row semantics and narrowly recompile/deploy after the UI candidate is validated; do not apply synthetic ranking workarounds.

## Deferred UX enhancement

After platform acceptance, retain rotating rows and add:

- **All Lists** — searchable/text-first index of every lane grouped by tab, opening the existing `See all` route;
- **Genres** — stable genre browser independent of lane rotation.

## Exact next action

1. Inspect workflow #150 / `34627434968` exactly once on continuation.
2. If green, retrieve the new mobile-beta artifact and exact SHA; update/install Moonfin Beta side-by-side.
3. Retest only carousel start/retention/refresh-reset and Discovery header spacing in portrait/landscape.
4. Then fix/recompile/deploy `Family Favourites` semantics and sanity-check that row.
5. If mobile passes, checkpoint and proceed to LG OLED65C6PSA/webOS, then Android TV/Google TV.
6. Implement All Lists + Genres after platform acceptance.
