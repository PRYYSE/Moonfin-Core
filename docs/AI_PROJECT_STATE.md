# AI Project State

**Updated:** 2026-09-12 Australia/Adelaide

## Current objective

Complete the **pre-acceptance live server cutover** for Home Lab Moonfin Discovery v2, then begin physical acceptance in the locked order: Android mobile -> LG webOS -> Android TV/Google TV.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`.

GitHub/current repo is authoritative. Completed client/platform work must not be reopened without current defect evidence.

## Current live state

Catalogue semantics and Moonbase deduplication are complete.

Verified after the failed 00:59 config-recovery attempt auto-rolled back:

- Jellyfin `10.11.11` on `docker01` / `192.168.50.12`.
- authoritative Compose remains `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- only live Moonbase directory is `Moonbase_2.2.0.0`; superseded 2.1 remains archived outside the plugin root.
- `/System/Info/Public` HTTP 200.
- `/Moonfin/Web/` HTTP 200.
- Jellyfin -> `http://seerr:5055/api/v1/status` HTTP 200.
- external Discovery Web cutover is not active.
- `/srv/appdata/moonfin/android-signing` remains untouched.

### Current blocker — migrate Seerr fields into the valid Moonbase 2.2 config

The exact August config backup still contains the old working Seerr settings:

`/srv/appdata/moonfin/rollback/server-migration-20260911-215908/Moonfin.Server.xml.before`

Secret-safe inspection proved:

- source backup: 15,754 bytes, mtime 2026-08-13, `SeerrEnabled=true`, `SeerrUrl` present, webhook secret present;
- current Moonbase 2.2 XML: 1,183 bytes, `SeerrEnabled=false`, `SeerrUrl` absent, webhook secret present;
- direct-recovery backup: `/srv/appdata/moonfin/rollback/moonbase-config-direct-recovery-20260912-005932/Moonfin.Server.xml.current-before-direct-recovery` matches the current 1,183-byte XML exactly.

A controlled whole-file restore of the 15 KB August XML at 00:59 failed validation and automatically restored the previous 2.2 XML. Jellyfin/Moonbase still started cleanly during both restarts; no duplicate-plugin fault returned.

Important correction: the August XML predates Moonbase 2.2.0 (released 2026-08-28). V3's earlier successful Seerr-backed compile happened before the plugin restart while the old Moonbase instance was still serving requests, so it was not proof that the entire August XML was valid under 2.2.

Do **not** restore the full August XML again. The next repair is a field-level migration: start from the current valid 2.2 XML, copy only `SeerrEnabled=true` and `SeerrUrl` from the August backup, preserve the current 2.2 webhook secret and all other settings, restart only Jellyfin, then verify the authenticated Moonbase Seerr config plus Web/Seerr health. Roll back to the saved 1,183-byte XML if any gate fails.

V6 must use this field-level migration approach rather than v5's full-config selector/restore logic.

## Catalogue / semantic repair — complete

Locked live catalogue result:

- authored `486`
- compiled `481`
- semantic drops `5`
- provider drops `0`
- tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20.

Compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`; Discovery workflow #145 / `34598425336` is GREEN. Do not revisit this work.

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
- Moonbase duplicate-load repair: COMPLETE; 2.2 only / Web 200.

## Exact next actions

1. Perform one controlled **field-level** Seerr migration into the current valid Moonbase 2.2 XML; do not restore the whole August file.
2. Restart only Jellyfin and verify: Jellyfin ready, Moonfin Web 200, Jellyfin -> Seerr 200, only Moonbase 2.2 live, and authenticated `/Moonfin/Seerr/Config` reports enabled with a non-empty URL.
3. If successful, build v6 with the same field-level recovery logic and finish the already-proven 481/486 / 5 / 0 server cutover.
4. Record live catalogue SHA/release pointer/rollback paths, then begin Android mobile physical acceptance.
