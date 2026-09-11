# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

Complete the **pre-acceptance live server cutover** for Home Lab Moonfin Discovery v2, then begin physical acceptance in the locked order: Android mobile -> LG webOS -> Android TV/Google TV.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`.

GitHub/client implementation remains complete. Do not reopen completed platform work without current defect evidence.

## Current live state

The semantic/catalogue issue is resolved and the duplicate-Moonbase issue is also resolved.

Cutover v3 proved the live catalogue gate at **481/486**, **5 semantic drops**, **0 provider drops**. Its later Jellyfin recreate exposed simultaneous Moonbase 2.1/2.2 loading; v4 fixed that by archiving only the superseded 2.1 plugin directory outside the live plugin root.

V4 verified:

- repository semantic test suite: 9 tests PASS;
- archived Moonbase 2.1 at `/srv/appdata/moonfin/rollback/moonbase-dedup-20260911-221439/Moonbase_2.1.0.0`;
- Jellyfin restarted cleanly;
- Jellyfin `/Plugins`: only `Moonbase 2.2.0.0 / Active`;
- no duplicate `Moonfin.Server.PluginConfiguration` collision;
- `/Moonfin/Web/`: HTTP 200.

V4 then stopped before Compose/Web cutover because live catalogue compilation could no longer obtain the Seerr URL from `/Moonfin/Seerr/Config`; Moonbase reports Seerr disabled/unconfigured.

### Current blocker — Moonbase Seerr configuration

The previous v3 script created `/srv/appdata/moonfin/rollback/server-migration-20260911-215908/Moonfin.Server.xml.before` before the bad dual-load restart, but its rollback script restored Compose/Web only and did **not** restore `Moonfin.Server.xml`. The dual-load failure can therefore leave the current Moonfin plugin config reset/defaulted even after the plugin binaries are repaired.

Official Moonbase 2.2.0 configuration uses `SeerrEnabled` (default false) plus `SeerrUrl`, while retaining legacy `Jellyseerr*` keys for migration. Do not create new credentials or reconfigure Seerr manually unless recovery from the known-good pre-cutover config fails.

Do **not** restore Moonbase 2.1. The dedup repair is correct and should remain.

## Root semantic repair — complete

Compiler/test source: `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`.

Historical TMDb keyword `romantic comedy=380334` disappeared; current search only returns narrower `lighthearted romantic comedy=380026`, which is deliberately not substituted.

`anime-theme-romantic-comedy` compiles from broad stable semantics: `discoverTv`, genre `16,35` (Animation + Comedy), language `ja`, `voteCountGte=5`, exact `romance` keyword. It still fails closed if `romance` disappears.

Full Discovery workflow **#145 / `34598425336` is GREEN** at `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`. Do not re-run this semantic work.

## Exact release candidate

Whole-product #139 / `34571653740`, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`.

- Web SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`; Moonfin `2.5.1`, build `30000149`.
- Android mobile SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- `/srv/appdata/moonfin/android-signing` remains protected/untouched.

## Prepared recovery + cutover bundle v5

Use only `Moonfin_DiscoveryV2_Server_Cutover_fd06ec560235_v5.zip`.

- bundle SHA-256 `c67d6529b70f0cacb39116c1acfc129250de17a7e7697810179677d17023cc30`
- deploy script SHA-256 `aaa7198bceb5a67aba5da0dcb3d541f2f50213acf72510de13569dc250de5d3c`
- embedded exact #139 Web tar SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`.
- ZIP integrity: PASS.
- `bash -n`: PASS.
- synthetic known-good config selection test: PASS.

V5 preserves the successful v4 Moonbase dedup. Before live catalogue compilation it checks `/Moonfin/Seerr/Config`. If already configured it continues unchanged. If not, it:

1. backs up the current `Moonfin.Server.xml` under `rollback/moonbase-config-repair-<timestamp>/`;
2. scans only prior `server-migration-*/Moonfin.Server.xml.before` rollback records;
3. selects the newest XML that actually contains enabled Seerr/Jellyseerr plus a non-empty URL, without printing URL contents, API keys, webhook secrets or credentials;
4. stops only Jellyfin, restores that known-good plugin config, and starts Jellyfin;
5. requires Moonbase 2.2 `Active`, Moonbase 2.1 absent, `/Moonfin/Web/` HTTP 200, and `/Moonfin/Seerr/Config` enabled/configured;
6. automatically restores the pre-repair current config if this repair fails.

After that it runs the unchanged live catalogue gate **481/486 / 5 semantic drops / 0 provider drops**, safely replaces only the verified inactive `fd06ec560235` staging copy left by v3, performs the external-Web Compose cutover, and verifies live routes/catalogue/Seerr/Moonbase.

The cutover rollback path now restores the saved plugin configuration as well as Compose and the Web pointer.

## Completed — do not redo

- shared Discovery catalogue/compiler semantics: 486 authored / 481 accepted.
- Web source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet #120 / `34326151119` GREEN.
- Android TV/Google TV #128 / `34429841034` GREEN.
- Smart-TV/webOS Discovery parity #52 / `34439022624` GREEN.
- cross-platform parity/recommendation #132 / `34439296054` GREEN.
- whole-product release #139 / `34571653740` GREEN.
- semantic repair workflow #145 / `34598425336` GREEN.
- stable bases: Core 2.5.1, Moonbase 2.2.0, Smart-TV 2.8.2.

## Exact next action

Run v5 once. Required progression: Moonbase 2.2 remains clean/Active -> Seerr config recovery PASS -> catalogue **481/486 / 5 / 0** -> external-Web cutover PASS. If it passes, record the live catalogue SHA, Web release pointer, Moonbase 2.2 state and rollback paths, then begin Android mobile physical acceptance.
