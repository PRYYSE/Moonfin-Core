# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed GitHub/code stages must not be restarted without current fault evidence.

## Status — first cutover aborted safely; repository semantic fix + final cutover prepared

GitHub/client implementation remains COMPLETE. The only current gate before physical client acceptance is the controlled live Jellyfin/Moonbase external-Web/catalogue cutover.

The first cutover attempt stopped at its pre-Compose catalogue regression gate. It did **not** edit Compose, recreate Jellyfin, set `MOONFIN_WEB_ROOT`, switch the external Web root or begin physical acceptance. It only created unserved compiler output under `/srv/appdata/moonfin/discovery`.

## Current live server evidence

- Jellyfin `10.11.11`, container `jellyfin`, LAN `http://192.168.50.12:8096`.
- Compose project `media`: `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- `/srv/appdata/jellyfin:/config`, `/srv/appdata/jellyfin-transcode:/transcode`, `/data/media:/data/media:ro`, `/dev/dri:/dev/dri`.
- PUID 1000 / PGID 1001 / `Australia/Adelaide`; Intel OpenCL Docker mod retained.
- `MOONFIN_WEB_ROOT` remains unset.
- existing `/Moonfin/Web/` and `/Moonfin/Web/config.json` return 200.
- `/Moonfin/Web/homelab/discovery.catalogue.json` remains unserved/404.
- `/srv/appdata/moonfin/web` remains absent.
- `/srv/appdata/moonfin/discovery` contains only the first attempt's unserved catalogue/cache/diagnostics.
- protected `/srv/appdata/moonfin/android-signing` remains untouched.
- Seerr container `seerr` / `ghcr.io/seerr-team/seerr:latest`.

## Moonbase live-state correction

Do **not** reinstall Moonbase.

- plugin root contains `Moonbase_2.1.0.0` and `Moonbase_2.2.0.0`.
- official Moonbase 2.2.0 ZIP MD5 verified: `205728081ECEA212F9FEA419FC2EFD77`.
- installed-vs-official package comparison: 172 exact, 0 missing, only `meta.json` differs.
- installed `Moonfin.Server.dll` exactly matches official payload SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`.
- Jellyfin `/Plugins` pre-cutover reported `Moonbase 2.1.0.0 / Superseded` and `Moonfin 2.2.0.0 / Restart`.

The final deployment accepts 2.2.0 `Restart` only as the pre-cutover pending-restart state, then requires Moonfin 2.2.0 `Active` after the already-planned controlled Jellyfin recreate.

## Exact tested release candidate

Whole-product #139 / `34571653740` at `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`:

- Web `Moonfin_HomeLab_Web_fd06ec560235.tar.gz`: SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`; Moonfin `2.5.1`, build `30000149`.
- Android mobile: SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV: SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.

The old mobile hash beginning `117e633f...` was incorrect; do not use it.

## First cutover catalogue failure — diagnosed

Forced live semantic resolution produced **480/486**, **6 semantic drops**, **0 provider drops**:

- `movies-theme-heist-movies` -> `heist movies`
- `series-theme-high-school-teen-drama` -> `high school & teen drama`
- `series-theme-supernatural-mysteries` -> `supernatural mysteries`
- `anime-theme-giant-robots` -> `giant robots`
- `anime-theme-parallel-worlds` -> `parallel worlds`
- `anime-theme-romantic-comedy` -> `romantic comedy`

Historical accepted cache contained `romantic comedy=380334`. Current Seerr lookup for keyword `380334` returns null; current search for `romantic comedy` returns only `380026 / lighthearted romantic comedy`.

Do **not** map the broad lane to the narrower current keyword.

## Root semantic repair — committed

Compiler source commit: `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`.

The compiler now keeps the authored lane ID/title `anime-theme-romantic-comedy` but translates it to stable executable components:

- source `discoverTv`
- media type `tv`
- genres `16,35` = Animation + Comedy
- language `ja`
- `voteCountGte=5`
- exact broad keyword `romance`

It explicitly refuses to apply the override if the authored source semantics change, preventing a stale transformation from silently broadening/narrowing future catalogues.

Regression coverage proves:

- missing historical `romantic comedy` keyword does not drop the lane when exact `romance` is available;
- compiled filters retain `16,35` + `ja` + resolved `romance` ID;
- if `romance` is also unavailable, the lane still fails closed.

## Final cutover bundle

Use only:

- `Moonfin_DiscoveryV2_Server_Cutover_fd06ec560235_v3.zip`
- bundle SHA-256 `73f1337b175ab793d83510baa87b49f3b355fd42aac44ae8c9e9b1f9517bc707`
- deployment script SHA-256 `0195acdeee144ceb08f65a1f5d6c2e652bfb13a63b681878298a8736afe9af67`
- exact #139 Web tar SHA-256 remains `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`.

Local bundle extraction, Bash syntax and embedded Web hash: PASS.

The script pins the #139 generator/catalogue semantics plus repository compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`. On `docker01`, before any authoritative live change it:

1. verifies exact Web and official-matching Moonbase DLL hashes;
2. retrieves pinned tooling;
3. `py_compile`s it and runs the repository catalogue regression test suite;
4. confirms Jellyfin sees Moonfin 2.2.0 in safe pre-cutover `Active` or `Restart` state;
5. force-compiles against current Jellyfin/Seerr metadata;
6. requires schema v2, **481/486**, exactly **5 semantic drops** and **0 provider drops**;
7. stages `/srv/appdata/moonfin/web/releases/fd06ec560235` and the canonical catalogue;
8. creates timestamped rollback data;
9. sets `web/current -> releases/fd06ec560235`;
10. adds `MOONFIN_WEB_ROOT=/moonfin-web/current` and read-only `/srv/appdata/moonfin/web:/moonfin-web` to authoritative Compose;
11. validates Compose and recreates only Jellyfin;
12. requires Moonfin 2.2.0 `Active` and verifies Seerr config, Web routes and served 481-lane catalogue;
13. automatically restores previous Compose/bundled-Web state on any post-edit failure.

Rollback after a checkpoint exists:

`sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

## Locked completion evidence — do not redo

- shared catalogue/compiler/semantics: 486 authored / 481 accepted active reference.
- Web: `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, #120 / `34326151119` GREEN.
- Android TV/Google TV: `15ccc28b84727543ad714ef19dd318f907d1a1d8`, #128 / `34429841034` GREEN.
- Smart-TV/webOS accepted Discovery parity: `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, #52 / `34439022624` GREEN; 468/481 executable intentionally.
- cross-platform parity/recommendation: `e654668f89af49470df417d4fcc444e73c53121e`, #132 / `34439296054` GREEN.
- whole-product release: `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, #139 / `34571653740` GREEN.
- stable update detector/protocol complete.
- stable bases: Core 2.5.1, Moonbase 2.2.0, Smart-TV 2.8.2.

## Physical acceptance

Still NOT STARTED. Begin only after server cutover is green.

Locked order:

1. Android mobile
2. LG OLED65C6PSA / webOS
3. Android TV / Google TV

Android beta identity `org.moonfin.androidtv.beta` / `Moonfin Beta`; production remains `org.moonfin.androidtv`. Never replace signing material under `/srv/appdata/moonfin/android-signing`.

Smart-TV accepted/live baseline remains 2.7.0 until physical acceptance. Validated 2.8.2 merge `44a72276e87f611791348fbd11584e6aff56641a`, artifact `10192446254`, IPK SHA-256 `75be2fedecbd3b503a5f74d2c2fad403e9ac0bede4c842d4da87bd80cae2460a`; rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e` remains untouched.

## Exact next action

Transfer and run `Moonfin_DiscoveryV2_Server_Cutover_fd06ec560235_v3.zip` (SHA-256 `73f1337b175ab793d83510baa87b49f3b355fd42aac44ae8c9e9b1f9517bc707`). If its pre-Compose live catalogue gate is anything other than 481/486 with exactly 5 semantic drops and 0 provider drops, stop and diagnose only that gate. If it passes, record live catalogue SHA, Web release pointer, Moonfin 2.2.0 `Active` result and rollback directory, then begin Android mobile physical acceptance.
