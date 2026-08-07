#!/usr/bin/env python3
"""Add the Home Lab hub destinations to Moonfin's native mobile bottom nav.

The native mobile layout shows four primary actions plus More when additional
actions exist. Keeping Home / Movies / TV / Anime first gives the fork the same
four-destination model as web/desktop while Search and secondary actions remain
available from More.
"""

from pathlib import Path

MOBILE_NAV = Path("lib/ui/widgets/mobile_bottom_nav_bar.dart")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"Refusing to patch {label}: expected one anchor, found {count}. "
            "Upstream UI structure changed."
        )
    return text.replace(old, new, 1)


def main() -> None:
    text = MOBILE_NAV.read_text(encoding="utf-8")

    if "HomelabHubRoutes.movies" in text:
        print("Home Lab mobile hub navigation already present.")
        return

    text = replace_once(
        text,
        "import '../navigation/destinations.dart';\n",
        "import '../navigation/destinations.dart';\n"
        "import '../navigation/homelab_hub_routes.dart';\n",
        "mobile hub import",
    )

    search_anchor = """      _BottomNavAction(
        icon: Icons.search_rounded,
        label: l10n.search,
        isActive: _isActive(Destinations.search),
        onTap: () {
          if (_isActive(Destinations.search)) return;
          context.navigateTopLevel(Destinations.search);
        },
      ),
"""

    hub_actions = """      _BottomNavAction(
        icon: Icons.movie_rounded,
        label: 'Movies',
        isActive: _isActive(HomelabHubRoutes.movies),
        onTap: () {
          if (_isActive(HomelabHubRoutes.movies)) return;
          context.navigateTopLevel(HomelabHubRoutes.movies);
        },
      ),
      _BottomNavAction(
        icon: Icons.tv_rounded,
        label: 'TV',
        isActive: _isActive(HomelabHubRoutes.tv),
        onTap: () {
          if (_isActive(HomelabHubRoutes.tv)) return;
          context.navigateTopLevel(HomelabHubRoutes.tv);
        },
      ),
      _BottomNavAction(
        icon: Icons.auto_awesome_rounded,
        label: 'Anime',
        isActive: _isActive(HomelabHubRoutes.anime),
        onTap: () {
          if (_isActive(HomelabHubRoutes.anime)) return;
          context.navigateTopLevel(HomelabHubRoutes.anime);
        },
      ),
"""

    text = replace_once(
        text,
        search_anchor,
        hub_actions + search_anchor,
        "native mobile hub actions",
    )

    MOBILE_NAV.write_text(text, encoding="utf-8")
    print("Home Lab native mobile hub navigation patch applied.")


if __name__ == "__main__":
    main()
