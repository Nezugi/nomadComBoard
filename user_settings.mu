#!/usr/bin/env python3
#!c=0

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

print("#!c=0")

user   = sess.require_login()
token  = sess.session_token()
action = os.environ.get("var_action", "")

prof_f = f"user={user['username']}"
if token:
    prof_f += f"|session={token}"
back = f"{forum.page_path}/profile.mu`{prof_f}"
print(forum.nav_bar(user, back_url=back, token=token))
print(">Edit Profile")
print()

if action == "save":
    try:
        forum.update_profile(
            user["id"],
            os.environ.get("field_lxmf", "").strip()[:32],
            os.environ.get("field_display_name", "").strip()[:60],
            os.environ.get("field_city", "").strip()[:24],
            os.environ.get("field_website", "").strip()[:40],
            os.environ.get("field_email", "").strip()[:60],
            os.environ.get("field_about", "").strip()[:500],
        )
        print("`F080Profile updated.`f")
        print()
    except Exception as e:
        print(f"`Ff55Error: {e}`f")
        print()

# Current values
user = forum.get_user_by_id(user["id"])

print("Display Name")
print("`B333`<60|display_name`>`b")
print()
print("LXMF Address (32 hex chars)")
print("`B333`<32|lxmf`>`b")
print()
print("City")
print("`B333`<24|city`>`b")
print()
print("Website")
print("`B333`<40|website`>`b")
print()
print("Email")
print("`B333`<40|email`>`b")
print()
print("About Me")
print("`B333`<60|about`>`b")
print()

print(f"`[Save`{forum.page_path}/user_settings.mu`action=save|session={token}|*]")
print(f"`[Back to Profile`{back}]")

forum.print_footer()
