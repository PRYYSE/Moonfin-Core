# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-13 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed implementation must not be restarted without current fault evidence.

## Status

Discovery v2 server cutover is complete. The richer For You catalogue is now live and passed the locked server gate. The exact #152 mobile repair candidate is GREEN. Immediate next action is physical retest of only the repaired mobile UI/For You behaviour, then the separate `Family Favourites` semantic fix.

## Live server — accepted

- `/moonfin-web/current -> releases/fd06ec560235`
- product source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- live Discovery compiler/catalogue source `145678fae77feb733975ffbafe62a6ae2b6ec2cb`
- served catalogue: schema v2 / 481 lanes / SHA-256 `592a96c2752cd00a4fada31ebeae7bf31619658cd24f8fed6f92f531a8dc2af4`
- locked gate: **486 authored / 481 compiled / 5 semantic drops / 0 provider drops**
- For You: 16 reviewed rows / `minItems=4` / tab minimum 4
- Moonbase `2.2.0.0` Active; Moonbase -> Seerr proxy PASS
- original cutover rollback `/srv/appdata/moonfin/rollback/server-migration-20260912-015401`
- latest catalogue rollback `/srv/appdata/moonfin/rollback/discovery-for-you-20260913-192027`

The 2026-09-13 For You deployment was catalogue-only. **No Jellyfin restart, Compose edit or Moonbase change.** Canonical and served catalogue SHA matched after install.

## Mobile repair candidate — GREEN

Workflow **#152**, run **`34672828217`**, source **`145678fae77feb733975ffbafe62a6ae2b6ec2cb`** completed **SUCCESS**.

All focused validation and build jobs passed, including route, catalogue tests, format, analyse, Flutter tests, Web interaction tests, scope, Web/mobile/TV builds, Android identity/signing and packaging.

Artefact `10291880971`:
- outer SHA-256 `a3184852ea3a272b2209c50055db31c9ffb8ad203477de77224cb6daa83f8320`
- mobile APK `Moonfin_HomeLab_Android_145678fae77f.apk` SHA-256 **`dfb867820940456122bdeb7b2c193a7e75cec1e0d5877ad22786e09cf7509413`**
- Android-TV APK SHA-256 `b3edb2445e076ff8af41046bce7bc4e68a095532b0efc68b58750a2efb85446a`
- Web tar SHA-256 `5265cc22af6b87f1bdbd698966bddd60fa4d6e2a09cb95a385724611375d5f67`

Mobile repair under retest:
- carousel state identity = tab + section + refresh generation;
- refreshed lanes reset to start without cross-row offset inheritance;
- mobile top-navigation Discovery reserves toolbar height + 8 dp.

## For You redesign — LIVE

Compiler change first landed at `87390d713c24aba7a30aa66cee98d1c59b027752` and is included in #152 source.

- 16 reviewed executable rows;
- separate movie/series recommendations from recent history;
- clearer source/outcome naming;
- optional favourites/watchlist/ratings/likes still fail closed when empty;
- personal rows `minItems=4`; tab minimum 4;
- stale checks prevent silently applying the contract after authoring drift.

Live deployment PASS evidence:
- source `145678fae77feb733975ffbafe62a6ae2b6ec2cb`;
- compiler reported `481/486`;
- 5 semantic drops / 0 provider drops;
- For You contract PASS;
- served SHA `592a96c2752cd00a4fada31ebeae7bf31619658cd24f8fed6f92f531a8dc2af4`;
- rollback `/srv/appdata/moonfin/rollback/discovery-for-you-20260913-192027`.

## Other open quality issue — keep separate

`Lists -> Family Favourites` currently uses `genre: "10751|16"`, so Animation alone can qualify. Correct the authoritative generator separately after the green candidate's For You/mobile UI retest; likely semantics should be Family-only rather than OR Animation, but validate before deployment.

## Deferred enhancement

After platform acceptance: add **All Lists** and **Genres** browsing while retaining rotating landing rows.

## Exact next action

1. Install/update exact #152 mobile-beta APK `Moonfin_HomeLab_Android_145678fae77f.apk` (SHA-256 `dfb867820940456122bdeb7b2c193a7e75cec1e0d5877ad22786e09cf7509413`).
2. Retest only carousel start/retention/refresh reset, Discovery header spacing, and For You richness/naming.
3. Then fix/sanity-check `Family Favourites` semantics.
4. If mobile passes, checkpoint Android mobile as accepted and proceed to LG webOS, then Android TV/Google TV.
