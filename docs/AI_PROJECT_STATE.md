# AI Project State

**Updated:** 2026-09-12 Australia/Adelaide

## Current objective

Discovery v2 **server cutover is complete**. Finish Android mobile physical acceptance, then continue in the locked order: **LG webOS -> Android TV/Google TV**.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`.

GitHub/current repo is authoritative. Do not reopen completed server work without current defect evidence.

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

## Previously accepted release input

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- beta package `org.moonfin.androidtv.beta`; production package `org.moonfin.androidtv`.
- beta signer intentionally differs from production.

The #139 mobile candidate proved the product flow but now has two confirmed UI defects from physical acceptance; use the newer repair candidate once workflow #150 completes for final mobile acceptance.

## Android mobile physical acceptance — repair candidate building

Initial beta connection failure was resolved as **Tailscale Android app-based split tunnelling excluding `org.moonfin.androidtv.beta`**. Local routing issue only; no Moonfin/server network defect.

### On-device functional coverage — PASS

User reports the requested functional acceptance slice is working, and screenshots directly confirm the server-driven schema-v2 Discovery experience across For You, Movies, Series, Anime, New & Upcoming and Lists.

Confirmed/accepted so far:

- login/session/reopen path working;
- custom v2 catalogue rather than stock fallback;
- personalised For You rows;
- broad rotating Movies/Series/Anime lanes;
- New & Upcoming and Lists;
- `See all` + Back flow;
- owned-Jellyfin detail/playback path;
- external-Seerr request path;
- orientation/background/reopen behaviour;
- normal artwork, badges and portrait presentation.

### Confirmed mobile UI defects — fixes implemented

Physical screenshots show two defects in #139:

1. **Horizontal carousels can appear/jump at an inherited later offset.** Root cause: non-TV landing `ListView.separated` rows had no lane-specific PageStorage identity, allowing lazy row reuse/rotation to transplant horizontal scroll state.
2. **Discovery title/header overlaps the fixed mobile top toolbar/back control.** Root cause: Discovery content begins in the same SafeArea but did not reserve the fixed top-toolbar height.

Implemented repair on `homelab/discovery-v2`:

- `62b5851c715e16d404aa7d59d8efbb44853bd589`: adaptive UI helpers for header and lane scroll identity.
- `bdcf16d985172dd631559a4027380d00c5a64e54`: lane scroll storage now scoped by tab + section + refresh generation; refreshed content starts with fresh horizontal state; Discovery mobile title reserves top toolbar height + 8 dp only for top-navigation layout.
- `1d16eb8885ded0de9fd886a73823cdd3cee7c389`: type-safety polish.
- `63925bd4e42f6546fb599a94202e4c63a9ef8112`: focused mobile regression tests for header spacing and scroll-state identity.
- `d736adf2565bb3a82fdce661d72fc4296c9f89c9`: UI invariants documented and **full candidate build triggered**.

Workflow #150 / run `34627434968`, source `d736adf2565bb3a82fdce661d72fc4296c9f89c9`, is the exact long-CI checkpoint. It was pending when recorded. **Do not poll continuously.** On continuation inspect this exact run once; if green, extract the new mobile-beta APK and record its exact SHA before physical retest.

### Current recommendation-quality issue

`Lists -> Family Favourites` visibly included animation-only/non-family titles. Authoritative authoring uses `genre: "10751|16"`, which admits Family **or** Animation. Treat as a concrete lane-semantics issue; fix the authoritative catalogue definition rather than ranking around it. This is separate from the mobile UI repair build.

### Deferred UX enhancement requested on-device

After platform acceptance, preserve rotating rows but add:

- **All Lists**: dense text-first/searchable index of every lane, grouped by tab, opening existing `See all` views.
- **Genres**: permanent genre browser independent of current lane rotation.

## Completed — do not redo

- shared Discovery catalogue/compiler semantics: complete except newly proven lane-specific quality defects.
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
- Android beta Tailscale connection issue: RESOLVED.
- Android mobile functional acceptance: **PASS apart from current UI/quality repair retests**.

## Exact next actions

1. On next continuation, inspect workflow #150 / `34627434968` exactly once.
2. If green, extract and hash the new `mobile-beta` APK; install/update Moonfin Beta side-by-side and recheck only: carousel starts/retention across vertical recycling + refresh reset, and Discovery/top-toolbar spacing in portrait/landscape.
3. If those pass, close the mobile UI defects.
4. Correct and narrowly recompile/deploy the `Family Favourites` lane semantics, then sanity-check that row on mobile; do not regenerate unrelated architecture.
5. Checkpoint Android mobile as accepted, then proceed to LG OLED65C6PSA/webOS and Android TV/Google TV.
6. After platform acceptance, implement **All Lists** + **Genres** browsing.
