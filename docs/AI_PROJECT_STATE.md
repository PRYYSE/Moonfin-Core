# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

Complete the **pre-acceptance live server cutover** for Home Lab Moonfin Discovery v2, then begin physical acceptance in the locked order: Android mobile -> LG webOS -> Android TV/Google TV.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`.

GitHub/client implementation remains complete. Do not reopen completed platform work without current defect evidence.

## Current live blocker — Moonbase duplicate load

The semantic/catalogue problem is resolved. Cutover v3 successfully compiled and gated the live catalogue at **481/486**, **5 semantic drops**, **0 provider drops**.

The later Jellyfin recreate exposed the actual server prerequisite fault: both plugin directories were present and Jellyfin loaded both assemblies:

- `/srv/appdata/jellyfin/data/plugins/Moonbase_2.1.0.0/Moonfin.Server.dll`
- `/srv/appdata/jellyfin/data/plugins/Moonbase_2.2.0.0/Moonfin.Server.dll`

This causes `Moonfin.Server.PluginConfiguration` type collisions between 2.1 and 2.2, disables the 2.2 plugin instance, and registers `MoonfinWebController.GetWebAsset` twice. Result: Jellyfin core is healthy but `/Moonfin/Web/` returns HTTP 500 with `AmbiguousMatchException`.

Current post-rollback evidence:

- Jellyfin container: running, exit 0.
- `/System/Info/Public`: HTTP 200.
- `/Moonfin/Web/`: HTTP 500.
- effective Compose: no `MOONFIN_WEB_ROOT` / `/moonfin-web` override, so the v3 Compose rollback succeeded.
- startup itself is fast (~8 seconds); the previous failure was not a 60-second startup timeout problem.
- logs load both Moonfin.Server 2.1.0.0 and 2.2.0.0; 2.2 then fails with `InvalidCastException` and is disabled.
- the duplicate controller route directly explains the current Moonfin Web HTTP 500.

Do **not** reinstall Moonbase. The installed 2.2.0 DLL already matches the official payload SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`.

## Root semantic repair — complete

Compiler/test source: `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`.

Historical TMDb keyword `romantic comedy=380334` disappeared; current search only returns narrower `lighthearted romantic comedy=380026`, which is deliberately not substituted.

`anime-theme-romantic-comedy` now compiles from broad stable semantics: `discoverTv`, genre `16,35` (Animation + Comedy), language `ja`, `voteCountGte=5`, exact `romance` keyword. It still fails closed if `romance` disappears.

Full Discovery workflow checkpoint: #145 / `34598425336`, source `ee00cb...`. Long-CI rule applies: do not poll continuously.

## Exact release candidate

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Web SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`; Moonfin `2.5.1`, build `30000149`.
- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- `/srv/appdata/moonfin/android-signing` remains protected/untouched.

## Prepared recovery + cutover bundle v4

Use only `Moonfin_DiscoveryV2_Server_Cutover_fd06ec560235_v4.zip`.

- bundle SHA-256 `fdb6c0e9d04dcadbe2a3dfe2e29143b922282676fd3047b70a13e374224a950c`
- deploy script SHA-256 `c0b0d6efa8a204e83323fb0644f9330c9f1d4747f80bb8e76c5d59f8ed8a6a10`
- embedded Web tar remains exact #139 SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`.
- local ZIP integrity and `bash -n`: PASS.

V4 performs one bounded prerequisite repair before cutover:

1. requires rolled-back Compose with no external Moonfin Web override;
2. verifies the exact trusted Moonbase 2.2.0 DLL;
3. archives `Moonbase_2.1.0.0` outside the Jellyfin plugin root under `/srv/appdata/moonfin/rollback/moonbase-dedup-<timestamp>/` instead of deleting it;
4. preserves plugin configuration and writes a manual legacy-restore script;
5. recreates only Jellyfin and requires no 2.1 assembly load, no duplicate-type collision, Moonbase 2.2.0 `Active`, and `/Moonfin/Web/` HTTP 200;
6. permits at most one additional restart if Jellyfin reports 2.2.0 `Restart` after its update task;
7. then runs the existing pinned semantic tests/compile gate and requires **481/486 / 5 semantic drops / 0 provider drops**;
8. safely removes/re-stages only the verified **inactive** `fd06ec560235` Web release left by v3; it refuses to replace an active or provenance-mismatched release;
9. performs the normal external-Web Compose cutover and post-verification;
10. uses 120-second bounded readiness windows and verifies rollback health rather than claiming rollback success without evidence.

The plugin dedup is not automatically reversed on later cutover failure because the old dual-plugin layout is now proven broken. The archived 2.1 copy remains available for explicit manual restoration if genuinely needed.

## Completed — do not redo

- shared Discovery catalogue/compiler semantics: 486 authored / 481 accepted.
- Web source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet #120 / `34326151119` GREEN.
- Android TV/Google TV #128 / `34429841034` GREEN.
- Smart-TV/webOS Discovery parity #52 / `34439022624` GREEN.
- cross-platform parity/recommendation #132 / `34439296054` GREEN.
- whole-product release #139 / `34571653740` GREEN.
- stable bases: Core 2.5.1, Moonbase 2.2.0, Smart-TV 2.8.2.

## Exact next action

Run v4 once. Require the Moonbase dedup prerequisite gate to show only 2.2.0 loading cleanly and `/Moonfin/Web/` HTTP 200, then require the existing catalogue gate **481/486 / 5 / 0** and final cutover verification. If v4 passes, record live catalogue SHA, Web release pointer, active Moonbase state and rollback paths, then begin Android mobile physical acceptance.
