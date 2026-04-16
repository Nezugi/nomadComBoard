# nomadComBoard

A full‑featured community discussion forum for [NomadNet](https://github.com/markqvist/NomadNet) nodes.

Part of the [**Off‑Grid Community Suite**](https://github.com/Nezugi/Off-Grid-Community-Suite).

**Tech stack:** Python · Micron Markup · SQLite  
**No external dependencies. No internet required.**

---

## Features

- **Subforums** — admin‑managed topic categories
- **Topics & comments** — threaded discussions with chronological replies
- **Tags** — assign on creation; tag cloud and filtered views
- **User accounts** — registration, login, profiles (LXMF address, bio, city, website)
- **Roles** — Guest · User · Moderator · Admin with granular permissions
- **Groups** — Admin can create Groups an restrict Subforums in read / write to ceratain groups
- **Moderation** — close/reopen topics, delete topics and comments
- **Admin panel** — manage subforums, rules, moderators, passwords and users
- **Clickable LXMF addresses** — contact users directly from profiles
- **Built‑in help page**
- **Standard library only** — no pip, no background services

---

## Installation

```bash
copy the files to  ~/.nomadnetwork/storage/pages/comboard/

chmod +x ~/.nomadnetwork/storage/pages/comboard/*.mu
chmod +x ~/.nomadnetwork/storage/pages/comboard/admin/*.mu

# Edit main.py and set storage_path
python3 ~/.nomadnetwork/storage/pages/comboard/admin/create_admin.py

# Restart NomadNet
```

---

## Configuration

```python
storage_path = "/home/YOUR_USER/.nomadComBoard"
page_path = ":/page/comboard"
forum_name = "nomadComBoard"
site_description = "Discussions, Topics & Comments"
node_homepage = ":/page/index.mu"
```

---

## File Structure

```text
comboard/
├── main.py              # database, sessions, helpers
├── session.py           # login checks
├── index.mu             # subforums + tag cloud
├── login.mu
├── logout.mu
├── register.mu
├── subforum.mu
├── new_topic.mu
├── topic.mu
├── tags.mu
├── tag.mu
├── users.mu
├── profile.mu
├── user_settings.mu
├── rules.mu
├── help.mu
└── admin/
    ├── admin.mu
    ├── create_admin.py
    ├── close_topic.mu
    ├── delete_topic.mu
    └── delete_comment.mu
```

---

## Permissions

| Action | Guest | User | Mod | Admin |
|------|:----:|:---:|:---:|:-----:|
| Read | ✓ | ✓ | ✓ | ✓ |
| Post topics & comments | — | ✓ | ✓ | ✓ |
| Edit own profile | — | ✓ | ✓ | ✓ |
| Close / reopen topics | — | — | ✓ | ✓ |
| Delete topics / comments | — | — | ✓ | ✓ |
| Manage subforums | — | — | — | ✓ |
| Edit rules | — | — | — | ✓ |
| Promote / demote mods | — | — | — | ✓ |
| Reset passwords / delete users | — | — | — | ✓ |

---

## Database

- **SQLite**: `~/.nomadComBoard/comboard.db` (auto‑created)
- **Passwords**: SHA‑256 + 16‑byte salt
- **Sessions**: 64‑char hex token, 7‑day TTL
- **Auth transport**: session token passed via URL parameters (NomadNet requirement)

---

## Similar Projects

- [nomadForum](https://github.com/AutumnSpark1226/nomadForum) — separate implementation

nomadComBoard is independently developed with a tag system, moderator role model and Profil Page
I like the NomadForum but wanted to do my owne interpretation for the nomadnet
---

## Access

```
YOUR_NODE_HASH:/page/comboard/index.mu
```

---

## License

MIT
