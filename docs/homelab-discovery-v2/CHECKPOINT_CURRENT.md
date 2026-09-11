# Home Lab Discovery v2 — Current Checkpoint

**Updated:** 2026-09-11 Australia/Adelaide
**Primary branch:** `homelab/discovery-v2`

GitHub/current repo is authoritative. Do not restart completed Discovery platform work or touch live services during GitHub-only work.

## Current boundary

- Shared Discovery semantics/catalogue: COMPLETE (`486 authored / 481 active`).
- Web, Android mobile/tablet, Android TV/Google TV and Smart-TV accepted Discovery parity: GITHUB/CODE COMPLETE.
- Cross-platform parity/recommendation semantics: COMPLETE for GitHub/code evidence.
- Whole-product Flutter release engineering: COMPLETE — #139 GREEN.
- Stable-update automation: corrected to release tags and validated GREEN.
- Current work: final validation of isolated Smart-TV 2.8.2 Home-Lab candidate.

## Smart-TV 2.8.2 evidence

- official release `2.8.2` commit `ed327948aeb8ef19098b810145ab6a3b76ccf372`.
- accepted ancestry anchor remains `384d7cab3642f846463a4308e92d213e51507edf`.
- Port Analysis #1 / `34578965427` GREEN; exactly five overlap paths explicitly reviewed.
- reviewed conflict patch SHA-256 `23d7800c6d15812cea030a8e5329bea267a5dd17d18be9003efb9b4904f54848`.
- repair/control source `8fb273c024c773d730bd22304fa3d12961db18a2`.
- Port Staging #3 / `34582511512`: GREEN; release/ref guard, exact conflict gate, patch, focused tests, Node 20 build, app identity/version/entry and isolated push all passed.
- accepted-branch regression #57 / `34582511474`: GREEN.
- #57 artifact `10192272864`; digest `sha256:a37554228197b4b8640a722f96b274eebe0a0daf6f3003a3d9fc31fa3796370c`.
- isolated product merge commit `44a72276e87f611791348fbd11584e6aff56641a`; tree `f3422be8bc22c312fbb94807b71a90e815c0213e`.
- same-tree checkpoint `26883e4dc3d1d2d25ce820756cf09a845227e3c1`.
- validation trigger `3dc9d2d3ba4e2e94793d70c14d18c3fb5c1b2568` adds only `.github/homelab-webos-2.8.2-validation.txt`, not product/package content.

## Waiting — inspect ONCE next continuation

Home Lab webOS Discovery v2 #58 / `34582969197`, source `3dc9d2d3ba4e2e94793d70c14d18c3fb5c1b2568`, captured IN PROGRESS at dependency install.

**DO NOT POLL #58 AGAIN THIS CYCLE.**

## Exact next actions

1. Inspect #58 once next continuation.
2. If green, capture IPK artifact metadata/digest and verify established tests/build/app-ID/version/package checks.
3. Mark Smart-TV 2.8.2 GitHub/code integration complete and retire conflict-probe PR #1.
4. Update stable baselines/checkpoints and create the explicit whole-project GitHub completion checkpoint if no other code blocker remains.
5. Keep accepted product/rollback refs and all live/physical systems unchanged until deliberate later acceptance/promotion.

## Locked invariants

- Android production signing cert `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`.
- webOS app ID `org.moonfin.webos`, entry `index.html`, Node 20 for legacy LG C6 compatibility.
- rollback `homelab/webos-v1-staging` / `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`.
- no CI result equals physical/live acceptance.
