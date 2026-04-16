#!/usr/bin/env python3

# nomadBlog - Create / edit a post (admin only)

import os
import sys
import uuid
import main

try:
    print(main.PAGE_HEADER, end="")
    main.print_header("Write Post")

    if not main.check_admin_session():
        print(">Admin only.")
        print()
        print(f"`Fa0a`_`[Login`{main.page_path}/admin_login.mu]`_`f")
        main.close_database(write_changes=False)
        main.print_footer()
        sys.exit(0)

    session_id = os.environ.get("var_session", "")
    post_id    = os.environ.get("var_post_id", "")
    title      = os.environ.get("field_title", "")
    content    = os.environ.get("field_content", "")
    tags_raw   = os.environ.get("field_tags", "")
    confirm    = os.environ.get("var_confirm", "")

    editing = bool(post_id and main.check_uuid(post_id))

    # Pre-fill fields when editing an existing post
    if editing and not title:
        row = main.query_database(
            f"SELECT title, content FROM posts WHERE post_id = '{main.safe(post_id)}'"
        )
        if row:
            title   = row[0][0].replace("\\", "\\\\")
            content = row[0][1].replace("\n", "$newline$").replace("\\", "\\\\")

        existing_tags = main.query_database(
            f"SELECT name FROM tags WHERE post_id = '{main.safe(post_id)}'"
        )
        if existing_tags and not tags_raw:
            tags_raw = ",".join(t[0] for t in existing_tags)

    # Show the write form
    if not title or not content or not confirm:
        heading = ">Edit Post" if editing else ">New Post"
        print(heading)
        print()

        title_disp   = title.replace("\\", "\\\\")
        content_disp = content.replace("\n", "$newline$").replace("\\", "\\\\")

        print("`FbbbTitle`f")
        print(f"`B333`<40|title`{title_disp}>`b")
        print()

        print("`FbbbContent`f")
        print(f"`B333`<50|content`{content_disp}>`b")
        print("`F777Line break: Enter or $newline$`f")
        print()

        print("`FbbbTags`f")
        print(f"`B333`<40|tags`{tags_raw}>`b")
        print("`F777Comma-separated, e.g.: tech,python,news`f")
        print()

        if editing:
            print(
                f"`Fa0a`_`[Save`{main.page_path}/write.mu`*|post_id={post_id}|session={session_id}|confirm=1]`_`f"
            )
        else:
            print(
                f"`Fa0a`_`[Publish`{main.page_path}/write.mu`*|session={session_id}|confirm=1]`_`f"
            )

        main.close_database(write_changes=False)
        main.print_footer()
        sys.exit(0)

    # Validate
    title_clean   = main.prepare_title(title)
    content_clean = main.prepare_content(content)

    if len(title_clean) < 3 or len(title_clean) > 200:
        print("`Ff44Title must be 3–200 characters.`f")
        main.close_database(write_changes=False)
        main.print_footer()
        sys.exit(0)

    if len(content_clean) > 50000:
        print("`Ff44Content must not exceed 50,000 characters.`f")
        main.close_database(write_changes=False)
        main.print_footer()
        sys.exit(0)

    # Process tags
    tag_names = []
    for raw in tags_raw.split(","):
        t = main.prepare_tag(raw)
        if t and t not in tag_names:
            tag_names.append(t)

    # Write to DB
    if editing:
        main.execute_sql(
            f"UPDATE posts SET title = '{title_clean}', content = '{content_clean}', "
            f"changed = unixepoch() WHERE post_id = '{main.safe(post_id)}'"
        )
        main.execute_sql(f"DELETE FROM tags WHERE post_id = '{main.safe(post_id)}'")
        for t in tag_names:
            main.execute_sql(
                f"INSERT INTO tags (post_id, name) VALUES ('{main.safe(post_id)}', '{main.safe(t)}')"
            )
        main.close_database(write_changes=True)
        print("`Fa0aPost updated!`f")
        print()
        print(f"`F88f`_`[View Post`{main.page_path}/view.mu`post_id={post_id}|session={session_id}]`_`f")
    else:
        new_id = str(uuid.uuid4())
        main.execute_sql(
            f"INSERT INTO posts (post_id, title, content, created, changed) "
            f"VALUES ('{new_id}', '{title_clean}', '{content_clean}', unixepoch(), unixepoch())"
        )
        for t in tag_names:
            main.execute_sql(
                f"INSERT INTO tags (post_id, name) VALUES ('{new_id}', '{main.safe(t)}')"
            )
        main.close_database(write_changes=True)
        print("`Fa0aPost published!`f")
        print()
        print(f"`F88f`_`[View Post`{main.page_path}/view.mu`post_id={new_id}|session={session_id}]`_`f")

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
