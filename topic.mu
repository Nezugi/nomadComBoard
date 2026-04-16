#!/usr/bin/env python3
#!c=0

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

print("#!c=0")

user     = sess.get_current_user()
token    = sess.session_token()
topic_id = os.environ.get("var_topic", "").strip()
action   = os.environ.get("var_action", "")

if not topic_id:
    print(forum.nav_bar(user, token=token))
    print("`F800No topic specified.`f")
    sys.exit(0)

try:
    topic_id = int(topic_id)
except (ValueError, TypeError):
    print(forum.nav_bar(user, token=token))
    print("`F800Invalid topic ID.`f")
    sys.exit(0)

topic = forum.get_topic(topic_id)
if not topic:
    print(forum.nav_bar(user, token=token))
    print("`F800Topic not found.`f")
    sys.exit(0)

# Add comment if submitted
if action == "comment" and user and can_write and not topic["is_closed"]:
    body = os.environ.get("field_body", "").strip()[:5000]
    if body:
        forum.add_comment(topic_id, user["id"], body)
        topic = forum.get_topic(topic_id)

sf_fields = f"sf={topic['subforum_id']}"
if token:
    sf_fields += f"|session={token}"
back = f"{forum.page_path}/subforum.mu`{sf_fields}"

# ── Access control ──
if not forum.user_can_read_subforum(user, topic["subforum_id"]):
    print(forum.nav_bar(user, back_url=back, token=token))
    print("`Ff55Access restricted. You do not have permission to view this subforum.`f")
    forum.print_footer()
    sys.exit(0)

can_write = forum.user_can_write_subforum(user, topic["subforum_id"])

print(forum.nav_bar(user, back_url=back, token=token))

print(f">>{topic['title']}")
a_link = forum.profile_link(topic["author_name"], token)
status = "`F800[CLOSED]`f " if topic["is_closed"] else ""
print(f"{status}by {a_link}  ·  {forum.fmt_time(topic['created_at'])}")
print()

tags = forum.get_tags_for_topic(topic_id)
if tags:
    print("`F777Tags: ", end="")
    for i, tag in enumerate(tags):
        if i > 0:
            print(", ", end="")
        t_f = f"tag={tag}"
        if token:
            t_f += f"|session={token}"
        print(f"`[{tag}`{forum.page_path}/tag.mu`{t_f}]`f", end="")
    print("`f")
    print()

print(f"-")
print(topic["body"])
print()

# Comments
comments = forum.get_comments(topic_id)
if comments:
    print(">Comments")
    for c in comments:
        a_link = forum.profile_link(c["author_name"], token)
        print(f"`F777{forum.fmt_time(c['created_at'])} by {a_link}`f")
        print(c["body"])
        if user and (user.get("is_admin") or user.get("is_mod") or user["id"] == c["author_id"]):
            dc_f = f"comment={c['id']}"
            if token:
                dc_f += f"|session={token}"
            print(f"`Ff55`[Delete`{forum.page_path}/admin/delete_comment.mu`{dc_f}]`f")
        print()

# Reply form
if user and can_write and not topic["is_closed"]:
    print(">Reply")
    print("Your reply:")
    print("`B333`<60|body`>`b")
    print(f"`[Post`{forum.page_path}/topic.mu`action=comment|session={token}|*]")
elif user and not can_write:
    print("`F777You do not have permission to post in this subforum.`f")
elif not user:
    print("`F777`[Login to reply`{forum.page_path}/login.mu]`f")
elif topic["is_closed"]:
    print("`F800This topic is closed.`f")

forum.print_footer()
