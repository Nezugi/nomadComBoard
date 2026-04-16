#!/usr/bin/env python3

# nomadBlog - Help / info page

import main

try:
    print(main.PAGE_HEADER, end="")
    main.print_header("Help")
    print()

    print(">About this Blog")
    print()
    print("This is the node blog — posts, news and notes from the operator.")
    print("Browse posts, filter by tag, or read full articles.")
    print()
    print("-")
    print(">Reading Posts")
    print()
    print("The start page lists all posts, newest first.")
    print("Click a post title to read the full article.")
    print("Use the Tags page to find posts by topic.")
    print()
    print("-")
    print(">Tags")
    print()
    print("Each post can have one or more tags.")
    print("Click a tag to see all posts with that tag.")
    print("Browse all tags on the Tags page.")
    print()
    print("-")
    print(">Writing Posts")
    print()
    print("Only the node admin can write and publish posts.")
    print("Log in via Admin Login to access the write form.")
    print("Posts support line breaks and tags.")
    print()
    print("-")
    print(">Markup")
    print()
    print("Posts are plain text with optional Micron formatting.")
    print("Use standard text or Micron codes for styling.")
    print()

    main.print_footer()
except Exception as e:
    print(f"`Ff55Error: {e}`f")
    import traceback
    traceback.print_exc()
    try:
        main.print_footer()
    except:
        pass
