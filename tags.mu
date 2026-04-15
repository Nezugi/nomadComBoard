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
print(">All Tags")
print()

tags = forum.get_all_tags()
if not tags:
    print("No tags yet.")
else:
    for t in tags:
        t_f = f"tag={t['name']}"
        if token:
            t_f += f"|session={token}"
        print(f"`[{t['name']}`{forum.page_path}/tag.mu`{t_f}]  `F777({t['count']} topics)`f")

forum.print_footer()
