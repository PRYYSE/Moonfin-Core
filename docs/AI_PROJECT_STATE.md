# AI Project State

**Updated:** 2026-09-12 Australia/Adelaide

## Current objective

Discovery v2 server cutover is complete. Finish Android mobile repair/recommendation-quality acceptance, then continue in locked order: **LG webOS -> Android TV/Google TV**.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`. GitHub/current repo is authoritative.

## Live server — accepted

- Jellyfin `10.11.11` on `docker01`.
- Compose: `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- external Web: `/moonfin-web/current -> releases/fd06ec560235`.
- live product source: `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.
- live semantic compiler source remains `ee00cb3867d9c294bae5759d6d19d5d5bd31dade` until the pending catalogue-only For You deployment.
- served catalogue: schema v2 / 481 lanes / SHA-256 `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`.
- locked catalogue gate: **486 authored / 481 compiled / 5 semantic drops / 0 provider drops**.
- Moonbase `2.2.0.0` Active; Moonbase -> Seerr proxy PASS.
- `/srv/appdata/moonfin/android-signing` untouched.
- rollback record: `/srv/appdata/moonfin/rollback/server-migration-20260912-015401`.
- rollback command: `sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`.

Do not reopen server cutover, Moonbase migration, QSV, Compose architecture or completed semantic repair without current defect evidence.

## Android mobile acceptance

Functional acceptance already passed for login/session/reopen, custom schema-v2 Discovery, all Discovery tabs, See All/back, owned playback, Seerr request flow, artwork/status rendering and orientation/background behaviour.

Physical acceptance then found two UI defects; fixes are now CI-green:

1. carousel horizontal offset inheritance — storage identity is tab + section + refresh generation;
2. Discovery title/header colliding with fixed mobile top toolbar — top-navigation layout reserves toolbar height + 8 dp.

Relevant implementation commits: `62b5851c715e16d404aa7d59d8efbb44853bd589`, `bdcf16d985172dd631559a4027380d00c5a64e54`, `1d16eb8885ded0de9fd886a73823cdd3cee7c389`, tests `63925bd4e42f6546fb599a94202e4c63a9ef8112`.

### Replacement candidate — GREEN

Workflow **#152**, run **`34672828217`**, source **`145678fae77feb733975ffbafe62a6ae2b6ec2cb`** completed **SUCCESS**.

All focused validation and build jobs passed: route integration, catalogue generation/tests, format, analyse, focused tests, Web interaction tests, scope gate, Web build, mobile-beta build, Android-TV build, identity/signing and artefact packaging.

Artefact:
- ID `10291880971`
- `homelab-discovery-v2-candidates-145678fae77feb733975ffbafe62a6ae2b6ec2cb`
- outer SHA-256 `a3184852ea3a272b2209c50055db31c9ffb8ad203477de77224cb6daa83f8320`
- mobile APK `Moonfin_HomeLab_Android_145678fae77f.apk` SHA-256 **`dfb867820940456122bdeb7b2c193a7e75cec1e0d5877ad22786e09cf7509413`**
- Android-TV APK SHA-256 `b3edb2445e076ff8af41046bce7bc4e68a095532b0efc68b58750a2efb85446a`
- Web tar SHA-256 `5265cc22af6b87f1bdbd698966bddd60fa4d6e2a09cb95a385724611375d5f67`
- app `2.5.1+30000149`; beta package `org.moonfin.androidtv.beta`
- CI signer `2ebdd4396ed9a64c6d0e073906001eb76650d7380d3c512ac64444e96a334b5e`; production signing remains untouched.

## For You redesign — implemented, not live

On-device #139 showed only two useful For You rows with vague naming. Root cause was not a two-row catalogue cap: 16 rows existed, but optional-source rows could be empty, personal rows required 8 usable items, and one strategy had no truthful adapter.

Commit `87390d713c24aba7a30aa66cee98d1c59b027752` adds a stale-checked reviewed For You contract while preserving 16 rows and the locked total-count model. Personal rows now use `minItems=4`; the tab minimum is 4. Empty optional-source rows still fail closed.

Reviewed rows include separate movie/series watch-history recommendations, favourites, watchlist, ratings, likes, unseen-high-rated, novelty, movie/series/anime affinity, quick picks, older/recent picks, rewatch and mixed-taste recommendations with clearer names.

This change is **server-catalogue driven and not live yet**. Next server action is a bounded catalogue-only compile/install from exact source `145678fae77feb733975ffbafe62a6ae2b6ec2cb`: stage candidate files first, require the unchanged 481/486 + 5 semantic drops + 0 provider drops gate, preserve rollback files, atomically swap the catalogue, and verify the served catalogue. Do not edit Compose, recreate Jellyfin or change Moonbase.

## Other quality defect — separate

`Lists -> Family Favourites` currently uses `genre: "10751|16"`, admitting Family **or** Animation. Correct authoritative generator semantics separately after the already-green For You/mobile repair candidate is physically verified; do not stack an unvalidated semantic edit into that candidate.

## Deferred UX enhancement

After platform acceptance, preserve rotating rows but add:

- **All Lists**: dense text-first/searchable index of every lane, grouped by tab, opening existing See All views.
- **Genres**: permanent genre browser independent of current lane rotation.

## Completed — do not redo

- Web source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet #120 / `34326151119` GREEN.
- Android TV/Google TV #128 / `34429841034` GREEN.
- Smart-TV/webOS parity #52 / `34439022624` GREEN.
- cross-platform parity/recommendation #132 / `34439296054` GREEN.
- whole-product release #139 / `34571653740` GREEN.
- semantic repair #145 / `34598425336` GREEN.
- mobile repair/replacement candidate #152 / `34672828217` GREEN.
- Moonbase duplicate-load repair and 2.2 Seerr migration COMPLETE.
- Discovery v2 server cutover COMPLETE/PASSED.
- Android beta Tailscale split-tunnel issue RESOLVED.
- Android mobile functional acceptance PASS except current repaired UI/For You retest.

## Exact next actions

1. Perform the bounded For You catalogue-only quality deployment on `docker01` from source `145678fae77feb733975ffbafe62a6ae2b6ec2cb`; preserve rollback and require exact 481/5/0 gates; no Jellyfin/Compose/Moonbase restart.
2. Extract/install the exact #152 mobile-beta APK and retest only carousel start/retention/refresh reset, header spacing, and For You richness/naming.
3. If those pass, correct and narrowly validate/deploy `Family Favourites` semantics.
4. Checkpoint Android mobile as accepted, then proceed to LG OLED65C6PSA/webOS, then Android TV/Google TV.
5. After platform acceptance, implement deferred **All Lists** + **Genres** browsing.
