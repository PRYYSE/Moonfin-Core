# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed GitHub/code stages must not be restarted without current fault evidence.

## Status — pre-acceptance server migration

> GitHub/code remains COMPLETE. The next required work is the live Moonbase/Web migration that was deliberately deferred during Discovery-v2 development.

The user confirmed on 2026-09-11 that Moonbase/Web has not been changed since Discovery v2 work began. Live therefore remains custom Moonbase `2.0.3.1` plus legacy Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`.

Do **not** skip directly to Android acceptance merely because the client candidate is ready.

## Locked completion evidence

- shared catalogue/compiler/semantics: COMPLETE, `486 authored / 481 active`.
- Web: COMPLETE, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: #120 / `34326151119` GREEN, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`.
- Android TV/Google TV: #128 / `34429841034` GREEN, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`.
- cross-platform parity/recommendation: #132 / `34439296054` GREEN, source `e654668f89af49470df417d4fcc444e73c53121e`.
- whole-product Flutter release gate: #139 / `34571653740` GREEN, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.
- upstream-update detector/protocol automation: COMPLETE; official stable releases rechecked as Core `2.5.1`, Moonbase `2.2.0`, Smart-TV `2.8.2`.

## Server migration gate

Discovery-v2 architecture requires the live server to move to the maintainable production model before device acceptance:

- official stock Moonbase `2.2.0`;
- external persistent Moonfin Web root through official `MOONFIN_WEB_ROOT`;
- release directories under `/srv/appdata/moonfin/web/releases/` with reversible `current` selection;
- compiled Discovery-v2 catalogue served at `/Moonfin/Web/homelab/discovery.catalogue.json`;
- existing bundled Moonbase Web retained as emergency fallback;
- existing Seerr functionality preserved;
- `/srv/appdata/moonfin/android-signing` untouched.

The Windows request to `http://192.168.50.12/Moonfin/Web/homelab/discovery.catalogue.json` failed because it targeted plain HTTP port 80 on the Docker VM. Moonbase is a Jellyfin plugin and its route is served through the actual Jellyfin server endpoint. That failed request does not establish catalogue absence.

### Safety / rollback requirements

Before changing live state:

1. inspect container/Compose ownership, Jellyfin port/base URL, Moonbase plugin location/version and current Web layout read-only;
2. preserve the current plugin/Web deployment or equivalent exact rollback state;
3. avoid exposing secrets while inspecting environment/config;
4. deploy stock Moonbase 2.2.0 and external Web/catalogue as one coherent reversible migration;
5. verify Jellyfin, Moonbase, Seerr, Moonfin Web and catalogue schema/accounting after restart/cutover;
6. record exact deployment and rollback state here before physical client acceptance.

## Real-world acceptance

See `docs/homelab-discovery-v2/REAL_WORLD_ACCEPTANCE_CHECKPOINT.md`.

Physical device order remains locked **after the server migration gate passes**:

1. Android mobile
2. LG OLED65C6PSA / webOS
3. Android TV / Google TV

### Android mobile candidate

- status: PREPARED / NOT RUN
- source: `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- workflow: #139 / `34571653740` GREEN
- artifact: `10188826944`
- APK: `Moonfin_HomeLab_Android_fd06ec560235.apk`
- APK SHA-256: `117e633f0f6c97a969a7a0095b5ae3419ab626f82a5f672b92e5cf6122c00fb5`
- beta identity: `org.moonfin.androidtv.beta` / `Moonfin Beta`
- production identity remains `org.moonfin.androidtv`

Do not install it until the server migration gate above is green.

## Smart-TV 2.8.2 validated candidate

- accepted/live webOS baseline remains `2.7.0`; ancestry anchor `384d7cab3642f846463a4308e92d213e51507edf`.
- official 2.8.2 source `ed327948aeb8ef19098b810145ab6a3b76ccf372`.
- product merge `44a72276e87f611791348fbd11584e6aff56641a`; tree `f3422be8bc22c312fbb94807b71a90e815c0213e`.
- Port Analysis #1 / `34578965427`: GREEN.
- Port Staging #3 / `34582511512`: GREEN.
- accepted-branch regression #57 / `34582511474`: GREEN.
- update-branch validation #58 / `34582969197`: GREEN.
- artifact `10192446254`.
- IPK SHA-256 `75be2fedecbd3b503a5f74d2c2fad403e9ac0bede4c842d4da87bd80cae2460a`.

## Locked invariants

- Android production signing cert `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`.
- production Android signing material remains outside Git at `/srv/appdata/moonfin/android-signing`; never regenerate/replace it.
- webOS app ID `org.moonfin.webos`, entry `index.html`, Node 20 for legacy LG C6 compatibility.
- rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.

## Exact next action

Run a single bounded read-only audit on `docker01` to capture the actual Jellyfin/Moonbase endpoint, Docker/Compose ownership, current Moonbase plugin path/version and Web-serving layout without printing secrets. Use that evidence to build the reversible stock-Moonbase-2.2.0 + external-Discovery-v2-Web migration. Do not begin Android installation yet.
