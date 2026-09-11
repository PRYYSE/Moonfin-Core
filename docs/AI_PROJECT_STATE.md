# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

Complete the **pre-acceptance live server migration** for Home Lab Moonfin Discovery v2 before beginning physical client acceptance.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`  
Smart-TV accepted branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`  
Smart-TV validated update candidate: `PRYYSE/Smart-TV` / `update/webos-2.8.2`

Implementation source remains GitHub/code complete. Last verified pre-checkpoint branch HEAD: `6106351afcd8a00788ea7d1b28a0c88b509bef00`.

**Current phase:** PRE-ACCEPTANCE SERVER MIGRATION.

## Why this phase exists

The live Home Lab server was deliberately left unchanged during Discovery-v2 GitHub/code work. The user confirmed on 2026-09-11 that Moonbase/Web has not been changed since Discovery v2 work began.

Live therefore remains the legacy deployment boundary:

- custom Moonbase `2.0.3.1`
- live Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery reference `481/486`
- Seerr enabled

Discovery-v2 architecture already specifies a controlled migration before physical acceptance:

1. preserve the current live Web/plugin state and rollback information;
2. move to official stock Moonbase `2.2.0`;
3. use official `MOONFIN_WEB_ROOT` to serve a persistent external Web release;
4. deploy the exact tested Discovery-v2 Web candidate plus compiled catalogue to that external root;
5. verify `/Moonfin/Web/` and `/Moonfin/Web/homelab/discovery.catalogue.json` through the real Jellyfin/Moonbase server endpoint;
6. only then begin physical client acceptance.

Do not skip this migration merely to reach Android testing faster.

The failed Windows check against `http://192.168.50.12/Moonfin/Web/homelab/discovery.catalogue.json` tested plain HTTP port 80 on the Docker VM and does not prove the Moonbase catalogue is absent. Moonbase is a Jellyfin server plugin and its routes are served through the Jellyfin server endpoint.

## Completed — do not redo

- Discovery catalogue/compiler/shared semantics: COMPLETE (`486 authored / 481 active`).
- Web: GITHUB/CODE COMPLETE, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: GITHUB/CODE COMPLETE, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, #120 / `34326151119` GREEN.
- Android TV / Google TV: GITHUB/CODE COMPLETE, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, #128 / `34429841034` GREEN.
- Smart-TV/webOS accepted Discovery parity: GITHUB/CODE COMPLETE for accepted 2.7.0 branch, source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, #52 / `34439022624` GREEN; `468 executable / 481 active` intentionally.
- Cross-platform parity/recommendation semantics: COMPLETE, source `e654668f89af49470df417d4fcc444e73c53121e`, #132 / `34439296054` GREEN.
- Whole-product Flutter release engineering: COMPLETE, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, #139 / `34571653740` GREEN.
- Stable-release detector/update protocol automation: COMPLETE and release-tag based; Core remains 2.5.1, Smart-TV 2.8.2 update path validated.
- Explicit whole-project GitHub closure: `docs/homelab-discovery-v2/GITHUB_COMPLETION_CHECKPOINT.md`.

## Pre-acceptance server migration

### Target architecture

Persistent root:

`/srv/appdata/moonfin/`

Relevant target structure:

- `discovery/catalogue.authoring.json`
- `discovery/discovery.catalogue.json`
- `discovery/diagnostics.json`
- `web/current -> releases/<release>/`
- `web/releases/`
- existing `android-signing/` remains untouched

Moonbase must serve the external Web release via `MOONFIN_WEB_ROOT`, while retaining its bundled Web as emergency fallback if the override path is unavailable.

### Migration safety requirements

- inspect the live Jellyfin/Moonbase deployment read-only before changing it;
- identify the actual Jellyfin base URL/port, plugin path, current Moonbase files/version and container/Compose ownership;
- preserve current plugin/Web files or equivalent rollback state before modification;
- do not print Seerr credentials, API keys, tokens or other secrets;
- preserve `/srv/appdata/moonfin/android-signing` exactly;
- do not reinstall or rebuild unrelated working services;
- make the external Web release switch symlink-based/reversible where practical;
- verify stock Moonbase 2.2.0 loads and existing Seerr/plugin functionality remains available after the change;
- verify the served Discovery catalogue reports supported `schemaVersion` `1` or `2` and expected catalogue accounting before device acceptance.

## Real-world acceptance

Durable record: `docs/homelab-discovery-v2/REAL_WORLD_ACCEPTANCE_CHECKPOINT.md`.

Physical device order remains locked **after the server migration gate passes**:

1. Android mobile
2. LG OLED65C6PSA / webOS
3. Android TV / Google TV

### Android mobile candidate

- source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- whole-product CI #139 / `34571653740` GREEN
- artifact `10188826944`
- APK `Moonfin_HomeLab_Android_fd06ec560235.apk`
- APK SHA-256 `117e633f0f6c97a969a7a0095b5ae3419ab626f82a5f672b92e5cf6122c00fb5`
- beta package `org.moonfin.androidtv.beta`, label `Moonfin Beta`
- production package remains `org.moonfin.androidtv`

Do not install/start physical acceptance until the server migration and catalogue gate above pass.

## Smart-TV 2.8.2

Official release remains `2.8.2` at `ed327948aeb8ef19098b810145ab6a3b76ccf372`.

- accepted/live baseline remains release `2.7.0` until physical acceptance and deliberate promotion;
- product merge `44a72276e87f611791348fbd11584e6aff56641a`, tree `f3422be8bc22c312fbb94807b71a90e815c0213e`;
- update-branch validation #58 / `34582969197` GREEN;
- artifact `10192446254`;
- IPK SHA-256 `75be2fedecbd3b503a5f74d2c2fad403e9ac0bede4c842d4da87bd80cae2460a`.

## Locked identities / rollback

- production Android signing certificate `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604` — never replace;
- production Android signing material remains outside Git under `/srv/appdata/moonfin/android-signing`;
- webOS app ID `org.moonfin.webos`; entry `index.html`; Node 20 retained for legacy LG C6 compatibility;
- Smart-TV rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e` remains untouched;
- CI candidates are not production acceptance.

## Exact next actions

1. Run one bounded read-only audit on `docker01` to identify the actual Jellyfin/Moonbase endpoint, container/Compose ownership, plugin path/version and current Web serving layout without exposing secrets.
2. From that evidence, prepare and execute one reversible migration to stock Moonbase 2.2.0 plus the persistent external Discovery-v2 Web root/catalogue.
3. Verify Jellyfin, Moonbase, Seerr integration, Moonfin Web and the Discovery-v2 catalogue endpoint.
4. Update this checkpoint with the exact deployed release/symlink/plugin state and rollback command.
5. Then install the exact #139 Android mobile beta side-by-side and begin physical acceptance.

## Non-blocking maintenance debt

GitHub Action runtime deprecation warnings, future Flutter Built-in Kotlin migration and Smart-TV legacy tooling remain separate maintenance work. They are not blockers to Discovery v2 acceptance.
