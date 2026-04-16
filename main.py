#!/usr/bin/env python3

# nomadBlog - core library
# Imported by every .mu page. Initializes DB on import.

import os
import sys
import sqlite3
import hashlib
import uuid
import re
from datetime import datetime

# ─── Configuration ────────────────────────────────────────────────────────────
storage_path     = "/home/user/.nomadBlog"   # absolute path, no trailing /
page_path        = ":/page/blog"             # path on your node, no trailing /
blog_name        = "nomadBlog"
site_description = "Articles, thoughts & news from the node"
node_homepage    = ":/page/index.mu"         # link to node homepage
# ──────────────────────────────────────────────────────────────────────────────

# Page config: no cache, dark background, light text
PAGE_HEADER = "#!c=0\n#!bg=222\n#!fg=ddd\n"

_db_connection = None


def get_db():
    global _db_connection
    if _db_connection is None:
        os.makedirs(storage_path, exist_ok=True)
        _db_connection = sqlite3.connect(f"{storage_path}/blog.db")
        _init_db(_db_connection)
    return _db_connection


def _init_db(conn):
    c = conn.cursor()
    c.executescript("""
        CREATE TABLE IF NOT EXISTS posts (
            post_id     TEXT PRIMARY KEY,
            title       TEXT NOT NULL,
            content     TEXT NOT NULL,
            created     INTEGER NOT NULL,
            changed     INTEGER NOT NULL
        );

        CREATE TABLE IF NOT EXISTS tags (
            tag_id      INTEGER PRIMARY KEY AUTOINCREMENT,
            post_id     TEXT NOT NULL,
            name        TEXT NOT NULL,
            FOREIGN KEY (post_id) REFERENCES posts(post_id)
        );

        CREATE TABLE IF NOT EXISTS admin_sessions (
            session_id  TEXT PRIMARY KEY,
            created     INTEGER NOT NULL
        );

        CREATE TABLE IF NOT EXISTS settings (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
    """)
    conn.commit()


def query_database(sql):
    conn = get_db()
    c = conn.cursor()
    c.execute(sql)
    return c.fetchall()


def execute_sql(sql):
    conn = get_db()
    c = conn.cursor()
    c.execute(sql)


def close_database(write_changes=True):
    global _db_connection
    if _db_connection:
        if write_changes:
            _db_connection.commit()
        _db_connection.close()
        _db_connection = None


def check_uuid(value):
    try:
        uuid.UUID(value)
        return True
    except Exception:
        return False


def safe(text):
    """Escape single quotes for SQL."""
    return text.replace("'", "''")


def prepare_content(text):
    text = text.replace("$newline$", "\n")
    text = safe(text)
    return text


def prepare_title(text):
    text = text.strip()
    text = safe(text)
    return text


def prepare_tag(text):
    text = text.strip().lower()
    text = re.sub(r"[^a-z0-9_\-äöüß]", "", text)
    return text


def remove_micron(text):
    """Strip Micron formatting codes from plain text."""
    return re.sub(r"`[^`]*`", "", text)


def format_date(timestamp):
    """Convert Unix timestamp to DD-MM-YYYY."""
    try:
        dt = datetime.utcfromtimestamp(timestamp)
        return dt.strftime("%d-%m-%Y")
    except Exception:
        return "Unknown"


def get_admin_password_hash():
    rows = query_database("SELECT value FROM settings WHERE key = 'admin_password_hash'")
    if rows:
        return rows[0][0]
    return None


def check_admin_session():
    session_id = os.environ.get("var_session", "")
    if not session_id:
        return False
    rows = query_database(
        f"SELECT session_id FROM admin_sessions "
        f"WHERE session_id = '{safe(session_id)}' AND unixepoch() < (created + 3600)"
    )
    return len(rows) > 0


def get_setting(key, default=""):
    """Read a single settings value."""
    rows = query_database(f"SELECT value FROM settings WHERE key = '{safe(key)}'")
    if rows:
        return rows[0][0]
    return default


def set_setting(key, value):
    """Write/update a settings value (upsert)."""
    execute_sql(f"DELETE FROM settings WHERE key = '{safe(key)}'")
    execute_sql(f"INSERT INTO settings (key, value) VALUES ('{safe(key)}', '{safe(value)}')")


def lxmf_link(address):
    """Clickable LXMF link — lxmf@ADDRESS format.
    Color/underline goes outside the link tag, never inside the label."""
    if address and address.strip():
        addr = address.strip()
        return f"`F4be`[lxmf@{addr}`lxmf://{addr}]`f"
    return ""


def print_header(title=None):
    """Print page config headers and navigation bar.
    page_path already starts with : (e.g. :/page/blog) so links use it directly."""
    print(PAGE_HEADER, end="")
    print(f"`c`!`F0af{blog_name}`!`f`c")
    print(f"`c`F777{site_description}`f`c")
    if title and title != blog_name:
        print(f"`c`F555{title}`f`c")
    print("`a")  # reset centering — everything below is left-aligned
    session_id = os.environ.get("var_session", "")
    print(
        f"`[Blog`{page_path}/index.mu`session={session_id}]"
        f"  `[About`{page_path}/about.mu`session={session_id}]"
        f"  `[Tags`{page_path}/tags.mu`session={session_id}]"
        f"  `[Help`{page_path}/help.mu`session={session_id}]"
        f"  `Fca4`[← Node Start`{node_homepage}]`f"
    )
    print("-")
    print()


def print_footer():
    """Footer with suite notice."""
    print("-")
    print("`c`F444Off-Grid Community Suite · NomadNet`f`c")
    print("`a")  # reset centering after footer


# Initialize database on import
init_db = _init_db
