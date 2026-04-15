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
    
    action = os.environ.get("var_action", "")
    
    # Get topic
    topic = forum.get_topic(topic_id)
    
    nav = forum.nav_bar(mod, back_url=f"{forum.page_path}/topic.mu`topic={topic_id}|session={token}", token=token)
    
    if not topic:
        print(nav)
        print("`Ff55Topic not found.`f")
        sys.exit(0)
    
    # Process action
    if action == "close":
        try:
            c = forum.get_db()
            c.execute("UPDATE topics SET is_closed=1 WHERE id=?", (topic_id,))
            c.commit()
            c.close()
            print(nav)
            print("`F1a6Topic closed.`f")
        except Exception as e:
            print(nav)
            print(f"`Ff55Error closing topic: {e}`f")
    
    elif action == "open":
        try:
            c = forum.get_db()
            c.execute("UPDATE topics SET is_closed=0 WHERE id=?", (topic_id,))
            c.commit()
            c.close()
            print(nav)
            print("`F1a6Topic reopened.`f")
        except Exception as e:
            print(nav)
            print(f"`Ff55Error reopening topic: {e}`f")
    
    else:
        # Show current status
        print(nav)
        is_closed = topic.get('is_closed', 0)
        status = "CLOSED" if is_closed else "OPEN"
        print(f"`F777Topic Status: {status}`f\n")
        
        topic_title = topic.get('title', 'Unknown')[:100]
        if is_closed:
            action_url = f"{forum.page_path}/admin/close_topic.mu`topic={topic_id}|action=open|session={token}"
            print(f"`[Reopen Topic`{action_url}]")
        else:
            action_url = f"{forum.page_path}/admin/close_topic.mu`topic={topic_id}|action=close|session={token}"
            print(f"`[Close Topic`{action_url}]")

except PermissionError:
    print("`Ff55Access denied. Moderators only.`f")
except Exception as e:
    print(f"`Ff55Error: {e}`f")
