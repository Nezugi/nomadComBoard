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
    
    # Get IDs with validation
    comment_id_str = os.environ.get("var_comment", "").strip()
    topic_id_str = os.environ.get("var_topic", "").strip()
    
    try:
        comment_id = int(comment_id_str) if comment_id_str else 0
        topic_id = int(topic_id_str) if topic_id_str else 0
    except (ValueError, TypeError):
        comment_id = 0
        topic_id = 0
    
    confirm = os.environ.get("var_confirm", "")
    
    # Get comment and topic
    c = forum.get_db()
    comment = c.execute("SELECT * FROM comments WHERE id=?", (comment_id,)).fetchone()
    c.close()
    
    nav = forum.nav_bar(mod, back_url=f"{forum.page_path}/topic.mu`topic={topic_id}|session={token}", token=token)
    
    if not comment or not topic_id:
        print(nav)
        print("`Ff55Comment not found.`f")
        sys.exit(0)
    
    # Delete comment if confirmed
    if confirm == "yes":
        try:
            c = forum.get_db()
            c.execute("DELETE FROM comments WHERE id=?", (comment_id,))
            # Update topic comment_count
            c.execute("UPDATE topics SET comment_count = MAX(0, comment_count - 1) WHERE id=?", (topic_id,))
            c.commit()
            c.close()
            print(nav)
            print("`F1a6Comment deleted.`f")
        except Exception as e:
            print(nav)
            print(f"`Ff55Error deleting comment: {e}`f")
    else:
        # Show confirmation
        print(nav)
        comment_body = comment[3] if len(comment) > 3 else "Unknown"
        preview = comment_body[:80] + "..." if len(comment_body) > 80 else comment_body
        print(f"`Ff55Delete Comment`f\n")
        print(f"Preview: {preview}\n")
        print("Are you sure? This cannot be undone.")
        print()
        
        confirm_url = f"{forum.page_path}/admin/delete_comment.mu`comment={comment_id}|topic={topic_id}|confirm=yes|session={token}"
        cancel_url = f"{forum.page_path}/topic.mu`topic={topic_id}|session={token}"
        
        print(f"`Ff55`[Yes, delete`{confirm_url}]`f  `[Cancel`{cancel_url}]")

except PermissionError:
    print("`Ff55Access denied. Moderators only.`f")
except Exception as e:
    print(f"`Ff55Error: {e}`f")
