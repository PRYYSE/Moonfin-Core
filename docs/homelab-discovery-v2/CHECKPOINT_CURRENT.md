# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-12 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed implementation must not be restarted without current fault evidence.

## Status

**Discovery v2 server cutover PASSED.** External Moonfin Web and the live server-driven catalogue are active. Android mobile beta physical acceptance is now in progress.

## Live server cutover — complete

V6 final result:

- `=== CUTOVER PASSED ===`
- live Moonfin Web root: `/moonfin-web/current -> releases/fd06ec560235`
- product source: `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- semantic compiler source: `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`
- Web tar SHA-256: `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- canonical catalogue: `/srv/appdata/moonfin/discovery/discovery.catalogue.json`
- served catalogue SHA-256: `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`
- served catalogue: schema v2, 481 lanes
- all required endpoints HTTP 200: Jellyfin public API, Moonfin Web, config, version and Discovery catalogue
- Moonbase `2.2.0.0` Active after final recreate; 2.1 remains archived outside the live plugin root
- Moonbase Seerr config remained enabled/configured after recreate
- authenticated Moonbase -> Seerr proxy PASS
- Android signing material untouched

Rollback record:

`/srv/appdata/moonfin/rollback/server-migration-20260912-015401`

Rollback command:

`sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

Readiness rule retained: future Jellyfin restart/rollback verification must require both `/System/Info/Public` 200 and `/Moonfin/Web/` 200.

## Locked catalogue result — do not redo

- 486 authored / 481 compiled
- exactly 5 semantic drops / 0 provider drops
- tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20
- compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`
- workflow #145 / `34598425336`: GREEN

## Exact release inputs

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Web: Moonfin 2.5.1 build 30000149, SHA above.
- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- Android beta package `org.moonfin.androidtv.beta`; production package `org.moonfin.androidtv`.
- beta signer intentionally differs from production; do not infer production update compatibility from beta acceptance.

## Android mobile acceptance — current state

Initial beta connection appeared to fail over both Tailscale/LAN while regular Moonfin worked from the same phone.

Root cause confirmed on-device: **Tailscale Android app-based split tunnelling excluded `org.moonfin.androidtv.beta`**. Regular Moonfin uses `org.moonfin.androidtv`, so only production was being routed through Tailscale.

This is resolved configuration state, not a Moonfin code/server defect. Do not rebuild the APK or change server networking for this issue.

## Exact next action

With Moonfin Beta removed from Tailscale's excluded-app list:

1. connect/authenticate to the live Jellyfin server;
2. fully close/reopen beta and confirm session persistence;
3. open Discovery and prove the custom v2 structure is active rather than stock fallback: For You / Movies / Series / Anime / New/Upcoming / Lists;
4. once that passes, continue recommendation-quality and interaction acceptance only on observed behaviour.

If mobile passes, checkpoint it and proceed to LG OLED65C6PSA/webOS, then Android TV/Google TV.
