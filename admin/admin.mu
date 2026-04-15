#!/usr/bin/env python3
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import main as forum
import session as sess

print("#!c=0")

try:
    admin = sess.require_admin()
    token = sess.session_token()
    action = os.environ.get("var_action", "")
    
    back_f = f"session={token}" if token else ""
    back = f"{forum.page_path}/index.mu`{back_f}" if back_f else f"{forum.page_path}/index.mu"
    print(forum.nav_bar(admin, back_url=back, token=token))
    print("`F0af`!Admin Panel`!`f")
    print()

    # ── Quick links ──────────────────────────────────────────────────────────
    grp_f = f"session={token}" if token else ""
    print(f"`[Manage Groups & Access`{forum.page_path}/admin/groups.mu`{grp_f}]")
    print("-")
    
    # Create subforum
    if action == "create_sf":
        sf_name = os.environ.get("field_sf_name", "").strip()[:100]
        sf_desc = os.environ.get("field_sf_desc", "").strip()[:500]
        if sf_name:
            try:
                forum.create_subforum(sf_name, sf_desc)
                print(f"`F1a6Subforum '{sf_name}' created.`f\n")
            except Exception as e:
                print(f"`Ff55Error creating subforum: {e}`f\n")
        else:
            print("`Ff55Name cannot be empty.`f\n")
    
    # Delete subforum
    elif action == "delete_sf":
        sf_id = os.environ.get("var_sf", "").strip()
        confirm = os.environ.get("var_confirm", "")
        if confirm == "yes" and sf_id:
            try:
                forum.delete_subforum(sf_id)
                print("`F1a6Subforum deleted.`f\n")
            except Exception as e:
                print(f"`Ff55Error deleting subforum: {e}`f\n")
    
    # Save rules
    elif action == "save_rules":
        rules = os.environ.get("field_rules", "").strip()[:5000]
        try:
            forum.set_setting("rules", rules)
            print("`F1a6Rules saved.`f\n")
        except Exception as e:
            print(f"`Ff55Error saving rules: {e}`f\n")
    
    # Manage subforums
    print(">>Manage Subforums")
    print()
    
    try:
        subforums = forum.get_subforums()
        if not subforums:
            print("No subforums yet.")
        else:
            for sf in subforums:
                d_f = f"action=delete_sf|sf={sf['id']}|confirm=yes"
                if token:
                    d_f += f"|session={token}"
                acc_f = f"view=access|sf={sf['id']}"
                if token:
                    acc_f += f"|session={token}"
                topic_count = sf.get('topic_count', 0)
                restr = forum.subforum_is_restricted(sf["id"])
                badge = " `Fca4[restricted]`f" if restr else ""
                print(f"`!{sf['name']}`!{badge}  `F777{topic_count} topics`f  "
                      f"`F4af`[access`{forum.page_path}/admin/groups.mu`{acc_f}]`f  "
                      f"`Ff55`[delete`{forum.page_path}/admin/admin.mu`{d_f}]`f")
    except Exception as e:
        print(f"`Ff55Error loading subforums: {e}`f\n")
    
    print()
    base_f = "action=create_sf"
    if token:
        base_f += f"|session={token}"
    
    print("Create new subforum:")
    print(f"""
Name:
`B333`<40|sf_name`>`b

Description:
`B333`<40|sf_desc`>`b

`[Create`{forum.page_path}/admin/admin.mu`*|{base_f}]
""")
    
    print("-")
    
    # Edit rules
    print(">>Edit Rules")
    rules = forum.get_setting("rules") or ""
    rules_f = "action=save_rules"
    if token:
        rules_f += f"|session={token}"
    print(f"""
`B333`<60|rules`{rules}>`b

`[Save Rules`{forum.page_path}/admin/admin.mu`*|{rules_f}]
""")
    
    forum.print_footer()

except PermissionError:
    print("`Ff55Access denied. Admin only.`f")
except Exception as e:
    print(f"`Ff55Error: {e}`f")
