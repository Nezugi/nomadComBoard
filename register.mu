#!/usr/bin/env python3
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

print("#!c=0")

action   = os.environ.get("var_action", "")
username = os.environ.get("field_username", "").strip()[:32]
password = os.environ.get("field_password", "").strip()[:64]
confirm  = os.environ.get("field_confirm",  "").strip()[:64]

# Already logged in?
user = sess.get_current_user()
if user:
    token = sess.session_token()
    print(forum.nav_bar(user, token=token))
    print(f"\nYou are already logged in as `!{user['username']}`!.")
    print(f"\n`[Go to Forum`{forum.page_path}/index.mu`session={token}]")
    sys.exit(0)

# Detect remote identity
remote_id  = forum.get_remote_identity()
has_id     = forum.is_valid_identity(remote_id)

print(forum.nav_bar())
print(">Register")
print()

# ── Handle: Register with identity ───────────────────────────────────────────
if action == "reg_identity":
    try:
        if not username:
            raise ValueError("Username cannot be empty.")
        if not has_id:
            raise ValueError("No valid identity detected. Enable 'Identify to Nodes' in your NomadNet settings.")
        err = forum.register_user_identity(username, remote_id)
        if err:
            raise ValueError(err)
        u     = forum.get_user_by_name(username)
        token = forum.create_session(u["id"])
        print("`F1a6Registration successful!`f")
        print(f"\nWelcome, `!{username}`!. You are signed in via your node identity.")
        print(f"\n`Fa60`[→ Go to Forum`{forum.page_path}/index.mu`session={token}]`f")
        sys.exit(0)
    except ValueError as e:
        print(f"`Ff55{e}`f")
        print()

# ── Handle: Register with password ───────────────────────────────────────────
if action == "reg_password":
    try:
        if not username:
            raise ValueError("Username cannot be empty.")
        if not password:
            raise ValueError("Password cannot be empty.")
        if len(password) < 6:
            raise ValueError("Password too short (min 6 characters).")
        if password != confirm:
            raise ValueError("Passwords do not match.")
        err = forum.register_user(username, password)
        if err:
            raise ValueError(err)
        u     = forum.get_user_by_name(username)
        token = forum.create_session(u["id"])
        print("`F1a6Registration successful!`f")
        print(f"\nWelcome, `!{username}`!.")
        print(f"\n`Fa60`[→ Go to Forum`{forum.page_path}/index.mu`session={token}]`f")
        sys.exit(0)
    except ValueError as e:
        print(f"`Ff55{e}`f")
        print()

# ── Option A: Identity registration (shown if identity is present) ────────────
if has_id:
    print("`F1a6Your node identity was detected.`f")
    print()
    print(">>Register with Node Identity")
    print()
    print("Just pick a username — no password needed.")
    print("You will be logged in automatically on this node.")
    print()
    print("Username")
    print("`B333`<32|username`>`b")
    print()
    print(forum.btn("✚ Register with Identity", f"{forum.page_path}/register.mu", "action=reg_identity|*"))
    print()
    print("-")
    print()
    print(">>Or: Register with Password")
    print()
    print("Use this if you also want to log in from other devices.")
else:
    print("`F777No node identity detected.`f")
    print("`F555Enable 'Identify to Nodes' in NomadNet settings for passwordless login.`f")
    print()
    print(">>Register with Password")
    print()

print()
print("Username")
print("`B333`<32|username`>`b")
print()
print("Password")
print("`B333`<!32|password`>`b")
print()
print("Confirm Password")
print("`B333`<!32|confirm`>`b")
print()
print(forum.btn("✚ Register", f"{forum.page_path}/register.mu", "action=reg_password|*"))
print()
print(f"`Fa60`[← Back to Login`{forum.page_path}/login.mu]`f")

forum.print_footer()
