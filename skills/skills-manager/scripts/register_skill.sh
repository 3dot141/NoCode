#!/bin/bash
# Register an existing skill in central repository to skills-manager-installed.json
# Useful for skills installed manually or via git clone

SKILL_NAME=$1
SOURCE_TYPE=${2:-local}  # npx, git, local
VERSION=${3:-unknown}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config
init_record_file

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: register_skill.sh <skill-name> [source-type] [version]"
    echo ""
    echo "Register an existing skill in central repository to the record file."
    echo ""
    echo "Arguments:"
    echo "  skill-name   - Name of the skill (directory name in central repo)"
    echo "  source-type  - Source type: npx, git, local (default: local)"
    echo "  version      - Version string (default: unknown)"
    echo ""
    echo "Examples:"
    echo "  register_skill.sh file-search git"
    echo "  register_skill.sh my-skill local 1.0.0"
    exit 1
fi

# Check if skill exists in central repository
if [ ! -d "$CENTRAL_REPO/$SKILL_NAME" ]; then
    echo "Error: Skill '$SKILL_NAME' not found in central repository: $CENTRAL_REPO"
    exit 1
fi

echo "=== Register Skill: $SKILL_NAME ==="
echo ""
echo "Source type: $SOURCE_TYPE"
echo "Version: $VERSION"
echo ""

# Check if already registered
REGISTER_STATUS=$(python3 - "$RECORD_FILE" "$SKILL_NAME" 2>/dev/null <<'PYEOF'
import json
import sys
record_file, skill_name = sys.argv[1:3]
with open(record_file, 'r') as f:
    data = json.load(f)
skills = data.get('skills', {})
if skill_name in skills:
    print("registered")
else:
    print("not_registered")
PYEOF
)

if [ "$REGISTER_STATUS" == "registered" ]; then
    echo "Skill '$SKILL_NAME' is already registered. Updating..."
fi

# Generate project ID if in a project
get_project_id() {
    local hash_cmd="sha256sum"
    if ! command -v sha256sum >/dev/null 2>&1; then
        hash_cmd="shasum -a 256"
    fi

    if [ -d ".git" ]; then
        git remote get-url origin 2>/dev/null | $hash_cmd | cut -c1-12 || pwd | $hash_cmd | cut -c1-12
    else
        pwd | $hash_cmd | cut -c1-12
    fi
}

PROJECT_ID=$(get_project_id)
PROJECT_PATH=$(pwd)

# Register global location
echo "Registering global location..."
record_skill "$SKILL_NAME" "global" "$SOURCE_TYPE" "$VERSION" "" "" "$GLOBAL_AGENTS_DIR" "$PROJECT_AGENTS_REL"

# Check if skill exists in current project
if [ -d "$PROJECT_PATH/$PROJECT_AGENTS_REL/$SKILL_NAME" ]; then
    echo "Found in current project, registering project location..."
    record_skill "$SKILL_NAME" "project" "$SOURCE_TYPE" "$VERSION" "$PROJECT_ID" "$PROJECT_PATH" "$GLOBAL_AGENTS_DIR" "$PROJECT_AGENTS_REL"
fi

echo ""
echo "Done! Skill '$SKILL_NAME' has been registered."
echo "Record file: $RECORD_FILE"
