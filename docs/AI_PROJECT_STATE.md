# AI Project State

**Updated:** 2026-09-12 Australia/Adelaide

## Current objective

Complete the **pre-acceptance live server cutover** for Home Lab Moonfin Discovery v2, then begin physical acceptance in the locked order: Android mobile -> LG webOS -> Android TV/Google TV.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`.

GitHub/current repo is authoritative. Completed client/platform work must not be reopened without current defect evidence.

## Current live state

All server prerequisites are now green. External Discovery Web cutover is **not yet active**.

Verified live on `docker01` after the successful surgical Seerr migration:

- Jellyfin `10.11.11`; authoritative Compose remains `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- only live Moonbase directory is `Moonbase_2.2.0.0`; superseded 2.1 remains archived outside the plugin root and must not be restored/reinstalled.
- `/System/Info/Public` HTTP 200 and `/Moonfin/Web/` HTTP 200 after full Moonbase readiness.
- `SeerrEnabled=true` and `SeerrUrl` were migrated into the clean Moonbase 2.2 XML; both survived restart.
- existing Moonbase 2.2 webhook secret was preserved unchanged.
- Jellyfin -> `http://seerr:5055/api/v1/status` HTTP 200.
- authenticated Moonbase -> Seerr proxy query passed with the expected response shape.
- successful migration rollback checkpoint: `/srv/appdata/moonfin/rollback/moonbase-seerr-field-migration-20260912-014055`.
- `/srv/appdata/moonfin/android-signing` remains untouched.

Important readiness correction: `/System/Info/Public` can return 200 before Moonbase Web is ready. Every cutover/rollback readiness gate must require **both** Jellyfin public API 200 and `/Moonfin/Web/` 200. The prior 503 during field migration was a verifier race, not a Moonbase Web configuration fault.

Do not restore the full 2026-08-13 Moonfin XML. It is a Moonbase 2.1-era source and is used only as the source of the two Seerr fields if recovery is ever needed again.

## V6 final cutover package — prepared

Local generated artefact:

`Moonfin_DiscoveryV2_Server_Cutover_fd06ec560235_v6.zip`

- bundle SHA-256 `6f20fa92520c07627b04f3e078978990c5a31e074efbf174df1205e3640f468b`
- deploy script SHA-256 `f75dfa10d3259bac0b6d049caf115ef90741e4090895e803fee294ac7c641ef8`
- embedded exact #139 Web tar SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- ZIP integrity PASS; `bash -n` PASS; embedded Web hash PASS.

V6 changes only the recovery/readiness mechanics around the already-proven deployment:

- skips an unnecessary prerequisite Jellyfin recreate when Moonbase 2.1 is already absent;
- requires full Jellyfin + Moonfin Web readiness after any restart and after rollback;
- if Seerr recovery is ever needed, migrates only `SeerrEnabled` and `SeerrUrl` into the current clean 2.2 XML and preserves the current webhook secret/all other 2.2 settings;
- post-cutover verification includes an authenticated Moonbase -> Seerr proxy request.

Catalogue/compiler, exact Web candidate, Compose patch and release layout remain unchanged from the proven cutover path.

## Catalogue / semantic repair — complete

Locked live catalogue result:

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

## Completed — do not redo

- shared Discovery catalogue/compiler semantics: 486 authored / 481 accepted.
- Web source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet #120 / `34326151119` GREEN.
- Android TV/Google TV #128 / `34429841034` GREEN.
- Smart-TV/webOS parity #52 / `34439022624` GREEN.
- cross-platform parity/recommendation #132 / `34439296054` GREEN.
- whole-product release #139 / `34571653740` GREEN.
- semantic repair #145 / `34598425336` GREEN.
- Moonbase duplicate-load repair: COMPLETE.
- Moonbase 2.2 Seerr field migration: COMPLETE and proxy-verified.

## Exact next actions

1. Run the verified v6 package. It should accept the current 2.2/Seerr baseline without another prerequisite restart.
2. Require catalogue gate **481/486 / 5 semantic / 0 provider**, stage exact Web candidate, create rollback checkpoint, patch only the authoritative Jellyfin Compose, and recreate only Jellyfin.
3. Require full post-recreate Moonbase readiness, all Web/catalogue HTTP gates, Moonbase 2.2 Active, Seerr config enabled, and authenticated Moonbase -> Seerr proxy PASS.
4. If cutover passes, record the live catalogue SHA, release pointer and rollback record immediately; then begin Android mobile physical acceptance.
