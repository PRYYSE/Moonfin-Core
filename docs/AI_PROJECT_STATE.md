# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

Complete the **pre-acceptance live server cutover** for Home Lab Moonfin Discovery v2, then begin physical acceptance in the locked order: Android mobile -> LG webOS -> Android TV/Google TV.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`  
Smart-TV accepted branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`  
Smart-TV validated update candidate: `PRYYSE/Smart-TV` / `update/webos-2.8.2`

GitHub/client implementation remains complete. Do not reopen completed platform work without current defect evidence.

## Current live server state

Host: `docker01` / `192.168.50.12`.

- Jellyfin `10.11.11`, container `jellyfin`, image `lscr.io/linuxserver/jellyfin:latest`.
- Compose project `media` at `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- mounts: `/srv/appdata/jellyfin:/config`, `/srv/appdata/jellyfin-transcode:/transcode`, `/data/media:/data/media:ro`, `/dev/dri:/dev/dri`.
- PUID `1000`, PGID `1001`, TZ `Australia/Adelaide`; Intel OpenCL mod retained.
- `MOONFIN_WEB_ROOT` remains unset.
- existing `/Moonfin/Web/` and `/Moonfin/Web/config.json` return 200; Discovery v2 catalogue route remains unserved.
- `/srv/appdata/moonfin/web` remains absent.
- `/srv/appdata/moonfin/discovery` contains only unserved output from the safely aborted first compile.
- `/srv/appdata/moonfin/android-signing` remains protected/untouched.
- Seerr container `seerr` / `ghcr.io/seerr-team/seerr:latest`.

## Moonbase state

Do **not** reinstall Moonbase.

- installed plugin dirs include `Moonbase_2.1.0.0` and `Moonbase_2.2.0.0`.
- official Moonbase 2.2.0 ZIP MD5 verified: `205728081ECEA212F9FEA419FC2EFD77`.
- official-vs-installed comparison: 172 exact package files, 0 missing, only `meta.json` differs.
- installed `Moonfin.Server.dll` exactly matches official payload SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`.
- Jellyfin `/Plugins` pre-cutover reports `Moonbase 2.1.0.0 / Superseded` and `Moonfin 2.2.0.0 / Restart`.
- final cutover accepts 2.2.0 `Restart` only before the planned recreate and requires 2.2.0 `Active` afterwards.

## Exact release candidate

Whole-product #139 / run `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Web: SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`; Moonfin `2.5.1`, build `30000149`.
- Android mobile: SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV: SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- live compilation tooling restored in `14706f9e5534392be3f1035d41a0253bcc7241d2`.

## Safely aborted first cutover

The first cutover force-compiled current live Seerr/TMDb semantics to **480/486**, with **6 semantic drops** and **0 provider drops**. It aborted before any Compose edit, Web-root switch or Jellyfin recreate.

Drops were `heist movies`, `high school & teen drama`, `supernatural mysteries`, `giant robots`, `parallel worlds`, and `romantic comedy`.

Historical cache had `romantic comedy=380334`; current lookup for 380334 returns null and current `romantic comedy` search returns only `380026 / lighthearted romantic comedy`. That narrower keyword is deliberately not used for the broad lane.

## Root semantic repair

Compiler/test source: `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`.

`anime-theme-romantic-comedy` now compiles from stable broad components:

- `discoverTv`
- genres `16,35` (Animation + Comedy)
- language `ja`
- `voteCountGte=5`
- exact keyword `romance`

The compiler refuses the transformation if the authored source shape changes. Regression coverage proves the lane survives loss of the removed `romantic comedy` keyword when exact `romance` exists, and still fails closed if `romance` also disappears.

Automatic full Discovery workflow checkpoint: **#145 / `34598425336`**, source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`, was `in_progress` when recorded. Do not poll it continuously; inspect this exact run once on the next continuation if needed.

## Final server cutover bundle

Use only:

- `Moonfin_DiscoveryV2_Server_Cutover_fd06ec560235_v3.zip`
- SHA-256 `73f1337b175ab793d83510baa87b49f3b355fd42aac44ae8c9e9b1f9517bc707`
- deploy script SHA-256 `0195acdeee144ceb08f65a1f5d6c2e652bfb13a63b681878298a8736afe9af67`
- embedded #139 Web tar SHA-256 remains `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`.

Local bundle extraction, Bash syntax and Web hash verification: PASS.

Before any authoritative live change, the script retrieves the pinned #139 catalogue source plus compiler/test source `ee00cb...`, runs `py_compile` and the repository catalogue regression suite, confirms a safe Moonfin pre-restart state, force-compiles live semantics, then requires **481/486**, exactly **5 semantic drops**, and **0 provider drops**.

Only after those gates pass does it stage the Web release/catalogue, create rollback data, edit authoritative Compose, set `MOONFIN_WEB_ROOT`, recreate only Jellyfin, and verify Moonfin 2.2.0 `Active`, Seerr config, Web routes and the served 481-lane catalogue. Post-edit failures automatically restore the previous Compose/bundled-Web state.

Rollback after a checkpoint exists:

`sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

## Completed milestones — do not redo

- shared Discovery semantics/catalogue: 486 authored / 481 accepted reference.
- Web: `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, #120 / `34326151119` GREEN.
- Android TV/Google TV: `15ccc28b84727543ad714ef19dd318f907d1a1d8`, #128 / `34429841034` GREEN.
- Smart-TV/webOS Discovery parity: `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, #52 / `34439022624` GREEN; 468/481 executable intentionally.
- cross-platform parity/recommendation: `e654668f89af49470df417d4fcc444e73c53121e`, #132 / `34439296054` GREEN.
- whole-product release: `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, #139 / `34571653740` GREEN.
- stable update detector/protocol complete.
- stable bases: Core 2.5.1, Moonbase 2.2.0, Smart-TV 2.8.2.

## Exact next actions

1. Transfer and run final cutover bundle v3.
2. Require pre-Compose live compile **481/486**, **5 semantic drops**, **0 provider drops**.
3. If it fails, diagnose only that gate; do not weaken semantics.
4. If it passes, record live catalogue SHA, Web release pointer, Moonfin 2.2.0 `Active` result and rollback directory.
5. Begin Android mobile beta physical acceptance side-by-side with production.

## Non-blocking debt

GitHub Action runtime deprecation warnings, future Flutter Built-in Kotlin migration and Smart-TV legacy tooling remain separate maintenance work and are not Discovery v2 acceptance blockers.
