#!/usr/bin/env python3
#!c=0

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

print("#!c=0")

username = os.environ.get("field_username", "").strip()[:32]
password = os.environ.get("field_password", "").strip()[:64]
action   = os.environ.get("var_action", "")

user = sess.get_current_user()
if user:
    token = sess.session_token()
    print(forum.nav_bar(user, token=token))
    print(f"\nYou are already logged in as `!{user['username']}`!.")
    s_f = f"session={token}"
    print(f"\n`[Go to Forum`{forum.page_path}/index.mu`{s_f}]")
    sys.exit(0)

print(forum.nav_bar())
print(">Login")
print()

if action == "submit" and username and password:
    forum.purge_expired_sessions()
    u = forum.get_user_by_name(username)
    if u and forum.verify_password(password, u["password_hash"]):
        token = forum.create_session(u["id"])
        print("`F080Successfully logged in.`f")
        print(f"\n`[Go to Forum`{forum.page_path}/index.mu`session={token}]")
        sys.exit(0)
    else:
        print("`Ff55Invalid username or password.`f")
        print()

print("Username:")
print("`B333`<32|username`>`b")
print()
print("Password:")
print("`B333`<32|password`>`b")
print()
print(f"`[Login`{forum.page_path}/login.mu`action=submit|session=PLACEHOLDER|*]")
print(f"`[Back`{forum.page_path}/index.mu]")

forum.print_footer()
