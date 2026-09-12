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
- live semantic compiler source remains `ee00cb3867d9c294bae5759d6d19d5d5bd31dade` until the pending catalogue-only quality deployment.
- served catalogue: schema v2 / 481 lanes / SHA-256 `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`.
- locked catalogue gate: **486 authored / 481 compiled / 5 semantic drops / 0 provider drops**.
- Moonbase `2.2.0.0` Active; Moonbase -> Seerr proxy PASS.
- `/srv/appdata/moonfin/android-signing` untouched.
- rollback record: `/srv/appdata/moonfin/rollback/server-migration-20260912-015401`.
- rollback command: `sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`.

Do not reopen server cutover, Moonbase migration, QSV, Compose architecture or semantic repair without current defect evidence.

## Android mobile acceptance

Functional acceptance has already passed for login/session/reopen, custom schema-v2 Discovery, all Discovery tabs, See All/back, owned playback, Seerr request flow, artwork/status rendering and orientation/background behaviour.

Two physical UI defects were found and fixed:

1. carousel horizontal offset inheritance — storage identity is now tab + section + refresh generation;
2. Discovery title/header colliding with the fixed mobile top toolbar — top-navigation layout now reserves toolbar height + 8 dp.

Relevant implementation commits: `62b5851c715e16d404aa7d59d8efbb44853bd589`, `bdcf16d985172dd631559a4027380d00c5a64e54`, `1d16eb8885ded0de9fd886a73823cdd3cee7c389`, tests `63925bd4e42f6546fb599a94202e4c63a9ef8112`.

## For You redesign — implemented, not live

On-device #139 showed only two useful For You rows with vague naming. Root cause was not a two-row catalogue cap: 16 rows existed, but optional-source rows could be empty, personal rows required 8 usable items, and one strategy had no truthful adapter.

Commit `87390d713c24aba7a30aa66cee98d1c59b027752` adds a stale-checked reviewed For You contract while preserving 16 rows and the locked total-count model. Personal rows now use `minItems=4`; the tab minimum is 4. Empty optional source rows still fail closed.

Reviewed rows include separate movie/series watch-history recommendations, favourites, watchlist, ratings, likes, unseen-high-rated, novelty, movie/series/anime affinity, quick picks, older/recent picks, rewatch and mixed-taste recommendations with clearer names.

This change is **server-catalogue driven and not live yet**. Deploy later as a catalogue-only update: preserve the current catalogue for rollback, require 481/486 + 5 semantic drops + 0 provider drops, then atomically replace the served catalogue. Do not edit Compose, recreate Jellyfin or change Moonbase.

## Other quality defect

`Lists -> Family Favourites` currently uses `genre: "10751|16"`, admitting Family **or** Animation. Fix authoritative generator semantics before final mobile sign-off; do not compensate with ranking heuristics.

## Candidate CI

### #151 — failed for formatting only

- run `34668019767`
- source `87390d713c24aba7a30aa66cee98d1c59b027752`
- result: **FAILURE** at `Format gate` only.
- route integration: PASS.
- authoring catalogue gate: PASS.
- generator: 486 total / For You 16 / Movies 130 / Series 140 / Anime 160 / New & Upcoming 20 / Lists 20.
- catalogue tests: **9/9 PASS**.
- failure was only `dart format` reflowing one test block in `test/homelab_discovery/homelab_discovery_mobile_test.dart`; analyse/tests/build were skipped after that gate.

The exact formatter output was committed without semantic changes.

### Current long-CI checkpoint — #152

- commit/source: **`145678fae77feb733975ffbafe62a6ae2b6ec2cb`**
- message: `chore(discovery): format mobile regression test [full-build]`
- workflow: **#152**
- run ID: **`34672828217`**
- event: push
- state when recorded: **queued**

Do not continuously poll #152. On the next continuation inspect this exact run once. If green, retrieve the candidate artifact and record the exact mobile-beta APK SHA-256.

## Previously accepted release input

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- old mobile APK SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV APK SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- beta package `org.moonfin.androidtv.beta`; production package `org.moonfin.androidtv`.
- beta signer intentionally differs from production.

## Completed — do not redo

- Web source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet #120 / `34326151119` GREEN.
- Android TV/Google TV #128 / `34429841034` GREEN.
- Smart-TV/webOS parity #52 / `34439022624` GREEN.
- cross-platform parity/recommendation #132 / `34439296054` GREEN.
- whole-product release #139 / `34571653740` GREEN.
- semantic repair #145 / `34598425336` GREEN.
- Moonbase duplicate-load repair and 2.2 Seerr migration COMPLETE.
- Discovery v2 server cutover COMPLETE/PASSED.
- Android beta Tailscale split-tunnel issue RESOLVED.
- Android mobile functional acceptance PASS except current UI/quality retest.

## Exact next actions

1. Inspect workflow #152 / `34672828217` exactly once on continuation.
2. If green, retrieve/hash the replacement mobile-beta APK from source `145678fae77feb733975ffbafe62a6ae2b6ec2cb`.
3. Perform the narrow catalogue-only quality deployment on `docker01`, including the reviewed For You compiler contract and corrected `Family Favourites`, while retaining the locked 481/5/0 gate and a rollback copy. Do not touch Compose/Jellyfin/Moonbase.
4. Install/update Moonfin Beta side-by-side and retest only carousel start/retention/refresh reset, header spacing, For You richness/naming, and Family Favourites semantics.
5. If mobile passes, checkpoint it as accepted and proceed to LG OLED65C6PSA/webOS, then Android TV/Google TV.
6. After platform acceptance, implement deferred **All Lists** + **Genres** browsing.
