# Discovery v2 — Real-World Acceptance Checkpoint

**Updated:** 2026-09-11 Australia/Adelaide

GitHub/current repository state is authoritative. This checkpoint tracks only physical-device/live-service acceptance after the completed GitHub/code phase.

## Boundary

- GitHub/code phase remains closed. Do not restart completed implementation, parity, CI/release-engineering or upstream-update work without real acceptance evidence of a genuine defect.
- No Discovery v2 candidate has yet been physically accepted, promoted or deployed as the accepted/live product.
- Live Home Lab/device state remains unchanged.
- Physical device order is locked: **Android mobile -> LG OLED65C6PSA/webOS -> Android TV/Google TV**.
- A platform is not accepted until it has actually been tested on its real target.

## Android mobile

**Status:** PREPARED / NOT YET PHYSICALLY TESTED

### Candidate

- source: `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- whole-product workflow: #139 / `34571653740` — GREEN
- artifact: `10188826944` / `homelab-discovery-v2-candidates-fd06ec560235`
- APK: `Moonfin_HomeLab_Android_fd06ec560235.apk`
- APK SHA-256: `117e633f0f6c97a969a7a0095b5ae3419ab626f82a5f672b92e5cf6122c00fb5`

### Identity and signing

- beta package/application ID: `org.moonfin.androidtv.beta`
- beta app label: `Moonfin Beta`
- accepted/production package/application ID: `org.moonfin.androidtv`
- first functional acceptance uses the beta package side-by-side; it does **not** require the protected production signing identity.
- #139 verifies the CI beta candidate is signed with the non-production/debug-fallback signer and that this signer is distinct from the protected production certificate.
- protected production signing material remains outside Git under `/srv/appdata/moonfin/android-signing`; do not rotate, regenerate or replace it.
- production signing configuration continues to use ignored local `android/keystore.properties` plus `android/app/release.keystore` when present.
- side-by-side beta acceptance does **not** prove a later production in-place update/signature-compatibility path. Treat that as a separate promotion gate if an in-place production update is required.
- if `org.moonfin.androidtv.beta` is already installed, inspect it before changing/removing it. Never uninstall `org.moonfin.androidtv` as a beta-test workaround.

### Live-service prerequisite

Discovery v2 activates only when the app accepts the schema-v3 catalogue from:

`<server>/Moonfin/Web/homelab/discovery.catalogue.json`

The GitHub-recorded live Web source `a9c789fff317b41bba268d3a213439e23b8d1af5` contains no Discovery-v2 catalogue path. This does **not** prove the live filesystem has no separately deployed/generated catalogue, so verify the live endpoint read-only before installation/acceptance.

If the catalogue is missing, invalid or unsupported, the candidate deliberately delegates to stock Discovery. A stock-fallback pass must **not** be counted as Discovery-v2 acceptance.

Dynamic Jellyfin and Seerr operations continue through the existing authenticated Moonfin proxy paths once a valid catalogue is accepted.

### Reversible installation route

1. Read-only verify that the live Moonbase endpoint serves a valid schema-v3 Discovery catalogue.
2. Download the exact #139 candidate artifact and verify the mobile APK SHA-256 above.
3. Inspect installed package state, then install only `org.moonfin.androidtv.beta` via ADB without replacing `org.moonfin.androidtv`.
4. Verify both package identities remain distinct after installation.
5. Beta-only rollback is removal of `org.moonfin.androidtv.beta`; accepted/production `org.moonfin.androidtv` remains untouched.

### Acceptance state

- tests actually performed: none physical yet
- PASS/FAIL: NOT RUN
- genuine defects found: none from physical testing yet
- fixes/CI caused by acceptance: none
- untested/deferred: full Android-mobile behaviour pass; production in-place update/signing compatibility; LG/webOS acceptance; Android TV acceptance

### Exact next action

Read-only verify whether the live Moonbase endpoint currently serves a valid schema-v3 Discovery catalogue. If absent, establish only the minimum reversible catalogue/Web deployment prerequisite before installing the beta APK. If present, verify/install the exact #139 mobile beta side-by-side and begin Android-mobile physical acceptance.
