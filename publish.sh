#!/bin/bash

# publish.sh — Publish an Obsidian markdown note to your Hugo blog
# Usage: ./publish.sh /path/to/your/note.md

set -e

BLOG_DIR="$HOME/blog"

if [ -z "$1" ]; then
    echo "Usage: ./publish.sh /path/to/your/note.md"
    exit 1
fi

SOURCE_FILE="$1"
SOURCE_DIR="$(dirname "$SOURCE_FILE")"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: File not found: $SOURCE_FILE"
    exit 1
fi

# First line = title (strip any leading # characters)
TITLE=$(head -n 1 "$SOURCE_FILE" | sed 's/^#* *//')

if [ -z "$TITLE" ]; then
    echo "Error: First line is empty. First line should be your title."
    exit 1
fi

echo "Title: $TITLE"

# URL-friendly slug
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

DATE=$(date +%Y-%m-%d)

# Body = everything after first line, skip leading blanks
BODY=$(tail -n +2 "$SOURCE_FILE" | sed '/./,$!d')

# Summary = first ~200 chars
SUMMARY=$(echo "$BODY" | head -c 250 | sed 's/\(.\{150,\}\)\..*/\1./' | tr '\n' ' ' | sed 's/  */ /g')

# Handle images
mkdir -p "$BLOG_DIR/static/images"

# Standard markdown images: ![alt](path)
IMAGES=$(echo "$BODY" | grep -oP '!\[.*?\]\(\K[^)]+' 2>/dev/null || true)

for IMG in $IMAGES; do
    if echo "$IMG" | grep -qE '^https?://'; then
        continue
    fi
    IMG_BASENAME=$(basename "$IMG")
    if [ -f "$SOURCE_DIR/$IMG" ]; then
        cp "$SOURCE_DIR/$IMG" "$BLOG_DIR/static/images/$IMG_BASENAME"
        echo "Copied image: $IMG_BASENAME"
    elif [ -f "$IMG" ]; then
        cp "$IMG" "$BLOG_DIR/static/images/$IMG_BASENAME"
        echo "Copied image: $IMG_BASENAME"
    else
        echo "Warning: Image not found: $IMG"
    fi
    BODY=$(echo "$BODY" | sed "s|$IMG|/images/$IMG_BASENAME|g")
done

# Obsidian-style embeds: ![[image.png]]
OBSIDIAN_IMAGES=$(echo "$BODY" | grep -oP '!\[\[\K[^]]+\.(png|jpg|jpeg|gif|webp)' 2>/dev/null || true)

for IMG in $OBSIDIAN_IMAGES; do
    IMG_BASENAME=$(basename "$IMG")
    if [ -f "$SOURCE_DIR/$IMG" ]; then
        cp "$SOURCE_DIR/$IMG" "$BLOG_DIR/static/images/$IMG_BASENAME"
        echo "Copied Obsidian image: $IMG_BASENAME"
    elif [ -f "$SOURCE_DIR/attachments/$IMG" ]; then
        cp "$SOURCE_DIR/attachments/$IMG" "$BLOG_DIR/static/images/$IMG_BASENAME"
        echo "Copied Obsidian image: $IMG_BASENAME"
    else
        echo "Warning: Obsidian image not found: $IMG"
    fi
    BODY=$(echo "$BODY" | sed "s|!\[\[$IMG\]\]|![$IMG_BASENAME](/images/$IMG_BASENAME)|g")
done

# Write the Hugo post
POST_PATH="$BLOG_DIR/content/posts/$SLUG.md"

cat > "$POST_PATH" << FRONTMATTER
---
title: "$TITLE"
date: $DATE
summary: "$SUMMARY"
---

$BODY
FRONTMATTER

echo "Created post: $POST_PATH"

# Build
cd "$BLOG_DIR"
hugo

echo "Site built successfully."

# Deploy
git add -A
git commit -m "Publish: $TITLE"
git push

echo ""
echo "Published: $TITLE"
