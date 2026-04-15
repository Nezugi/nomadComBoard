#!/usr/bin/env python3
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import main as forum
import session as sess

print("#!c=0")

try:
    mod = sess.require_mod()
    token = sess.session_token()
    
    # Get topic_id with validation
    topic_id_str = os.environ.get("var_topic", "").strip()
    try:
        topic_id = int(topic_id_str) if topic_id_str else 0
    except (ValueError, TypeError):
        topic_id = 0
    
    confirm = os.environ.get("var_confirm", "")
    
    # Get topic
    topic = forum.get_topic(topic_id)
    
    nav = forum.nav_bar(mod, back_url=f"{forum.page_path}/index.mu`session={token}", token=token)
    
    if not topic:
        print(nav)
        print("`Ff55Topic not found.`f")
        sys.exit(0)
    
    # Delete topic if confirmed
    if confirm == "yes":
        try:
            c = forum.get_db()
            # Delete comments first (cascade)
            c.execute("DELETE FROM comments WHERE topic_id=?", (topic_id,))
            # Delete topic_tags
            c.execute("DELETE FROM topic_tags WHERE topic_id=?", (topic_id,))
            # Delete topic
            c.execute("DELETE FROM topics WHERE id=?", (topic_id,))
            c.commit()
            c.close()
            print(nav)
            print("`F1a6Topic deleted.`f")
        except Exception as e:
            print(nav)
            print(f"`Ff55Error deleting topic: {e}`f")
    else:
        # Show confirmation
        print(nav)
        topic_title = topic.get('title', 'Unknown')[:100]
        print(f"`Ff55Delete Topic: {topic_title}`f\n")
        print("Are you sure? This cannot be undone.")
        print()
        
        confirm_url = f"{forum.page_path}/admin/delete_topic.mu`topic={topic_id}|confirm=yes|session={token}"
        cancel_url = f"{forum.page_path}/index.mu`session={token}"
        
        print(f"`Ff55`[Yes, delete`{confirm_url}]`f  `[Cancel`{cancel_url}]")

except PermissionError:
    print("`Ff55Access denied. Moderators only.`f")
except Exception as e:
    print(f"`Ff55Error: {e}`f")
