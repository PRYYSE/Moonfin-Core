#!/usr/bin/env python3
"""Patch Moonfin's existing Seerr client/repository for schema-v2 Discovery.

The patch is intentionally small and idempotent:
- SeerrHttpClient gains one authenticated, discover-only generic GET.
- SeerrRepository gains one executor that compiles SeerrDiscoveryQuery through
  SeerrDiscoveryRequestPlan and reuses the existing _withClient lifecycle.

No credentials are read or printed. Files are backed up before first mutation.
"""

from __future__ import annotations

import argparse
import shutil
import tempfile
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HTTP_FILE = ROOT / "lib/data/services/seerr/seerr_http_client.dart"
REPOSITORY_FILE = ROOT / "lib/data/repositories/seerr_repository.dart"

HTTP_METHOD_MARKER = "Future<Map<String, dynamic>> getDiscoveryPath("
REPOSITORY_METHOD_MARKER = "Future<SeerrDiscoverPage> executeDiscoveryQuery("

HTTP_INSERT_BEFORE = "  Future<Map<String, dynamic>> getCurrentUser() async {\n"
HTTP_METHOD = r'''  /// Executes a compiled deep-discovery GET through Moonfin's existing
  /// authenticated Seerr proxy. The route is deliberately restricted to the
  /// discover namespace so a server-delivered catalogue cannot turn this into
  /// an arbitrary Seerr API proxy.
  Future<Map<String, dynamic>> getDiscoveryPath(
    String path, {
    Map<String, dynamic> queryParameters = const {},
  }) async {
    final trimmed = _trimSlash(path);
    if (!trimmed.startsWith('discover/')) {
      throw ArgumentError.value(path, 'path', 'Discovery path must start with discover/');
    }
    final response = await _dio.get(
      _apiUrl(trimmed),
      queryParameters: queryParameters,
      options: _authOptions(),
    );
    _requireSuccess(response, 'getDiscoveryPath');
    final data = response.data;
    if (data is! Map) {
      throw StateError('getDiscoveryPath returned a non-object response');
    }
    return Map<String, dynamic>.from(data);
  }

'''

REPOSITORY_IMPORT_MARKER = "import '../services/seerr/seerr_http_client.dart';\n"
REPOSITORY_IMPORTS = """import '../services/seerr/seerr_discovery_request_plan.dart';
import '../services/seerr/seerr_discovery_schema.dart';
"""
REPOSITORY_INSERT_BEFORE = "  Future<SeerrDiscoverPage> search(\n"
REPOSITORY_METHOD = r'''  /// Executes one compiled server-delivered Discovery query while preserving
  /// the repository's existing Seerr client/session lifecycle.
  ///
  /// Personalised and external-list sources are intentionally handled by their
  /// dedicated services and therefore do not produce a raw Seerr request plan.
  Future<SeerrDiscoverPage> executeDiscoveryQuery(
    SeerrDiscoveryQuery query, {
    int page = 1,
    DateTime? now,
  }) async {
    final plan = SeerrDiscoveryRequestPlan.fromQuery(
      query,
      page: page,
      now: now,
    );
    if (plan == null) {
      throw UnsupportedError(
        'Discovery source ${query.source.name} requires a dedicated executor or unresolved semantic filters',
      );
    }
    return _withClient(
      (client) async => SeerrDiscoverPage.fromJson(
        await client.getDiscoveryPath(
          plan.path,
          queryParameters: plan.queryParameters,
        ),
      ),
    );
  }

'''


def patch_http(text: str) -> tuple[str, bool]:
    if HTTP_METHOD_MARKER in text:
        return text, False
    if HTTP_INSERT_BEFORE not in text:
        raise RuntimeError(f"HTTP insertion marker not found in {HTTP_FILE}")
    return text.replace(HTTP_INSERT_BEFORE, HTTP_METHOD + HTTP_INSERT_BEFORE, 1), True


def patch_repository(text: str) -> tuple[str, bool]:
    changed = False
    if "seerr_discovery_request_plan.dart" not in text:
        if REPOSITORY_IMPORT_MARKER not in text:
            raise RuntimeError(f"Repository import marker not found in {REPOSITORY_FILE}")
        text = text.replace(
            REPOSITORY_IMPORT_MARKER,
            REPOSITORY_IMPORT_MARKER + REPOSITORY_IMPORTS,
            1,
        )
        changed = True
    if REPOSITORY_METHOD_MARKER not in text:
        if REPOSITORY_INSERT_BEFORE not in text:
            raise RuntimeError(f"Repository insertion marker not found in {REPOSITORY_FILE}")
        text = text.replace(
            REPOSITORY_INSERT_BEFORE,
            REPOSITORY_METHOD + REPOSITORY_INSERT_BEFORE,
            1,
        )
        changed = True
    return text, changed


def backup(path: Path, backup_dir: Path) -> None:
    backup_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup_dir / path.name)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--backup-dir",
        type=Path,
        help="Backup directory. Defaults to a private temporary directory.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify markers and report whether mutation would be required.",
    )
    args = parser.parse_args()

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_dir = args.backup_dir or Path(
        tempfile.mkdtemp(prefix=f"moonfin-seerr-network-{timestamp}-")
    )

    original_http = HTTP_FILE.read_text(encoding="utf-8")
    original_repository = REPOSITORY_FILE.read_text(encoding="utf-8")
    patched_http, http_changed = patch_http(original_http)
    patched_repository, repository_changed = patch_repository(original_repository)

    if args.check:
        print(
            f"network_patch_required={str(http_changed or repository_changed).lower()} "
            f"http={str(http_changed).lower()} repository={str(repository_changed).lower()}"
        )
        return 0

    if not http_changed and not repository_changed:
        print("Discovery networking patch already applied; no files changed.")
        return 0

    try:
        if http_changed:
            backup(HTTP_FILE, backup_dir)
            HTTP_FILE.write_text(patched_http, encoding="utf-8")
        if repository_changed:
            backup(REPOSITORY_FILE, backup_dir)
            REPOSITORY_FILE.write_text(patched_repository, encoding="utf-8")
    except Exception:
        if (backup_dir / HTTP_FILE.name).exists():
            shutil.copy2(backup_dir / HTTP_FILE.name, HTTP_FILE)
        if (backup_dir / REPOSITORY_FILE.name).exists():
            shutil.copy2(backup_dir / REPOSITORY_FILE.name, REPOSITORY_FILE)
        raise

    print(f"Discovery networking patch applied. Backup: {backup_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
