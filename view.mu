#!/usr/bin/env python3

# nomadBlog - view a single post

import os
import sys
import main

try:
    print(main.PAGE_HEADER, end="")
    main.print_header()

    post_id = os.environ.get("var_post_id", "")

    if not post_id or not main.check_uuid(post_id):
        print(">Post not found.")
        main.close_database(write_changes=False)
        main.print_footer()
        sys.exit(0)

    post = main.query_database(
        f"SELECT title, content, created, changed "
        f"FROM posts WHERE post_id = '{main.safe(post_id)}'"
    )

    if not post:
        print(">Post not found.")
        main.close_database(write_changes=False)
        main.print_footer()
        sys.exit(0)

    title, content, ts_created, ts_changed = post[0]

    tags = main.query_database(
        f"SELECT name FROM tags WHERE post_id = '{main.safe(post_id)}'"
    )

    # Title and date
    print(f"`c`!`Ff8a{title}`f`!")
    print()
    date_created = main.format_date(ts_created)
    print(f"`c`F777{date_created}`f")
    if ts_created != ts_changed:
        date_changed = main.format_date(ts_changed)
        print(f"`c`F777(edited: {date_changed})`f")
    print("`a")

    # Tags
    if tags:
        tag_str = "  ".join(
            f"`F58f`_`[{t[0]}`{main.page_path}/tags.mu`tag={t[0]}]`_`f"
            for t in tags
        )
        print(f"Tags: {tag_str}")

    print("-")
    print()

    # Post content
    print(content)

    print()
    print("-")
    print()

    # Admin actions
    if main.check_admin_session():
        session_id = os.environ.get("var_session", "")
        print(
            f"`Fa0a`_`[Edit`{main.page_path}/write.mu`post_id={post_id}|session={session_id}]`_`f"
            f"  `Ff44`_`[Delete`{main.page_path}/delete.mu`post_id={post_id}|session={session_id}]`_`f"
        )
        print()

    print(f"`F777`_`[← Overview`{main.page_path}/index.mu]`_`f")

    main.close_database(write_changes=False)
    main.print_footer()
except Exception as e:
    print(f"`Ff55Error: {e}`f")
    import traceback
    traceback.print_exc()
    try:
        main.close_database(write_changes=False)
        main.print_footer()
    except:
        pass
