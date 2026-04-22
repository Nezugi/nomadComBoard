#!/usr/bin/env python3
#!c=0

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

print("#!c=0")

user  = sess.get_current_user()
token = sess.session_token()
sf_id = os.environ.get("var_sf", "").strip()

if not sf_id:
    print(forum.nav_bar(user, token=token))
    print("`F800No subforum specified.`f")
    sys.exit(0)

try:
    sf_id = int(sf_id)
except (ValueError, TypeError):
    sf_id = 0

sf = forum.get_subforum(sf_id)
if not sf:
    print(forum.nav_bar(user, token=token))
    print("`F800Subforum not found.`f")
    sys.exit(0)

back_f = f"session={token}" if token else ""
back   = f"{forum.page_path}/index.mu`{back_f}" if back_f else f"{forum.page_path}/index.mu"

# ── Access control ──
if not forum.user_can_read_subforum(user, sf_id):
    print(forum.nav_bar(user, back_url=back, token=token))
    print("`Ff55Access restricted. You do not have permission to view this subforum.`f")
    forum.print_footer()
    sys.exit(0)

print(forum.nav_bar(user, back_url=back, token=token))
print(f">{sf['name']}")
if sf["description"]:
    print(f"`F888{sf['description']}`f")
print()

if user and forum.user_can_write_subforum(user, sf_id):
    sf_fields = f"sf={sf_id}"
    if token:
        sf_fields += f"|session={token}"
    print(f"`Fa60`[✚ New Topic`{forum.page_path}/new_topic.mu`{sf_fields}]`f")
    print()

topics = forum.get_topics(sf_id)
if not topics:
    print("No topics in this subforum yet.")
else:
    for i, t in enumerate(topics):
        if i > 0:
            print("-")
        t_f = f"topic={t['id']}"
        if token:
            t_f += f"|session={token}"
        a_link = forum.profile_link(t["author_name"], token)
        closed = "`F844[✖ closed]`f " if t["is_closed"] else ""
        print(f"`Fa60`[▸ {t['title']}`{forum.page_path}/topic.mu`{t_f}]`f  {closed}")
        print(f"`F666{t['comment_count']} replies  ·  {forum.fmt_time(t['last_reply_at'])}  ·  by `f{a_link}")

forum.print_footer()
