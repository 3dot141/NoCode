#!/bin/bash
# Link a skill to project .claude/skills/

SKILL_NAME=$1
CENTRAL_REPO="/Users/yes365/AI/NoCode/skills"
PROJECT_DIR="./.claude/skills"

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: link_project.sh <skill-name>"
    exit 1
fi

if [ ! -d "$CENTRAL_REPO/$SKILL_NAME" ]; then
    echo "Error: Skill '$SKILL_NAME' not found in central repository"
    exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p "$PROJECT_DIR"
fi

if [ -L "$PROJECT_DIR/$SKILL_NAME" ]; then
    echo "Skill '$SKILL_NAME' already linked in project"
    exit 0
fi

if [ -e "$PROJECT_DIR/$SKILL_NAME" ]; then
    echo "Error: '$SKILL_NAME' already exists in project (not a symlink)"
    exit 1
fi

ln -s "$CENTRAL_REPO/$SKILL_NAME" "$PROJECT_DIR/$SKILL_NAME"
echo "Linked '$SKILL_NAME' to ./.claude/skills/"
