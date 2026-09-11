# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-12 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed code/platform stages must not be restarted without current fault evidence.

## Status

Catalogue semantics are green. Moonbase deduplication is green. External Discovery Web cutover is not active. The remaining prerequisite is a **field-level Seerr migration into the valid Moonbase 2.2 config**.

### Locked catalogue result — do not redo

- 486 authored / 481 compiled
- exactly 5 semantic drops / 0 provider drops
- tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20
- semantic compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`
- workflow #145 / `34598425336`: GREEN

### Moonbase deduplication — complete

Only `Moonbase_2.2.0.0` is live. Superseded 2.1 remains archived outside the plugin root. Current baseline after rollback is healthy: Jellyfin public API 200, Moonfin Web 200, Jellyfin -> `seerr:5055` 200.

Do **not** restore/reinstall Moonbase 2.1.

### Seerr recovery diagnosis

The exact source backup `/srv/appdata/moonfin/rollback/server-migration-20260911-215908/Moonfin.Server.xml.before` is 15,754 bytes, dated 2026-08-13, and contains `SeerrEnabled=true` plus a non-empty `SeerrUrl`.

The current clean Moonbase 2.2 XML is 1,183 bytes and contains `SeerrEnabled=false`, no `SeerrUrl`, and its own webhook secret. Its saved recovery copy is:

`/srv/appdata/moonfin/rollback/moonbase-config-direct-recovery-20260912-005932/Moonfin.Server.xml.current-before-direct-recovery`

The 00:59 whole-file restore of the August XML failed validation and automatically rolled back. Both Jellyfin restarts loaded Moonbase 2.2 cleanly; current Web and Seerr network endpoints are healthy.

Important correction: the August XML predates Moonbase 2.2.0 (released 2026-08-28). The earlier v3 compile through Seerr occurred before the plugin restart while the old Moonbase instance was still serving requests, so it did not prove whole-file compatibility with 2.2.

**Do not restore the whole August XML again.**

## Exact release inputs

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Web SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`; Moonfin 2.5.1 build 30000149.
- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- signing material remains untouched.

## Exact next action

Back up the current 2.2 XML, stop only Jellyfin, parse both XML files, and copy **only** `SeerrEnabled=true` and `SeerrUrl` from the August source into the current valid 2.2 XML. Preserve the current webhook secret and every other 2.2 setting. Restart Jellyfin and require:

- Jellyfin ready;
- Moonfin Web HTTP 200;
- Jellyfin -> Seerr HTTP 200;
- only Moonbase 2.2 live;
- authenticated `/Moonfin/Seerr/Config` says enabled and URL present.

If any gate fails, restore the saved 2.2 XML automatically.

After this passes, v6 must implement the same field-level migration rather than v5's full-config recovery. Then finish the already-proven 481/486 / 5 / 0 server cutover and proceed to Android mobile physical acceptance.
