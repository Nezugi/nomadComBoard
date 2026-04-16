#!/usr/bin/env python3
#!c=0

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

print("#!c=0")
user  = sess.get_current_user()
token = sess.session_token()

back_f = f"session={token}" if token else ""
back   = f"{forum.page_path}/index.mu`{back_f}" if back_f else f"{forum.page_path}/index.mu"
print(forum.nav_bar(user, back_url=back, token=token))
print(">Users")
print()

for u in forum.get_all_users():
    if u["is_admin"]:
        role = "`F0af[Admin]`f"
    elif u["is_mod"]:
        role = "`F0a0[Mod]`f"
    else:
        role = ""
    dn  = u["display_name"] or u["username"]
    p_f = f"user={u['username']}"
    if token:
        p_f += f"|session={token}"
    if role:
        print(f"`[{dn}`{forum.page_path}/profile.mu`{p_f}]  {role}  `F777{u['post_count']} posts`f")
    else:
        print(f"`[{dn}`{forum.page_path}/profile.mu`{p_f}]  `F777{u['post_count']} posts`f")

forum.print_footer()
