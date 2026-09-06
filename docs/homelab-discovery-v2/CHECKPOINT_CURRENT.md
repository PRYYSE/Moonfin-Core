# Home Lab Discovery v2 — Current Checkpoint

**Last updated:** 2026-09-06 Australia/Adelaide

This file is the primary resume point for any future chat/agent working on the Home Lab Moonfin architecture pivot.

## Objective

Replace the legacy broad Home Lab Moonfin fork with:

> current stable official Moonfin + a small isolated Home Lab Discovery overlay + server-driven Discovery catalogue.

Maintained clients:

1. Web
2. Android mobile/tablet
3. Google TV / Android TV (Google TV Streamer 4K)

LG webOS is retired.

## Work mode

The user requested Unlazy **Solo Complete**: do everything possible in GitHub/research/testing/preparation without waiting for interactive checkpoints. Do not touch the live server because this environment cannot execute commands there. Prepare safe batched server commands instead.

## Verified upstream state

Re-checked 2026-09-06:

- official Moonfin latest stable: `2.5.1`
- official Moonfin stable commit: `f18c45b1fbf9b63871b4f93237179f9706154763`
- official Moonfin upstream `main`: `508f052f4da725b1f520f4a73b64330d43c86f92`
- official Moonbase latest stable: `2.2.0`
- Moonbase 2.2.0 bundles Moonfin Web 2.5.1
- Moonfin 2.5.1 uses Flutter `3.44.1`
- official Android has `mobile`, `mobile-beta`, `androidTv`, and `androidTv-beta` flavours
- official Moonbase supports `MOONFIN_WEB_ROOT`

Production will follow stable tags. Upstream `main` is compatibility-canary only.

## GitHub changes already completed

Repository: `PRYYSE/Moonfin-Core`

Archive branches created before any reset:

- `archive/pre-v2-main-2026-09-06` -> `cfe9c5c1a4c32d1c0828eff5ed41ea3a2947d126`
- `archive/seerr-discovery-v1-2026-09-06` -> `aa604b6cdc0083cebe8762f85ede896024f88725`
- `archive/live-web-a9c789-2026-09-06` -> accepted live Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- `archive/android-accepted-e7e5ab-2026-09-06` -> accepted Android source `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`

Fork `main` was then force-synchronised to current official upstream `main`:

- `main` -> `508f052f4da725b1f520f4a73b64330d43c86f92`

Clean production work branch created from the current stable 2.5.1 commit:

- `homelab/discovery-v2` -> initially `f18c45b1fbf9b63871b4f93237179f9706154763`

The legacy branches were not deleted.

## Legacy live state — do not alter yet

The existing live server remains the known-good rollback/reference until the replacement passes acceptance gates:

- custom Moonbase: `2.0.3.1`
- live Web source: `a9c789fff317b41bba268d3a213439e23b8d1af5`
- compiled Discovery: `481/486` lanes
- Seerr enabled
- prepared old pointer/touch hotfix exists but was never deployed

Do **not** spend time finishing the old pointer hotfix unless this architecture pivot is abandoned.

Existing accepted Android baseline:

- source: `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`
- version: `2.4.0+30000147`
- signing root on server: `/srv/appdata/moonfin/android-signing`
- signing certificate SHA-256: `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Never regenerate Android signing.

## Architectural lock

Custom code should be isolated under:

`lib/features/homelab_discovery/`

Official Moonfin should remain authoritative for Home, standard navigation, playback, downloads, themes, Seerr auth/session, request handling, media detail routes, mobile input, and Android TV focus/D-pad behaviour.

The custom route must be guarded:

- valid compatible catalogue -> Home Lab Discovery
- missing/invalid/incompatible catalogue -> stock `SeerrDiscoverScreen`

The custom catalogue should be static server-driven JSON served from:

`/Moonfin/Web/homelab/discovery.catalogue.json`

Target server root:

`/srv/appdata/moonfin/`

with `MOONFIN_WEB_ROOT` pointing Moonbase to a persistent external Web release symlink.

## Legacy breadth evidence

Comparing old fork base `cfe9c5c...` to accepted live source `a9c789...` shows **346 commits ahead** and broad modifications across Home, navigation, Seerr repository/client, DI, browse screens and rollout tooling. This is why wholesale cherry-picking is forbidden.

## Next work from this checkpoint

Continue on `homelab/discovery-v2` only.

1. Commit architecture and keep/adapt/drop matrix.
2. Inspect current official APIs against each legacy Discovery component.
3. Scaffold the isolated feature and guarded entry/fallback.
4. Port the server-driven catalogue schema/loader first.
5. Port pure Discovery engine components selectively (composer, dedup, rotation, personal presentation, pagination/refinement) only where upstream does not already provide the capability.
6. Add focused tests and CI that run on `homelab/discovery-v2` pushes.
7. Prepare server migration scripts and rollback scripts without executing them.
8. Update this checkpoint after each meaningful verified milestone.

## Acceptance gates before live cutover

- fork/archive refs verified
- current stable baseline builds/tests
- custom diff remains narrow
- missing/invalid catalogue falls back to stock Discovery
- catalogue schema validates
- no unexplained regression below accepted 481-lane semantic baseline
- Web mouse/touch/keyboard tabs work
- mobile touch works
- Google TV D-pad/focus/back works
- request and local media routes work
- Android signing certificate unchanged and versionCode increased
- stock Moonbase + external Web root migration has a tested rollback path

## Things not to do

- do not delete legacy branches/backups
- do not modify the live server from GitHub-only work
- do not regenerate Android signing
- do not reintroduce broad Home/nav/player customisation
- do not force the remaining five semantic lanes merely to reach 486
- do not merge upstream `main` continuously into production; production follows stable tags
- do not claim server cutover complete until commands have actually been run and runtime gates pass
