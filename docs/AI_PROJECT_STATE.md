# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

Complete everything reasonably possible in GitHub/code for Home Lab Moonfin Discovery v2 before physical-device, live-service or production acceptance.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`  
Smart-TV repo/branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`

**Current phase:** upstream-update automation / protocol integration.

## Completed foundations — do not redo

- Shared Discovery catalogue/compiler and Flutter semantics/personalisation: **COMPLETE**.
- Catalogue: **486 authored / 481 accepted active**.
- Web: code complete, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`, workflow #115.
- Android mobile/tablet: code complete, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, workflow #120 / `34326151119` GREEN.
- Android TV / Google TV: code complete, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, workflow #128 / `34429841034` GREEN.
- Smart-TV/webOS parity source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, workflow #52 / `34439022624` GREEN.
- webOS intentionally remains **468 executable / 481 active**; 13 structural/context strategies fail closed.
- Cross-platform parity/recommendation semantics: **COMPLETE for GitHub/code evidence**. Do not tune ranking from synthetic fixtures.
- Preserve Smart-TV rollback branch `homelab/webos-v1-staging` and candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.
- Production Android certificate SHA-256 remains `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`; never regenerate/replace it.

## Smart-TV release candidate — validated

- artifact ID `10137277340`
- name `Moonfin-HomeLab-webOS-DiscoveryV2-a9dfa657a220a3f8f77753261bd7d8e902c0d837`
- size `4,312,826` bytes
- ZIP digest `sha256:9d5ccfed0889a680fa6b4d3532725ce1877f950d306d9599bb6916e9d150c47f`

## Flutter whole-product CI / release engineering — COMPLETE

Authoritative successful gate:

- workflow **#139 / `34571653740`** — GREEN
- source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- focused validation: PASS
- Web release build: PASS
- `mobile-beta` APK: PASS
- `androidTv-beta` APK: PASS
- package identity / Leanback split / signer verification: PASS
- packaging / upload: PASS

Release artifact:

- artifact ID `10188826944`
- name `homelab-discovery-v2-candidates-fd06ec5602351e53f0eacb56b2457ad0e80f169e`
- size `304,690,594` bytes
- GitHub ZIP digest `sha256:59f6678026ea665eceb74a2ed3fd3c43ae1d593c9c121b1d2ff2a81d29fc65e5`
- independently recomputed ZIP SHA-256 matched GitHub

`BUILD_INFO.txt` evidence:

- Flutter `3.44.1`
- app `2.5.1+30000149`
- Android TV `2.5.1`, build `2000016`
- beta application ID `org.moonfin.androidtv.beta`
- mobile Leanback optional; Android-TV Leanback required
- CI signer `9590094799a3b051292ad54904df0d964815a871ef9f6238068607e7ee1202b9`
- CI signer differs from protected production certificate
- CI APKs remain debug-fallback candidates and are **not deployment APKs**

Candidate SHA-256 values, independently rechecked against the archived payloads:

- Web tar.gz `0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`
- mobile APK `117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`
- Android TV APK `71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`

No physical/live acceptance is implied by this CI closure.

## Upstream-update automation / protocol integration — CURRENT

Existing policy remains `docs/UPSTREAM_UPDATE_PROTOCOL.md`: detect/report only, isolated update branches, explicit overlap review, narrow overlay reapplication, complete regression gates, preserved identities/rollback and no automatic merge/deploy/promotion.

Verified official lineages and accepted upstream bases:

- Core official upstream: `Moonfin-Client/Moonfin-Core` / `main`
  - accepted base `f18c45b1fbf9b63871b4f93237179f9706154763`
  - observed official head during integration: `3b7c07865b9ac9378606d267fcd35faed4ee5b89`
- Smart-TV official upstream: `Moonfin-Client/Smart-TV` / `main`
  - accepted base `384d7cab3642f846463a4308e92d213e51507edf`
  - observed official head during integration: `c7e1ff570ace275871f8c63589c30cfb58106edb`

Core integration commit:

`6f0a333774ca430531f06e3985a968fcb7b4b645` — `ci(upstream): integrate Home Lab update impact gates`

Adds/integrates:

- `tooling/homelab-discovery-v2/upstream-baselines.json` — machine-readable accepted bases, lineages and protected identities
- `tooling/homelab-discovery-v2/upstream_impact_report.py` — fail-closed impact/overlap report generator
- `.github/workflows/homelab-upstream-impact.yml` — read-only Core + Smart-TV upstream detection/report workflow
- `docs/homelab-discovery-v2/UPSTREAM_UPDATE_AUTOMATION.md` — implementation binding/operating contract
- `.github/workflows/homelab-discovery-v2.yml` now supports `update/moonfin-*` and resolves update-branch scope against its official-upstream merge base instead of treating legitimate upstream changes as Home Lab scope expansion

Smart-TV integration commit:

`a4e0a3251bf3a987e6c92ad4c1575e5c528401e0` — `ci(webos): support isolated upstream update branches`

- supports `update/webos-*`
- keeps Node 20
- keeps app ID `org.moonfin.webos` and entry `index.html`
- baseline branch still requires version `2.7.0`
- update branches may advance semver but cannot regress below `2.7.0`
- preserved rollback branch/candidate untouched

Local focused validation before push:

- impact generator Python compile: PASS
- baseline JSON parse: PASS
- Core/impact/Smart-TV workflow YAML parse: PASS
- synthetic upstream/Home-Lab overlap detection: PASS
- stale/rebased accepted-base ancestry test fails closed as intended: PASS
- webOS version guard fixtures (`2.7.0`, `2.8.0`, reject `2.6.9`): PASS

### Authoritative validation runs — captured once, do not poll again this cycle

- Core Discovery workflow **#140 / `34576497402`**, source `6f0a333774ca430531f06e3985a968fcb7b4b645`, captured **QUEUED**
- Home Lab Upstream Impact workflow **#1 / `34576497458`**, source `6f0a333774ca430531f06e3985a968fcb7b4b645`, captured **QUEUED**
- Smart-TV webOS workflow **#53 / `34576558771`**, source `a4e0a3251bf3a987e6c92ad4c1575e5c528401e0`, captured **IN PROGRESS**

GitHub scheduled workflows execute from the default branch only. The upstream-impact workflow is intentionally isolated with the Home Lab overlay, so its daily cron is dormant unless its control workflow is deliberately promoted to the default branch. Do **not** contaminate the clean upstream-mirror/default branch merely to activate cron; `workflow_dispatch` remains the safe control path.

## Known non-blocking debt

- GitHub Actions warnings for Node-20-targeted older action runtimes and `setup-java@v4` deprecation.
- Flutter warns about future Built-in Kotlin migration.
- Smart-TV application itself should remain Node 20 for legacy LG C6 compatibility unless separately proven safe.
- Keep these maintenance items separate from current update-integration validation.

## Exact next actions

1. Next continuation: inspect exact Core Discovery **#140 / `34576497402` once**.
2. Inspect exact upstream-impact **#1 / `34576497458` once**; if green, download its report artifact and capture Core + Smart-TV current drift/overlap evidence.
3. Inspect exact Smart-TV **#53 / `34576558771` once**.
4. If a run failed, inspect only its failing job/step and fix that integration defect; launch/record a replacement and stop polling it.
5. If all are green, mark upstream-update automation/protocol integration **COMPLETE**, create the explicit GitHub completion checkpoint, then stop before physical/live acceptance unless explicitly instructed to cross that boundary.

## Later stages

1. cross-platform parity + recommendation quality — **COMPLETE for GitHub/code evidence**
2. whole-product CI/release engineering — **COMPLETE**
3. upstream-update automation/protocol integration — **CURRENT; validation runs launched**
4. explicit GitHub completion checkpoint
5. physical/live acceptance

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
