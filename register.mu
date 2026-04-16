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
    print("\nYou are already logged in.")
    sys.exit(0)

print(forum.nav_bar())
print(">Register")
print()

if action == "submit" and username and password:
    err = forum.register_user(username, password)
    if err:
        print(f"\n`Ff55{err}`f")
    else:
        u     = forum.get_user_by_name(username)
        token = forum.create_session(u["id"])
        print("`F080Registration successful!`f")
        print(f"\nWelcome, `!{username}`!.")
        print(f"\n`[Go to Forum`{forum.page_path}/index.mu`session={token}]")
        sys.exit(0)

print("Create a new account:")
print()
print("Username:")
print("`B333`<32|username`>`b")
print()
print("Password:")
print("`B333`<32|password`>`b")
print()
print(f"`[Register`{forum.page_path}/register.mu`action=submit|*]")
print(f"`[Back to Login`{forum.page_path}/login.mu]")

forum.print_footer()
