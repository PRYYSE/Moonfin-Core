# Home Lab Discovery v2 — GitHub Completion Checkpoint

**Status:** COMPLETE — GitHub/code scope  
**Date:** 2026-09-11 Australia/Adelaide  
**Primary repo/branch:** `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`

## Completion declaration

> No known GitHub/code-side work remains. Remaining work requires real devices, real services, deployment infrastructure, or subjective visual/recommendation acceptance.

This is the Phase-10 checkpoint required by `GITHUB_COMPLETION_PLAN.md`. It does **not** claim physical-device, live-service or production acceptance.

## Gates closed

| Area | Evidence |
| --- | --- |
| Shared catalogue/compiler/semantic contract | `486 authored / 481 active`; unsupported structural/context semantics fail closed. |
| Web | GitHub/code complete at `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`. |
| Android mobile/tablet | `4af01af054d9b7cbe8e230b7ded482cb8fea330c`; #120 / `34326151119` GREEN. |
| Android TV / Google TV | `15ccc28b84727543ad714ef19dd318f907d1a1d8`; #128 / `34429841034` GREEN. |
| Smart-TV/webOS accepted parity | `a9dfa657a220a3f8f77753261bd7d8e902c0d837`; #52 / `34439022624` GREEN; `468 executable / 481 active` intentionally. |
| Cross-platform parity/recommendation | `e654668f89af49470df417d4fcc444e73c53121e`; #132 / `34439296054` GREEN; matrix in `CROSS_PLATFORM_PARITY_MATRIX.md`. |
| Whole-product Flutter release engineering | `fd06ec5602351e53f0eacb56b2457ad0e80f169e`; #139 / `34571653740` GREEN. |
| Official-update protocol/automation | Stable-release detector is release-tag based; isolated branch/impact/report/identity safeguards validated. |
| Latest Smart-TV stable integration | 2.8.2 isolated candidate passed Port Analysis #1, Port Staging #3 and update-branch validation #58. |

## Whole-product release artefact evidence

Flutter release gate #139 / `34571653740`:

- artifact `10188826944`.
- ZIP digest `sha256:59f6678026ea665eceb74a2ed3fd3c43ae1d593c9c121b1d2ff2a81d29fc65e5` independently matched.
- Android TV APK `sha256:71c2b017cb827e216ef4e5eb23bb4bc40e595b1eb1255aff24cd51298be3e1e8`.
- Android mobile APK `sha256:117e63325942dddcf352a5756e2926a16340d86317e3d8706d540febeda7ae9c`.
- Web tar.gz `sha256:0fbf4918a04581a6d79e7e0a6aa407a66d474402bfd33fb20cb38692112fa425`.
- CI Android signer was debug-fallback/non-production and remains distinct from the protected production certificate. No production signing identity was changed.

## Smart-TV 2.8.2 final GitHub evidence

Accepted/live webOS remains 2.7.0 until physical acceptance. The new stable release is held as an isolated validated candidate.

- official 2.8.2 source `ed327948aeb8ef19098b810145ab6a3b76ccf372`.
- accepted real source-base ancestry `384d7cab3642f846463a4308e92d213e51507edf` remains unchanged.
- reviewed conflict patch `sha256:23d7800c6d15812cea030a8e5329bea267a5dd17d18be9003efb9b4904f54848`.
- product merge `44a72276e87f611791348fbd11584e6aff56641a`; tree `f3422be8bc22c312fbb94807b71a90e815c0213e`.
- validation trigger `3dc9d2d3ba4e2e94793d70c14d18c3fb5c1b2568` changes only `.github/homelab-webos-2.8.2-validation.txt`.
- Port Analysis #1 / `34578965427`: GREEN; exactly five overlapping files reviewed.
- Port Staging #3 / `34582511512`: GREEN; focused tests, Node 20 build and exact `org.moonfin.webos` / `2.8.2` / `index.html` verification passed before isolated push.
- accepted-branch regression #57 / `34582511474`: GREEN.
- established update-branch validation #58 / `34582969197`: GREEN; all Discovery tests/build/identity/package/upload steps passed.
- #58 artifact `10192446254`, ZIP digest `sha256:7cb6387cde7681fb598edb431d31bb7f596a9e86dd1be27b0fc5c6d3c7fb4717`.
- packaged IPK `sha256:75be2fedecbd3b503a5f74d2c2fad403e9ac0bede4c842d4da87bd80cae2460a`; independently recomputed and matched the packaged checksum.
- conflict-probe PR #1 is CLOSED and unmerged.

## Stable-release state at checkpoint

- Moonfin Core latest official stable: `2.5.1`; accepted stable: `2.5.1`.
- Smart-TV latest official stable: `2.8.2`; accepted/live stable: `2.7.0`; validated candidate: `2.8.2` on `update/webos-2.8.2`.
- The accepted/live Smart-TV baseline is intentionally not advanced until physical LG acceptance and deliberate promotion.

## Permanent safeguards

- production Android signing certificate: `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604` — preserve.
- webOS app ID: `org.moonfin.webos` — preserve.
- Smart-TV rollback: `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e` — preserve.
- unsupported semantics continue to fail closed.
- GitHub candidates are not production acceptance.

## Remaining work — outside this checkpoint

The next primary phase is controlled real-world acceptance: Web, Android mobile/tablet, Android TV/Google TV, LG OLED65C6PSA webOS, real Jellyfin/Seerr recommendation quality, request/detail/local playback, lifecycle/resume/update compatibility, then deliberate production cutover with rollback prepared.

Do not restart completed GitHub/code phases unless real acceptance exposes a genuine defect or a newer official release arrives.
