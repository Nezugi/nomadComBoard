#!/usr/bin/env python3

# nomadBlog - tag overview and filtered post list

import os
import sys
import main

try:
    print(main.PAGE_HEADER, end="")
    main.print_header("Tags")

    tag = os.environ.get("var_tag", "").strip()

    if not tag:
        print(">All Tags")
        print()

        all_tags = main.query_database(
            "SELECT name, COUNT(*) as c FROM tags GROUP BY name ORDER BY c DESC, name ASC"
        )

        if not all_tags:
            print("`F999No tags yet.`f")
        else:
            for row in all_tags:
                tag_name  = row[0]
                tag_count = row[1]
                print(f"`F58f`_`[{tag_name}`{main.page_path}/tags.mu`tag={tag_name}]`_`f  `F777({tag_count})`f")
    else:
        print(f">Posts tagged: `!{tag}`!")
        print()

        posts = main.query_database(
            f"SELECT p.post_id, p.title, p.created "
            f"FROM posts p "
            f"JOIN tags t ON p.post_id = t.post_id "
            f"WHERE t.name = '{main.safe(tag)}' "
            f"ORDER BY p.created DESC"
        )

        if not posts:
            print("`F999No posts with this tag.`f")
        else:
            for post in posts:
                post_id   = post[0]
                title     = post[1].replace("`", "'").replace("[", "(").replace("]", ")")
                timestamp = post[2]
                date_str  = main.format_date(timestamp)
                print("-")
                print(f"`Ff8a`_`[{title}`{main.page_path}/view.mu`post_id={post_id}]`_`f")
                print(f"`F777{date_str}`f")
                print("-")

    print()
    print("-")
    print(f"`F777`_`[← All Tags`{main.page_path}/tags.mu]`_`f  `F777`_`[← Overview`{main.page_path}/index.mu]`_`f")

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
