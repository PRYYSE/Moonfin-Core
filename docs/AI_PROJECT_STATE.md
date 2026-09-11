# AI Project State

**Updated:** 2026-09-12 Australia/Adelaide

## Current objective

Discovery v2 **server cutover is complete**. Continue physical acceptance in the locked order: **Android mobile -> LG webOS -> Android TV/Google TV**.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`.

GitHub/current repo is authoritative. Do not reopen completed server/client implementation without current defect evidence.

## Live server state — CUTOVER PASSED

V6 completed successfully on `docker01`.

Verified live:

- Jellyfin `10.11.11`.
- authoritative Compose `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- external Moonfin Web `/moonfin-web/current -> releases/fd06ec560235`.
- product source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.
- semantic compiler source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`.
- Web tar SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`.
- served Discovery catalogue schema v2 / **481 lanes**, SHA-256 `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`.
- required Jellyfin/Moonfin Web/config/version/catalogue endpoints HTTP 200.
- only Moonbase `2.2.0.0` live and `Active`; Moonbase -> Seerr proxy PASS after final recreate.
- `/srv/appdata/moonfin/android-signing` untouched.

Rollback record: `/srv/appdata/moonfin/rollback/server-migration-20260912-015401`

Rollback command: `sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

Readiness rule: future restart/rollback acceptance requires both `/System/Info/Public` 200 and `/Moonfin/Web/` 200.

## Catalogue / semantic repair — complete

Locked result: 486 authored / 481 compiled / 5 semantic drops / 0 provider drops. Tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20.

Compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`; workflow #145 / `34598425336` GREEN. Do not revisit completed semantic repair unless current on-device quality evidence identifies a specific lane defect.

## Exact release candidate

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- beta package `org.moonfin.androidtv.beta`; production package `org.moonfin.androidtv`.
- beta signer intentionally differs from production.

## Android mobile physical acceptance — in progress

Exact beta candidate installed side-by-side.

Initial connection failure was resolved as a **Tailscale Android app-based split-tunnelling exclusion of `org.moonfin.androidtv.beta`**. This was local routing configuration, not a Moonfin/server defect. No rebuild required.

### On-device Discovery coverage — PASS so far

User screenshots now directly confirm all major v2 surfaces are live and populated: For You, Movies, Series, Anime, New & Upcoming and Lists. Custom schema-v2 behaviour is clearly active rather than stock fallback.

Observed:

- personalised `Because You Watched` and `Something Different` rows render;
- broad Movies, Series and Anime lane rotation works;
- New & Upcoming and Lists tabs load and populate;
- artwork, media-type badges, availability/request state and horizontal carousels render normally in portrait;
- user reports the experience appears to be working and likes the rotating-list concept.

Session persistence after force-close/reopen has not yet been explicitly confirmed in chat.

### Current recommendation-quality note

One specific lane needs follow-up before declaring quality fully accepted: **Lists -> Family Favourites** showed titles including `Attack on Titan: The Roar of Awakening`, `Princess Mononoke` and `Dou kyu sei - Classmates`. The authoritative generator currently defines `Family Favourites` with `genre: "10751|16"`, which is broad enough to admit animation-only titles rather than family-only content. Treat this as a concrete lane-semantics issue to fix in the authoritative catalogue generator if retained after final sanity check; do not apply synthetic ranking tweaks.

### Deferred UX enhancement requested on-device

After acceptance, add stable deliberate-browsing entry points without replacing rotating Discovery rows:

- **All Lists**: dense text-first/searchable index of all lane names, grouped by tab; tapping a lane opens its existing `See all` view.
- **Genres**: permanent genre browser independent of whichever genre lanes rotate into the current session.

Do not change the current candidate mid-acceptance solely for this enhancement unless the user changes priority.

## Completed — do not redo

- shared Discovery catalogue/compiler semantics: complete except any newly proven lane-specific quality defect.
- Web source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet #120 / `34326151119` GREEN.
- Android TV/Google TV #128 / `34429841034` GREEN.
- Smart-TV/webOS parity #52 / `34439022624` GREEN.
- cross-platform parity/recommendation #132 / `34439296054` GREEN.
- whole-product release #139 / `34571653740` GREEN.
- semantic repair #145 / `34598425336` GREEN.
- Moonbase duplicate-load repair: COMPLETE.
- Moonbase 2.2 Seerr migration: COMPLETE.
- Discovery v2 live server cutover: **COMPLETE / PASSED**.
- Android beta initial connection blocker: **RESOLVED — Tailscale split tunnelling**.
- Android beta custom Discovery v2 first-load/tab coverage: **PASSED so far**.

## Exact next actions

1. Confirm session persistence after force-close/reopen if not already tested.
2. Finish mobile interaction acceptance: one `See all` + Back/retention check, touch/horizontal scroll, portrait/landscape and background/return behaviour.
3. Verify one owned-Jellyfin detail/playback flow and one external-Seerr request-state flow.
4. Recheck the observed `Family Favourites` semantic issue and correct the authoritative generator if confirmed; regenerate/recompile only what that fix requires.
5. If mobile then passes, checkpoint it and proceed to LG OLED65C6PSA/webOS, then Android TV/Google TV.
6. After platform acceptance, implement the deferred **All Lists** text index and **Genres** browser enhancement.
