#!/bin/bash
# Link a skill to global ~/.claude/skills/

SKILL_NAME=$1
CENTRAL_REPO="/Users/yes365/AI/NoCode/skills"
GLOBAL_DIR="$HOME/.claude/skills"

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: link_global.sh <skill-name>"
    exit 1
fi

if [ ! -d "$CENTRAL_REPO/$SKILL_NAME" ]; then
    echo "Error: Skill '$SKILL_NAME' not found in central repository"
    exit 1
fi

if [ -L "$GLOBAL_DIR/$SKILL_NAME" ]; then
    echo "Skill '$SKILL_NAME' already linked globally"
    exit 0
fi

if [ -e "$GLOBAL_DIR/$SKILL_NAME" ]; then
    echo "Error: '$SKILL_NAME' already exists in global directory (not a symlink)"
    exit 1
fi

ln -s "$CENTRAL_REPO/$SKILL_NAME" "$GLOBAL_DIR/$SKILL_NAME"
echo "Linked '$SKILL_NAME' to ~/.claude/skills/"
