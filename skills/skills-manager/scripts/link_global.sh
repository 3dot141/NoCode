#!/bin/bash
# Sync a skill to configured global skills directory.

SKILL_NAME=$1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: link_global.sh <skill-name>"
    exit 1
fi

if ! ensure_global_claude_link; then
    exit 1
fi

if sync_skill_to_dir "$SKILL_NAME" "$GLOBAL_AGENTS_DIR"; then
    echo "Synced '$SKILL_NAME' to $GLOBAL_AGENTS_DIR/"
    echo "Mapped claude path: $GLOBAL_CLAUDE_LINK -> $GLOBAL_AGENTS_DIR"
else
    exit 1
fi
