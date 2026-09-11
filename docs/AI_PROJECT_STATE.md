# AI Project State

**Updated:** 2026-09-12 Australia/Adelaide

## Current objective

Discovery v2 **server cutover is complete**. Begin physical acceptance in the locked order: **Android mobile -> LG webOS -> Android TV/Google TV**.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`.

GitHub/current repo is authoritative. Do not reopen completed server/client implementation without current defect evidence.

## Live server state — CUTOVER PASSED

V6 completed successfully on `docker01`.

Verified live:

- Jellyfin `10.11.11`.
- authoritative Compose remains `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- external Moonfin Web is active through container path `/moonfin-web/current`, backed by host release `releases/fd06ec560235`.
- product source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.
- semantic compiler source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`.
- exact Web tar SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`.
- `/System/Info/Public` HTTP 200.
- `/Moonfin/Web/` HTTP 200.
- `/Moonfin/Web/config.json` HTTP 200.
- `/Moonfin/Web/version.json` HTTP 200.
- `/Moonfin/Web/homelab/discovery.catalogue.json` HTTP 200.
- served Web metadata matches Moonfin `2.5.1`, build `30000149`.
- served Discovery catalogue is schema v2 / live-compiled / **481 lanes**.
- served canonical catalogue SHA-256 `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`.
- only Moonbase `2.2.0.0` is live and Jellyfin reports it `Active`; superseded 2.1 remains archived outside the plugin root and must not be restored.
- Moonbase Seerr configuration survived the final Jellyfin recreate and is enabled/configured.
- authenticated Moonbase -> Seerr proxy passed after cutover.
- `/srv/appdata/moonfin/android-signing` remains untouched.

Rollback record:

`/srv/appdata/moonfin/rollback/server-migration-20260912-015401`

Rollback command:

`sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

Canonical live catalogue:

`/srv/appdata/moonfin/discovery/discovery.catalogue.json`

### Readiness rule retained

`/System/Info/Public` can return 200 before Moonbase Web is ready. Any future restart/rollback acceptance must require **both** Jellyfin public API 200 and `/Moonfin/Web/` 200.

Do not restore the full 2026-08-13 Moonfin XML. It is Moonbase 2.1-era. Seerr was successfully migrated field-by-field into the clean 2.2 configuration, preserving the 2.2 webhook secret.

## Catalogue / semantic repair — complete

Locked result:

- authored `486`
- compiled `481`
- semantic drops `5`
- provider drops `0`
- tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20.

Compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`; Discovery workflow #145 / `34598425336` is GREEN. Do not revisit this work.

`anime-theme-romantic-comedy` compiles as Japanese Animation + Comedy + exact broad `romance`; do not restore stale keyword ID `380334` or map it to narrower `lighthearted romantic comedy`.

## Exact release candidate

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Web SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`; Moonfin `2.5.1`, build `30000149`.
- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- beta Android package `org.moonfin.androidtv.beta`; production package `org.moonfin.androidtv`.
- beta signer intentionally differs from production; beta physical acceptance does not prove production signing/update compatibility.

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

## Exact next actions

1. Install the exact **Android mobile beta** candidate side-by-side; do not uninstall production Moonfin.
2. On a fresh beta app-data first launch, connect/authenticate to the live Jellyfin server and prove Discovery is using the served schema-v2 catalogue rather than stock fallback.
3. Physical acceptance: For You / Movies / Series / Anime recommendation quality; personalised Jellyfin/Seerr rows; See All; refresh/retention; touch/scroll; portrait/landscape; back/background behaviour; artwork/performance; owned-Jellyfin detail/playback; external-Seerr request state.
4. Diagnose only genuine mobile defects. Poor recommendations should be traced to source/ranking rather than synthetic retuning.
5. If mobile passes, checkpoint it and proceed to LG OLED65C6PSA/webOS, then Android TV/Google TV.
