#!/bin/bash
# Sync a skill to configured global skills directory.

SKILL_NAME=$1
SOURCE_TYPE=${2:-local}  # npx, git, local
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config
init_record_file

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: link_global.sh <skill-name> [source-type]"
    echo ""
    echo "Source types: npx, git, local (default: local)"
    exit 1
fi

if ! ensure_global_claude_link; then
    exit 1
fi

if sync_skill_to_dir "$SKILL_NAME" "$GLOBAL_AGENTS_DIR"; then
    echo "Synced '$SKILL_NAME' to $GLOBAL_AGENTS_DIR/"
    echo "Mapped claude path: $GLOBAL_CLAUDE_LINK -> $GLOBAL_AGENTS_DIR"

    # Record in skills-manager-installed.json
    record_skill "$SKILL_NAME" "global" "$SOURCE_TYPE" "unknown" "" "" "$GLOBAL_AGENTS_DIR" "$PROJECT_AGENTS_REL"
    echo "Recorded in $RECORD_FILE"
else
    exit 1
fi
