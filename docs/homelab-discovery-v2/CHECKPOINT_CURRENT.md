# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-12 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed implementation must not be restarted without current fault evidence.

## Status

Discovery v2 server cutover is complete. Android mobile functional acceptance broadly passed. The carousel/header fixes plus For You redesign are now validated by **GREEN workflow #152**. The immediate next action is a bounded For You catalogue-only deployment, followed by physical retest with the exact #152 mobile APK. `Family Favourites` remains a separate quality fix after that retest.

## Live server — accepted

- `/moonfin-web/current -> releases/fd06ec560235`
- product source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- live compiler source still `ee00cb3867d9c294bae5759d6d19d5d5bd31dade` until catalogue-only update
- served catalogue: schema v2 / 481 lanes / SHA-256 `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`
- Moonbase `2.2.0.0` Active; Moonbase -> Seerr proxy PASS
- rollback `/srv/appdata/moonfin/rollback/server-migration-20260912-015401`
- rollback command `sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

Locked catalogue gate remains **486 authored / 481 compiled / 5 semantic drops / 0 provider drops**.

## Mobile repair candidate — GREEN

Workflow **#152**, run **`34672828217`**, source **`145678fae77feb733975ffbafe62a6ae2b6ec2cb`** completed **SUCCESS**.

All focused-validation and build jobs passed, including route, catalogue tests, format, analyse, Flutter tests, Web interaction tests, scope, Web/mobile/TV builds, Android identity/signing and packaging.

Artefact `10291880971`:
- outer SHA-256 `a3184852ea3a272b2209c50055db31c9ffb8ad203477de77224cb6daa83f8320`
- mobile APK `Moonfin_HomeLab_Android_145678fae77f.apk` SHA-256 **`dfb867820940456122bdeb7b2c193a7e75cec1e0d5877ad22786e09cf7509413`**
- Android-TV APK SHA-256 `b3edb2445e076ff8af41046bce7bc4e68a095532b0efc68b58750a2efb85446a`
- Web tar SHA-256 `5265cc22af6b87f1bdbd698966bddd60fa4d6e2a09cb95a385724611375d5f67`

## For You redesign — validated, not live

Compiler change first landed at `87390d713c24aba7a30aa66cee98d1c59b027752` and is included in #152 source.

- 16 reviewed executable rows;
- separate movie/series recommendations from recent history;
- clearer source/outcome naming;
- optional favourites/watchlist/ratings/likes still fail closed when empty;
- For You `minItems=4`; tab minimum 4;
- stale checks prevent silently applying the contract after authoring drift.

Deploy only with the exact live compiler source from `145678fae77feb733975ffbafe62a6ae2b6ec2cb`, first to staging paths. Require exact 481/486, 5 semantic drops, 0 provider drops and the expected tab counts before install. Preserve current canonical/served files for rollback. **No Compose edit, Jellyfin restart or Moonbase change.**

## Other open quality issue — keep separate

`Lists -> Family Favourites` currently uses `genre: "10751|16"`, so Animation alone can qualify. Correct the authoritative generator separately after the green candidate's For You/mobile UI retest; likely semantics should be Family-only rather than OR Animation, but validate before deployment.

## Deferred enhancement

After platform acceptance: add **All Lists** and **Genres** browsing while retaining rotating landing rows.

## Exact next action

1. Run the bounded For You catalogue-only deployment on `docker01` from source `145678fae77feb733975ffbafe62a6ae2b6ec2cb`.
2. Install/update the exact #152 mobile-beta APK and retest carousel state, Discovery header spacing, and For You richness/naming only.
3. Then fix/sanity-check `Family Favourites` semantics.
4. If mobile passes, checkpoint and proceed to LG webOS, then Android TV/Google TV.
