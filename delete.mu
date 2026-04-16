#!/usr/bin/env python3

# nomadBlog - delete a post (admin only)

import os
import sys
import main

try:
    print(main.PAGE_HEADER, end="")
    main.print_header("Delete Post")

    if not main.check_admin_session():
        print(">Admin only.")
        print()
        print(f"`Fa0a`_`[Login`{main.page_path}/admin_login.mu]`_`f")
        main.close_database(write_changes=False)
        main.print_footer()
        sys.exit(0)

    session_id = os.environ.get("var_session", "")
    post_id    = os.environ.get("var_post_id", "")
    confirmed  = os.environ.get("var_confirmed", "")

    if not post_id or not main.check_uuid(post_id):
        print("`Ff44Post not found.`f")
        main.close_database(write_changes=False)
        main.print_footer()
        sys.exit(0)

    row = main.query_database(
        f"SELECT title FROM posts WHERE post_id = '{main.safe(post_id)}'"
    )

    if not row:
        print("`Ff44Post not found.`f")
        main.close_database(write_changes=False)
        main.print_footer()
        sys.exit(0)

    title = row[0][0]

    if not confirmed:
        print(">Really delete?")
        print()
        print(f"`Ff8a`!{title}`!`f")
        print()
        print(
            f"`Ff44`_`[Yes, delete`{main.page_path}/delete.mu`post_id={post_id}|session={session_id}|confirmed=1]`_`f"
            f"  `F999`_`[Cancel`{main.page_path}/view.mu`post_id={post_id}|session={session_id}]`_`f"
        )
        main.close_database(write_changes=False)
    else:
        main.execute_sql(f"DELETE FROM tags WHERE post_id = '{main.safe(post_id)}'")
        main.execute_sql(f"DELETE FROM posts WHERE post_id = '{main.safe(post_id)}'")
        main.close_database(write_changes=True)
        print("`Fa0aPost deleted.`f")
        print()
        print(f"`F777`_`[← Overview`{main.page_path}/index.mu`session={session_id}]`_`f")

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
