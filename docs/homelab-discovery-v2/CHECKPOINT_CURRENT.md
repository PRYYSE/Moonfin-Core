# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-12 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed implementation must not be restarted without current fault evidence.

## Status

**Discovery v2 server cutover PASSED.** Android mobile functional acceptance broadly passed, but physical acceptance found two UI defects plus a weak two-row For You experience. Both repair streams are implemented; workflow #151 is the current replacement-candidate checkpoint. A separate `Family Favourites` lane-semantics defect remains before final mobile sign-off.

## Live server cutover — complete

- `=== CUTOVER PASSED ===`
- `/moonfin-web/current -> releases/fd06ec560235`
- product source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- live compiler source remains `ee00cb3867d9c294bae5759d6d19d5d5bd31dade` until the pending narrow catalogue-quality update
- Web tar SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- served catalogue schema v2 / 481 lanes / SHA-256 `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`
- Moonbase `2.2.0.0` Active; authenticated Moonbase -> Seerr proxy PASS
- rollback `/srv/appdata/moonfin/rollback/server-migration-20260912-015401`
- rollback command `sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

Locked live gate remains 486 authored / 481 compiled / 5 semantic drops / 0 provider drops. Do not lower it for current quality work.

## Android mobile — confirmed functional evidence

The #139 beta candidate proved the live schema-v2 product flow. Tailscale split tunnelling initially excluded `org.moonfin.androidtv.beta`; that local routing problem is resolved.

User reports/checks cover:

- all Discovery tabs;
- session/reopen;
- `See all` + Back;
- owned-Jellyfin detail/playback;
- external Seerr request path;
- orientation/background/reopen;
- normal artwork/status rendering.

## Mobile UI defects — repair implemented

1. **Carousel offset inheritance:** horizontal state now has a unique identity by tab + section + refresh generation. Lazy recycling cannot transplant another lane's offset; explicit refresh gets fresh state.
2. **Discovery/top-toolbar spacing:** top-navigation mobile Discovery now reserves the toolbar height + 8 dp; left/bottom layouts keep normal padding.

Implementation/tests are already on the branch. Do not reopen the root-cause investigation unless the replacement APK still reproduces either defect.

## For You defect — redesign implemented, pending live catalogue update

On-device #139 showed only two usable For You rows with vague labels.

Root cause:

- 16 rows were authored; composer was not capped at 2;
- many depend on optional favourites/watchlist/ratings/likes data;
- personal rows required 8 usable items, hiding valid smaller sets;
- one strategy had no truthful current source and failed closed.

Compiler source **`87390d713c24aba7a30aa66cee98d1c59b027752`** applies a stale-checked reviewed 16-row For You contract while preserving the existing overall catalogue counts.

Key changes:

- explicit movie + series rows from real watch history;
- clearer provenance/outcome names for favourites, watchlist, ratings, likes, mixed taste, novelty, movie/series/anime affinity, quick/older/recent picks and rewatch;
- all 16 strategies are executable by current personalisation adapters;
- `minItems` lowered from 8 to **4** for For You only;
- For You minimum usable-lane contract set to **4**;
- compiler validates the reviewed IDs/titles/strategies/media types and fails if the old authoring assumptions drift.

This is **not live yet**. Apply it only through the planned narrow compiler/catalogue-only server update after CI passes. Preserve the current live catalogue for rollback; require 481/486, 5 semantic drops and 0 provider drops; no Compose/Jellyfin/Moonbase restart.

## Current long CI checkpoint

Previous #150 is superseded by the combined replacement build.

- workflow **#151**
- run **`34668019767`**
- source **`87390d713c24aba7a30aa66cee98d1c59b027752`**
- `[full-build]`
- status when recorded: **in progress**

Do not continuously poll. On next continuation inspect this exact run once.

## Other open recommendation-quality defect

`Lists -> Family Favourites` showed animation-only/non-family results because current authoring uses `genre: "10751|16"` (Family OR Animation). Correct authoritative semantics, not ranking.

## Deferred UX enhancement

After platform acceptance, retain rotating rows and add:

- **All Lists** — searchable/text-first index of every lane grouped by tab, opening existing `See all`;
- **Genres** — stable genre browser independent of lane rotation.

## Exact next action

1. Inspect workflow #151 / `34668019767` once.
2. If green, retrieve/hash its replacement mobile-beta APK.
3. Apply the For You compiler change with a narrow catalogue-only server update; keep rollback and require the locked 481/5/0 gates.
4. Install/update Moonfin Beta and retest only carousel behaviour, header spacing and For You richness/naming.
5. Correct/sanity-check `Family Favourites` semantics.
6. If mobile passes, checkpoint and proceed to LG webOS, then Android TV/Google TV.
7. Implement All Lists + Genres after platform acceptance.
