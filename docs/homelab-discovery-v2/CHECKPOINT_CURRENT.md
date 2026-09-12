# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-12 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed implementation must not be restarted without current fault evidence.

## Status

Discovery v2 server cutover is complete. Android mobile functional acceptance broadly passed; two UI defects and the weak For You experience have repairs implemented. The active long-CI checkpoint is now workflow #152 after #151 failed only because one test file was not `dart format`-clean. `Family Favourites` semantics still need correction before final mobile sign-off.

## Live server — accepted

- `/moonfin-web/current -> releases/fd06ec560235`
- product source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- live compiler source still `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`
- served catalogue: schema v2 / 481 lanes / SHA-256 `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`
- Moonbase `2.2.0.0` Active; Moonbase -> Seerr proxy PASS
- rollback `/srv/appdata/moonfin/rollback/server-migration-20260912-015401`
- rollback command `sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

Locked catalogue gate remains **486 authored / 481 compiled / 5 semantic drops / 0 provider drops**.

## Mobile repair — implemented

- carousel state identity = tab + section + refresh generation;
- explicit refresh gets fresh horizontal state;
- mobile top-navigation Discovery reserves toolbar height + 8 dp;
- focused regression tests exist.

Do not reopen these root causes unless the replacement APK still reproduces them.

## For You redesign — implemented, not live

Compiler commit `87390d713c24aba7a30aa66cee98d1c59b027752` adds the reviewed 16-row For You contract.

- separate movie and series recommendations from real recent watch history;
- clearer optional-source rows for favourites/watchlist/ratings/likes;
- useful affinity/novelty/rewatch/quick/older/recent rows;
- all 16 strategies executable by current adapters;
- For You `minItems=4`, tab minimum 4;
- stale checks prevent silently applying the override if authoring assumptions drift.

Deploy only through a narrow catalogue-only update after CI validation. Preserve the current live catalogue and require the unchanged 481/5/0 gate. No Compose/Jellyfin/Moonbase changes.

## CI evidence

### #151 / `34668019767`

Source `87390d713c24aba7a30aa66cee98d1c59b027752`.

Result: **FAILURE at Format gate only**.

Before the failure:
- route integration PASS;
- generator PASS with 486 total lanes and For You 16;
- catalogue tests **9/9 PASS**.

`dart format` changed only the line wrapping of one test in `test/homelab_discovery/homelab_discovery_mobile_test.dart`; later analyse/test/build jobs were skipped. The exact formatter output was committed with no semantic change.

### Current long-CI checkpoint — #152

- source **`145678fae77feb733975ffbafe62a6ae2b6ec2cb`**
- workflow **#152**
- run ID **`34672828217`**
- event push / `[full-build]`
- status when recorded: **queued**

Do not continuously poll. On continuation inspect this exact run once.

## Other open quality issue

`Lists -> Family Favourites` currently uses `genre: "10751|16"`, so Animation alone can qualify. Correct the authoritative generator semantics before final mobile sign-off.

## Deferred enhancement

After platform acceptance: add **All Lists** and **Genres** browsing while retaining rotating landing rows.

## Exact next action

1. Inspect #152 / `34672828217` exactly once.
2. If green, retrieve/hash its mobile-beta APK.
3. Perform one narrow catalogue-quality deployment on `docker01`: reviewed For You + corrected Family Favourites, rollback copy, locked 481/5/0 gate, no Jellyfin/Compose/Moonbase changes.
4. Update Moonfin Beta side-by-side and retest only carousel behaviour, header spacing, For You richness/naming and Family Favourites content.
5. If mobile passes, checkpoint and proceed to LG webOS, then Android TV/Google TV.
