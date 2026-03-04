#!/bin/bash
# Remove a skill from central repository and all symlinks

SKILL_NAME=$1
CENTRAL_REPO="/Users/yes365/AI/NoCode/skills"

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: remove_skill.sh <skill-name>"
    exit 1
fi

if [ ! -d "$CENTRAL_REPO/$SKILL_NAME" ]; then
    echo "Error: Skill '$SKILL_NAME' not found in central repository"
    exit 1
fi

read -p "Are you sure you want to remove '$SKILL_NAME'? This cannot be undone. [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Remove from central repository
rm -rf "$CENTRAL_REPO/$SKILL_NAME"
echo "Removed '$SKILL_NAME' from central repository"

# Remove global symlink if exists
if [ -L "$HOME/.claude/skills/$SKILL_NAME" ]; then
    rm "$HOME/.claude/skills/$SKILL_NAME"
    echo "Removed global symlink"
fi

# Remove project symlinks
if [ -d "./.claude/skills" ]; then
    if [ -L "./.claude/skills/$SKILL_NAME" ]; then
        rm "./.claude/skills/$SKILL_NAME"
        echo "Removed project symlink"
    fi
fi

echo "Done. Skill '$SKILL_NAME' has been completely removed."
