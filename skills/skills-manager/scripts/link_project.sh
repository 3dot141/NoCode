#!/bin/bash
# Sync a skill to current project's .agents/skills and map .claude/skills.

SKILL_NAME=$1
PROJECT_PATH=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config
init_record_file

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: link_project.sh <skill-name>"
    exit 1
fi

if ! ensure_project_claude_link "$PROJECT_PATH"; then
    exit 1
fi

if sync_skill_to_dir "$SKILL_NAME" "$PROJECT_PATH/$PROJECT_AGENTS_REL"; then
    record_managed_project "$PROJECT_PATH"
    echo "Synced '$SKILL_NAME' to ./$PROJECT_AGENTS_REL/"
    echo "Mapped project claude path: ./$PROJECT_CLAUDE_REL -> ./$PROJECT_AGENTS_REL"
else
    exit 1
fi
