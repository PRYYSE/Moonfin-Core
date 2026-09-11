# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

Complete the **pre-acceptance live server cutover** for Home Lab Moonfin Discovery v2, verify the real Jellyfin/Moonbase/Seerr/Web/catalogue path, then begin physical acceptance in the locked device order.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`  
Smart-TV accepted branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`  
Smart-TV validated update candidate: `PRYYSE/Smart-TV` / `update/webos-2.8.2`

GitHub/code implementation is complete. The current phase is **PRE-ACCEPTANCE SERVER CUTOVER**.

## Live server evidence — 2026-09-11

Read-only audits against `docker01` established the real current state:

- Jellyfin: `10.11.11`, container `jellyfin`, image `lscr.io/linuxserver/jellyfin:latest`.
- Jellyfin LAN endpoint: `http://192.168.50.12:8096`.
- authoritative Compose project: `media` in `/opt/stacks/media` using `compose.yaml` + `compose.jellyfin-opencl.yml`.
- `/srv/appdata/jellyfin -> /config`, `/srv/appdata/jellyfin-transcode -> /transcode`, `/data/media -> /data/media:ro`.
- Intel `/dev/dri` remains passed through; OpenCL mod remains `linuxserver/mods:jellyfin-opencl-intel`.
- PUID `1000`, PGID `1001`, TZ `Australia/Adelaide`.
- `MOONFIN_WEB_ROOT` is currently unset.
- `/Moonfin/Web/` = HTTP 200; `/Moonfin/Web/config.json` = HTTP 200.
- `/Moonfin/Web/homelab/discovery.catalogue.json` = HTTP 404, confirming the Discovery-v2 server catalogue is not deployed yet.
- persistent `/srv/appdata/moonfin` currently contains only the protected `android-signing/` area; `web/` and `discovery/` are not yet present.
- Seerr container: `seerr`, image `ghcr.io/seerr-team/seerr:latest`.

### Moonbase correction

The old checkpoint assumption that live Moonbase remained custom `2.0.3.1` was stale.

Current plugin root is `/srv/appdata/jellyfin/data/plugins/` and contains `Moonbase_2.1.0.0` plus `Moonbase_2.2.0.0`. The 2.2.0 metadata reports version `2.2.0.0` and status `Active`.

The official Moonbase 2.2.0 release ZIP was verified against official MD5 `205728081ECEA212F9FEA419FC2EFD77`. Comparing all 173 official package files against the installed `Moonbase_2.2.0.0` directory produced:

- 172 exact matches;
- 0 missing files;
- exactly 1 differing file: `meta.json`;
- installed/official-matching `Moonfin.Server.dll` SHA-256 `f4863466ea6fe7763f9e8ad128cc050142246f0a48bde5069408f4b2487fc01c`.

Therefore **do not reinstall Moonbase**. The cutover preflight will query Jellyfin `/Plugins` using an existing API key without printing it and must confirm 2.2.0 is actually loaded before the first authoritative live change.

## Discovery-v2 deployment inputs

Whole-product workflow #139 / `34571653740` is GREEN at source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`; artifact `10188826944` remains the exact candidate source.

The artifact was downloaded and independently hashed:

- Web: `Moonfin_HomeLab_Web_fd06ec560235.tar.gz`
  - SHA-256 `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
  - embedded Moonfin `2.5.1`, build `30000149`
  - compiled JS contains `/Moonfin/Web/homelab/discovery.catalogue.json` loader path.
- Android mobile: `Moonfin_HomeLab_Android_fd06ec560235.apk`
  - corrected SHA-256 `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Android TV: `Moonfin_HomeLab_AndroidTV_fd06ec560235.apk`
  - SHA-256 `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.

The previously recorded Android-mobile SHA beginning `117e633f...` was incorrect and must not be used.

The missing live catalogue wrapper was restored to the v2 branch in commit `14706f9e5534392be3f1035d41a0253bcc7241d2`. Its purpose is safe read-only Jellyfin/Seerr metadata resolution plus atomic catalogue output; no secrets are printed.

## Prepared server cutover — NOT YET EXECUTED

A bounded cutover package has been prepared from the exact #139 Web tarball. Local verification passed:

- deployment script `bash -n`: PASS;
- Compose text patch simulated against the audited Jellyfin service: PASS;
- package ZIP integrity: PASS;
- embedded Web tar SHA-256 reverified: PASS.

The deployment script is fail-closed and must, before altering authoritative Compose:

1. require root/sudo and the exact audited Jellyfin/Moonbase paths;
2. verify exact Web SHA and official-matching Moonbase DLL SHA;
3. fetch pinned catalogue tooling;
4. query Jellyfin `/Plugins` without printing credentials and require loaded Moonbase 2.2.0;
5. live-compile the catalogue against existing Jellyfin/Seerr configuration;
6. require schema v2, **481/486**, exactly 5 reviewed semantic drops and **0 provider drops**;
7. stage `/srv/appdata/moonfin/web/releases/fd06ec560235` and canonical `/srv/appdata/moonfin/discovery`;
8. create a timestamped rollback checkpoint;
9. set `web/current -> releases/fd06ec560235`;
10. add `MOONFIN_WEB_ROOT=/moonfin-web/current` and read-only `/srv/appdata/moonfin/web:/moonfin-web` mount to the authoritative Jellyfin Compose service;
11. validate effective Compose before recreating only Jellyfin;
12. verify Jellyfin, Moonbase 2.2.0, Seerr config, Moonfin Web and the served 481-lane schema-v2 catalogue;
13. automatically restore the previous Compose/bundled-Web path on any post-edit/post-cutover failure.

Expected rollback command after the checkpoint is created:

`sudo bash /srv/appdata/moonfin/rollback/latest/rollback.sh`

`/srv/appdata/moonfin/android-signing` must remain untouched throughout.

## Completed — do not redo

- Discovery catalogue/compiler/shared semantics: COMPLETE (`486 authored / 481 accepted active`).
- Web: GITHUB/CODE COMPLETE, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, #120 / `34326151119` GREEN.
- Android TV / Google TV: source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, #128 / `34429841034` GREEN.
- Smart-TV/webOS accepted Discovery parity: source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, #52 / `34439022624` GREEN; `468 executable / 481 active` intentionally.
- Cross-platform parity/recommendation semantics: source `e654668f89af49470df417d4fcc444e73c53121e`, #132 / `34439296054` GREEN.
- Whole-product release engineering: source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, #139 / `34571653740` GREEN.
- Stable update detector/protocol: COMPLETE.
- Core stable base: `2.5.1`; official Moonbase stable: `2.2.0`; Smart-TV stable/update candidate: `2.8.2`.

## Physical acceptance — blocked only by server cutover gate

Physical device order remains locked:

1. Android mobile
2. LG OLED65C6PSA / webOS
3. Android TV / Google TV

No Discovery-v2 candidate has yet been physically accepted.

Android beta identity remains `org.moonfin.androidtv.beta` / `Moonfin Beta`; production remains `org.moonfin.androidtv`. Production Android signing certificate remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate or replace its signing material under `/srv/appdata/moonfin/android-signing`.

Smart-TV accepted/live baseline remains 2.7.0 until physical acceptance. Validated 2.8.2 product merge remains `44a72276e87f611791348fbd11584e6aff56641a`, artifact `10192446254`, IPK SHA-256 `75be2fedecbd3b503a5f74d2c2fad403e9ac0bede4c842d4da87bd80cae2460a`; rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e` remains untouched.

## Exact next actions

1. Transfer and run the prepared bounded server-cutover package.
2. If its preflight/catalogue gate aborts, make **no live workaround**; diagnose only the reported failing gate.
3. If cutover passes, record the exact live release, catalogue SHA/counts, loaded Moonbase status and rollback checkpoint here.
4. Then install the exact #139 Android mobile beta side-by-side and begin physical acceptance.

## Non-blocking maintenance debt

GitHub Action runtime deprecation warnings, future Flutter Built-in Kotlin migration and Smart-TV legacy tooling remain separate maintenance work. They are not blockers to Discovery v2 acceptance.
