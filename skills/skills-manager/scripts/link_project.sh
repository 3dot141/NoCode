#!/bin/bash
# Sync a skill to current project's .agents/skills and map .claude/skills.

SKILL_NAME=$1
SOURCE_TYPE=${2:-local}  # npx, git, local
PROJECT_PATH=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config
init_record_file

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: link_project.sh <skill-name> [source-type]"
    echo ""
    echo "Source types: npx, git, local (default: local)"
    exit 1
fi

if ! ensure_project_claude_link "$PROJECT_PATH"; then
    exit 1
fi

# Generate project ID
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

if sync_skill_to_dir "$SKILL_NAME" "$PROJECT_PATH/$PROJECT_AGENTS_REL"; then
    record_managed_project "$PROJECT_PATH"
    echo "Synced '$SKILL_NAME' to ./$PROJECT_AGENTS_REL/"
    echo "Mapped project claude path: ./$PROJECT_CLAUDE_REL -> ./$PROJECT_AGENTS_REL"

    # Record in skills-manager-installed.json
    record_skill "$SKILL_NAME" "project" "$SOURCE_TYPE" "unknown" "$PROJECT_ID" "$PROJECT_PATH" "$GLOBAL_AGENTS_DIR" "$PROJECT_AGENTS_REL"
    echo "Recorded in $RECORD_FILE"
else
    exit 1
fi
