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
print(">Rules")
print()
rules = forum.get_setting("rules")
print(rules if rules else "No rules set yet.")

forum.print_footer()
