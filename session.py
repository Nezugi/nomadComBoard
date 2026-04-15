#!/usr/bin/env python3
"""
session.py – Read session from environment variables.
Imported by all .mu pages.
"""

import os
import sys

# Add forum directory to import path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum


def get_current_user():
    """Read session token from environment and return user or None."""
    token = os.environ.get("var_session", "")
    if not token:
        return None
    return forum.get_session_user(token)


def session_token():
    """Return current session token or empty string."""
    return os.environ.get("var_session", "")


def require_login(back_url=None):
    """Print error and exit script if not logged in."""
    user = get_current_user()
    if user is None:
        redirect = back_url or f"{forum.page_path}/login.mu"
        print("#!c=0")
        print(forum.nav_bar())
        print(f"\n`F800Not logged in.`f")
        print(f"\n`[Go to Login`{redirect}]")
        sys.exit(0)
    return user


def require_admin():
    """Print error and exit script if not admin."""
    user = require_login()
    if not user.get("is_admin"):
        print("#!c=0")
        print(forum.nav_bar(user))
        print(f"\n`F800Access denied. Admin only.`f")
        sys.exit(0)
    return user


def require_mod():
    """Print error and exit if not moderator or admin."""
    user = require_login()
    if not user.get("is_admin") and not user.get("is_mod"):
        print("#!c=0")
        print(forum.nav_bar(user))
        print(f"\n`F800Access denied. Moderators only.`f")
        sys.exit(0)
    return user
