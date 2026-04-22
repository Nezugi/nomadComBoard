#!/usr/bin/env python3
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
print(">Settings")
print()

notice = ""
error  = ""

# ── Save profile ─────────────────────────────────────────────────────────────
if action == "save_profile":
    try:
        forum.update_profile(
            user["id"],
            os.environ.get("field_lxmf",         "").strip()[:32],
            os.environ.get("field_display_name",  "").strip()[:60],
            os.environ.get("field_city",          "").strip()[:24],
            os.environ.get("field_website",       "").strip()[:40],
            os.environ.get("field_email",         "").strip()[:60],
            os.environ.get("field_about",         "").strip()[:500],
        )
        notice = "Profile updated."
    except Exception as e:
        error = str(e)

# ── Set / change password ─────────────────────────────────────────────────────
if action == "save_password":
    pw1 = os.environ.get("field_pw1", "").strip()
    pw2 = os.environ.get("field_pw2", "").strip()
    if pw1 != pw2:
        error = "Passwords do not match."
    else:
        err = forum.set_password(user["id"], pw1)
        if err:
            error = err
        else:
            notice = "Password set successfully."

# ── Link identity ─────────────────────────────────────────────────────────────
if action == "link_identity":
    remote_id = forum.get_remote_identity()
    err = forum.link_identity(user["id"], remote_id)
    if err:
        error = err
    else:
        notice = "Node identity linked to your account."

# ── Unlink identity ───────────────────────────────────────────────────────────
if action == "unlink_identity":
    err = forum.unlink_identity(user["id"])
    if err:
        error = err
    else:
        notice = "Node identity removed from your account."

# Reload fresh user data after any changes
user = forum.get_user_by_id(user["id"])

if notice:
    print(f"`F1a6{notice}`f")
    print()
if error:
    print(f"`Ff55{error}`f")
    print()

# ── Section: Profile ─────────────────────────────────────────────────────────
print(">>Profile")
print()
print("Display Name")
v = user.get("display_name") or ""
print(f"`B333`<60|display_name`{v}`>`b")
print()
print("LXMF Address (32 hex chars)")
v = user.get("lxmf_address") or ""
print(f"`B333`<32|lxmf`{v}`>`b")
print()
print("City")
v = user.get("city") or ""
print(f"`B333`<24|city`{v}`>`b")
print()
print("Website")
v = user.get("website") or ""
print(f"`B333`<40|website`{v}`>`b")
print()
print("Email")
v = user.get("email") or ""
print(f"`B333`<40|email`{v}`>`b")
print()
print("About Me")
v = user.get("about") or ""
print(f"`B333`<60|about`{v}`>`b")
print()
print(forum.btn("✔ Save Profile", f"{forum.page_path}/user_settings.mu", f"action=save_profile|session={token}|*"))

# ── Section: Node Identity ───────────────────────────────────────────────────
print()
print("-")
print(">>Node Identity")
print()

remote_id  = forum.get_remote_identity()
has_id     = forum.is_valid_identity(remote_id)
linked_id  = user.get("identity_hash") or ""
has_linked = forum.is_valid_identity(linked_id)
has_pw     = bool(user.get("password_hash"))

if has_linked:
    print("`F1a6Node identity linked.`f")
    print(f"`F555{linked_id[:16]}...`f")
    print()
    if has_pw:
        print("Your account has a password — you can safely unlink the identity.")
        print()
        print(forum.btn("✖ Unlink Identity", f"{forum.page_path}/user_settings.mu", f"action=unlink_identity|session={token}", "danger"))
    else:
        print("`F777Set a password below before unlinking the identity.`f")
else:
    if has_id:
        print("`F777Node identity detected — not yet linked to this account.`f")
        print()
        print(forum.btn("✔ Link this Identity", f"{forum.page_path}/user_settings.mu", f"action=link_identity|session={token}"))
    else:
        print("`F555No node identity detected.`f")
        print("`F555Enable 'Identify to Nodes' in your NomadNet settings,`f")
        print("`F555then reload this page.`f")

# ── Section: Password ────────────────────────────────────────────────────────
print()
print("-")
if has_pw:
    print(">>Change Password")
else:
    print(">>Set Password")
    print()
    print("Setting a password lets you log in from other devices.")
print()
print("New Password")
print("`B333`<!32|pw1`>`b")
print()
print("Confirm Password")
print("`B333`<!32|pw2`>`b")
print()
label = "Change Password" if has_pw else "Set Password"
print(forum.btn(f"✔ {label}", f"{forum.page_path}/user_settings.mu", f"action=save_password|session={token}|*"))

forum.print_footer()
