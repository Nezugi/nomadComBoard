#!/usr/bin/env python3

# nomadBlog - About page
# Public view with node/operator info.
# Admin can edit all fields via the edit form on this page.

import os
import sys
import main

# Settings keys used by this page
KEY_TITLE   = "about_title"
KEY_DESC    = "about_description"
KEY_LXMF   = "about_lxmf"
KEY_CONTACT = "about_contact"
KEY_LOCATION= "about_location"
KEY_WEBSITE = "about_website"

try:
    print(main.PAGE_HEADER, end="")
    main.print_header("About")

    session_id = os.environ.get("var_session", "")
    is_admin   = main.check_admin_session()
    action     = os.environ.get("var_action", "")

    # ── Handle save ───────────────────────────────────────────────────────────
    if is_admin and action == "save":
        try:
            new_title    = os.environ.get("field_title", "").strip()[:60]
            new_desc     = os.environ.get("field_description", "").strip()[:500]
            new_lxmf     = os.environ.get("field_lxmf", "").strip()[:32]
            new_contact  = os.environ.get("field_contact", "").strip()[:80]
            new_location = os.environ.get("field_location", "").strip()[:40]
            new_website  = os.environ.get("field_website", "").strip()[:60]

            # Validate LXMF: must be exactly 32 hex chars or empty
            if new_lxmf and not (len(new_lxmf) == 32 and all(c in "0123456789abcdefABCDEF" for c in new_lxmf)):
                new_lxmf = ""

            main.set_setting(KEY_TITLE,    new_title)
            main.set_setting(KEY_DESC,     new_desc)
            main.set_setting(KEY_LXMF,     new_lxmf)
            main.set_setting(KEY_CONTACT,  new_contact)
            main.set_setting(KEY_LOCATION, new_location)
            main.set_setting(KEY_WEBSITE,  new_website)
            main.close_database(write_changes=True)
            print("`Fa0aAbout page saved.`f")
            print()
            print(f"`F777`_`[← View About`{main.page_path}/about.mu`session={session_id}]`_`f")
            main.print_footer()
            sys.exit(0)
        except Exception as e:
            print(f"`Ff55Save error: {e}`f")
            main.close_database(write_changes=False)
            main.print_footer()
            sys.exit(0)

    # ── Edit form (admin only) ────────────────────────────────────────────────
    if is_admin and action == "edit":
        title    = main.get_setting(KEY_TITLE,    "")
        desc     = main.get_setting(KEY_DESC,     "")
        lxmf     = main.get_setting(KEY_LXMF,     "")
        contact  = main.get_setting(KEY_CONTACT,  "")
        location = main.get_setting(KEY_LOCATION, "")
        website  = main.get_setting(KEY_WEBSITE,  "")

        print(">Edit About Page")
        print()

        print("`FbbbTitle`f")
        print(f"`B333`<40|title`{title}>`b")
        print()

        print("`FbbbDescription`f")
        print(f"`B333`<50|description`{desc}>`b")
        print()

        print("`FbbbLXMF Address`f")
        print(f"`B333`<32|lxmf`{lxmf}>`b")
        print("`F77732 hex characters`f")
        print()

        print("`FbbbContact Info`f")
        print(f"`B333`<40|contact`{contact}>`b")
        print()

        print("`FbbbLocation`f")
        print(f"`B333`<30|location`{location}>`b")
        print()

        print("`FbbbWebsite`f")
        print(f"`B333`<40|website`{website}>`b")
        print()

        print(f"`Fa0a`_`[Save`{main.page_path}/about.mu`*|action=save|session={session_id}]`_`f")
        print(f"  `F777`_`[Cancel`{main.page_path}/about.mu`session={session_id}]`_`f")

        main.close_database(write_changes=False)
        main.print_footer()
        sys.exit(0)

    # ── Public view ───────────────────────────────────────────────────────────
    title    = main.get_setting(KEY_TITLE,    "About this Node")
    desc     = main.get_setting(KEY_DESC,     "")
    lxmf     = main.get_setting(KEY_LXMF,     "")
    contact  = main.get_setting(KEY_CONTACT,  "")
    location = main.get_setting(KEY_LOCATION, "")
    website  = main.get_setting(KEY_WEBSITE,  "")

    print(f"`c`!`Ff8a{title}`f`!")
    print()

    if desc:
        print(desc)
        print()

    has_info = any([lxmf, contact, location, website])
    if has_info:
        print("-")
        print()
        if location:
            print(f"`F777Location`f  {location}")
            print()
        if lxmf:
            # Clickable LXMF link: formatting outside link tag
            print(f"`F777LXMF`f  {main.lxmf_link(lxmf)}")
            print()
        if contact:
            print(f"`F777Contact`f  {contact}")
            print()
        if website:
            print(f"`F777Website`f  {website}")
            print()

    if not has_info and not desc:
        print("`F777No information available yet.`f")
        print()

    # Admin edit link
    if is_admin:
        print("-")
        print()
        print(f"`Fca4`_`[Edit About Page`{main.page_path}/about.mu`action=edit|session={session_id}]`_`f")

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
