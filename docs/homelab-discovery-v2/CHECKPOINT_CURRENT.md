# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-12 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed code/platform stages must not be restarted without current fault evidence.

## Status

All pre-cutover server prerequisites are green. External Discovery Web cutover is **not yet active**. The exact next action is the verified v6 cutover package.

### Moonbase / Seerr prerequisite — complete

Verified live after the successful field-level migration:

- only `Moonbase_2.2.0.0` is live; superseded 2.1 remains archived outside the plugin root;
- Jellyfin public API HTTP 200;
- Moonfin Web HTTP 200 after full Moonbase readiness;
- `SeerrEnabled=true` and `SeerrUrl` survived Moonbase 2.2 restart;
- existing 2.2 webhook secret remained unchanged;
- Jellyfin -> Seerr HTTP 200;
- authenticated Moonbase -> Seerr proxy PASS;
- recovery checkpoint `/srv/appdata/moonfin/rollback/moonbase-seerr-field-migration-20260912-014055`.

Do not restore the full August 2026 Moonfin XML; it predates Moonbase 2.2. If recovery is needed, only the two Seerr fields may be migrated into the current clean 2.2 XML.

Readiness rule: `/System/Info/Public` alone is insufficient. Any restart/rollback must wait for **both** `/System/Info/Public` and `/Moonfin/Web/` HTTP 200.

### Locked catalogue result — do not redo

- 486 authored / 481 compiled
- exactly 5 semantic drops / 0 provider drops
- tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20
- semantic compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`
- workflow #145 / `34598425336`: GREEN

### V6 cutover artefact

`Moonfin_DiscoveryV2_Server_Cutover_fd06ec560235_v6.zip`

- bundle SHA-256 `6f20fa92520c07627b04f3e078978990c5a31e074efbf174df1205e3640f468b`
- deploy script SHA-256 `f75dfa10d3259bac0b6d049caf115ef90741e4090895e803fee294ac7c641ef8`
- embedded #139 Web SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- ZIP integrity PASS; shell syntax PASS; embedded Web hash PASS.

V6 skips the unnecessary prerequisite restart when 2.1 is already absent, uses full Moonbase readiness after restarts/rollbacks, retains surgical Seerr recovery only as a fallback, and adds a final authenticated Seerr proxy gate.

## Exact release inputs

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Web: Moonfin 2.5.1 build 30000149, SHA above.
- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- signing material remains untouched.

## Exact next action

Run v6 and require:

- current Moonbase 2.2/Seerr baseline accepted without an unnecessary prerequisite recreate;
- catalogue `481/486`, semantic drops `5`, provider drops `0`;
- exact Web release staged and authoritative Compose patch validated;
- controlled Jellyfin recreate reaches full Moonbase readiness;
- Web/version/catalogue endpoints HTTP 200 and served catalogue bytes equal canonical;
- Moonbase 2.2 Active, Seerr config enabled, authenticated Moonbase -> Seerr proxy PASS;
- final `=== CUTOVER PASSED ===`.

If green, immediately checkpoint the live catalogue SHA/release pointer/rollback record and proceed to Android mobile physical acceptance. Do not revisit completed platform implementation.
