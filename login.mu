#!/usr/bin/env python3
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

print("#!c=0")

action   = os.environ.get("var_action", "")
username = os.environ.get("field_username", "").strip()[:32]
password = os.environ.get("field_password", "").strip()[:64]

# Already logged in?
user = sess.get_current_user()
if user:
    token = sess.session_token()
    print(forum.nav_bar(user, token=token))
    print(f"\nYou are already logged in as `!{user['username']}`!.")
    print(f"\n`Fa60`[→ Go to Forum`{forum.page_path}/index.mu`session={token}]`f")
    sys.exit(0)

# Detect remote identity
remote_id = forum.get_remote_identity()
has_id    = forum.is_valid_identity(remote_id)

forum.purge_expired_sessions()

# ── Auto-login via identity ───────────────────────────────────────────────────
if has_id and action != "password":
    id_user, token = forum.login_by_identity(remote_id)
    if id_user:
        print(forum.nav_bar(id_user, token=token))
        print(f"\n`F1a6Signed in as `!{id_user['username']}`! via node identity.`f")
        print(f"\n`Fa60`[→ Go to Forum`{forum.page_path}/index.mu`session={token}]`f")
        sys.exit(0)

# ── Handle password login submit ─────────────────────────────────────────────
login_error = ""
if action == "submit":
    u = forum.get_user_by_name(username)
    if u and forum.verify_password(password, u["password_hash"]):
        token = forum.create_session(u["id"])
        print(forum.nav_bar(u, token=token))
        print("`F1a6Successfully logged in.`f")
        print(f"\n`Fa60`[→ Go to Forum`{forum.page_path}/index.mu`session={token}]`f")
        sys.exit(0)
    else:
        login_error = "Invalid username or password."

print(forum.nav_bar())
print(">Login")
print()

# ── Identity present but not registered ──────────────────────────────────────
if has_id and action != "password":
    print("`F777Node identity detected, but not linked to any account.`f")
    print()
    print(f"`Fa60`[Register with this identity`{forum.page_path}/register.mu]`f")
    print()
    print("-")
    print()

if login_error:
    print(f"`Ff55{login_error}`f")
    print()

print(">>Password Login")
print()
print("Username")
print("`B333`<32|username`>`b")
print()
print("Password")
print("`B333`<!32|password`>`b")
print()
print(forum.btn("→ Login", f"{forum.page_path}/login.mu", "action=submit|*"))
print()
print(f"`Fa60`[Register`{forum.page_path}/register.mu]`f")

forum.print_footer()
