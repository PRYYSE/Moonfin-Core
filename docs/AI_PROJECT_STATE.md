# AI Project State

**Updated:** 2026-09-11 Australia/Adelaide

## Current objective

GitHub/code completion for Home Lab Moonfin Discovery v2 is reached. The next primary project boundary is controlled physical-device/live-service acceptance; do not promote accepted/rollback refs or modify live systems unless explicitly entering that phase.

Primary repo/branch: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`  
Smart-TV accepted branch: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`  
Smart-TV validated update candidate: `PRYYSE/Smart-TV` / `update/webos-2.8.2`

**Current phase:** GITHUB/CODE COMPLETE — physical/live acceptance is next.

> No known GitHub/code-side work remains. Remaining work requires real devices, real services, deployment infrastructure, or subjective visual/recommendation acceptance.

## Completed — do not redo

- Discovery catalogue/compiler/shared semantics: COMPLETE (`486 authored / 481 active`).
- Web: GITHUB/CODE COMPLETE, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: GITHUB/CODE COMPLETE, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`, #120 / `34326151119` GREEN.
- Android TV / Google TV: GITHUB/CODE COMPLETE, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`, #128 / `34429841034` GREEN.
- Smart-TV/webOS accepted Discovery parity: GITHUB/CODE COMPLETE for the current accepted 2.7.0 branch, source `a9dfa657a220a3f8f77753261bd7d8e902c0d837`, #52 / `34439022624` GREEN; `468 executable / 481 active` intentionally.
- Cross-platform parity/recommendation semantics: COMPLETE for GitHub/code evidence, source `e654668f89af49470df417d4fcc444e73c53121e`, #132 / `34439296054` GREEN.
- Whole-product Flutter release engineering: COMPLETE, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`, #139 / `34571653740` GREEN.
- Stable-release detector/update protocol automation: COMPLETE and release-tag based; Core remains 2.5.1, Smart-TV 2.8.2 update path validated.
- Explicit whole-project closure: `docs/homelab-discovery-v2/GITHUB_COMPLETION_CHECKPOINT.md`.

## Smart-TV 2.8.2 — GitHub/code validated candidate

Official release remains `2.8.2` at `ed327948aeb8ef19098b810145ab6a3b76ccf372`.

- accepted/live baseline intentionally remains release `2.7.0`, real source-base ancestry `384d7cab3642f846463a4308e92d213e51507edf`, until physical acceptance and deliberate promotion.
- Port Analysis #1 / `34578965427`: GREEN; exactly five overlap paths reviewed.
- reviewed conflict patch SHA-256 `23d7800c6d15812cea030a8e5329bea267a5dd17d18be9003efb9b4904f54848`.
- repair/control source `8fb273c024c773d730bd22304fa3d12961db18a2`.
- Port Staging #3 / `34582511512`: GREEN; exact release/ref/conflict gates, focused tests, Node 20 build, `org.moonfin.webos` / `2.8.2` / `index.html` identity and isolated push all passed.
- accepted-branch regression #57 / `34582511474`: GREEN.
- isolated product merge `44a72276e87f611791348fbd11584e6aff56641a`, tree `f3422be8bc22c312fbb94807b71a90e815c0213e`.
- validation trigger `3dc9d2d3ba4e2e94793d70c14d18c3fb5c1b2568` adds only `.github/homelab-webos-2.8.2-validation.txt`; no product/package content changed.
- established update-branch webOS validation #58 / `34582969197`: GREEN; Discovery tests, build, identity/package verification and artifact upload all passed.
- #58 artifact `10192446254`; ZIP digest `sha256:7cb6387cde7681fb598edb431d31bb7f596a9e86dd1be27b0fc5c6d3c7fb4717`.
- independently recomputed IPK SHA-256 `75be2fedecbd3b503a5f74d2c2fad403e9ac0bede4c842d4da87bd80cae2460a`, matching the packaged checksum file.
- conflict-probe PR #1 is CLOSED, unmerged and retired.
- validation marker is retained on the isolated candidate branch as provenance; it is outside product/package scope.

## Stable upstream state

Final release check on 2026-09-11:

- Moonfin Core latest stable: `2.5.1`; accepted stable: `2.5.1` — no Core update pending.
- Smart-TV latest stable: `2.8.2`; accepted/live stable: `2.7.0`; 2.8.2 is already GitHub/code validated on the isolated candidate branch and awaits physical acceptance.
- `tooling/homelab-discovery-v2/upstream-baselines.json` keeps accepted/live fields unchanged and records the validated 2.8.2 candidate separately.

## Locked identities / rollback

- production Android signing certificate `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604` — never replace.
- webOS app ID `org.moonfin.webos`; entry `index.html`; Node 20 retained for legacy LG C6 compatibility.
- Smart-TV rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e` remains untouched.
- CI candidates are not production acceptance.

## Next primary phase — not yet executed

Controlled physical/live acceptance. Suggested order remains Web -> Android mobile/tablet -> Android TV/Google TV -> LG OLED65C6PSA webOS -> real Jellyfin/Seerr recommendation-quality capture -> request/detail/local-playback/lifecycle/update compatibility -> deliberate production cutover with rollback preserved.

Do not infer any of these outcomes from CI. If physical acceptance exposes a genuine defect, fix the authoritative GitHub source/candidate and revalidate only the affected surface.

## Non-blocking maintenance debt

GitHub Action runtime deprecation warnings, future Flutter Built-in Kotlin migration and Smart-TV legacy tooling remain separate maintenance work. They are not blockers to the Discovery v2 GitHub completion checkpoint.

## Live boundary

Live remains untouched: custom Moonbase 2.0.3.1, Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`, accepted legacy Discovery 481/486, Seerr enabled. No physical/device/live acceptance is claimed by GitHub CI.
