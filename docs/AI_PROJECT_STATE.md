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
- superseded `Moonbase_2.1.0.0` is absent from the live plugin root and archived under `/srv/appdata/moonfin/rollback/moonbase-dedup-20260911-221439/`.
- Jellyfin reports only `Moonbase 2.2.0.0 / Active` and `/Moonfin/Web/` is HTTP 200.
- official-matching Moonbase 2.2 DLL remains SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`.
- external Discovery Web cutover is not active; v5 stopped before catalogue compilation/Compose/Web activation.
- `/srv/appdata/moonfin/android-signing` remains protected/untouched.

### Current blocker — restore known-good Moonbase Seerr config

The secret-safe scan after v5 proved the configuration was not lost. V5's selector is defective.

Exact evidence:

- current `/srv/appdata/jellyfin/data/plugins/configurations/Moonfin.Server.xml` has `SeerrEnabled=false`;
- exact pre-v3 rollback `/srv/appdata/moonfin/rollback/server-migration-20260911-215908/Moonfin.Server.xml.before` has `SeerrEnabled=true` and a non-empty `SeerrUrl`;
- several older pre-discovery/pre-API Moonfin XML backups also contain enabled Seerr configuration;
- Jellyfin and Seerr are both on Docker network `media`;
- Jellyfin resolves `seerr` to the Seerr container and `http://seerr:5055/api/v1/status` returns HTTP 200 from inside Jellyfin.

Therefore do **not** recreate credentials, alter Seerr networking, reinstall Moonbase, or restore Moonbase 2.1.

Next action is a controlled direct recovery of the exact pre-v3 XML: back up the current XML, stop only Jellyfin, restore `/srv/appdata/moonfin/rollback/server-migration-20260911-215908/Moonfin.Server.xml.before`, start Jellyfin, and require Jellyfin ready + Moonfin Web 200 + retained enabled Seerr config + Jellyfin->Seerr HTTP 200. If validation fails, restore the pre-repair current XML.

After that, correct the v5 recovery selector in a v6 cutover bundle rather than blindly rerunning v5.

## Catalogue / semantic repair — complete

The live catalogue gate is locked and proven:

- authored `486`
- compiled `481`
- semantic drops `5`
- provider drops `0`
- tab counts: For You 16, Movies 129, Series 138, Anime 158, New/Upcoming 20, Lists 20.

Compiler/test source: `ee00cb3867d9c294bae5759d6d19d5d5bd31dade`; full Discovery workflow #145 / `34598425336` is GREEN. Do not revisit this work.

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

1. Controlled restore of the exact pre-v3 Moonfin config with an automatic rollback on failed validation.
2. Verify Moonbase 2.2 remains the only live Moonbase, Moonfin Web HTTP 200, Seerr enabled/config retained, and Jellyfin -> Seerr HTTP 200.
3. Correct the v5 config-selector defect and prepare v6; do not blindly rerun v5.
4. Run the already-proven catalogue gate **481/486 / 5 / 0** and finish external-Web cutover.
5. Record live catalogue SHA/release pointer/rollback paths, then begin Android mobile physical acceptance.
