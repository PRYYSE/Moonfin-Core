# AI Project State

**Updated:** 2026-09-12 Australia/Adelaide

## Current objective

Discovery v2 **server cutover is complete**. Finish Android mobile repair/quality acceptance, then continue in the locked order: **LG webOS -> Android TV/Google TV**.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`.

GitHub/current repo is authoritative. Do not reopen completed server work without current defect evidence.

## Live server state — CUTOVER PASSED

V6 completed successfully on `docker01`.

Verified live:

- Jellyfin `10.11.11`.
- authoritative Compose `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- external Moonfin Web `/moonfin-web/current -> releases/fd06ec560235`.
- product source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.
- live semantic compiler source remains `ee00cb3867d9c294bae5759d6d19d5d5bd31dade` until the pending catalogue-only quality update.
- Web tar SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`.
- served Discovery catalogue schema v2 / **481 lanes**, SHA-256 `2331f6f24428de5203ec8fd4d5d867a4734ebd3449df1538ce60eb4448904b50`.
- required Jellyfin/Moonfin Web/config/version/catalogue endpoints HTTP 200.
- only Moonbase `2.2.0.0` live and `Active`; Moonbase -> Seerr proxy PASS after final recreate.
- `/srv/appdata/moonfin/android-signing` untouched.

Rollback record: `/srv/appdata/moonfin/rollback/server-migration-20260912-015401`

Rollback command: `sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

Readiness rule: future restart/rollback acceptance requires both `/System/Info/Public` 200 and `/Moonfin/Web/` 200.

## Catalogue baseline / semantic repair

Accepted live baseline remains 486 authored / 481 compiled / 5 semantic drops / 0 provider drops. Tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20.

Original semantic repair source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`; workflow #145 / `34598425336` GREEN.

Do not lower the 481/486, 5 semantic-drop, 0 provider-drop live regression gate for current quality changes.

## Previously accepted release input

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- beta package `org.moonfin.androidtv.beta`; production package `org.moonfin.androidtv`.
- beta signer intentionally differs from production.

The #139 mobile candidate proved the product flow but physical acceptance found two UI defects plus a weak For You experience. A replacement candidate is now building.

## Android mobile physical acceptance — repair candidate building

Initial beta connection failure was resolved as **Tailscale Android app-based split tunnelling excluding `org.moonfin.androidtv.beta`**. Local routing issue only; no Moonfin/server network defect.

### Functional coverage — PASS

User reports the requested functional acceptance slice is working, and screenshots directly confirm the server-driven schema-v2 Discovery experience across For You, Movies, Series, Anime, New & Upcoming and Lists.

Confirmed/accepted so far:

- login/session/reopen path;
- custom v2 catalogue rather than stock fallback;
- rotating Movies/Series/Anime lanes;
- New & Upcoming and Lists;
- `See all` + Back;
- owned-Jellyfin detail/playback path;
- external-Seerr request path;
- orientation/background/reopen behaviour;
- normal artwork, badges and portrait presentation.

### Mobile UI defects — fixes implemented

Physical screenshots proved:

1. **Horizontal carousel offset inheritance.** Non-TV landing rows lacked lane-specific PageStorage identity, allowing lazy/recycled rows to inherit another row's horizontal offset.
2. **Discovery/top-toolbar spacing.** Discovery content did not reserve the fixed mobile toolbar height, leaving the title/back/navigation chrome visually crowded.

Implemented repair:

- carousel storage identity = **tab + section + refresh generation**; ordinary rebuild/recycling retains the correct row state, explicit refresh gets fresh state and starts from the beginning;
- mobile Discovery with top navigation reserves fixed toolbar height + **8 dp**; left/bottom navigation remains unchanged;
- focused regression tests added.

Relevant implementation commits include `62b5851c715e16d404aa7d59d8efbb44853bd589`, `bdcf16d985172dd631559a4027380d00c5a64e54`, `1d16eb8885ded0de9fd886a73823cdd3cee7c389`, and tests `63925bd4e42f6546fb599a94202e4c63a9ef8112`.

## For You quality defect — redesign implemented, not yet live

On-device #139 showed only two usable For You rows with vague naming: one effectively series-heavy and one movie-heavy.

Root cause review:

- authoring already contained 16 For You definitions; the composer was **not** capped at two;
- several rows depend on optional user data such as favourites, watchlist, ratings or likes;
- personal lanes required **8** usable items, causing valid but smaller personal result sets to disappear;
- one authored strategy (`recent-discovery-context`) had no truthful current source adapter and therefore failed closed.

Compiler commit **`87390d713c24aba7a30aa66cee98d1c59b027752`** adds a stale-checked reviewed For You contract while preserving **16 lanes and the 486 authored / 481 accepted compiled-count model**.

Reviewed For You behaviour:

- `Movies Based on Your Watch History` — real recent-history source, movie-only;
- `Series Based on Your Watch History` — real recent-history source, series-only;
- `Inspired by Your Favourites`;
- `Inspired by Your Watchlist`;
- `Because You Rated These Highly`;
- `Based on Things You Like`;
- `Highly Rated Picks You Haven't Seen`;
- `Try Something Different`;
- `Movies You Might Like`;
- `Series You Might Like`;
- `Anime You Might Like`;
- `Quick Picks for You`;
- `Older Gems for You`;
- `Recent Picks for You`;
- `Worth Rewatching`;
- `Based on Your Taste`.

All For You lanes now use `minItems=4`; the tab's minimum usable-lane contract is 4. Source-specific rows still fail closed when the user genuinely has no qualifying source data. The compiler validates all 16 reviewed IDs/titles/strategies/media types and refuses to apply the override if original authoring assumptions drift.

**Important:** this For You redesign is server-catalogue driven and is not live yet. Do not manually edit the served JSON. After CI validation, deploy it with a narrow compiler/catalogue-only update on `docker01`, preserving the current catalogue for rollback and requiring the same 481/486, 5 semantic-drop, 0 provider-drop gate. No Compose edit, Jellyfin recreate or Moonbase change is required.

### Current long-CI checkpoint

The For You compiler commit also contains `[full-build]`, so it supersedes the earlier #150 candidate.

- workflow **#151**
- run **`34668019767`**
- source **`87390d713c24aba7a30aa66cee98d1c59b027752`**
- event: push
- status when recorded: **in progress**

Do not poll continuously. On continuation inspect this exact run once. If green, retrieve/hash the new mobile-beta artifact.

## Other recommendation-quality issue

`Lists -> Family Favourites` visibly included animation-only/non-family titles. Current authoring uses `genre: "10751|16"`, which admits Family **or** Animation. Fix the authoritative catalogue semantics rather than ranking around it. Keep this separate from the For You source redesign unless deliberately folded into the same narrow catalogue-only deployment after validation.

## Deferred UX enhancement requested on-device

After platform acceptance, preserve rotating rows but add:

- **All Lists**: dense text-first/searchable index of every lane, grouped by tab, opening existing `See all` views.
- **Genres**: permanent genre browser independent of current lane rotation.

## Completed — do not redo

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

1. On next continuation inspect workflow #151 / `34668019767` exactly once.
2. If green, extract/hash the replacement `mobile-beta` APK from source `87390d713c24aba7a30aa66cee98d1c59b027752`.
3. Perform a narrow catalogue-only update on `docker01` using the reviewed compiler source, preserving the current catalogue and requiring 481/486, 5 semantic drops, 0 provider drops; verify served catalogue HTTP/SHA. Do not touch Compose/Jellyfin/Moonbase.
4. Update/install Moonfin Beta side-by-side and retest only: carousel start/retention/refresh reset, Discovery header spacing, and the richer For You rows/naming.
5. Correct/sanity-check `Family Favourites` semantics, preferably in the same planned catalogue-only quality pass if it can retain all locked gates.
6. If mobile passes, checkpoint and proceed to LG OLED65C6PSA/webOS, then Android TV/Google TV.
7. After platform acceptance, implement **All Lists** + **Genres** browsing.
