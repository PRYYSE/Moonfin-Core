# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-12 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed implementation must not be restarted without current fault evidence.

## Status

**Discovery v2 server cutover PASSED.** Android mobile beta physical acceptance is in progress. The custom Discovery v2 first-load gate has now passed on-device.

## Live server cutover — complete

- `=== CUTOVER PASSED ===`
- `/moonfin-web/current -> releases/fd06ec560235`
- product source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- semantic compiler source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`
- Web tar SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- served catalogue schema v2 / 481 lanes / SHA-256 `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`
- Moonbase `2.2.0.0` Active; authenticated Moonbase -> Seerr proxy PASS
- rollback `/srv/appdata/moonfin/rollback/server-migration-20260912-015401`
- rollback command `sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

Locked catalogue: 486 authored / 481 compiled / 5 semantic drops / 0 provider drops. Workflow #145 / `34598425336` GREEN.

## Exact mobile candidate

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.

- mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`
- beta package `org.moonfin.androidtv.beta`; production `org.moonfin.androidtv`
- installed side-by-side; do not uninstall production

## Android mobile acceptance — current evidence

Initial beta connection failure was caused by **Tailscale Android app-based split tunnelling excluding the beta package**. Resolved locally; no app/server change required.

### Custom Discovery v2 first-load gate — PASS

User screenshots show the beta rendering the server-driven v2 UI rather than stock fallback.

Confirmed visually:

- For You / Movies / Series / Anime / New & Upcoming tab structure visible; Lists is off the current phone-width viewport and still needs a direct check;
- personalised `Because You Watched` and `Something Different` rows populated;
- Movies includes multiple distinct live lanes such as Trending Movies, Popular Movies, Critically Acclaimed, Fresh This Month, Animation, DreamWorks, Danish Cinema, Paramount Plus Movies and Space & Deep Space;
- portrait rendering, artwork, item labels, status badges and row scrolling presentation appear normal in supplied screenshots.

Session persistence after force-close/reopen has not yet been explicitly confirmed.

## Exact next action

1. Confirm session persistence after force-close/reopen if not already tested.
2. Check Series, Anime, New/Upcoming and Lists plus representative For You quality; report only genuine oddities.
3. Exercise See All, refresh/retention, touch/horizontal scroll, portrait/landscape and back/background behaviour.
4. Verify one owned-Jellyfin detail/playback flow and one external-Seerr request-state flow.
5. If mobile passes, checkpoint it and proceed to LG OLED65C6PSA/webOS, then Android TV/Google TV.
