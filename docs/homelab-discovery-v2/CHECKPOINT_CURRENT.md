# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed GitHub/code stages must not be restarted without current fault evidence.

## Status — first cutover aborted safely; revised semantic-repair cutover prepared

GitHub/client implementation remains COMPLETE. The only current gate before physical client acceptance is the controlled live Jellyfin/Moonbase external-Web/catalogue cutover.

The first cutover attempt stopped at its pre-Compose catalogue regression gate. It did **not** edit Compose, recreate Jellyfin, set `MOONFIN_WEB_ROOT`, switch the external Web root or begin physical acceptance. It did create the unserved compiler output under `/srv/appdata/moonfin/discovery`.

### Current live evidence

- Jellyfin `10.11.11`, container `jellyfin`, LAN `http://192.168.50.12:8096`.
- Compose project `media`: `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- `/srv/appdata/jellyfin:/config`, `/srv/appdata/jellyfin-transcode:/transcode`, `/data/media:/data/media:ro`, `/dev/dri:/dev/dri`.
- PUID 1000 / PGID 1001 / `Australia/Adelaide`; Intel OpenCL Docker mod retained.
- `MOONFIN_WEB_ROOT` remains unset.
- `/Moonfin/Web/` and `/Moonfin/Web/config.json` return 200 from the existing bundled path.
- `/Moonfin/Web/homelab/discovery.catalogue.json` remains unserved/404 because the external cutover did not occur.
- `/srv/appdata/moonfin/web` remains absent.
- `/srv/appdata/moonfin/discovery` now contains the first attempt's generated catalogue/cache/diagnostics only; these are not live-served.
- Protected `/srv/appdata/moonfin/android-signing` remains untouched.
- Seerr container is `seerr` / `ghcr.io/seerr-team/seerr:latest`.

### Moonbase live-state correction

The earlier assumption of custom live Moonbase 2.0.3.1 was stale.

`/srv/appdata/jellyfin/data/plugins/` contains `Moonbase_2.1.0.0` and `Moonbase_2.2.0.0`; 2.2.0 metadata reports `2.2.0.0` / `Active`.

The official 2.2.0 ZIP matched official MD5 `205728081ECEA212F9FEA419FC2EFD77`. Installed-vs-official file comparison: 172 exact, 0 missing, only `meta.json` different. The `Moonfin.Server.dll` is an exact official-payload match at SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`.

Jellyfin `/Plugins` during the first cutover preflight reported:

- `Moonbase` `2.1.0.0` — `Superseded`
- `Moonfin` `2.2.0.0` — `Restart`

Do **not** reinstall Moonbase. The revised deployment accepts `Restart` as the expected pre-cutover pending-restart state, performs the already-planned controlled Jellyfin recreate only after all catalogue/Compose gates are ready, then requires Moonfin 2.2.0 to report `Active` after restart.

## Exact tested deployment inputs

Whole-product #139 / `34571653740` at `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`:

- Web `Moonfin_HomeLab_Web_fd06ec560235.tar.gz`: SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`; Moonfin `2.5.1`, build `30000149`; Discovery catalogue loader path confirmed in compiled JS.
- Android mobile `Moonfin_HomeLab_Android_fd06ec560235.apk`: SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV `Moonfin_HomeLab_AndroidTV_fd06ec560235.apk`: SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.

The old mobile hash beginning `117e633f...` was incorrect; do not use it.

Missing v2 live catalogue compilation tooling was restored in commit `14706f9e5534392be3f1035d41a0253bcc7241d2`.

## First cutover catalogue failure — diagnosed

Forced live semantic resolution produced **480/486**, with **6 semantic drops** and **0 provider drops**:

- `movies-theme-heist-movies` -> `heist movies`
- `series-theme-high-school-teen-drama` -> `high school & teen drama`
- `series-theme-supernatural-mysteries` -> `supernatural mysteries`
- `anime-theme-giant-robots` -> `giant robots`
- `anime-theme-parallel-worlds` -> `parallel worlds`
- `anime-theme-romantic-comedy` -> `romantic comedy`

The accepted legacy cache contained exact historical entries including `high school=6270`, `romantic comedy=380334`, and `supernatural=6152`. Current Seerr/TMDb lookup for keyword ID `380334` returns null; searching `romantic comedy` now returns only keyword ID `380026`, name `lighthearted romantic comedy`.

Do **not** map the broad `Romantic Comedy` lane to the narrower `lighthearted romantic comedy` keyword merely to recover the count.

### Reviewed semantic repair

Preserve the existing lane ID/title `anime-theme-romantic-comedy` but represent it using stable executable components:

- source `discoverTv`
- media type `tv`
- genres `16,35` = Animation + Comedy
- language `ja`
- `voteCountGte=5`
- exact keyword `romance`

`romance` already resolves in the current live semantic pass. This keeps the lane broad/truthful and should restore exactly one lane while leaving the other five reviewed semantic drops fail-closed.

The revised cutover package applies and verifies this one-lane semantic transformation before live compilation. It still requires **481/486**, exactly **5 semantic drops**, and **0 provider drops** before any Compose change.

Revised local bundle evidence:

- bundle `Moonfin_DiscoveryV2_Server_Cutover_fd06ec560235_v2.zip`
- bundle SHA-256 `6317d9517455e5e43a520846fa2e09dae220634d3e288c5ae9f48f2d9af21b35`
- deployment script SHA-256 `06a575ab160db139484e4f1c3456ab6ac467080714728ae9ad753efdd9e0dee3`
- exact #139 Web tar SHA-256 remains `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- bundle extraction, Bash syntax, embedded Web hash and semantic source-patch simulation: PASS

## Revised cutover gate

The revised script:

1. verifies exact Web and official-matching Moonbase DLL hashes;
2. confirms Jellyfin sees Moonfin 2.2.0 in a safe `Active` or `Restart` pre-cutover state without printing credentials;
3. applies and self-verifies only the reviewed Anime Romantic Comedy composite semantic;
4. force-compiles against current Jellyfin/Seerr metadata;
5. requires schema v2, 481/486 lanes, exactly 5 reviewed semantic drops and 0 provider drops;
6. stages `/srv/appdata/moonfin/web/releases/fd06ec560235` and the canonical Discovery catalogue;
7. creates a timestamped rollback checkpoint;
8. sets `web/current -> releases/fd06ec560235`;
9. adds `MOONFIN_WEB_ROOT=/moonfin-web/current` plus read-only `/srv/appdata/moonfin/web:/moonfin-web` to the authoritative Jellyfin Compose service;
10. validates effective Compose and recreates only Jellyfin;
11. requires Moonfin 2.2.0 `Active`, verifies Seerr config, Web routes and the served 481-lane schema-v2 catalogue;
12. automatically restores the old Compose/bundled-Web path on any failure after the authoritative config boundary.

Rollback command once checkpoint creation has occurred:

`sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

## Locked completion evidence — do not redo

- shared catalogue/compiler/semantics: COMPLETE, 486 authored / 481 accepted active reference.
- Web: source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: #120 / `34326151119` GREEN, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`.
- Android TV/Google TV: #128 / `34429841034` GREEN, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`.
- cross-platform parity/recommendation: #132 / `34439296054` GREEN, source `e654668f89af49470df417d4fcc444e73c53121e`.
- whole-product release gate: #139 / `34571653740` GREEN, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.
- official stable bases currently Core 2.5.1, Moonbase 2.2.0, Smart-TV 2.8.2.

## Physical acceptance

Still NOT STARTED. Begin only after the server cutover gate is green.

Locked order:

1. Android mobile
2. LG OLED65C6PSA / webOS
3. Android TV / Google TV

Android beta identity: `org.moonfin.androidtv.beta` / `Moonfin Beta`; production remains `org.moonfin.androidtv`. Production signing cert `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never replace signing material under `/srv/appdata/moonfin/android-signing`.

Smart-TV accepted/live baseline remains 2.7.0; validated 2.8.2 merge `44a72276e87f611791348fbd11584e6aff56641a`, artifact `10192446254`, IPK SHA-256 `75be2fedecbd3b503a5f74d2c2fad403e9ac0bede4c842d4da87bd80cae2460a`; rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e` remains untouched.

## Exact next action

Transfer and run `Moonfin_DiscoveryV2_Server_Cutover_fd06ec560235_v2.zip` (SHA-256 `6317d9517455e5e43a520846fa2e09dae220634d3e288c5ae9f48f2d9af21b35`). If its catalogue gate does not return 481/486 with exactly 5 semantic drops and 0 provider drops, stop and diagnose only that failing gate. If it passes, record the exact live catalogue SHA, release pointer, post-restart Moonfin status and timestamped rollback directory, then begin Android mobile physical acceptance.
