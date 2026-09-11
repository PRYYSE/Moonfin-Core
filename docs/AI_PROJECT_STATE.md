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
- authoritative Compose remains `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- external Moonfin Web active through `/moonfin-web/current -> releases/fd06ec560235`.
- product source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.
- semantic compiler source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`.
- exact Web tar SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`.
- served Discovery catalogue schema v2 / **481 lanes**, SHA-256 `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`.
- required Jellyfin/Moonfin Web/config/version/catalogue endpoints HTTP 200.
- only Moonbase `2.2.0.0` live and `Active`; Moonbase -> Seerr proxy PASS after final recreate.
- `/srv/appdata/moonfin/android-signing` untouched.

Rollback record: `/srv/appdata/moonfin/rollback/server-migration-20260912-015401`

Rollback command: `sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

Readiness rule retained: future Jellyfin restart/rollback acceptance must require both `/System/Info/Public` 200 and `/Moonfin/Web/` 200.

## Catalogue / semantic repair — complete

Locked result: 486 authored / 481 compiled / 5 semantic drops / 0 provider drops. Tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20.

Compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`; workflow #145 / `34598425336` GREEN. Do not revisit.

## Exact release candidate

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- beta package `org.moonfin.androidtv.beta`; production package `org.moonfin.androidtv`.
- beta signer intentionally differs from production.

## Android mobile physical acceptance — in progress

Exact beta candidate installed side-by-side.

Initial connection failure was resolved as a **Tailscale Android app-based split-tunnelling exclusion of `org.moonfin.androidtv.beta`**. This was local routing configuration, not a Moonfin/server defect. No rebuild required.

### First on-device Discovery gate — PASS

User-provided screenshots confirm the beta now reaches the live server and renders the custom Discovery v2 experience rather than stock fallback.

Observed on-device:

- expected v2 tab strip is active: For You / Movies / Series / Anime / New & Upcoming (Lists is beyond the visible phone-width portion of the strip and is not yet independently checked);
- personalised `Because You Watched` and `Something Different` rows render under For You;
- Movies renders many server-driven lanes including Trending Movies, Popular Movies, Critically Acclaimed, Fresh This Month, Animation, DreamWorks, Danish Cinema, Paramount Plus Movies and Space & Deep Space;
- artwork, labels, availability/request badges and horizontal rows are rendering normally in the supplied portrait screenshots;
- no stock-fallback presentation is evident.

Session persistence after a force-close/reopen has not yet been explicitly confirmed in chat.

## Completed — do not redo

- shared Discovery catalogue/compiler semantics: complete.
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
- Android beta custom Discovery v2 first-load gate: **PASSED**.

## Exact next actions

1. Confirm beta session survives a complete force-close/reopen if not already done.
2. Continue Android mobile recommendation/interaction acceptance: Series, Anime, New/Upcoming and Lists; For You quality; See All; refresh/retention; touch/scroll; portrait/landscape; back/background; artwork/performance.
3. Verify one owned Jellyfin item detail/playback path and one external Seerr request-state path.
4. Diagnose only defects actually observed on-device; recommendation issues should be traced to source/ranking rather than synthetic retuning.
5. If mobile passes, checkpoint it and proceed to LG OLED65C6PSA/webOS, then Android TV/Google TV.
