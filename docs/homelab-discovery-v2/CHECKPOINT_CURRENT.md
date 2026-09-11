# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-11 Australia/Adelaide  
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Completed GitHub/code stages must not be restarted without current fault evidence.

## Status — GitHub/code COMPLETE

> No known GitHub/code-side work remains. Remaining work requires real devices, real services, deployment infrastructure, or subjective visual/recommendation acceptance.

The next boundary is physical/live acceptance. Do not promote accepted/rollback refs or touch live services until explicitly entering that phase.

## Locked completion evidence

- shared catalogue/compiler/semantics: COMPLETE, `486 authored / 481 active`.
- Web: COMPLETE, source `1ac1499a0d43d404fa46d1e1abf49a433f972ea9`.
- Android mobile/tablet: #120 / `34326151119` GREEN, source `4af01af054d9b7cbe8e230b7ded482cb8fea330c`.
- Android TV/Google TV: #128 / `34429841034` GREEN, source `15ccc28b84727543ad714ef19dd318f907d1a1d8`.
- cross-platform parity/recommendation: #132 / `34439296054` GREEN, source `e654668f89af49470df417d4fcc444e73c53121e`.
- whole-product Flutter release gate: #139 / `34571653740` GREEN, source `fd06ec5602351e53f0eacb56b2457ad0e80f169e`.
- upstream-update detector/protocol automation: COMPLETE; official stable releases rechecked as Core `2.5.1`, Smart-TV `2.8.2`.

## Smart-TV 2.8.2 validated candidate

- accepted/live webOS baseline remains `2.7.0`; ancestry anchor `384d7cab3642f846463a4308e92d213e51507edf`.
- official 2.8.2 source `ed327948aeb8ef19098b810145ab6a3b76ccf372`.
- product merge `44a72276e87f611791348fbd11584e6aff56641a`; tree `f3422be8bc22c312fbb94807b71a90e815c0213e`.
- Port Analysis #1 / `34578965427`: GREEN; five overlaps explicitly reviewed.
- Port Staging #3 / `34582511512`: GREEN.
- accepted-branch regression #57 / `34582511474`: GREEN.
- update-branch validation #58 / `34582969197`: GREEN; tests, build, app identity/package verification and artifact upload passed.
- artifact `10192446254`; ZIP digest `sha256:7cb6387cde7681fb598edb431d31bb7f596a9e86dd1be27b0fc5c6d3c7fb4717`.
- IPK SHA-256 `75be2fedecbd3b503a5f74d2c2fad403e9ac0bede4c842d4da87bd80cae2460a`, independently verified against the packaged checksum.
- conflict-probe PR #1: CLOSED, unmerged, retired.
- accepted branch and rollback ref remain unchanged pending physical LG acceptance.

## Completion record

See `docs/homelab-discovery-v2/GITHUB_COMPLETION_CHECKPOINT.md` for the whole-product Phase-10 closure evidence.

## Locked invariants

- Android production signing cert `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`.
- webOS app ID `org.moonfin.webos`, entry `index.html`, Node 20 for legacy LG C6 compatibility.
- rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.
- live systems remain untouched.

## Exact next action

When explicitly entering the next phase, begin controlled physical/live acceptance using the completion checkpoint as the source of truth. Do not redo completed GitHub/code work unless acceptance exposes a genuine defect.
