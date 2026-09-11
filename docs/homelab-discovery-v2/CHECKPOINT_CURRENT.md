# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed GitHub/code stages must not be restarted without current fault evidence.

## Status — catalogue gate green; live blocker is duplicate Moonbase versions

Client/code work remains complete. Physical acceptance is still blocked only by the server cutover.

Cutover v3 proved the repaired live catalogue is correct:

- authored `486`
- compiled `481`
- semantic drops `5`
- provider drops `0`
- tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20.

The cutover then reached the Jellyfin recreate and rolled Compose back after failure. The later narrow log check proved the failure domain is Moonbase plugin duplication, not catalogue generation or slow Jellyfin startup.

## Current live evidence

- Jellyfin `10.11.11` container is running; `/System/Info/Public` = HTTP 200.
- effective Compose contains no `MOONFIN_WEB_ROOT` or `/moonfin-web`; v3 Compose rollback succeeded.
- `/Moonfin/Web/` currently = HTTP 500.
- startup log loads both `/config/data/plugins/Moonbase_2.1.0.0/Moonfin.Server.dll` and `/config/data/plugins/Moonbase_2.2.0.0/Moonfin.Server.dll`.
- Jellyfin loads `Moonbase 2.1.0.0`, then creation of the 2.2 plugin fails because the two separate load contexts each define `Moonfin.Server.PluginConfiguration`; XML configuration handling throws `InvalidCastException`.
- Jellyfin disables the 2.2 plugin directory for that startup.
- both assemblies register `MoonfinWebController.GetWebAsset`, so `/Moonfin/Web/` throws `AmbiguousMatchException` due multiple matching endpoints.
- Jellyfin core startup completes in about 8 seconds, therefore the old 60-second wait was not the root cause.
- rollback record from v3: `/srv/appdata/moonfin/rollback/server-migration-20260911-215908`.

Do **not** reinstall Moonbase. The 2.2.0 DLL is already exact official payload SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`.

## Semantic repair — locked

Compiler/test source `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`.

The removed historical `romantic comedy=380334` keyword is not replaced with narrower `lighthearted romantic comedy=380026`. The Anime Romantic Comedy lane instead compiles as Japanese Animation + Comedy plus exact broad `romance`; fail-closed behaviour remains.

Workflow checkpoint: #145 / `34598425336` at `ee00cb...`; long-CI rule applies, so do not continuously poll it.

## Exact release inputs

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Web SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`, Moonfin 2.5.1 build 30000149.
- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- signing material under `/srv/appdata/moonfin/android-signing` remains untouched.

## Prepared v4 recovery + cutover

Use only `Moonfin_DiscoveryV2_Server_Cutover_fd06ec560235_v4.zip`.

- bundle SHA-256 `fdb6c0e9d04dcadbe2a3dfe2e29143b922282676fd3047b70a13e374224a950c`
- deploy script SHA-256 `c0b0d6efa8a204e83323fb0644f9330c9f1d4747f80bb8e76c5d59f8ed8a6a10`
- local ZIP integrity + `bash -n`: PASS.

V4 first performs a bounded Moonbase dedup prerequisite repair:

- refuses to proceed if the external Web Compose override is unexpectedly active;
- verifies the trusted 2.2 DLL;
- moves only superseded `Moonbase_2.1.0.0` out of the live Jellyfin plugin root into `/srv/appdata/moonfin/rollback/moonbase-dedup-<timestamp>/`;
- preserves configuration and a manual legacy restore script;
- recreates only Jellyfin;
- requires no 2.1 assembly load, no duplicate-type collision, 2.2 `Active`, and `/Moonfin/Web/` HTTP 200;
- permits one additional controlled restart only if 2.2 is reported `Restart` after the update task.

After that repair, V4 runs the normal pinned semantic tests and requires **481/486, 5 semantic drops, 0 provider drops**. It safely replaces only the verified inactive `fd06ec560235` Web staging copy left by v3; active/mismatched releases are refused. It then performs the normal external-Web cutover. Readiness windows are 120 seconds, and rollback health is explicitly checked.

The dedup repair is not automatically undone if a later cutover step fails because the dual-plugin layout is now proven broken; the archived 2.1 copy remains available only for deliberate manual restoration.

## Locked completion evidence — do not redo

- shared catalogue/compiler semantics: COMPLETE, 486 authored / 481 accepted.
- Web source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet #120 / `34326151119` GREEN.
- Android TV/Google TV #128 / `34429841034` GREEN.
- Smart-TV/webOS parity #52 / `34439022624` GREEN.
- cross-platform parity/recommendation #132 / `34439296054` GREEN.
- whole-product release #139 / `34571653740` GREEN.

## Physical acceptance

Not started. Begin only after server cutover passes.

Locked order: Android mobile -> LG OLED65C6PSA/webOS -> Android TV/Google TV.

## Exact next action

Run v4 once. The required progression is: Moonbase dedup gate green -> catalogue 481/486, 5/0 green -> external-Web cutover green. If it passes, update this checkpoint with the live catalogue SHA, Web release pointer, Moonbase 2.2 active state and rollback locations, then begin Android mobile physical acceptance.
