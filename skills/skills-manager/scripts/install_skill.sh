#!/bin/bash
# Install a skill and choose where to link it (global, project, or both)

SKILL_NAME=$1
CENTRAL_REPO="/Users/yes365/AI/NoCode/skills"
GLOBAL_DIR="$HOME/.claude/skills"

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: install_skill.sh <skill-name>"
    exit 1
fi

if [ ! -d "$CENTRAL_REPO/$SKILL_NAME" ]; then
    echo "Error: Skill '$SKILL_NAME' not found in central repository"
    echo "Run 'list_skills.sh' to see available skills"
    exit 1
fi

echo ""
echo "=== Install Skill: $SKILL_NAME ==="
echo ""
echo "Where would you like to install this skill?"
echo ""
echo "  1) Global (~/.claude/skills/) - Available in all projects"
echo "  2) Project (./.claude/skills/) - Available only in current project"
echo "  3) Both - Available globally and in current project"
echo "  4) Cancel"
echo ""
read -p "Enter choice (1-4): " choice

link_global() {
    if [ -L "$GLOBAL_DIR/$SKILL_NAME" ]; then
        echo "  Skill '$SKILL_NAME' already linked globally"
        return 0
    fi
    if [ -e "$GLOBAL_DIR/$SKILL_NAME" ]; then
        echo "  Error: '$SKILL_NAME' already exists in global directory (not a symlink)"
        return 1
    fi
    ln -s "$CENTRAL_REPO/$SKILL_NAME" "$GLOBAL_DIR/$SKILL_NAME"
    echo "  Linked '$SKILL_NAME' to ~/.claude/skills/"
}

link_project() {
    if [ ! -f "CLAUDE.md" ] && [ ! -d ".claude" ]; then
        echo "  Warning: Current directory doesn't appear to be a Claude project"
        echo "  (no CLAUDE.md or .claude directory found)"
        read -p "  Continue anyway? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "  Cancelled project linking"
            return 1
        fi
    fi

    mkdir -p .claude/skills

    if [ -L ".claude/skills/$SKILL_NAME" ]; then
        echo "  Skill '$SKILL_NAME' already linked in project"
        return 0
    fi
    if [ -e ".claude/skills/$SKILL_NAME" ]; then
        echo "  Error: '$SKILL_NAME' already exists in project directory (not a symlink)"
        return 1
    fi
    ln -s "$CENTRAL_REPO/$SKILL_NAME" ".claude/skills/$SKILL_NAME"
    echo "  Linked '$SKILL_NAME' to ./.claude/skills/"
}

case $choice in
    1)
        echo ""
        echo "Linking to global..."
        link_global
        echo ""
        echo "Done! Skill '$SKILL_NAME' is now available globally."
        ;;
    2)
        echo ""
        echo "Linking to project..."
        link_project
        echo ""
        echo "Done! Skill '$SKILL_NAME' is now available in this project."
        ;;
    3)
        echo ""
        echo "Linking to global..."
        link_global
        echo ""
        echo "Linking to project..."
        link_project
        echo ""
        echo "Done! Skill '$SKILL_NAME' is now available globally and in this project."
        ;;
    4)
        echo ""
        echo "Installation cancelled."
        exit 0
        ;;
    *)
        echo ""
        echo "Invalid choice. Installation cancelled."
        exit 1
        ;;
esac
