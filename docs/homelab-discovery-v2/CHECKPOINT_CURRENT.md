# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed GitHub/code stages must not be restarted without current fault evidence.

## Status — server cutover prepared, not yet executed

GitHub/code implementation remains COMPLETE. The only current gate before physical client acceptance is the controlled live Jellyfin/Moonbase external-Web/catalogue cutover.

### Read-only live evidence

- Jellyfin `10.11.11`, container `jellyfin`, LAN `http://192.168.50.12:8096`.
- Compose project `media`: `/opt/stacks/media/compose.yaml` + `compose.jellyfin-opencl.yml`.
- `/srv/appdata/jellyfin:/config`, `/srv/appdata/jellyfin-transcode:/transcode`, `/data/media:/data/media:ro`, `/dev/dri:/dev/dri`.
- PUID 1000 / PGID 1001 / `Australia/Adelaide`; Intel OpenCL Docker mod retained.
- `MOONFIN_WEB_ROOT` unset.
- `/Moonfin/Web/` and `/Moonfin/Web/config.json` return 200.
- `/Moonfin/Web/homelab/discovery.catalogue.json` returns 404.
- `/srv/appdata/moonfin/web` and `/srv/appdata/moonfin/discovery` are absent; protected `android-signing/` exists and must remain untouched.
- Seerr container is `seerr` / `ghcr.io/seerr-team/seerr:latest`.

### Moonbase live-state correction

The earlier assumption of custom live Moonbase 2.0.3.1 was stale.

`/srv/appdata/jellyfin/data/plugins/` contains `Moonbase_2.1.0.0` and `Moonbase_2.2.0.0`; 2.2.0 metadata reports `2.2.0.0` / `Active`.

The official 2.2.0 ZIP matched official MD5 `205728081ECEA212F9FEA419FC2EFD77`. Installed-vs-official file comparison: 172 exact, 0 missing, only `meta.json` different. The `Moonfin.Server.dll` is an exact official-payload match at SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`.

**Do not reinstall Moonbase.** The deployment preflight must still confirm Jellyfin actually reports 2.2.0 loaded before any authoritative live change.

## Exact tested deployment inputs

Whole-product #139 / `34571653740` at `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, artifact `10188826944`:

- Web `Moonfin_HomeLab_Web_fd06ec560235.tar.gz`: SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`; Moonfin `2.5.1`, build `30000149`; Discovery catalogue loader path confirmed in compiled JS.
- Android mobile `Moonfin_HomeLab_Android_fd06ec560235.apk`: **corrected** SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV `Moonfin_HomeLab_AndroidTV_fd06ec560235.apk`: SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.

The old mobile hash beginning `117e633f...` was incorrect; do not use it.

Missing v2 live catalogue compilation tooling was restored in commit `14706f9e5534392be3f1035d41a0253bcc7241d2`.

## Prepared cutover gate

A local deployment bundle is prepared and locally verified. Its script:

1. verifies exact Web and official-matching Moonbase DLL hashes;
2. safely confirms loaded Moonbase 2.2.0 through Jellyfin `/Plugins` without printing credentials;
3. compiles against current Jellyfin/Seerr metadata;
4. requires schema v2, 481/486 lanes, 5 reviewed semantic drops and 0 provider drops;
5. stages `/srv/appdata/moonfin/web/releases/fd06ec560235` and `/srv/appdata/moonfin/discovery`;
6. creates a timestamped rollback checkpoint;
7. sets `web/current -> releases/fd06ec560235`;
8. adds `MOONFIN_WEB_ROOT=/moonfin-web/current` plus read-only `/srv/appdata/moonfin/web:/moonfin-web` to the authoritative Jellyfin Compose service;
9. validates effective Compose and recreates only Jellyfin;
10. verifies Jellyfin, Moonbase 2.2.0, Seerr config, Web and the served 481-lane schema-v2 catalogue;
11. automatically restores the old Compose/bundled-Web path on any failure after the authoritative config boundary.

Rollback command once checkpoint creation has occurred:

`sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

## Locked completion evidence — do not redo

- shared catalogue/compiler/semantics: COMPLETE, 486 authored / 481 accepted active.
- Web: source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: #120 / `34326151119` GREEN, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`.
- Android TV/Google TV: #128 / `34429841034` GREEN, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`.
- cross-platform parity/recommendation: #132 / `34439296054` GREEN, source `e654668f89af49470df417d4fcc444e73c53121e`.
- whole-product release gate: #139 / `34571653740` GREEN, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.
- official stable bases currently Core 2.5.1, Moonbase 2.2.0, Smart-TV 2.8.2.

## Physical acceptance

Still NOT STARTED. Begin only after the server cutover gate is green.

Locked order:

1. Android mobile
2. LG OLED65C6PSA / webOS
3. Android TV / Google TV

Android beta identity: `org.moonfin.androidtv.beta` / `Moonfin Beta`; production remains `org.moonfin.androidtv`. Production signing cert `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never replace signing material under `/srv/appdata/moonfin/android-signing`.

Smart-TV accepted/live baseline remains 2.7.0; validated 2.8.2 merge `44a72276e87f611791348fbd11584e6aff56641a`, artifact `10192446254`, IPK SHA-256 `75be2fedecbd3b503a5f74d2c2fad403e9ac0bede4c842d4da87bd80cae2460a`; rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e` remains untouched.

## Exact next action

Transfer and run the prepared server cutover bundle. If its preflight/catalogue gate aborts, do not improvise a live workaround; diagnose only that failing gate. If it passes, update this checkpoint with the exact live catalogue SHA, release pointer, loaded Moonbase result and timestamped rollback directory, then begin Android mobile physical acceptance.
