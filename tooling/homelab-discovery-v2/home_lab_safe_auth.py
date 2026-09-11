#!/usr/bin/env python3
"""Retrieve an existing Jellyfin API token without printing it."""

import os
import sqlite3
from pathlib import Path


DEFAULT_DB = Path("/srv/appdata/jellyfin/data/data/jellyfin.db")


def jellyfin_token() -> str:
    configured = os.environ.get("MOONFIN_JELLYFIN_TOKEN", "").strip()
    if configured:
        return configured

    db_path = Path(os.environ.get("MOONFIN_JELLYFIN_DB", str(DEFAULT_DB)))
    if not db_path.is_file():
        raise RuntimeError(
            "Jellyfin database not found at the configured explicit path: "
            f"{db_path}"
        )

    connection = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    try:
        table = connection.execute(
            "SELECT name FROM sqlite_master "
            "WHERE type='table' AND lower(name)='apikeys'"
        ).fetchone()
        if not table:
            raise RuntimeError("Jellyfin ApiKeys table was not found.")
        table_name = table[0]
        columns = {
            str(row[1]).lower(): str(row[1])
            for row in connection.execute(
                f'PRAGMA table_info("{table_name}")'
            ).fetchall()
        }
        token_column = next(
            (
                columns[name]
                for name in ("accesstoken", "apikey", "token", "key")
                if name in columns
            ),
            None,
        )
        if not token_column:
            raise RuntimeError("Jellyfin ApiKeys token column was not found.")
        row = connection.execute(
            f'SELECT "{token_column}" FROM "{table_name}" '
            f'WHERE "{token_column}" IS NOT NULL '
            f'AND length(trim("{token_column}")) > 0 LIMIT 1'
        ).fetchone()
        if not row or not str(row[0]).strip():
            raise RuntimeError("Jellyfin ApiKeys table contains no usable key.")
        return str(row[0]).strip()
    finally:
        connection.close()
