# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-12 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed code/platform stages must not be restarted without current fault evidence.

## Status

Catalogue semantics are green and Moonbase deduplication is green. The only current blocker before the external-Web server cutover is recovering/confirming Moonbase 2.2 Seerr configuration.

### Locked catalogue result — do not redo

- 486 authored / 481 compiled
- exactly 5 semantic drops / 0 provider drops
- tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20
- semantic compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`
- workflow #145 / `34598425336`: GREEN

### Moonbase deduplication — complete

V4 archived superseded Moonbase 2.1 outside the live plugin root at:

`/srv/appdata/moonfin/rollback/moonbase-dedup-20260911-221439/Moonbase_2.1.0.0`

Verified after deduplication:

- only `Moonbase 2.2.0.0 / Active`
- `/Moonfin/Web/` HTTP 200
- no duplicate `Moonfin.Server.PluginConfiguration` collision
- exact official-matching 2.2 DLL SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`

Do **not** restore/reinstall Moonbase 2.1.

### V5 result — safe stop

V5 preserved the good 2.2-only state but stopped before any new Compose/Web cutover because its automatic config selector found no prior `server-migration-*/Moonfin.Server.xml.before` matching its enabled-Seerr predicate:

`ERROR: No known-good pre-cutover Moonfin config with enabled Seerr was found in server-migration rollback records`

This does not prove the settings are unavailable. V3 successfully compiled through Seerr immediately before the bad dual-plugin restart, so usable Seerr configuration/connectivity existed at that point.

Official Moonbase 2.2 configuration supports current `SeerrEnabled` / `SeerrUrl` and legacy `JellyseerrEnabled` / `JellyseerrUrl`; legacy fields are migrated by the plugin. V5 may therefore have missed the actual historical XML/path/field shape.

External Discovery Web activation is still not active. Signing material under `/srv/appdata/moonfin/android-signing` remains untouched.

## Exact release inputs

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Web SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`; Moonfin 2.5.1 build 30000149.
- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.

## Locked completion evidence — do not redo

- shared catalogue/compiler semantics complete
- Web source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`
- Android mobile/tablet #120 / `34326151119` GREEN
- Android TV/Google TV #128 / `34429841034` GREEN
- Smart-TV/webOS parity #52 / `34439022624` GREEN
- cross-platform parity/recommendation #132 / `34439296054` GREEN
- whole-product release #139 / `34571653740` GREEN
- semantic repair #145 / `34598425336` GREEN

## Exact next action

Run one **read-only, secret-safe** scan of current and rollback Moonfin XML for both `Seerr*` and legacy `Jellyseerr*` fields, and verify Jellyfin/Seerr Docker networking. Redact URL contents and do not expose webhook/session secrets.

Then:

- if an enabled historical config is found, restore only the required config after backing up current XML and verify 2.2 Active + Web 200 + Seerr enabled;
- if no historical enabled config exists but `seerr` networking is healthy, reconstruct only the non-secret enable/URL fields while preserving all other config and secrets;
- once Seerr is verified, rerun the already-proven 481/486 / 5 / 0 compile and finish the external-Web cutover;
- physical acceptance remains locked to Android mobile -> LG webOS -> Android TV/Google TV after server cutover passes.
