#!/usr/bin/env python3
#!c=0

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

print("#!c=0")
user     = sess.get_current_user()
token    = sess.session_token()
tag_name = os.environ.get("var_tag", "").strip()

back_f = f"session={token}" if token else ""
back   = f"{forum.page_path}/tags.mu`{back_f}" if back_f else f"{forum.page_path}/tags.mu"
print(forum.nav_bar(user, back_url=back, token=token))

if not tag_name:
    print("`F800No tag specified.`f")
    sys.exit(0)

print(f">Tag: `!{tag_name}`!")
print()

topics = forum.get_topics_by_tag(tag_name)
if not topics:
    print("No topics with this tag.")
else:
    for t in topics:
        t_f = f"topic={t['id']}"
        if token:
            t_f += f"|session={token}"
        a_link = forum.profile_link(t["author_name"], token)
        print(f"`F0af`[{t['title']}`{forum.page_path}/topic.mu`{t_f}]`f")
        print(f"by {a_link}  ·  {t['comment_count']} replies  ·  {forum.fmt_time(t['last_reply_at'])}")
        print()

forum.print_footer()
