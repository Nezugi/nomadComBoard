#!/usr/bin/env python3
#!c=0

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

print("#!c=0")

viewer   = sess.get_current_user()
token    = sess.session_token()
username = os.environ.get("var_user", "").strip()
action   = os.environ.get("var_action", "")

target = forum.get_user_by_name(username) if username else viewer
if not target:
    print(forum.nav_bar(viewer, token=token))
    print("`F800User not found.`f")
    sys.exit(0)

back_f = f"session={token}" if token else ""
back   = f"{forum.page_path}/index.mu`{back_f}" if back_f else f"{forum.page_path}/index.mu"
print(forum.nav_bar(viewer, back_url=back, token=token))

# Admin actions
if viewer and viewer["is_admin"] and action:
    if action == "set_mod":
        try:
            val = int(os.environ.get("var_val", "0"))
            forum.set_mod(target["id"], val)
            print(f"`F080Moderator status updated.`f")
        except (ValueError, TypeError):
            print("`Ff55Invalid value.`f")
        print()

# Profile display
role_badge = ""
if target.get("is_admin"):
    role_badge = "`F4af[Admin]`f "
elif target.get("is_mod"):
    role_badge = "`F1a6[Mod]`f "

print(f">>`!{target['display_name'] or target['username']}`! {role_badge}")
print(f"Member since: {forum.fmt_time(target['registered_at'])}")
print(f"Posts: {target['post_count']}")
print()

if target.get("lxmf_address") and len(target["lxmf_address"]) == 32:
    lx = target["lxmf_address"]
    print(f"LXMF: {forum.lxmf_link(lx)}")

if target.get("city"):
    print(f"City: {target['city']}")

if target.get("website"):
    print(f"Website: {target['website']}")

if target.get("email"):
    print(f"Email: {target['email']}")

if target.get("about"):
    print()
    print("About:")
    print(target['about'])

print()

# Admin box (only if viewer is admin and looking at someone else)
if viewer and viewer["is_admin"] and viewer["id"] != target["id"]:
    print("-")
    print(">Admin Actions")
    if not target.get("is_mod"):
        mod_f = f"user={target['username']}|action=set_mod|val=1"
        if token:
            mod_f += f"|session={token}"
        print(f"`[Make Moderator`{forum.page_path}/profile.mu`{mod_f}]")
    else:
        mod_f = f"user={target['username']}|action=set_mod|val=0"
        if token:
            mod_f += f"|session={token}"
        print(f"`[Remove Moderator`{forum.page_path}/profile.mu`{mod_f}]")

# Edit own profile
if viewer and viewer["id"] == target["id"]:
    print()
    print(f"`[Edit Profile`{forum.page_path}/user_settings.mu`session={token}]")

forum.print_footer()
