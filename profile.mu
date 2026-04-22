#!/usr/bin/env python3
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
    print("`Ff55User not found.`f")
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
            print("`F1a6Moderator status updated.`f")
        except (ValueError, TypeError):
            print("`Ff55Invalid value.`f")
        print()

# Role badge
role_badge = ""
if target.get("is_admin"):
    role_badge = "`F4af [Admin]`f"
elif target.get("is_mod"):
    role_badge = "`F1a6 [Mod]`f"

# Identity badge
id_badge = ""
if forum.is_valid_identity(target.get("identity_hash", "")):
    id_badge = " `F4be[✓ ID]`f"

display = target.get("display_name") or target["username"]
print(f">>`!{display}`!{role_badge}{id_badge}")
print()
print(f"Username:  `!{target['username']}`!")
print(f"Member since: {forum.fmt_time(target['registered_at'])}")
print(f"Posts: {target['post_count']}")
print()

if target.get("lxmf_address") and len(target["lxmf_address"]) == 32:
    print(f"LXMF: {forum.lxmf_link(target['lxmf_address'])}")

if target.get("city"):
    print(f"City: {target['city']}")

if target.get("website"):
    print(f"Website: {target['website']}")

if target.get("email"):
    print(f"Email: {target['email']}")

if target.get("about"):
    print()
    print("About:")
    print(target["about"])

print()

# Admin box
if viewer and viewer["is_admin"] and viewer["id"] != target["id"]:
    print("-")
    print(">>Admin")
    if not target.get("is_mod"):
        mod_f = f"user={target['username']}|action=set_mod|val=1"
        if token:
            mod_f += f"|session={token}"
        print(forum.btn("⬆ Make Moderator", f"{forum.page_path}/profile.mu", mod_f))
    else:
        mod_f = f"user={target['username']}|action=set_mod|val=0"
        if token:
            mod_f += f"|session={token}"
        print(forum.btn("✖ Remove Moderator", f"{forum.page_path}/profile.mu", mod_f, "danger"))

# Edit own profile
if viewer and viewer["id"] == target["id"]:
    print(f"`Fa60`[⚙ Edit Settings`{forum.page_path}/user_settings.mu`session={token}]`f")

forum.print_footer()
