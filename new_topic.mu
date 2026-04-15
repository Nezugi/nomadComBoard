#!/usr/bin/env python3
#!c=0

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as forum
import session as sess

print("#!c=0")

user   = sess.require_login()
token  = sess.session_token()
sf_id  = os.environ.get("var_sf", "").strip()
action = os.environ.get("var_action", "")
title  = os.environ.get("field_title", "").strip()[:100]
body   = os.environ.get("field_body", "").strip()[:5000]
tags   = os.environ.get("field_tags", "").strip()

try:
    sf_id = int(sf_id)
except (ValueError, TypeError):
    sf_id = 0

sf = forum.get_subforum(sf_id)
if not sf:
    print(forum.nav_bar(user, token=token))
    print("`F800Subforum not found.`f")
    sys.exit(0)

sf_fields = f"sf={sf_id}"
if token:
    sf_fields += f"|session={token}"
back = f"{forum.page_path}/subforum.mu`{sf_fields}"

# ── Access control ──
if not forum.user_can_write_subforum(user, sf_id):
    print(forum.nav_bar(user, back_url=back, token=token))
    print("`Ff55Access restricted. You do not have permission to post in this subforum.`f")
    forum.print_footer()
    sys.exit(0)

print(forum.nav_bar(user, back_url=back, token=token))
print(f">New topic in: {sf['name']}")
print()

if action == "submit" and title and body:
    try:
        topic_id = forum.create_topic(sf_id, user["id"], title, body, tags)
        print("`F080Topic created.`f")
        print(f"\n`[View Topic`{forum.page_path}/topic.mu`topic={topic_id}|session={token}]")
        sys.exit(0)
    except Exception as e:
        print(f"`Ff55Error: {e}`f")
        print()

print("Topic Title")
print("`B333`<60|title`>`b")
print()
print("Topic Body")
print("`B333`<60|body`>`b")
print()
print("Tags (comma-separated, optional)")
print("`B333`<60|tags`>`b")
print()

print(f"`[Create`{forum.page_path}/new_topic.mu`action=submit|sf={sf_id}|session={token}|*]")
print(f"`[Cancel`{back}]")

forum.print_footer()
