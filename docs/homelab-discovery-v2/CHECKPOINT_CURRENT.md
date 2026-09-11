# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed code/platform stages must not be restarted without current fault evidence.

## Status — catalogue green; Moonbase dedup green; Seerr config recovery next

Physical acceptance is still blocked only by the live server cutover.

### Locked catalogue result

Cutover v3 proved the repaired live catalogue:

- authored `486`
- compiled `481`
- semantic drops `5`
- provider drops `0`
- tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20.

Semantic compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`; workflow **#145 / `34598425336` GREEN**. Do not revisit the Romantic Comedy fix.

### Moonbase duplicate repair — complete

V4 archived superseded Moonbase 2.1 outside the live plugin root:

`/srv/appdata/moonfin/rollback/moonbase-dedup-20260911-221439/Moonbase_2.1.0.0`

V4 then verified:

- 9 repository semantic tests PASS;
- Jellyfin restarted cleanly;
- only `Moonbase 2.2.0.0 / Active` reported;
- no duplicate-type collision;
- `/Moonfin/Web/` HTTP 200.

Do **not** restore/reinstall Moonbase 2.1. The exact official 2.2 DLL remains SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`.

### Current blocker — Seerr plugin config

V4 stopped at live compilation because `/Moonfin/Seerr/Config` now reports disabled/unconfigured.

The v3 cutover had successfully used Seerr before its bad dual-load restart. Its rollback record is `/srv/appdata/moonfin/rollback/server-migration-20260911-215908`; the deployment script backed up `Moonfin.Server.xml` but the old rollback script restored only Compose/Web, not the plugin XML. The current plugin config can therefore be reset/defaulted even though Moonbase 2.2 itself is now healthy.

Official Moonbase 2.2.0 uses `SeerrEnabled` + `SeerrUrl` and can migrate legacy `Jellyseerr*` values. Do not create or print new credentials.

## Exact release inputs

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Web SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`, Moonfin 2.5.1 build 30000149.
- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- `/srv/appdata/moonfin/android-signing` untouched.

## Prepared v5 recovery + cutover

Use only:

`Moonfin_DiscoveryV2_Server_Cutover_fd06ec560235_v5.zip`

- bundle SHA-256 `c67d6529b70f0cacb39116c1acfc129250de17a7e7697810179677d17023cc30`
- deploy script SHA-256 `aaa7198bceb5a67aba5da0dcb3d541f2f50213acf72510de13569dc250de5d3c`
- embedded Web SHA-256 unchanged: `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- ZIP integrity PASS; Bash syntax PASS; synthetic config-selector test PASS.

V5 keeps the successful Moonbase dedup. If Seerr is not configured, it backs up the current plugin XML, selects only a prior `server-migration-*/Moonfin.Server.xml.before` that actually contains enabled Seerr/Jellyseerr and a non-empty URL, restores it while Jellyfin is stopped, then requires Moonbase 2.2 Active + Moonfin Web 200 + Seerr config enabled. Secrets and URL contents are not printed. If config recovery fails, the pre-repair current config is restored.

After that V5 runs the existing **481/486 / 5 / 0** catalogue gate, replaces only the verified inactive `fd06ec560235` staging copy left by v3, performs the external-Web Compose cutover, and verifies live Moonbase/Seerr/Web/catalogue. Future cutover rollback also restores `Moonfin.Server.xml`.

## Locked completion evidence — do not redo

- shared catalogue/compiler semantics complete.
- Web source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet #120 / `34326151119` GREEN.
- Android TV/Google TV #128 / `34429841034` GREEN.
- Smart-TV/webOS parity #52 / `34439022624` GREEN.
- cross-platform parity/recommendation #132 / `34439296054` GREEN.
- whole-product release #139 / `34571653740` GREEN.
- semantic repair #145 / `34598425336` GREEN.

## Physical acceptance

Not started. Begin only after server cutover passes.

Locked order: Android mobile -> LG OLED65C6PSA/webOS -> Android TV/Google TV.

## Exact next action

Run v5 once. Required progression: Moonbase 2.2 clean/Active -> Seerr config recovery PASS -> catalogue 481/486 with 5 semantic and 0 provider drops -> external-Web cutover PASS. On success, record live catalogue SHA, Web release pointer, Moonbase state and rollback paths, then start Android mobile physical acceptance.
