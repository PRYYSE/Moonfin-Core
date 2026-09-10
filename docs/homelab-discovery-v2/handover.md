# Home Lab Discovery v2 — Handover

**Handover date:** 2026-09-10 Australia/Adelaide  
**Boundary:** Platform-specific implementation is complete. Start next chat at **Cross-platform parity + recommendation quality**.

## 1. New-chat source of truth

Use this order and do not reconstruct completed work from older chats:

1. current chat/user instructions
2. current GitHub/repository state
3. `docs/AI_PROJECT_STATE.md`
4. this handover
5. current platform checkpoint files
6. confirmed project history
7. older chats/plans

If repository state conflicts with documentation, trust the repository and reconcile the docs.

Primary repo/branch:

- `PRYYSE/Moonfin-Core`
- `homelab/discovery-v2`

Smart-TV repo/branch:

- `PRYYSE/Smart-TV`
- `homelab/webos-discovery-v2`

Do a **narrow startup reconciliation only**: current branch HEADs, these checkpoint files and any exact workflow/source referenced below. Do not re-audit either repository or restart earlier platform stages.

## 2. Exact current project boundary

Completed:

- shared Discovery semantics/personalisation foundation
- catalogue/compiler
- Web implementation
- Android mobile/tablet implementation
- Android TV / Google TV implementation
- Smart-TV/webOS implementation and final cross-repo reconciliation

Next:

1. **Cross-platform parity + recommendation quality**
2. whole-product CI/release engineering
3. upstream-update automation/protocol integration
4. explicit GitHub completion checkpoint
5. physical/live acceptance

No physical/device/live acceptance has been claimed from CI.

## 3. Home Lab architecture relevant to Moonfin

### Hosts/network

LAN: `192.168.50.0/24`

- Proxmox VE host: `192.168.50.10`
- Home Assistant OS VM: `192.168.50.11`
- Debian Docker VM: `192.168.50.12`

Router: ASUS RT-AX82U v2. Use wired Ethernet where practical and Tailscale for remote management. Never expose Proxmox port 8006 directly.

### Media paths

- Movies: `/data/media/movies`
- TV: `/data/media/tv`
- Anime: `/data/media/anime`
- Anime Movies: `/data/media/anime-movies`
- Usenet incomplete: `/data/usenet/incomplete`
- Usenet Radarr complete: `/data/usenet/complete/radarr`
- Usenet Sonarr complete: `/data/usenet/complete/sonarr`

Docker appdata/databases: `/srv/appdata` on NVMe. Main media Compose historically `/opt/stacks/media`.

Media identity: PUID 1000 / PGID 1001. Preserve hardlinks/atomic moves and consistent paths/permissions.

### Relevant services

Jellyfin, Moonbase, Moonfin, Seerr, Radarr, Sonarr, Prowlarr, SABnzbd, qBittorrent/Gluetun, Bazarr, Homarr, Cockpit, Recyclarr and SMB.

Usenet is the automatic default, primarily NZBGeek + Frugal. Torrents/Nyaa are manual fallback unless deliberately changed.

### Jellyfin

Libraries:

- Movies `/data/media/movies`
- Anime Movies `/data/media/anime-movies`
- TV `/data/media/tv`
- Anime `/data/media/anime`

Hardware transcoding: Intel QSV via i915 `/dev/dri/renderD128`; do not switch to the NVIDIA MX250 without a clear reason. Transcode path `/transcode`. Prefer Direct Play.

Lounge TV: LG OLED65C6PSA. Supports Dolby Vision/HDR10/HLG, not HDR10+ or DTS passthrough. Audio-only DTS transcoding is acceptable.

## 4. Live system boundary — DO NOT TOUCH during parity work unless explicitly instructed

Live remains:

- custom Moonbase `2.0.3.1`
- live Web source `a9c789fff317b41bba268d3a213439e23b8d1af5`
- accepted legacy Discovery reference: 481/486
- Seerr enabled

The next parity stage is GitHub/code/analysis work first. Do not install candidates, modify live services, or infer physical success from CI.

## 5. Shared Discovery foundation — COMPLETE, DO NOT REDO

Shared accepted catalogue/accounting:

- schema v2
- **486 authored sections**
- **481 active reference sections**
- supported semantics use explicit policies/sources
- unsupported structural/context semantics fail closed rather than fabricating meaning

Shared safeguards already implemented and tested:

- bounded paging/read-ahead
- caching/LKG behaviour
- deduplication
- identity safety
- membership/availability/requestability policy
- deterministic composition
- surfaced-lane novelty/rotation
- refresh/reset semantics
- personal source handling
- force-refresh handling
- failure isolation
- deep paging and retained state

Important shared semantics source milestone:

- source `5d9f3e63d644f303db918b02d31bf55be7e92346`
- workflow #102 / `34189599805` GREEN
- at that milestone: 88 Discovery Flutter tests + 8 catalogue Python tests
- full Web/mobile-beta/androidTv-beta candidates passed
- artifact `10042251886`
- artifact digest `sha256:aae6742a1c300a3f6aef66c9a3e1af67a545505c7894282add9346052d7baab4`

Do not reintroduce generic hash/slot behaviour where stronger provenance-specific semantics now exist.

## 6. Web — GITHUB/CODE COMPLETE

Final Web source:

`1ac1499a0d43d404fa46d1e1abf49a433f972ea9`

Workflow:

- #115 / `34291216084` GREEN
- focused job `102277953232`
- full candidate job `102279011763`

Evidence at closure:

- 93 normal Discovery tests passed, 5 Web-only skipped in normal runner
- Chrome Web/entry-route tests 12/12
- route integration PASS
- full Web/mobile-beta/androidTv-beta builds PASS
- artifact `10082137559`
- digest `sha256:f2a7fc6b32667d3f4d38cf3a8e4165c2cce46d39facbd6dccb029687365e2abc`

Web-specific work already includes adaptive card density, pointer/touch/keyboard interaction and correct Jellyfin-vs-Seerr routing. Do not reopen unless parity evidence identifies a real defect.

## 7. Android mobile/tablet — GITHUB/CODE COMPLETE

Final source:

`4af01af054d9b7cbe8e230b7ded482cb8fea330c`

Final workflow:

- #120 / `34326151119` GREEN
- focused job `102383765266`
- full build job `102385002869`

Evidence:

- route PASS
- 486-lane catalogue/compiler + 8 Python tests PASS
- format PASS
- analyse PASS
- Discovery **100 passed / 5 skipped**
- Chrome **12 passed**
- custom-scope PASS
- Web + mobile-beta + androidTv-beta candidates PASS
- artifact `10094778627`, size `304608904` bytes
- artifact digest `sha256:27e01f5d5db575ee8d853e9808bbee7a2595dfa453be9ccd086ea0b3313cb421`
- mobile APK SHA-256 `4d968b1ee2a27dddfdba8c2aa117f7301323dee3d3ce861f075b015992aced8e`
- Android TV baseline APK SHA-256 `2c7ece2f5042f93d247b89d490d57de844d8d5b80f1ee05634128d7930e63621`
- Web SHA-256 `8f17099b4668300f763d246a6db96ddc7938962b4cad1712171c30dff48b4b73`

Adaptive layout is complete:

- compact `<600 px`
- medium `600–839 px`
- expanded `>=840 px`
- non-Web tab targets >=48 px

State semantics already cover retained tab state, coalesced normal loads, retry-safe failure, refresh/reset, safe overlapping paging/refresh and duplicate paging joining one operation.

Physical mobile/tablet acceptance is deferred.

## 8. Android TV / Google TV — GITHUB/CODE COMPLETE

### Existing focus architecture — preserve

`HomeLabDiscoveryTvLane` uses the existing `LockedFocusRow` primitive:

- one deterministic row focus owner
- 168 px cards
- 16 px spacing
- 24 px horizontal padding
- focus memory per `homelab-discovery:<tab>:<section>`
- Select opens focused card once
- Up/Down delegates to owning landing screen
- left boundary transfers to host
- right boundary opens See All when expandable, otherwise transfers to host

`HomeLabDiscoveryTvGrid`:

- one deterministic FocusNode
- focus memory
- responsive columns targeting 168 px, max 12
- RTL-aware horizontal navigation
- vertical row traversal with partial-final-row clamp
- Select/Back one-shot handling
- near-end paging threshold two rows
- paging notification dedup
- focus restoration after data changes
- pointer activation retained

### TV recovery/focus implementation

Slice 1 final recovery gate:

- source `955b5496d8e0d82d90ddb8de69b838737333243a`
- workflow #124 / `34416882794` GREEN
- Discovery 103 passed / 5 skipped
- Chrome 12 passed

Slice 2 primary focus source:

`2a204646fd296df1f57bd4dc4d7d3d1f969d7e6a`

Key final behaviour:

- TV tab strip owns one focus node
- Left/Right changes tabs while strip retains focus
- Down/Select enters active tab content
- first-lane Up returns to tab strip
- remembered lane/card re-entry
- inactive TabBar pages cannot steal autofocus
- deep-grid Up/Down edge delegation
- populated deep browse exposes remote Refresh
- paging errors expose reachable Retry More
- focus restores after refresh/retry/detail/deep route return

### Important paging defect fixed

Core source:

`5e0886a114dc1ee7ba783512e80e648634b915a7`

Problem: rebuilt controller state wrapped unchanged items in a fresh List; grid logic previously treated list identity as new paging data and could re-arm near-end paging. After page-2 failure that could cause an automatic retry and hide Retry More before the user acted.

Final semantics:

- same ordered logical `(mediaType,id)` list does not re-arm merely because wrapper identity changed
- real logical media changes re-arm
- explicit user Refresh can deliberately re-arm
- focus restoration does not re-arm implicitly

Workflow #127 / `34422202215` GREEN:

- Discovery 106 passed / 5 skipped
- Chrome 12 passed
- route/catalogue/8 Python/format/analyse/scope PASS

### Final Android TV source/gate

Final source:

`15ccc28b84727543ad714ef19dd318f907d1a1d8`

Workflow #128 / `34429841034` GREEN:

- focused job `102722801700`
- full candidate job `102723571678`
- Discovery **107 passed / 5 skipped**
- Chrome **12 passed**
- route, 486 catalogue + 8 Python tests, format, analyse and custom scope PASS
- wide-TV regression passes at 1920x1080 and 3840x2160 and proves off-screen focused cards scroll back into view
- Web release built
- mobile-beta release APK built
- androidTv-beta release APK built with `MOONFIN_FORCE_TV=true`

Identity/build:

- app `2.5.1+30000149`
- Android TV `2.5.1`
- TV build `2000016`
- Flutter `3.44.1`
- production app ID `org.moonfin.androidtv`
- beta app ID `org.moonfin.androidtv.beta`
- CI Android candidates use debug fallback and are **not deployment APKs**
- production signing certificate SHA-256 must remain `3163e01792e429ce972097a8e3ff9a4626488083142f8c2fdc102a4c75db2604`

Final candidate hashes:

- Android TV APK `39406273a5cf6d5cfb3d0a3316fb08b8cee6a5feec985056d51829096981279f`
- mobile APK `a9aaa9b32735e59c2ff9530a7a52c27d6a22c8b8fbbbd608da095c511fa88819`
- Web tar.gz `97084634a83e2d4ddf84976d0176bcf35d3ebea3ba11e04c6621af02f7e768e1`
- artifact ID `10134675199`
- artifact size `304720354` bytes
- artifact ZIP digest `sha256:c3f45b293d5d0b17b0e0086aa6f1724eaf6566d936e91840a0c23cbe0262014e`

Physical Android TV acceptance is deferred.

## 9. Smart-TV/webOS — GITHUB/CODE COMPLETE

Repo/branch:

- `PRYYSE/Smart-TV`
- `homelab/webos-discovery-v2`

Preserved rollback/reference:

- known-good branch `homelab/webos-v1-staging`
- preserved candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`
- app ID `org.moonfin.webos`
- version `2.7.0`
- entry `index.html`
- target TV LG OLED65C6PSA

Do not overwrite the rollback branch/candidate or change app identity merely for parity work.

### Mature webOS foundation — preserve

- lightweight Enact/webOS client; do not replace with Flutter Web
- guarded six-tab catalogue UI with stock `SeerrDiscover` fallback
- network-first server-scoped catalogue/LKG loader
- fail-closed planner aligned with Core filter/sort/date-token policy
- authenticated narrow Moonbase Seerr proxy
- membership filtering
- bounded lane loading
- deterministic composition and post-fetch dedup
- persistent surfaced-lane rotation
- refresh/reset handling
- real Jellyfin/Seerr personalisation sources
- unsupported semantics fail closed
- Enact Spotlight landing focus with exact card/See All restoration
- deep See All route/controller/VirtualGrid with incremental paging, dedup, retry and retained data/focus
- owned selections preserve Jellyfin identity and open local detail/playback
- failed refresh retains usable data and shows failure
- remote-reachable Retry/Load More/error states
- explicit `End of list`
- old-TV legacy WebKit build path
- artwork fallback
- provider/TMDB identity safety
- opt-in aggregate recommendation-quality diagnostics

### Old-LG performance policy — preserve

Low performance tier:

- w780 backdrops
- no backdrop blur
- no backdrop scale/fade animation
- 240 ms focus debounce
- non-animated row scrolling
- no invisible backdrop fetch when Home backdrops are disabled

Mid tier caps configured backdrop blur at 4 px. High tier preserves normal quality.

Short displays `<=800 px` use compact deep browsing:

- 160 x 300 virtual-grid footprint
- 240 px poster area
- tighter spacing/lower backdrop resolution
- normal 1080p path remains 190 x 350
- Enact VirtualGrid supplied positioning style must be merged, not replaced, to preserve legacy transforms/positioning

Do not increase initial lane concurrency/personal source fan-out casually on the LG C6.

### webOS semantic accounting

Shared accepted reference remains **486 authored / 481 active**.

webOS intentionally has a truthful static capability ceiling of **468 executable sections** before runtime sparse/error hiding.

Thirteen active catalogue lanes remain deliberately ineligible because their structural/context semantics have not been proven cheaply/truthfully on webOS:

For You:

- `Continue Exploring`

Series:

- `Limited-Series Spotlight`
- `Continue Exploring Series`
- `One-Season Wonders`
- `Long-Running Favourites`
- `Weekend Binge`

Anime:

- `Anime Specials & TV Movies`
- `One-Season Anime`
- `Long-Running Anime`
- `Bingeable Anime`
- `Completed Anime`
- `Continuing Anime`
- `Anime Miniseries & Short Runs`

Do not pursue 481/481 as a metric. Re-enable only if semantics are independently proven and request/memory cost is acceptable.

### Final webOS reconciliation defect

The final cross-repo check found one material semantic mismatch:

- catalogue labels advertised `Based on Your Highest Ratings` / `Similar to Anime You Rated Highly`
- webOS still used Likes + Favourites as `high-ratings`
- dynamic label said `Because You Liked ...`

Final product source:

`42854590caf4dbf847696483d943a886d5ab8ed7` — `fix(discovery-v2): use real Jellyfin high-rating seeds`

Final behaviour:

- one bounded Jellyfin item query, `Limit: 100`, recent played Movie/Series candidates
- keep only numeric per-user `UserData.Rating >= 8`
- `anime-high-ratings` inherits the same source plus its existing anime filter
- dynamic heading says `Because You Rated <title> Highly`
- initial source fan-out decreases from two Jellyfin calls to one
- focused regression proves source query/filter/chosen seed/anime alias

No catalogue structure, focus/UI, app identity or live-service change was needed.

### Final webOS workflow

#51 / `34432674158` — GREEN

- source `42854590caf4dbf847696483d943a886d5ab8ed7`
- 16/16 Discovery/integration suites
- **86/86 tests**
- strict Enact lint PASS
- legacy CSS/WebKit check PASS
- legacy compatibility patch stage: 17 files modified, 0 skipped
- optimized production Enact build compiled successfully
- IPK packaging succeeded
- identity verified `org.moonfin.webos` / `2.7.0` / `index.html`
- IPK `Moonfin_webOS_2.7.0.ipk`
- IPK SHA-256 `80a54d415b99c813b893c6abc7b465fa8f383244be01aab791cd9aefd0a90d10`
- artifact ID `10135098617`
- artifact name `Moonfin-HomeLab-webOS-DiscoveryV2-42854590caf4dbf847696483d943a886d5ab8ed7`
- artifact size `4,312,912` bytes
- artifact ZIP digest `sha256:7b7b1f60d05587a59fbd5913d0f3762fad150529c5e1a0a5f09bba09c8bd7c67`

Previous #50 source `a3a3317894a90bbab8b12cc7764187a8c5591369` remains a useful prior verified rollback/reference candidate:

- #50 / `34184420915` GREEN
- 85/85 tests
- artifact `10040048352`
- artifact digest `sha256:6e765d2ad65fcd0cfb487bfc13075da209332e3f5004ea3e14a434b8d2661eef`
- IPK manifest SHA-256 `24e7a3af27c6ddf77d747b9990780073edb692ad6cef6453957d3afc45ee8e06`

Physical LG acceptance remains deferred.

## 10. Cross-platform parity + recommendation quality — EXACT NEXT STAGE

The next chat should **not** start by changing code. First build an evidence-based semantic/behaviour matrix across the four delivery surfaces:

1. Moonfin-Core Web
2. Android mobile/tablet
3. Android TV / Google TV
4. Smart-TV Enact/webOS

The goal is common advertised behaviour and recommendation quality, not identical internals.

### Matrix dimensions

At minimum compare:

1. **Catalogue/eligibility**
   - active/ineligible semantics
   - source support
   - fail-closed behaviour
2. **Personalisation provenance**
   - real source used for each named strategy
   - high ratings
   - favourites/likes
   - recently watched
   - recommendations/similar
   - novelty/rewatch sources
   - anime-specific source filtering
3. **Membership/availability**
   - blacklisting
   - owned/available
   - not-owned/requestable/requested
   - watched/unwatched
   - NSFW handling
4. **Identity/routing**
   - valid TMDB identity
   - Jellyfin ownership resolution
   - local detail/playback vs Seerr external detail/request flow
5. **Composition/quality**
   - authored order
   - optional lane selection
   - cooldown/rotation
   - cross-lane novelty
   - family/franchise crowding
   - dedup
   - sparse/underfilled rows
6. **State semantics**
   - ordinary rebuild retention
   - retry after failure
   - refresh nonce/rotation
   - reset/new session
   - cache/LKG behaviour
7. **Deep browsing**
   - paging/read-ahead
   - duplicate in-flight request coalescing
   - failed-page retry semantics
   - retained data on error
   - explicit exhaustion/Load More behaviour
8. **Interaction/presentation**
   - Web pointer/keyboard
   - mobile touch/adaptive layout
   - Android TV D-pad/focus restoration
   - webOS Spotlight/legacy TV focus
9. **Request/performance cost**
   - initial source request count
   - paging bounds
   - caches
   - old-TV memory/image policy
10. **Recommendation quality**
   - lane/card count
   - cross-lane repeat rate
   - underfilled/failed/hidden rows
   - missing identity/artwork
   - owned-item ratio
   - title/family clustering
   - genuinely useful novelty vs repetitive recommendations

### Important parity philosophy

- A platform-specific implementation may be **different but correct**.
- Prefer the strongest truthful provenance implementation.
- Do not regress webOS to obsolete Flutter slot/hash behaviour.
- Do not weaken Core just to make it look like webOS.
- If webOS has a proven useful semantic that Core currently fails closed on, assess whether Core can adopt it safely.
- If Core has the stronger source, assess whether webOS can adopt it without old-LG cost regressions.
- Keep unproven structural/context semantics fail-closed.
- Recommendation-quality changes must be evidence-driven, not based only on catalogue labels or synthetic unit tests.

### Real-data quality evidence

webOS already has an opt-in aggregate diagnostic snapshot that can report:

- loaded lane count
- card count
- cross-lane repeat rate
- underfilled rows
- hidden/failed rows
- missing identity/artwork
- owned-item ratio

It intentionally excludes media titles and Jellyfin IDs. Use this or equivalent real Home Lab evidence when quality tuning begins. Do not enable new telemetry merely for this stage.

The user prefers many useful recommendations and wants personalisation to be meaningful, but quality takes priority over nominal lane count. Avoid micro-encodes-style thinking applied to recommendations: do not keep low-value/repetitive rows merely because they technically work.

## 11. Known non-blocking debt for later release-engineering stage

Smart-TV #51 `npm ci` reports legacy dependency vulnerabilities/deprecations, and the build logs warn about:

- Node 20/action deprecation
- old `baseline-browser-mapping`
- old `caniuse-lite` / Browserslist data
- legacy package dependencies

These did not fail the product gate. Do **not** blindly run broad `npm audit fix` or dependency upgrades during parity work; the webOS client intentionally supports legacy WebKit and indiscriminate upgrades can break the LG C6 path. Assess this later under whole-product CI/release engineering with explicit legacy-TV compatibility gates.

## 12. Archive/rollback references

Moonfin-Core archive refs that must remain useful:

- `archive/pre-v2-main-2026-09-06` -> `cfe9c5c1a4c32d1c0828eff5ed41ea3a2947d126`
- `archive/seerr-discovery-v1-2026-09-06` -> `aa604b6cdc0083cebe8762f85ede896024f88725`
- `archive/live-web-a9c789-2026-09-06` -> `a9c789fff317b41bba268d3a213439e23b8d1af5`
- `archive/android-accepted-e7e5ab-2026-09-06` -> `e7e5ab2b4f6b858c6e9ead22e13cb11f224cba86`
- `archive/pre-android-mobile-slice1-2026-09-09` -> `9491b145de7b3ea64dc6e31c4863e9c7c60520f6`

Avoid creating pointless temporary branches. `tmp-placeholder-do-not-use` is already redundant and should not be copied as a pattern.

Smart-TV rollback/reference:

- `homelab/webos-v1-staging`
- candidate `f5c3078ba388f8ba1da85166f62ebf7fe0bbda1e`
- earlier verified v2 source `a3a3317894a90bbab8b12cc7764187a8c5591369`

## 13. Working rules for the next chat

User has severe ADHD. Optimise for speed and low interaction overhead:

- action/decision first
- concise updates
- complete logical slices rather than micro-steps
- perform narrow inspection then act
- GitHub/repo is source of truth
- batch related changes
- root-cause fixes only
- do not repeatedly verify already-passed stages
- do not ask the user to repeat information available in GitHub/checkpoints/history
- update `docs/AI_PROJECT_STATE.md` after meaningful milestones
- commit/push useful stable progress often enough not to lose work
- preserve rollback data before substantial changes
- never print secrets/keys/tokens/signing material
- use Australian spelling and Australia/Adelaide dates/times

For long CI:

- do focused validation first
- trigger full workflow only when source is ready
- record exact source SHA and run ID in durable checkpoint
- if waiting for CI is the remaining work, stop
- on continuation inspect that exact run once
- do not continuously poll

## 14. Things the next chat must NOT redo

Do not:

- rebuild the catalogue foundation
- redo Web adaptive interaction
- redo Android mobile breakpoints/state retention
- redo Android TV focus architecture/recovery/paging fix
- rewrite `LockedFocusRow` without evidence
- replace webOS Enact with Flutter Web
- undo legacy WebKit compatibility patches casually
- re-enable the 13 webOS lanes just for count parity
- regenerate Android signing certificate/keystore
- treat CI Android APKs as production-signed
- install candidates to live devices during parity stage unless user explicitly changes the boundary
- alter live Moonbase/Jellyfin/Seerr merely to make tests easier
- claim physical LG/Android/device acceptance from CI

## 15. Exact first action in the new chat

1. Read this handover and `docs/AI_PROJECT_STATE.md`.
2. Check current HEAD/status for `PRYYSE/Moonfin-Core:homelab/discovery-v2` and `PRYYSE/Smart-TV:homelab/webos-discovery-v2` only.
3. Reconcile documentation if HEADs advanced; do not reconstruct old stages.
4. Inspect the current Core/webOS personalisation and policy source files needed for a semantic matrix.
5. Produce the first concise parity matrix with three classifications per difference: **intentional platform difference / stronger implementation worth sharing / genuine defect**.
6. Implement only evidence-backed defects or worthwhile shared improvements.
7. Keep recommendation-quality tuning separate from correctness: use real Home Lab diagnostic evidence before materially changing ranking/diversity policy.

The desired end state of the next stage is one coherent Discovery product across all platforms, with differences only where device/input/performance constraints justify them and with recommendation output that is both technically truthful and actually useful.
