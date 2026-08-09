# Home Lab upstream Moonfin notes

This file records upstream Moonfin/Moonbase changes that matter to the Home Lab fork so future hub/UI work does not accidentally remove or duplicate them.

## Current upstream baseline

- Synced Home Lab fork to upstream `Moonfin-Client/Moonfin-Core` through commit `3e9184dbcd5e48abd7a02c3f1beed235a2269dce` on 2026-08-09.
- Moonfin version: `2.4.0+30000146`.
- Android TV version: `2.4.0`, build `2000013`.
- `homelab/hubs-v1-pre-2.4-sync` preserves the pre-sync Home Lab branch as rollback/reference.
- Keep the Home Lab hub/navigation patches on top of upstream rather than freezing an old Moonfin base.
- Current Home Lab server was on Moonbase `2.0.2.0`; upstream Moonbase `2.0.3.0` was released 2026-08-08 and should be installed before the next web baseline is signed off.

## Upstream Moonfin features/fixes to preserve

- OLED Mode with Subtle/Vivid options and true-black-oriented presentation.
- Configurable personal rating styles and server-backed personal ratings. This is relevant to future per-user recommendation work.
- Seerr improvements for continuing TV series: Request More remains available where appropriate, available seasons get a green check, and continuing-series handling was tightened.
- External/discovery row taps now resolve owned titles back to the local library and non-owned titles through Seerr/TMDb.
- Mobile library initial-load/scroll crash guards.
- Library lazy-loading, local search, letter-jump and cold-start prefix-scan performance fixes.
- Home-screen return behaviour realigns the viewport to the row the user came from.
- Mobile media-bar trailer playback/width fixes.
- Specials displayed inside a regular season retain the correct season context during playback/navigation.
- Optional auto-hide behaviour for Skip Intro/Outro controls.
- MPEG-4 Part 2 direct play when the client device can decode it.
- Android TV Dolby Vision Profile 7 support documentation and reworked audio passthrough behaviour.
- Media3 playback fixes: audio view mounting and heap-aware buffer budgeting, especially important for low-RAM Android/TV hardware.
- Updated trickplay and Live TV direct-play defaults.
- Ongoing localization updates.

## Moonbase 2.0.3 changes to preserve/use

- New Playback admin-defaults tab for autoplay, language/subtitle defaults, skip lengths, intro behaviour, Still Watching, Next Up timeout and rewind durations.
- Admin-default pickers for Action Buttons and Seerr Discovery row order.
- Sync profile support for OLED Mode, player time labels and newer home-row options.
- ROM/BIOS routes now answer HEAD requests for client-side size checks.
- Fixes incorrect admin preference keys/units that previously caused some defaults to silently do nothing.
- Removes stale admin controls that no longer map to client settings while retaining underlying sync properties.
- Corrects Resume/Unpause Rewind option values and the Details Screen Blur label.

## LG lounge TV client

- The official `Moonfin-Client/Smart-TV` client explicitly supports LG TVs from 2016 onward and webOS 3.0+, so the LG OLED65C6PSA is in its documented support range.
- The webOS package is a native TV-oriented `.ipk` using the separate Enact/Sandstone Smart-TV codebase and webOS Starfish playback pipeline.
- Therefore the LG client will not automatically inherit Flutter `Moonfin-Core` UI patches. Home / Movies / TV / Anime row logic should remain conceptually consistent, but LG navigation/layout changes must be ported to the Smart-TV fork separately.
- This is desirable for the Home Lab design: shared content/row intent, platform-specific navigation, sizing, focus and remote behaviour.

## Home Lab design implications

- Do not reimplement personal ratings; use the upstream capability as an input to future per-user recommendations where practical.
- Preserve upstream Seerr ownership/request routing when building custom discovery rows.
- Preserve upstream home-row focus/return behaviour when redesigning Home.
- Keep OLED Mode available and compatible with the Home Lab visual redesign.
- Use Moonbase's new Seerr discovery row-order/profile capabilities where useful instead of duplicating server-side settings.
- Custom Movies / TV / Anime hubs should remain a thin overlay on current upstream Moonfin so playback, navigation, library and Seerr fixes continue to flow through.
- For LG webOS, port the final logical hub/row model into `Moonfin-Client/Smart-TV` rather than trying to install the Flutter Android/TV build.

## Update rule

Before a major Home Lab Moonfin release or after a meaningful upstream Moonfin/Moonbase/Smart-TV release, compare/sync current upstream, review new release notes/commits for UI, playback, Seerr, recommendation and platform changes, preserve relevant behaviour, then rebuild only the affected Home Lab targets. Run the full platform matrix only at milestone validation points.
