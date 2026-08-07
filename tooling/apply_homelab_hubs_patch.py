#!/usr/bin/env python3
"""Apply the minimal upstream-file patch for the Home Lab hub prototype.

The actual hub implementation lives in new files. Keeping the modifications to
upstream files to two deterministic insertions makes rebasing onto future
Moonfin releases substantially easier.
"""

from pathlib import Path

ROUTER = Path("lib/ui/navigation/app_router.dart")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"Refusing to patch {label}: expected one anchor, found {count}. "
            "Upstream router structure changed."
        )
    return text.replace(old, new, 1)


def main() -> None:
    text = ROUTER.read_text(encoding="utf-8")

    text = replace_once(
        text,
        "import 'destinations.dart';\n",
        "import 'destinations.dart';\nimport 'homelab_hub_routes.dart';\n",
        "router import",
    )

    text = replace_once(
        text,
        "  routes: [\n    // Auth\n",
        "  routes: [\n    ...homelabHubRoutes(),\n\n    // Auth\n",
        "router route list",
    )

    ROUTER.write_text(text, encoding="utf-8")
    print("Home Lab hub router patch applied.")


if __name__ == "__main__":
    main()
