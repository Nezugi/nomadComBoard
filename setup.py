#!/usr/bin/env python3

# nomadBlog - Admin Setup
# Run once to set or reset the admin password.

import sys
import os
import hashlib
import getpass

# Make parent directory importable
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import main

print("=== nomadBlog Admin Setup ===")
print(f"Storage path: {main.storage_path}\n")

pw = getpass.getpass("Enter new admin password: ")
pw2 = getpass.getpass("Confirm password: ")

if pw != pw2:
    print("Passwords do not match. Aborting.")
    sys.exit(1)

if len(pw) < 8:
    print("Password must be at least 8 characters. Aborting.")
    sys.exit(1)

pw_hash = hashlib.sha256(pw.encode()).hexdigest()

# Delete old entry if present
main.execute_sql("DELETE FROM settings WHERE key = 'admin_password_hash'")
main.execute_sql(f"INSERT INTO settings (key, value) VALUES ('admin_password_hash', '{pw_hash}')")
main.close_database(write_changes=True)

print("\nAdmin password set successfully.")
print(f"You can now log in at: {main.page_path}/admin_login.mu")
