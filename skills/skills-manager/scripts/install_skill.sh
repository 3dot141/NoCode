#!/bin/bash
# Install a skill using npx skills add and record relationships

SKILL_NAME=$1
INSTALL_TARGET=$2
NOCODE_DIR="$HOME/.nocode"
RECORD_FILE="$NOCODE_DIR/skills-manager.json"

# Ensure npx is available
if ! command -v npx &> /dev/null; then
    echo "Error: npx is not installed. Please install Node.js first."
    exit 1
fi

# Create nocode directory if not exists
mkdir -p "$NOCODE_DIR"

# Initialize JSON file if not exists
if [ ! -f "$RECORD_FILE" ]; then
    echo '{"skills": {}}' > "$RECORD_FILE"
fi

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: install_skill.sh <skill-name> [target]"
    echo ""
    echo "Targets:"
    echo "  global   - Link to ~/.claude/skills/"
    echo "  project  - Link to ./.claude/skills/"
    echo "  both     - Link to both locations"
    echo ""
    exit 1
fi

echo ""
echo "=== Install Skill: $SKILL_NAME ==="
echo ""

# Step 1: Use npx skills add to install
echo "Running: npx skills add $SKILL_NAME"
if ! npx skills add "$SKILL_NAME" 2>&1; then
    echo "Warning: npx skills add failed or skill already exists"
fi
echo ""

# Step 2: Determine install target
if [ -n "$INSTALL_TARGET" ]; then
    case "$INSTALL_TARGET" in
        global|1) choice="1" ;;
        project|2) choice="2" ;;
        both|3) choice="3" ;;
        *)
            echo "Error: Invalid target '$INSTALL_TARGET'"
            exit 1
            ;;
    esac
else
    # Interactive mode
    echo "Where would you like to link this skill?"
    echo ""
    echo "  1) Global (~/.claude/skills/) - Available in all projects"
    echo "  2) Project (./.claude/skills/) - Available only in current project"
    echo "  3) Both - Available globally and in current project"
    echo "  4) Cancel"
    echo ""
    read -p "Enter choice (1-4): " choice
fi

# Get project identifier
get_project_id() {
    if [ -d ".git" ]; then
        git remote get-url origin 2>/dev/null | sha256sum | cut -c1-12 || pwd | sha256sum | cut -c1-12
    else
        pwd | sha256sum | cut -c1-12
    fi
}

PROJECT_ID=$(get_project_id)
PROJECT_PATH=$(pwd)

# Update JSON record
update_record() {
    local target=$1
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Use Python to safely update JSON
    python3 << EOF
import json
import sys

try:
    with open('$RECORD_FILE', 'r') as f:
        data = json.load(f)
except:
    data = {"skills": {}}

skill_name = '$SKILL_NAME'
if skill_name not in data['skills']:
    data['skills'][skill_name] = {
        'installed_at': '$timestamp',
        'locations': []
    }

location = {
    'type': '$target',
    'linked_at': '$timestamp'
}

if '$target' == 'project':
    location['project_id'] = '$PROJECT_ID'
    location['project_path'] = '$PROJECT_PATH'

# Check if already exists
exists = False
for loc in data['skills'][skill_name]['locations']:
    if loc['type'] == '$target':
        if '$target' != 'project' or loc.get('project_id') == '$PROJECT_ID':
            exists = True
            break

if not exists:
    data['skills'][skill_name]['locations'].append(location)

with open('$RECORD_FILE', 'w') as f:
    json.dump(data, f, indent=2)

print(f"Updated record: $RECORD_FILE")
EOF
}

# Link functions
link_global() {
    echo "  Linking to global..."
    if npx skills link "$SKILL_NAME" --global 2>/dev/null || \
       ln -sf "$(npx skills get-path "$SKILL_NAME" 2>/dev/null || echo "$HOME/.claude/skills/$SKILL_NAME")" "$HOME/.claude/skills/$SKILL_NAME" 2>/dev/null; then
        echo "  ✓ Linked to ~/.claude/skills/"
        update_record "global"
    else
        echo "  ✗ Failed to link globally"
        return 1
    fi
}

link_project() {
    echo "  Linking to project..."
    mkdir -p .claude/skills
    if npx skills link "$SKILL_NAME" --local 2>/dev/null || \
       ln -sf "$(npx skills get-path "$SKILL_NAME" 2>/dev/null || echo "$HOME/.claude/skills/$SKILL_NAME")" ".claude/skills/$SKILL_NAME" 2>/dev/null; then
        echo "  ✓ Linked to ./.claude/skills/"
        update_record "project"
    else
        echo "  ✗ Failed to link to project"
        return 1
    fi
}

# Execute based on choice
case $choice in
    1)
        link_global
        echo ""
        echo "Done! Skill '$SKILL_NAME' is now available globally."
        ;;
    2)
        link_project
        echo ""
        echo "Done! Skill '$SKILL_NAME' is now available in this project."
        ;;
    3)
        link_global
        link_project
        echo ""
        echo "Done! Skill '$SKILL_NAME' is now available globally and in this project."
        ;;
    4)
        echo "Installation cancelled."
        exit 0
        ;;
    *)
        echo "Invalid choice. Installation cancelled."
        exit 1
        ;;
esac

echo ""
echo "Record file: $RECORD_FILE"
