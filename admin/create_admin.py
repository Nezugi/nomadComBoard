#!/usr/bin/env python3
"""
Create an admin account.
Run: python3 admin/create_admin.py
"""

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import main as forum

print("=== nomadForum – Create Admin Account ===")
print()

username = input("Username: ").strip()[:32]
password = input("Password (min 6 characters): ").strip()

# Validate input
if not username or not password:
    print("Error: Username and password cannot be empty.")
    sys.exit(1)

if len(password) < 6:
    print("Error: Password must be at least 6 characters.")
    sys.exit(1)

# Check if user exists
try:
    existing = forum.get_user_by_name(username)
    
    if existing:
        # Make existing user an admin
        conn = forum.get_db()
        conn.execute("UPDATE users SET is_admin=1 WHERE username=?", (username,))
        conn.commit()
        conn.close()
        print(f"✓ User '{username}' is now an admin.")
    else:
        # Create new admin user
        err = forum.register_user(username, password)
        if err:
            print(f"Error: {err}")
            sys.exit(1)
        
        conn = forum.get_db()
        conn.execute("UPDATE users SET is_admin=1 WHERE username=?", (username,))
        conn.commit()
        conn.close()
        print(f"✓ Admin account '{username}' created successfully.")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
