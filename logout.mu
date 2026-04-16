#!/usr/bin/env python3
#!c=0

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

print("#!c=0")
print(forum.nav_bar())

token = sess.session_token()
if token:
    forum.delete_session(token)
    print(">Logout")
    print("\n`F080You have been successfully logged out.`f")
else:
    print(">Logout")
    print("\nYou were not logged in.")

print(f"\n`[Go to Home`{forum.page_path}/index.mu]")
print(f"`[Login`{forum.page_path}/login.mu]")

forum.print_footer()
