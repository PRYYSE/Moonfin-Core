# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

Complete all reasonable GitHub/code work for Home Lab Moonfin Discovery v2 before physical-device, live-service or production acceptance.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`
Smart-TV accepted branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`
Smart-TV isolated update: `update/webos-2.8.2`

**Current phase:** final isolated Smart-TV 2.8.2 validation.

## Completed — do not redo

- Discovery catalogue/compiler and shared semantics: COMPLETE (`486 authored / 481 active`).
- Web: GITHUB/CODE COMPLETE, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: GITHUB/CODE COMPLETE, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, #120 / `34326151119` GREEN.
- Android TV / Google TV: GITHUB/CODE COMPLETE, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, #128 / `34429841034` GREEN.
- Smart-TV/webOS Discovery parity: GITHUB/CODE COMPLETE for accepted 2.7.0 baseline, source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, #52 / `34439022624` GREEN; `468 executable / 481 active` intentionally.
- Cross-platform parity/recommendation semantics: COMPLETE for GitHub/code evidence.
- Whole-product Flutter release engineering: COMPLETE, #139 / `34571653740` GREEN, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.
- Stable-release detector correction: COMPLETE, Core `2.5.1 -> 2.5.1` no update; Smart-TV `2.7.0 -> 2.8.2` update detected.

## Locked identities / rollback

- production Android signing certificate `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604` — never replace.
- webOS app ID `org.moonfin.webos`; entry `index.html`; Node 20 retained for legacy LG C6 compatibility.
- Smart-TV rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e` untouched.
- no CI candidate implies production or physical acceptance.

## Smart-TV 2.8.2 update — CURRENT

Official 2.8.2 source: `ed327948aeb8ef19098b810145ab6a3b76ccf372`.
Accepted real source-base ancestry remains `384d7cab3642f846463a4308e92d213e51507edf`.

Port Analysis #1 / `34578965427` was GREEN and identified exactly five overlap files. Reviewed conflict patch SHA-256: `23d7800c6d15812cea030a8e5329bea267a5dd17d18be9003efb9b4904f54848`.

Repair/control source `8fb273c024c773d730bd22304fa3d12961db18a2` passed:

- Port Staging #3 / `34582511512`: GREEN — exact release/ref guard, five-conflict gate, reviewed patch, dependency install, focused tests, webOS build, exact `org.moonfin.webos` / `2.8.2` / `index.html`, candidate push.
- accepted-branch regression #57 / `34582511474`: GREEN — Discovery tests, build, identity/package verification and artifact upload.
- #57 artifact `10192272864`; ZIP digest `sha256:a37554228197b4b8640a722f96b274eebe0a0daf6f3003a3d9fc31fa3796370c`.

Staging produced isolated product merge commit `44a72276e87f611791348fbd11584e6aff56641a`, tree `f3422be8bc22c312fbb94807b71a90e815c0213e`.

Because an Actions `GITHUB_TOKEN` push did not trigger the normal follow-on workflow, an external same-tree checkpoint `26883e4dc3d1d2d25ce820756cf09a845227e3c1` was created, then content-API trigger commit `3dc9d2d3ba4e2e94793d70c14d18c3fb5c1b2568` added only `.github/homelab-webos-2.8.2-validation.txt`. No product/package content changed in the trigger commit.

Established update-branch validation:

- Home Lab webOS Discovery v2 #58 / `34582969197`
- source `3dc9d2d3ba4e2e94793d70c14d18c3fb5c1b2568`
- captured IN PROGRESS at dependency install
- **DO NOT POLL AGAIN THIS CYCLE**

Draft PR #1 remains a conflict probe only and is labelled DO NOT MERGE.

## Exact next actions

1. On next continuation inspect #58 exactly once.
2. If green, capture artifact metadata/digest and verify all established Discovery test/build/identity/package steps passed.
3. Mark Smart-TV 2.8.2 GitHub/code integration complete; retire conflict-probe PR #1 and update stable baseline/checkpoints without implying physical/live acceptance.
4. Create/update the explicit whole-project GitHub completion checkpoint if no other stable/code blocker remains.
5. Do not promote live/accepted/rollback refs or perform physical-device work unless explicitly entering that later phase.

## Non-blocking debt

GitHub Action runtime deprecation warnings, future Flutter Built-in Kotlin migration and Smart-TV legacy tooling remain separate maintenance work. Do not mix them into this acceptance gate.

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by CI.
