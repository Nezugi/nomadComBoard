#!/usr/bin/env python3
#!c=0

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

user  = sess.get_current_user()
token = sess.session_token()

print("#!c=0")
print(forum.nav_bar(user, token=token))
forum.print_header()
print()
subforums = forum.get_subforums()
print(">Subforums")
print()

if not subforums:
    print("No subforums yet.")
else:
    first = True
    for sf in subforums:
        if not forum.user_can_read_subforum(user, sf["id"]):
            continue
        if not first:
            print("-")
        first = False
        tc     = sf.get("topic_count") or 0
        cc     = sf.get("total_comments") or 0
        fields = f"sf={sf['id']}"
        if token:
            fields += f"|session={token}"
        restricted = "`Fca4[restricted]`f " if forum.subforum_is_restricted(sf["id"]) else ""
        print(f"`Fa60`[◆ {sf['name']}`{forum.page_path}/subforum.mu`{fields}]`f  {restricted}")
        if sf["description"]:
            print(f"`F888{sf['description']}`f")
        print(f"`F666{tc} topics · {cc} replies`f")

forum.print_footer()
