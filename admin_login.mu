#!/usr/bin/env python3

# nomadBlog - Admin login

import os
import sys
import hashlib
import uuid
import main

try:
    print(main.PAGE_HEADER, end="")
    main.print_header("Admin Login")

    password = os.environ.get("field_password", "")

    if not password:
        print(">Admin Login")
        print()
        print("`FbbbPassword`f")
        print("`B333`<!32|password`>`b")
        print()
        print(f"`Fa0a`_`[Log In`{main.page_path}/admin_login.mu`*]`_`f")
    else:
        stored_hash = main.get_admin_password_hash()
        if not stored_hash:
            print("`Ff44No admin account found. Please run setup.py.`f")
            main.close_database(write_changes=False)
            main.print_footer()
            sys.exit(0)

        pw_hash = hashlib.sha256(password.encode()).hexdigest()

        if pw_hash == stored_hash:
            session_id = str(uuid.uuid4())
            main.execute_sql(
                f"INSERT INTO admin_sessions (session_id, created) "
                f"VALUES ('{session_id}', unixepoch())"
            )
            main.close_database(write_changes=True)
            print("`Fa0aLogin successful!`f")
            print()
            print(f"`F88f`_`[+ New Post`{main.page_path}/write.mu`session={session_id}]`_`f")
            print()
            print(f"`F777`_`[← Overview`{main.page_path}/index.mu`session={session_id}]`_`f")
            main.print_footer()
            sys.exit(0)
        else:
            print("`Ff44Wrong password.`f")
            print()
            print("`FbbbPassword`f")
            print("`B333`<!32|password`>`b")
            print()
            print(f"`Fa0a`_`[Try Again`{main.page_path}/admin_login.mu`*]`_`f")

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
