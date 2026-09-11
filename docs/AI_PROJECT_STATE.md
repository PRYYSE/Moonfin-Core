# AI Project State

**Updated:** 2026-09-12 Australia/Adelaide

## Current objective

Complete the **pre-acceptance live server cutover** for Home Lab Moonfin Discovery v2, then begin physical acceptance in the locked order: Android mobile -> LG webOS -> Android TV/Google TV.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`.

GitHub/client implementation remains complete. Do not reopen completed platform work without current defect evidence.

## Current live state

The catalogue/semantic issue and duplicate-Moonbase issue are resolved.

Verified live server state after v4/v5 prerequisite repair:

- Jellyfin `10.11.11` on `docker01` / `192.168.50.12`.
- authoritative Compose remains `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- superseded `Moonbase_2.1.0.0` is no longer in the live plugin root; archived at `/srv/appdata/moonfin/rollback/moonbase-dedup-20260911-221439/Moonbase_2.1.0.0`.
- Jellyfin reports only `Moonbase 2.2.0.0 / Active`.
- `/Moonfin/Web/` returns HTTP 200 after deduplication.
- official-matching 2.2 DLL remains SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`.
- do **not** restore Moonbase 2.1 and do **not** reinstall Moonbase.
- external Discovery Web cutover is not active; v5 stopped before any new Compose/Web activation.
- `/srv/appdata/moonfin/android-signing` remains protected/untouched.

### Current blocker — locate/restore Moonbase Seerr configuration

V4 reached the live compiler only after Moonbase 2.2 was cleanly active, but compilation failed because Moonbase reports Seerr disabled/unconfigured.

V5 attempted automatic recovery from prior `server-migration-*/Moonfin.Server.xml.before` records and stopped safely with:

`ERROR: No known-good pre-cutover Moonfin config with enabled Seerr was found in server-migration rollback records`

This does **not** establish that the old Seerr settings are gone. V3 successfully compiled through Seerr before its bad dual-plugin restart, so working Seerr configuration/connectivity existed immediately before that restart.

Official Moonbase 2.2 configuration supports both modern `SeerrEnabled` / `SeerrUrl` and legacy `JellyseerrEnabled` / `JellyseerrUrl`; `MigrateLegacyKeys()` migrates legacy values on load. The next action is therefore a secret-safe read-only scan of current/rollback XML plus Jellyfin/Seerr Docker networking before constructing any v6 repair.

Do not ask for Seerr credentials or manually reconfigure the UI unless that scan proves no recoverable configuration exists.

## Catalogue / semantic repair — complete

The live catalogue gate is locked and proven:

- authored `486`
- compiled `481`
- semantic drops `5`
- provider drops `0`
- tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20.

Compiler/test source: `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`.

The removed historical `romantic comedy=380334` keyword is not replaced with narrower `lighthearted romantic comedy=380026`. `anime-theme-romantic-comedy` instead compiles from Japanese Animation + Comedy plus exact broad `romance`; fail-closed behaviour remains.

Full Discovery workflow **#145 / `34598425336` is GREEN** at `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`. Do not revisit this work.

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
- Smart-TV/webOS Discovery parity #52 / `34439022624` GREEN.
- cross-platform parity/recommendation #132 / `34439296054` GREEN.
- whole-product release #139 / `34571653740` GREEN.
- semantic repair #145 / `34598425336` GREEN.
- Moonbase duplicate-load repair: COMPLETE; 2.2 only / Active / Web 200.

## Exact next actions

1. Run one secret-safe read-only scan across current Moonfin config and rollback XML for both `Seerr*` and legacy `Jellyseerr*` fields; do not print URL contents or secrets.
2. Confirm Jellyfin and Seerr share a Docker network and `seerr` resolves/reaches port 5055 from Jellyfin.
3. If a historical enabled config is found, restore only the required configuration after backing up the current XML, restart only Jellyfin, and verify Moonbase 2.2 Active + Web 200 + Seerr enabled.
4. If no recoverable config exists but Docker networking confirms the service endpoint, reconstruct only the non-secret enable/URL fields while preserving every other current setting/secret; verify before continuing.
5. Then rerun the already-proven catalogue gate **481/486 / 5 / 0** and finish external-Web cutover.
6. After server cutover passes, record live catalogue SHA/release pointer/rollback paths and begin Android mobile physical acceptance.
