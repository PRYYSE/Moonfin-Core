# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-12 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed implementation must not be restarted without current fault evidence.

## Status

**Discovery v2 server cutover PASSED.** Android mobile beta physical acceptance is in progress and all major Discovery v2 tabs now render live on-device.

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

### Discovery v2 on-device coverage — PASS so far

User screenshots directly show populated **For You, Movies, Series, Anime, New & Upcoming and Lists** tabs. Custom schema-v2 presentation is active rather than stock fallback.

Observed working:

- personalised For You rows;
- broad rotating Movies/Series/Anime lanes;
- New & Upcoming and Lists tabs;
- artwork, labels, availability/request badges and portrait horizontal carousels;
- user reports the experience appears to work and likes the rotating-lane design.

Session persistence after force-close/reopen is not explicitly confirmed yet.

### Recommendation-quality issue to recheck

`Lists -> Family Favourites` visibly included titles such as Attack on Titan, Princess Mononoke and Dou kyu sei. The authoritative authoring row currently uses `genre: "10751|16"`, allowing animation-only matches as well as Family. Treat as a concrete lane-semantics quality issue; if confirmed, fix the authoritative catalogue definition rather than ranking around it.

### Deferred UX follow-up

After acceptance, preserve rotating rows but add:

- **All Lists** — searchable/text-first index of every lane name grouped by tab, opening the existing `See all` view;
- **Genres** — stable genre browser independent of lane rotation.

Do not alter the current candidate for this enhancement during acceptance unless the user changes priority.

## Exact next action

1. Confirm session persistence after force-close/reopen if still untested.
2. Exercise one `See all` + Back/retention flow, orientation/background behaviour and normal touch scrolling.
3. Verify one owned-Jellyfin detail/playback path and one external-Seerr request-state path.
4. Recheck/fix `Family Favourites` semantics if confirmed.
5. If mobile passes, checkpoint it and proceed to LG OLED65C6PSA/webOS, then Android TV/Google TV.
6. Implement All Lists + Genres after platform acceptance.
