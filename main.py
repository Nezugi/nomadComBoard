#!/usr/bin/env python3
"""
nomadComBoard - main.py
Central library: Database, sessions, helper functions, identity auth
"""

import sqlite3
import hashlib
import os
import secrets
import time

# ─── CONFIGURATION ────────────────────────────────────────────────────────────

storage_path     = "/home/user/.nomadComBoard"          # Path for DB & data
page_path        = ":/page/comboard"                    # Path on node (: = local node)
forum_name       = "nomadComBoard"                      # Display name
site_description = "Discussions, topics & comments"     # Short description
node_homepage    = ":/page/index.mu"                    # Link to node homepage

# ─── DATABASE ────────────────────────────────────────────────────────────────

DB_PATH = os.path.join(storage_path, "comboard.db")


def get_db():
    os.makedirs(storage_path, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def init_db():
    conn = get_db()
    c = conn.cursor()

    c.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            username        TEXT    NOT NULL UNIQUE,
            password_hash   TEXT    NOT NULL DEFAULT '',
            lxmf_address    TEXT    DEFAULT '',
            display_name    TEXT    DEFAULT '',
            city            TEXT    DEFAULT '',
            website         TEXT    DEFAULT '',
            email           TEXT    DEFAULT '',
            about           TEXT    DEFAULT '',
            is_admin        INTEGER DEFAULT 0,
            is_mod          INTEGER DEFAULT 0,
            registered_at   INTEGER DEFAULT (strftime('%s','now')),
            post_count      INTEGER DEFAULT 0,
            identity_hash   TEXT    DEFAULT ''
        );

        CREATE TABLE IF NOT EXISTS subforums (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL UNIQUE,
            description TEXT    DEFAULT '',
            sort_order  INTEGER DEFAULT 0,
            created_at  INTEGER DEFAULT (strftime('%s','now'))
        );

        CREATE TABLE IF NOT EXISTS topics (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            subforum_id   INTEGER NOT NULL REFERENCES subforums(id) ON DELETE CASCADE,
            author_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            title         TEXT    NOT NULL,
            body          TEXT    NOT NULL,
            created_at    INTEGER DEFAULT (strftime('%s','now')),
            last_reply_at INTEGER DEFAULT (strftime('%s','now')),
            is_closed     INTEGER DEFAULT 0,
            comment_count INTEGER DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS comments (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            topic_id   INTEGER NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
            author_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            body       TEXT    NOT NULL,
            created_at INTEGER DEFAULT (strftime('%s','now'))
        );

        CREATE TABLE IF NOT EXISTS tags (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT    NOT NULL UNIQUE
        );

        CREATE TABLE IF NOT EXISTS topic_tags (
            topic_id INTEGER REFERENCES topics(id) ON DELETE CASCADE,
            tag_id   INTEGER REFERENCES tags(id) ON DELETE CASCADE,
            PRIMARY KEY (topic_id, tag_id)
        );

        CREATE TABLE IF NOT EXISTS sessions (
            token      TEXT    PRIMARY KEY,
            user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            expires_at INTEGER NOT NULL
        );

        CREATE TABLE IF NOT EXISTS settings (
            key   TEXT PRIMARY KEY,
            value TEXT DEFAULT ''
        );

        INSERT OR IGNORE INTO settings (key, value) VALUES
            ('rules', 'Be respectful. No spam. Have fun.');

        CREATE TABLE IF NOT EXISTS groups (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL UNIQUE,
            description TEXT    DEFAULT '',
            created_at  INTEGER DEFAULT (strftime('%s','now'))
        );

        CREATE TABLE IF NOT EXISTS user_groups (
            user_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            group_id  INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
            PRIMARY KEY (user_id, group_id)
        );

        CREATE TABLE IF NOT EXISTS subforum_access (
            subforum_id INTEGER NOT NULL REFERENCES subforums(id) ON DELETE CASCADE,
            group_id    INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
            can_read    INTEGER DEFAULT 1,
            can_write   INTEGER DEFAULT 1,
            PRIMARY KEY (subforum_id, group_id)
        );
    """)

    # Performance indices
    c.executescript("""
        CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
        CREATE INDEX IF NOT EXISTS idx_topics_subforum_id ON topics(subforum_id);
        CREATE INDEX IF NOT EXISTS idx_topics_author_id ON topics(author_id);
        CREATE INDEX IF NOT EXISTS idx_comments_topic_id ON comments(topic_id);
        CREATE INDEX IF NOT EXISTS idx_topic_tags_topic_id ON topic_tags(topic_id);
        CREATE INDEX IF NOT EXISTS idx_user_groups_user_id ON user_groups(user_id);
        CREATE INDEX IF NOT EXISTS idx_user_groups_group_id ON user_groups(group_id);
        CREATE INDEX IF NOT EXISTS idx_subforum_access_sf ON subforum_access(subforum_id);
    """)

    # Migration: add identity_hash column if upgrading from older DB
    existing_cols = [r[1] for r in c.execute("PRAGMA table_info(users)").fetchall()]
    if "identity_hash" not in existing_cols:
        c.execute("ALTER TABLE users ADD COLUMN identity_hash TEXT DEFAULT ''")

    # Migration: password_hash may need DEFAULT '' on old DBs — handled by ALTER above.
    # Migration: add groups/access tables if upgrading from older DB
    existing_tables = [r[0] for r in c.execute(
        "SELECT name FROM sqlite_master WHERE type='table'"
    ).fetchall()]
    if "groups" not in existing_tables:
        c.executescript("""
            CREATE TABLE IF NOT EXISTS groups (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    NOT NULL UNIQUE,
                description TEXT    DEFAULT '',
                created_at  INTEGER DEFAULT (strftime('%s','now'))
            );
            CREATE TABLE IF NOT EXISTS user_groups (
                user_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                group_id  INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
                PRIMARY KEY (user_id, group_id)
            );
            CREATE TABLE IF NOT EXISTS subforum_access (
                subforum_id INTEGER NOT NULL REFERENCES subforums(id) ON DELETE CASCADE,
                group_id    INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
                can_read    INTEGER DEFAULT 1,
                can_write   INTEGER DEFAULT 1,
                PRIMARY KEY (subforum_id, group_id)
            );
        """)

    conn.commit()
    conn.close()


# ─── IDENTITY AUTH ────────────────────────────────────────────────────────────

def get_remote_identity():
    """Return the connecting client's identity hash, or '' if not identified."""
    return os.environ.get("remote_identity", "").strip().lower()


def is_valid_identity(identity_hash):
    """Check that the identity hash is a valid 32-char hex string."""
    if not identity_hash or len(identity_hash) != 32:
        return False
    return all(c in "0123456789abcdef" for c in identity_hash.lower())


def get_user_by_identity(identity_hash):
    """Return user dict for the given identity hash, or None."""
    if not is_valid_identity(identity_hash):
        return None
    conn = get_db()
    row = conn.execute(
        "SELECT * FROM users WHERE identity_hash=?", (identity_hash.lower(),)
    ).fetchone()
    conn.close()
    return dict(row) if row else None


def register_user_identity(username, identity_hash):
    """Register a new user with username + identity hash only (no password).
    Returns None on success, else an error message string."""
    username      = username.strip()[:32] if username else ""
    identity_hash = identity_hash.strip().lower() if identity_hash else ""

    if not username:
        return "Username cannot be empty."
    if not is_valid_identity(identity_hash):
        return "No valid identity detected. Enable 'Identify to Nodes' in NomadNet settings."

    conn = get_db()
    if conn.execute("SELECT id FROM users WHERE username=?", (username,)).fetchone():
        conn.close()
        return "Username already taken."
    if conn.execute("SELECT id FROM users WHERE identity_hash=?", (identity_hash,)).fetchone():
        conn.close()
        return "This identity is already linked to an account."

    # Empty password_hash marks an identity-only account
    conn.execute(
        "INSERT INTO users (username, password_hash, identity_hash) VALUES (?,?,?)",
        (username, "", identity_hash)
    )
    conn.commit()
    conn.close()
    return None


def link_identity(user_id, identity_hash):
    """Link an identity hash to an existing account.
    Returns None on success, else an error message string."""
    identity_hash = identity_hash.strip().lower() if identity_hash else ""
    if not is_valid_identity(identity_hash):
        return "No valid identity detected. Enable 'Identify to Nodes' in NomadNet settings."
    conn = get_db()
    other = conn.execute(
        "SELECT id FROM users WHERE identity_hash=? AND id!=?",
        (identity_hash, user_id)
    ).fetchone()
    if other:
        conn.close()
        return "This identity is already linked to a different account."
    conn.execute(
        "UPDATE users SET identity_hash=? WHERE id=?", (identity_hash, user_id)
    )
    conn.commit()
    conn.close()
    return None


def unlink_identity(user_id):
    """Remove identity link from a user (only allowed if they have a password set)."""
    conn = get_db()
    user = conn.execute("SELECT password_hash FROM users WHERE id=?", (user_id,)).fetchone()
    if not user or not user["password_hash"]:
        conn.close()
        return "Cannot unlink: account has no password. Set a password first."
    conn.execute("UPDATE users SET identity_hash='' WHERE id=?", (user_id,))
    conn.commit()
    conn.close()
    return None


def set_password(user_id, new_password):
    """Set or update password for a user. Returns None on success, else error string."""
    new_password = new_password.strip() if new_password else ""
    if len(new_password) < 6:
        return "Password too short (min 6 characters)."
    conn = get_db()
    conn.execute(
        "UPDATE users SET password_hash=? WHERE id=?",
        (hash_password(new_password), user_id)
    )
    conn.commit()
    conn.close()
    return None


def login_by_identity(identity_hash):
    """Try to log in via identity hash. Returns (user, token) or (None, None)."""
    user = get_user_by_identity(identity_hash)
    if not user:
        return None, None
    token = create_session(user["id"])
    return user, token


# ─── GROUPS ───────────────────────────────────────────────────────────────────

def get_all_groups():
    conn = get_db()
    rows = conn.execute("SELECT * FROM groups ORDER BY name ASC").fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_group(group_id):
    try:
        group_id = int(group_id)
    except (ValueError, TypeError):
        return None
    conn = get_db()
    row = conn.execute("SELECT * FROM groups WHERE id=?", (group_id,)).fetchone()
    conn.close()
    return dict(row) if row else None


def create_group(name, description=""):
    name = name.strip()[:60] if name else ""
    description = description.strip()[:200] if description else ""
    if not name:
        return None
    conn = get_db()
    try:
        cur = conn.execute(
            "INSERT INTO groups (name, description) VALUES (?,?)", (name, description)
        )
        gid = cur.lastrowid
        conn.commit()
    except Exception:
        gid = None
    conn.close()
    return gid


def delete_group(group_id):
    try:
        group_id = int(group_id)
    except (ValueError, TypeError):
        return
    conn = get_db()
    conn.execute("DELETE FROM subforum_access WHERE group_id=?", (group_id,))
    conn.execute("DELETE FROM user_groups WHERE group_id=?", (group_id,))
    conn.execute("DELETE FROM groups WHERE id=?", (group_id,))
    conn.commit()
    conn.close()


def get_group_members(group_id):
    try:
        group_id = int(group_id)
    except (ValueError, TypeError):
        return []
    conn = get_db()
    rows = conn.execute("""
        SELECT u.id, u.username, u.display_name
        FROM users u JOIN user_groups ug ON ug.user_id=u.id
        WHERE ug.group_id=?
        ORDER BY u.username ASC
    """, (group_id,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_user_group_ids(user_id):
    try:
        user_id = int(user_id)
    except (ValueError, TypeError):
        return set()
    conn = get_db()
    rows = conn.execute(
        "SELECT group_id FROM user_groups WHERE user_id=?", (user_id,)
    ).fetchall()
    conn.close()
    return {r[0] for r in rows}


def add_user_to_group(user_id, group_id):
    try:
        user_id  = int(user_id)
        group_id = int(group_id)
    except (ValueError, TypeError):
        return
    conn = get_db()
    conn.execute(
        "INSERT OR IGNORE INTO user_groups (user_id, group_id) VALUES (?,?)",
        (user_id, group_id)
    )
    conn.commit()
    conn.close()


def remove_user_from_group(user_id, group_id):
    try:
        user_id  = int(user_id)
        group_id = int(group_id)
    except (ValueError, TypeError):
        return
    conn = get_db()
    conn.execute(
        "DELETE FROM user_groups WHERE user_id=? AND group_id=?",
        (user_id, group_id)
    )
    conn.commit()
    conn.close()


# ─── SUBFORUM ACCESS ──────────────────────────────────────────────────────────

def get_subforum_access(subforum_id):
    try:
        subforum_id = int(subforum_id)
    except (ValueError, TypeError):
        return []
    conn = get_db()
    rows = conn.execute("""
        SELECT g.id as group_id, g.name as group_name,
               sa.can_read, sa.can_write
        FROM subforum_access sa JOIN groups g ON g.id=sa.group_id
        WHERE sa.subforum_id=?
        ORDER BY g.name ASC
    """, (subforum_id,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def set_subforum_access(subforum_id, group_id, can_read, can_write):
    try:
        subforum_id = int(subforum_id)
        group_id    = int(group_id)
        can_read    = 1 if can_read else 0
        can_write   = 1 if can_write else 0
    except (ValueError, TypeError):
        return
    conn = get_db()
    conn.execute("""
        INSERT INTO subforum_access (subforum_id, group_id, can_read, can_write)
        VALUES (?,?,?,?)
        ON CONFLICT(subforum_id, group_id) DO UPDATE SET can_read=?, can_write=?
    """, (subforum_id, group_id, can_read, can_write, can_read, can_write))
    conn.commit()
    conn.close()


def remove_subforum_access(subforum_id, group_id):
    try:
        subforum_id = int(subforum_id)
        group_id    = int(group_id)
    except (ValueError, TypeError):
        return
    conn = get_db()
    conn.execute(
        "DELETE FROM subforum_access WHERE subforum_id=? AND group_id=?",
        (subforum_id, group_id)
    )
    conn.commit()
    conn.close()


def subforum_is_restricted(subforum_id):
    try:
        subforum_id = int(subforum_id)
    except (ValueError, TypeError):
        return False
    conn = get_db()
    row = conn.execute(
        "SELECT 1 FROM subforum_access WHERE subforum_id=? LIMIT 1", (subforum_id,)
    ).fetchone()
    conn.close()
    return row is not None


def user_can_read_subforum(user, subforum_id):
    if not subforum_is_restricted(subforum_id):
        return True
    if user is None:
        return False
    if user.get("is_admin") or user.get("is_mod"):
        return True
    user_gids = get_user_group_ids(user["id"])
    if not user_gids:
        return False
    conn = get_db()
    placeholders = ",".join("?" * len(user_gids))
    row = conn.execute(
        f"SELECT 1 FROM subforum_access WHERE subforum_id=? AND group_id IN ({placeholders}) AND can_read=1 LIMIT 1",
        (subforum_id, *user_gids)
    ).fetchone()
    conn.close()
    return row is not None


def user_can_write_subforum(user, subforum_id):
    if not subforum_is_restricted(subforum_id):
        return True
    if user is None:
        return False
    if user.get("is_admin") or user.get("is_mod"):
        return True
    user_gids = get_user_group_ids(user["id"])
    if not user_gids:
        return False
    conn = get_db()
    placeholders = ",".join("?" * len(user_gids))
    row = conn.execute(
        f"SELECT 1 FROM subforum_access WHERE subforum_id=? AND group_id IN ({placeholders}) AND can_write=1 LIMIT 1",
        (subforum_id, *user_gids)
    ).fetchone()
    conn.close()
    return row is not None


# ─── PASSWORD ─────────────────────────────────────────────────────────────────

def hash_password(password):
    salt = secrets.token_hex(16)
    h = hashlib.sha256((salt + password).encode()).hexdigest()
    return f"{salt}:{h}"


def verify_password(password, stored):
    if not stored:
        return False
    try:
        salt, h = stored.split(":", 1)
        return hashlib.sha256((salt + password).encode()).hexdigest() == h
    except Exception:
        return False


def reset_password(username, new_password):
    conn = get_db()
    conn.execute("UPDATE users SET password_hash=? WHERE username=?",
                 (hash_password(new_password), username))
    conn.commit()
    conn.close()


# ─── SESSION ──────────────────────────────────────────────────────────────────

SESSION_TTL = 60 * 60 * 24 * 7   # 7 days


def create_session(user_id):
    token   = secrets.token_hex(32)
    expires = int(time.time()) + SESSION_TTL
    conn    = get_db()
    conn.execute("DELETE FROM sessions WHERE user_id=?", (user_id,))
    conn.execute("INSERT INTO sessions (token,user_id,expires_at) VALUES (?,?,?)",
                 (token, user_id, expires))
    conn.commit()
    conn.close()
    return token


def get_session_user(token):
    if not token:
        return None
    conn = get_db()
    row  = conn.execute(
        "SELECT u.* FROM sessions s JOIN users u ON s.user_id=u.id "
        "WHERE s.token=? AND s.expires_at>?",
        (token, int(time.time()))
    ).fetchone()
    conn.close()
    return dict(row) if row else None


def delete_session(token):
    conn = get_db()
    conn.execute("DELETE FROM sessions WHERE token=?", (token,))
    conn.commit()
    conn.close()


def purge_expired_sessions():
    conn = get_db()
    conn.execute("DELETE FROM sessions WHERE expires_at<?", (int(time.time()),))
    conn.commit()
    conn.close()


# ─── USER ─────────────────────────────────────────────────────────────────────

def register_user(username, password):
    """Register with username + password. Returns None on success, else error string."""
    username = username.strip()[:32] if username else ""
    password = password.strip()[:64] if password else ""

    if not username or not password:
        return "Username and password cannot be empty."
    if len(password) < 6:
        return "Password too short (min 6 characters)."
    conn = get_db()
    if conn.execute("SELECT id FROM users WHERE username=?", (username,)).fetchone():
        conn.close()
        return "Username already taken."
    conn.execute("INSERT INTO users (username, password_hash) VALUES (?,?)",
                 (username, hash_password(password)))
    conn.commit()
    conn.close()
    return None


def get_user_by_name(username):
    conn = get_db()
    row  = conn.execute("SELECT * FROM users WHERE username=?", (username,)).fetchone()
    conn.close()
    return dict(row) if row else None


def get_user_by_id(user_id):
    conn = get_db()
    row  = conn.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    conn.close()
    return dict(row) if row else None


def update_profile(user_id, lxmf_address, display_name, city, website, email, about):
    lxmf_address = lxmf_address.strip()[:32] if lxmf_address else ""
    display_name = display_name.strip()[:60] if display_name else ""
    city         = city.strip()[:24]         if city         else ""
    website      = website.strip()[:40]      if website      else ""
    email        = email.strip()[:60]        if email        else ""
    about        = about.strip()[:500]       if about        else ""

    conn = get_db()
    conn.execute(
        "UPDATE users SET lxmf_address=?, display_name=?, city=?, "
        "website=?, email=?, about=? WHERE id=?",
        (lxmf_address, display_name, city, website, email, about, user_id)
    )
    conn.commit()
    conn.close()


def delete_user(user_id):
    conn = get_db()
    conn.execute("DELETE FROM sessions WHERE user_id=?", (user_id,))
    conn.execute("DELETE FROM users WHERE id=?", (user_id,))
    conn.commit()
    conn.close()


def set_mod(user_id, value):
    conn = get_db()
    conn.execute("UPDATE users SET is_mod=? WHERE id=?", (1 if value else 0, user_id))
    conn.commit()
    conn.close()


def get_all_users():
    conn = get_db()
    rows = conn.execute("SELECT * FROM users ORDER BY registered_at ASC").fetchall()
    conn.close()
    return [dict(r) for r in rows]


# ─── SUBFORUMS ────────────────────────────────────────────────────────────────

def get_subforums():
    conn = get_db()
    rows = conn.execute("""
        SELECT s.*,
               COUNT(DISTINCT t.id) as topic_count,
               COUNT(DISTINCT c.id) as total_comments
        FROM subforums s
        LEFT JOIN topics t ON t.subforum_id = s.id
        LEFT JOIN comments c ON c.topic_id = t.id
        GROUP BY s.id
        ORDER BY s.sort_order ASC
    """).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_subforum(subforum_id):
    try:
        subforum_id = int(subforum_id)
    except (ValueError, TypeError):
        return None
    conn = get_db()
    row  = conn.execute("SELECT * FROM subforums WHERE id=?", (subforum_id,)).fetchone()
    conn.close()
    return dict(row) if row else None


def create_subforum(name, description=""):
    name        = name.strip()[:100]        if name        else ""
    description = description.strip()[:500] if description else ""
    if not name:
        return None
    conn = get_db()
    conn.execute("INSERT INTO subforums (name, description) VALUES (?,?)",
                 (name, description))
    conn.commit()
    conn.close()


def delete_subforum(subforum_id):
    conn = get_db()
    conn.execute("DELETE FROM subforums WHERE id=?", (subforum_id,))
    conn.commit()
    conn.close()


# ─── TOPICS ───────────────────────────────────────────────────────────────────

def get_topics(subforum_id):
    try:
        subforum_id = int(subforum_id)
    except (ValueError, TypeError):
        return []
    conn = get_db()
    rows = conn.execute("""
        SELECT t.*, u.username as author_name
        FROM topics t JOIN users u ON t.author_id=u.id
        WHERE t.subforum_id=?
        ORDER BY t.last_reply_at DESC
    """, (subforum_id,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_topic(topic_id):
    try:
        topic_id = int(topic_id)
    except (ValueError, TypeError):
        return None
    conn = get_db()
    row  = conn.execute("""
        SELECT t.*, u.username as author_name
        FROM topics t JOIN users u ON t.author_id=u.id
        WHERE t.id=?
    """, (topic_id,)).fetchone()
    conn.close()
    return dict(row) if row else None


def create_topic(subforum_id, author_id, title, body, tag_names):
    title = title.strip()[:100] if title else ""
    body  = body.strip()[:5000] if body  else ""
    if not title or not body:
        return None
    try:
        subforum_id = int(subforum_id)
        author_id   = int(author_id)
    except (ValueError, TypeError):
        return None
    conn = get_db()
    cur  = conn.execute(
        "INSERT INTO topics (subforum_id, author_id, title, body) VALUES (?,?,?,?)",
        (subforum_id, author_id, title, body)
    )
    topic_id = cur.lastrowid
    conn.execute("UPDATE users SET post_count=post_count+1 WHERE id=?", (author_id,))
    _set_tags(conn, topic_id, tag_names)
    conn.commit()
    conn.close()
    return topic_id


def delete_topic(topic_id):
    try:
        topic_id = int(topic_id)
    except (ValueError, TypeError):
        return
    conn  = get_db()
    topic = conn.execute("SELECT author_id FROM topics WHERE id=?", (topic_id,)).fetchone()
    if topic:
        conn.execute("UPDATE users SET post_count=post_count-1 WHERE id=?", (topic["author_id"],))
    conn.execute("DELETE FROM topic_tags WHERE topic_id=?", (topic_id,))
    conn.execute("DELETE FROM comments WHERE topic_id=?",   (topic_id,))
    conn.execute("DELETE FROM topics WHERE id=?",           (topic_id,))
    conn.commit()
    conn.close()


def toggle_close_topic(topic_id):
    try:
        topic_id = int(topic_id)
    except (ValueError, TypeError):
        return
    conn = get_db()
    conn.execute("UPDATE topics SET is_closed = 1-is_closed WHERE id=?", (topic_id,))
    conn.commit()
    conn.close()


# ─── COMMENTS ──────────────────────────────────────────────────────────────────

def get_comments(topic_id):
    try:
        topic_id = int(topic_id)
    except (ValueError, TypeError):
        return []
    conn = get_db()
    rows = conn.execute("""
        SELECT c.*, u.username as author_name
        FROM comments c JOIN users u ON c.author_id=u.id
        WHERE c.topic_id=?
        ORDER BY c.created_at ASC
    """, (topic_id,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def add_comment(topic_id, author_id, body):
    body = body.strip()[:5000] if body else ""
    if not body:
        return False
    try:
        topic_id  = int(topic_id)
        author_id = int(author_id)
    except (ValueError, TypeError):
        return False
    now  = int(time.time())
    conn = get_db()
    conn.execute(
        "INSERT INTO comments (topic_id, author_id, body, created_at) VALUES (?,?,?,?)",
        (topic_id, author_id, body, now)
    )
    conn.execute(
        "UPDATE topics SET comment_count=comment_count+1, last_reply_at=? WHERE id=?",
        (now, topic_id)
    )
    conn.execute("UPDATE users SET post_count=post_count+1 WHERE id=?", (author_id,))
    conn.commit()
    conn.close()
    return True


def delete_comment(comment_id):
    try:
        comment_id = int(comment_id)
    except (ValueError, TypeError):
        return
    conn = get_db()
    c    = conn.execute("SELECT author_id, topic_id FROM comments WHERE id=?", (comment_id,)).fetchone()
    if c:
        conn.execute("UPDATE users SET post_count=post_count-1 WHERE id=?", (c["author_id"],))
        conn.execute("UPDATE topics SET comment_count=comment_count-1 WHERE id=?", (c["topic_id"],))
    conn.execute("DELETE FROM comments WHERE id=?", (comment_id,))
    conn.commit()
    conn.close()


# ─── TAGS ─────────────────────────────────────────────────────────────────────

def _set_tags(conn, topic_id, tag_names):
    conn.execute("DELETE FROM topic_tags WHERE topic_id=?", (topic_id,))
    if not tag_names:
        return
    for raw in tag_names.split(","):
        name = raw.strip().lower()[:32]
        if not name:
            continue
        conn.execute("INSERT OR IGNORE INTO tags (name) VALUES (?)", (name,))
        tag = conn.execute("SELECT id FROM tags WHERE name=?", (name,)).fetchone()
        if tag:
            conn.execute("INSERT OR IGNORE INTO topic_tags (topic_id, tag_id) VALUES (?,?)",
                         (topic_id, tag["id"]))


def get_tags_for_topic(topic_id):
    try:
        topic_id = int(topic_id)
    except (ValueError, TypeError):
        return []
    conn = get_db()
    rows = conn.execute("""
        SELECT t.name FROM tags t
        JOIN topic_tags tt ON tt.tag_id=t.id
        WHERE tt.topic_id=?
        ORDER BY t.name ASC
    """, (topic_id,)).fetchall()
    conn.close()
    return [r["name"] for r in rows]


def get_all_tags():
    conn = get_db()
    rows = conn.execute("""
        SELECT t.name, COUNT(tt.topic_id) as count
        FROM tags t LEFT JOIN topic_tags tt ON tt.tag_id=t.id
        GROUP BY t.id
        ORDER BY count DESC, t.name ASC
    """).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_topics_by_tag(tag_name):
    tag_name = tag_name.strip()
    conn     = get_db()
    rows     = conn.execute("""
        SELECT tp.*, u.username as author_name
        FROM topics tp
        JOIN users u ON tp.author_id=u.id
        JOIN topic_tags tt ON tt.topic_id=tp.id
        JOIN tags t ON t.id=tt.tag_id
        WHERE t.name=?
        ORDER BY tp.last_reply_at DESC
    """, (tag_name,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]


# ─── SETTINGS ──────────────────────────────────────────────────────────────────

def get_setting(key):
    conn = get_db()
    row  = conn.execute("SELECT value FROM settings WHERE key=?", (key,)).fetchone()
    conn.close()
    return row["value"] if row else ""


def set_setting(key, value):
    conn = get_db()
    conn.execute("INSERT OR REPLACE INTO settings (key, value) VALUES (?,?)", (key, value))
    conn.commit()
    conn.close()


# ─── HELPER FUNCTIONS ──────────────────────────────────────────────────────────

def fmt_time(ts):
    """Unix timestamp → dd-mm-yyyy HH:MM."""
    if not ts:
        return "—"
    return time.strftime("%d-%m-%Y %H:%M", time.localtime(int(ts)))


def profile_link(username, token=None):
    """Micron link to profile page."""
    fields = f"user={username}"
    if token:
        fields += f"|session={token}"
    return f"`Fa60`[{username}`{page_path}/profile.mu`{fields}]`f"


def nav_bar(current_user=None, back_url=None, token=None):
    """Standard navigation bar as Micron string."""
    lines = []
    lines.append(f"`c`!`F0af{forum_name}`!`f")
    lines.append(f"`c`F777{site_description}`f")
    lines.append("`a")
    lines.append("-")

    def lnk(label, dest, extra=""):
        parts = []
        if token:
            parts.append(f"session={token}")
        if extra:
            parts.append(extra)
        fields = ("`" + "|".join(parts)) if parts else ""
        return f"`[{label}`{dest}{fields}]"

    links = [lnk("Home", f"{page_path}/index.mu")]
    links.append(lnk("Help",  f"{page_path}/help.mu"))
    links.append(lnk("Tags",  f"{page_path}/tags.mu"))
    links.append(lnk("Users", f"{page_path}/users.mu"))
    links.append(lnk("Rules", f"{page_path}/rules.mu"))
    if current_user:
        links.append(lnk("My Profile", f"{page_path}/profile.mu",
                          f"user={current_user['username']}"))
        links.append(lnk("Settings", f"{page_path}/user_settings.mu"))
        if current_user.get("is_admin"):
            links.append(lnk("Admin", f"{page_path}/admin/admin.mu"))
        links.append(lnk("Logout", f"{page_path}/logout.mu"))
    else:
        links.append(f"`[Login`{page_path}/login.mu]")
        links.append(f"`[Register`{page_path}/register.mu]")
    links.append(f"`Fca4`[← Node Home`{node_homepage}]`f")
    lines.append("  ".join(links))
    if back_url:
        lines.append(f"`[← Back`{back_url}]")
    lines.append("-")
    return "\n".join(lines)


def print_header(title=None):
    if title:
        print(f"`c`!{title}`!")


def print_footer():
    print("-")
    print("`c`F444Off-Grid Community Suite · NomadNet`f")
    print("`a")


def lxmf_link(address):
    """Clickable LXMF link in NomadNet single-segment format."""
    if address and len(address) == 32 and all(c in "0123456789abcdefABCDEF" for c in address):
        return f"`F59f`[lxmf@{address}]`f"
    return ""


def btn(label, url, fields="", style="primary"):
    """Styled action button with background color for form submissions."""
    if style == "primary":
        bg, fg = "244", "eef"
    elif style == "danger":
        bg, fg = "411", "fca"
    else:
        bg, fg = "333", "aaa"
    f_part = f"`{fields}" if fields else ""
    return f"`B{bg}`F{fg}`[  {label}  `{url}{f_part}]`b`f"


# ─── INIT ─────────────────────────────────────────────────────────────────────

init_db()
