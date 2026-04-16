#!/usr/bin/env python3

# nomadBlog - index / overview page

import os
import sys
import main

try:
    print(main.PAGE_HEADER, end="")
    main.print_header()
    print()

    posts = main.query_database(
        "SELECT post_id, title, created FROM posts ORDER BY created DESC LIMIT 20"
    )

    if len(posts) == 0:
        print("`FbbbNo posts yet.`f")
    else:
        for post in posts:
            post_id   = post[0]
            title     = post[1].replace("`", "'").replace("[", "(").replace("]", ")")
            timestamp = post[2]
            date_str  = main.format_date(timestamp)

            tags = main.query_database(
                f"SELECT name FROM tags WHERE post_id = '{main.safe(post_id)}'"
            )
            tag_str = ""
            if tags:
                tag_str = "  " + " ".join(
                    f"`F58f`_`[{t[0]}`{main.page_path}/tags.mu`tag={t[0]}]`_`f"
                    for t in tags
                )

            print("-")
            print(f"`Ff8a`_`[{title}`{main.page_path}/view.mu`post_id={post_id}]`_`f")
            print(f"`F777{date_str}`f{tag_str}")
            print("-")

    print()
    print("-")
    if main.check_admin_session():
        session_id = os.environ.get("var_session", "")
        print(f"`Fa0a`_`[+ New Post`{main.page_path}/write.mu`session={session_id}]`_`f")
    else:
        print(f"`F777`_`[Admin`{main.page_path}/admin_login.mu]`_`f")

    main.close_database()
    main.print_footer()
except Exception as e:
    print(f"`Ff55Error: {e}`f")
    import traceback
    traceback.print_exc()
    main.print_footer()
