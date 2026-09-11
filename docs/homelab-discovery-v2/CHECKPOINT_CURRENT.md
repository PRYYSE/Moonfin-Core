# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-12 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed code/platform stages must not be restarted without current fault evidence.

## Status

Catalogue semantics are green and Moonbase deduplication is green. External Discovery Web cutover is not active. Current blocker is now narrowly identified: restore the existing known-good Moonbase Seerr configuration, then correct v5's defective selector.

### Locked catalogue result — do not redo

- 486 authored / 481 compiled
- exactly 5 semantic drops / 0 provider drops
- tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20
- semantic compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`
- workflow #145 / `34598425336`: GREEN

### Moonbase deduplication — complete

Superseded Moonbase 2.1 is outside the live plugin root under `/srv/appdata/moonfin/rollback/moonbase-dedup-20260911-221439/`.

Verified: only Moonbase 2.2 Active, Moonfin Web HTTP 200, exact official-matching DLL SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`.

Do **not** restore/reinstall Moonbase 2.1.

### V5 selector diagnosis — confirmed

V5 stopped safely before catalogue/Compose/Web cutover claiming no known-good enabled-Seerr XML existed. The subsequent secret-safe scan disproved that selector result:

- current `Moonfin.Server.xml`: `SeerrEnabled=false`;
- exact pre-v3 rollback `/srv/appdata/moonfin/rollback/server-migration-20260911-215908/Moonfin.Server.xml.before`: `SeerrEnabled=true` plus non-empty `SeerrUrl`;
- older pre-discovery/pre-API backups also contain enabled Seerr config;
- Jellyfin and Seerr share Docker network `media`;
- Jellyfin resolves `seerr` and reaches `http://seerr:5055/api/v1/status` with HTTP 200.

Conclusion: configuration is recoverable; networking is healthy; v5's selector is defective. Do not recreate credentials or alter Seerr networking.

## Exact release inputs

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Web SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`; Moonfin 2.5.1 build 30000149.
- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- signing material remains untouched.

## Exact next action

Perform one controlled recovery using the exact pre-v3 XML: back up current XML, stop only Jellyfin, restore `server-migration-20260911-215908/Moonfin.Server.xml.before`, start Jellyfin, and require Jellyfin ready + Moonfin Web 200 + retained enabled Seerr config + Jellyfin->Seerr HTTP 200. Automatically restore the pre-repair current XML if validation fails.

After this passes, correct v5's selector and prepare v6 rather than blindly rerunning v5. Then rerun the already-proven 481/486 / 5 / 0 compile and finish external-Web cutover.

Physical acceptance remains locked to Android mobile -> LG webOS -> Android TV/Google TV after server cutover passes.
