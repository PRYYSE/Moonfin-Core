# Home Lab Discovery v2

This feature is the only intended Home Lab product overlay on top of stock Moonfin.

Rules:

- depend on official Moonfin through narrow adapters;
- never duplicate general Home/navigation/player/Seerr session infrastructure;
- load Discovery configuration from the server-driven catalogue;
- fail closed to stock `SeerrDiscoverScreen` when the catalogue is missing, invalid or unsupported;
- keep Web, Android mobile and Android TV behaviour in the same Flutter feature;
- no secrets or per-user data in the catalogue.

UI invariants:

- when mobile navigation is positioned at the top, Discovery content must reserve the fixed toolbar height so the page title never overlaps the back/navigation controls;
- each non-TV landing carousel owns page-storage identity scoped to tab, section and refresh generation, preventing lazy row recycling from transplanting another lane's horizontal offset;
- ordinary rebuilds may retain a lane's position, but an explicit Discovery refresh must give refreshed carousel content a fresh scroll identity;
- TV focus-memory behaviour remains owned by the dedicated TV lane implementation and must not be coupled to mobile carousel state.

The guarded catalogue/loading boundary, rotating lane composition, deep browsing and adaptive Web/mobile/TV presentation are implemented. Physical platform acceptance is the authority for UI defects that are not decidable in automated tests.
