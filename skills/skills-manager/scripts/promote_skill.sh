#!/bin/bash
# Promote a project-local skill copy into the central repository, then sync out.

set -euo pipefail

SKILL_NAME=${1:-}
PROJECT_PATH=${2:-$(pwd)}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config
init_record_file

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: promote_skill.sh <skill-name> [project-path]"
    exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Project path not found: $PROJECT_PATH"
    exit 1
fi

if ! ensure_project_claude_link "$PROJECT_PATH"; then
    echo "Error: Invalid mapping in project: $PROJECT_PATH"
    exit 1
fi

PROJECT_SKILLS_DIR="$PROJECT_PATH/$PROJECT_AGENTS_REL"

echo "=== Promote Skill ==="
echo "Skill: $SKILL_NAME"
echo "From:  $PROJECT_SKILLS_DIR/$SKILL_NAME"
echo "To:    $CENTRAL_REPO/$SKILL_NAME"
echo ""

if ! sync_skill_to_central_from_dir "$SKILL_NAME" "$PROJECT_SKILLS_DIR"; then
    exit 1
fi

record_managed_project "$PROJECT_PATH"
echo "✓ Central repository updated."

echo ""
echo "Syncing promoted skill to managed projects..."
"$SCRIPT_DIR/sync_projects.sh" "$SKILL_NAME" --from-central

echo ""
echo "Done. '$SKILL_NAME' promoted to central and synced to managed projects."
