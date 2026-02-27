#!/bin/bash
# delete.sh — Remove a post from your blog
# Usage: ./delete.sh (then pick from a list)

set -e
BLOG_DIR="$HOME/blog"
POSTS_DIR="$BLOG_DIR/content/posts"

# List available posts
echo "Posts:"
ls -1 "$POSTS_DIR"/*.md 2>/dev/null | while read f; do
    echo "  $(basename "$f")"
done

echo ""
read -p "Filename to delete: " FILENAME

if [ -f "$POSTS_DIR/$FILENAME" ]; then
    rm "$POSTS_DIR/$FILENAME"
    cd "$BLOG_DIR"
    hugo
    git add -A
    git commit -m "Delete: $FILENAME"
    git push
    echo "Deleted and deployed."
else
    echo "Not found: $FILENAME"
fi
