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
    action  = os.environ.get("var_action", "")
    view    = os.environ.get("var_view", "")    # "group" | "access" | ""
    gid_str = os.environ.get("var_gid", "").strip()
    sf_str  = os.environ.get("var_sf", "").strip()

    back_f = f"session={token}" if token else ""
    back   = f"{forum.page_path}/admin/admin.mu`{back_f}" if back_f else f"{forum.page_path}/admin/admin.mu"
    here   = f"{forum.page_path}/admin/groups.mu"

    print(forum.nav_bar(admin, back_url=back, token=token))
    print("`F0af`!Group Management`!`f")
    print()

    # ── helper: link with token ──────────────────────────────────────────────
    def lnk(label, extra="", color=""):
        parts = [f"session={token}"] if token else []
        if extra:
            parts.append(extra)
        fields = "|".join(parts)
        seg = ("`" + fields) if fields else ""
        if color:
            return f"`F{color}`[{label}`{here}{seg}]`f"
        return f"`[{label}`{here}{seg}]"

    # ── ACTION: create group ─────────────────────────────────────────────────
    if action == "create_group":
        g_name = os.environ.get("field_g_name", "").strip()[:60]
        g_desc = os.environ.get("field_g_desc", "").strip()[:200]
        if g_name:
            try:
                forum.create_group(g_name, g_desc)
                print(f"`F1a6Group '{g_name}' created.`f\n")
            except Exception as e:
                print(f"`Ff55Error: {e}`f\n")
        else:
            print("`Ff55Group name cannot be empty.`f\n")

    # ── ACTION: delete group ─────────────────────────────────────────────────
    elif action == "delete_group":
        gid = gid_str
        if gid:
            try:
                forum.delete_group(gid)
                print("`F1a6Group deleted.`f\n")
            except Exception as e:
                print(f"`Ff55Error: {e}`f\n")

    # ── ACTION: add user to group ─────────────────────────────────────────────
    elif action == "add_member":
        uid_str = os.environ.get("var_uid", "").strip()
        gid     = gid_str
        if uid_str and gid:
            try:
                forum.add_user_to_group(uid_str, gid)
                print("`F1a6User added to group.`f\n")
            except Exception as e:
                print(f"`Ff55Error: {e}`f\n")

    # ── ACTION: remove user from group ───────────────────────────────────────
    elif action == "remove_member":
        uid_str = os.environ.get("var_uid", "").strip()
        gid     = gid_str
        if uid_str and gid:
            try:
                forum.remove_user_from_group(uid_str, gid)
                print("`F1a6User removed from group.`f\n")
            except Exception as e:
                print(f"`Ff55Error: {e}`f\n")

    # ── ACTION: set subforum access ───────────────────────────────────────────
    elif action == "set_access":
        sf_id   = sf_str
        gid     = os.environ.get("var_gid", "").strip()
        r_val   = os.environ.get("var_read",  "0").strip()
        w_val   = os.environ.get("var_write", "0").strip()
        if sf_id and gid:
            try:
                forum.set_subforum_access(sf_id, gid, r_val == "1", w_val == "1")
                print("`F1a6Access updated.`f\n")
            except Exception as e:
                print(f"`Ff55Error: {e}`f\n")

    # ── ACTION: remove subforum access ────────────────────────────────────────
    elif action == "remove_access":
        sf_id = sf_str
        gid   = os.environ.get("var_gid", "").strip()
        if sf_id and gid:
            try:
                forum.remove_subforum_access(sf_id, gid)
                print("`F1a6Access rule removed.`f\n")
            except Exception as e:
                print(f"`Ff55Error: {e}`f\n")

    # ═══════════════════════════════════════════════════════════════════════════
    # VIEW: group detail (members + subforum access)
    # ═══════════════════════════════════════════════════════════════════════════
    if view == "group" and gid_str:
        grp = forum.get_group(gid_str)
        if not grp:
            print("`Ff55Group not found.`f")
        else:
            print(f">>Group: `!{grp['name']}`!")
            if grp["description"]:
                print(f"`F888{grp['description']}`f")
            print()

            # ── Members ──────────────────────────────────────────────────────
            print(">Members")
            members = forum.get_group_members(gid_str)
            if members:
                for m in members:
                    rm_f = f"action=remove_member|gid={gid_str}|uid={m['id']}|view=group"
                    if token:
                        rm_f += f"|session={token}"
                    disp = m["display_name"] or m["username"]
                    print(f"`F0af{disp}`f (`F777{m['username']}`f)  "
                          f"`Ff55`[remove`{here}`{rm_f}]`f")
            else:
                print("`F777No members yet.`f")
            print()

            # ── Add member form ───────────────────────────────────────────────
            print("Add member by username:")
            add_f = f"action=add_member_form|gid={gid_str}|view=group"
            if token:
                add_f += f"|session={token}"

            # We use a select-style: list all users not yet in group
            all_users = forum.get_all_users()
            member_ids = {m["id"] for m in members}
            non_members = [u for u in all_users if u["id"] not in member_ids]

            if non_members:
                for u in non_members:
                    ua_f = f"action=add_member|gid={gid_str}|uid={u['id']}|view=group"
                    if token:
                        ua_f += f"|session={token}"
                    disp = u["display_name"] or u["username"]
                    print(f"`F4af`[+ {disp}`{here}`{ua_f}]`f")
            else:
                print("`F777All users are already members.`f")
            print()

            # ── Subforum access ───────────────────────────────────────────────
            print(">Subforum Access")
            subforums = forum.get_subforums()
            access_list = forum.get_subforum_access_for_group = None  # not needed

            # Build quick lookup: sf_id -> access row
            conn = forum.get_db()
            access_rows = conn.execute(
                "SELECT subforum_id, can_read, can_write FROM subforum_access WHERE group_id=?",
                (int(gid_str),)
            ).fetchall()
            conn.close()
            access_map = {r[0]: {"can_read": r[1], "can_write": r[2]} for r in access_rows}

            if not subforums:
                print("`F777No subforums exist.`f")
            else:
                for sf in subforums:
                    sfid = sf["id"]
                    acc  = access_map.get(sfid)
                    if acc:
                        r_label = "`F1a6read`f" if acc["can_read"]  else "`F555no-read`f"
                        w_label = "`F1a6write`f" if acc["can_write"] else "`F555no-write`f"
                        rm_f = f"action=remove_access|sf={sfid}|gid={gid_str}|view=group"
                        if token:
                            rm_f += f"|session={token}"
                        # Toggle read
                        new_r = 0 if acc["can_read"] else 1
                        new_w = acc["can_write"]
                        tr_f = f"action=set_access|sf={sfid}|gid={gid_str}|read={new_r}|write={new_w}|view=group"
                        if token:
                            tr_f += f"|session={token}"
                        # Toggle write
                        new_w2 = 0 if acc["can_write"] else 1
                        tw_f = f"action=set_access|sf={sfid}|gid={gid_str}|read={acc['can_read']}|write={new_w2}|view=group"
                        if token:
                            tw_f += f"|session={token}"
                        print(f"`!{sf['name']}`!  {r_label}  {w_label}  "
                              f"`[toggle read`{here}`{tr_f}]  "
                              f"`[toggle write`{here}`{tw_f}]  "
                              f"`Ff55`[remove`{here}`{rm_f}]`f")
                    else:
                        # No rule: subforum is open (unrestricted)
                        add_f = f"action=set_access|sf={sfid}|gid={gid_str}|read=1|write=1|view=group"
                        if token:
                            add_f += f"|session={token}"
                        add_ro = f"action=set_access|sf={sfid}|gid={gid_str}|read=1|write=0|view=group"
                        if token:
                            add_ro += f"|session={token}"
                        print(f"`F777{sf['name']}`f  `F555(open)`f  "
                              f"`F1a6`[grant read+write`{here}`{add_f}]`f  "
                              f"`F4af`[grant read-only`{here}`{add_ro}]`f")
            print()

            back_grp = f"session={token}" if token else ""
            print(f"`[← Back to Groups`{here}`{back_grp}]")

    # ═══════════════════════════════════════════════════════════════════════════
    # VIEW: subforum access overview
    # ═══════════════════════════════════════════════════════════════════════════
    elif view == "access" and sf_str:
        sf = forum.get_subforum(sf_str)
        if not sf:
            print("`Ff55Subforum not found.`f")
        else:
            print(f">>Access Rules: `!{sf['name']}`!")
            print()
            rules = forum.get_subforum_access(sf_str)
            if rules:
                for r in rules:
                    r_label = "`F1a6read`f"  if r["can_read"]  else "`F555no-read`f"
                    w_label = "`F1a6write`f" if r["can_write"] else "`F555no-write`f"
                    rm_f = f"action=remove_access|sf={sf_str}|gid={r['group_id']}|view=access|sfv={sf_str}"
                    if token:
                        rm_f += f"|session={token}"
                    print(f"`F0af{r['group_name']}`f  {r_label}  {w_label}  "
                          f"`Ff55`[remove`{here}`{rm_f}]`f")
            else:
                print("`F777No access restrictions set. All users may read and write.`f")
            print()
            back_sf = f"session={token}" if token else ""
            print(f"`[← Back to Groups`{here}`{back_sf}]")

    # ═══════════════════════════════════════════════════════════════════════════
    # VIEW: main groups list
    # ═══════════════════════════════════════════════════════════════════════════
    else:
        groups = forum.get_all_groups()

        print(">>Groups")
        print()
        if not groups:
            print("`F777No groups yet.`f")
        else:
            for g in groups:
                members = forum.get_group_members(g["id"])
                gv_f = f"view=group|gid={g['id']}"
                if token:
                    gv_f += f"|session={token}"
                del_f = f"action=delete_group|gid={g['id']}"
                if token:
                    del_f += f"|session={token}"
                print(f"`F0af`[{g['name']}`{here}`{gv_f}]`f  "
                      f"`F777{len(members)} members`f  "
                      f"`Ff55`[delete`{here}`{del_f}]`f")
                if g["description"]:
                    print(f"`F888{g['description']}`f")
                print()

        print("-")
        print("Create new group:")
        cg_f = f"action=create_group"
        if token:
            cg_f += f"|session={token}"
        print(f"""
Group name:
`B333`<40|g_name`>`b

Description:
`B333`<40|g_desc`>`b

`[Create Group`{here}`*|{cg_f}]
""")

        print("-")
        print(">>Subforum Access Overview")
        print()
        subforums = forum.get_subforums()
        if not subforums:
            print("`F777No subforums yet.`f")
        else:
            for sf in subforums:
                sfv_f = f"view=access|sf={sf['id']}"
                if token:
                    sfv_f += f"|session={token}"
                restr = forum.subforum_is_restricted(sf["id"])
                badge = "`Fca4[restricted]`f" if restr else "`F777[open]`f"
                print(f"`[{sf['name']}`{here}`{sfv_f}]  {badge}")
            print()

    forum.print_footer()

except PermissionError:
    print("`Ff55Access denied. Admin only.`f")
except Exception as e:
    print(f"`Ff55Error: {e}`f")
