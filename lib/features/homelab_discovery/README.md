# Home Lab Discovery v2

This feature is the only intended Home Lab product overlay on top of stock Moonfin.

Rules:

- depend on official Moonfin through narrow adapters;
- never duplicate general Home/navigation/player/Seerr session infrastructure;
- load Discovery configuration from the server-driven catalogue;
- fail closed to stock `SeerrDiscoverScreen` when the catalogue is missing, invalid or unsupported;
- keep Web, Android mobile and Android TV behaviour in the same Flutter feature;
- no secrets or per-user data in the catalogue.

The current implementation starts with the guarded catalogue/loading boundary. Deeper lane composition and UI are ported only after this boundary is verified.
