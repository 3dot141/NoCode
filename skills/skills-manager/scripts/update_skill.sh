#!/bin/bash
# Update a skill from internet via npx skills, refresh central copy, then sync projects.

SKILL_NAME=$1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: update_skill.sh <skill-name>"
    exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
    echo "Error: npx is not installed. Please install Node.js first."
    exit 1
fi

echo "=== Update Skill: $SKILL_NAME ==="
echo ""

echo "Running: npx skills update $SKILL_NAME"
if ! npx skills update "$SKILL_NAME" 2>&1; then
    echo "Warning: npx skills update failed. Falling back to npx skills add."
    npx skills add "$SKILL_NAME" 2>&1 || true
fi

NPX_SKILL_PATH=$(resolve_npx_skill_path "$SKILL_NAME")
if ! copy_skill_to_central "$SKILL_NAME" "$NPX_SKILL_PATH"; then
    exit 1
fi

echo "Central repository refreshed: $CENTRAL_REPO/$SKILL_NAME"
echo ""

"$SCRIPT_DIR/sync_projects.sh" "$SKILL_NAME" --from-central

echo ""
echo "Done. '$SKILL_NAME' has been updated from npx and synced to managed projects."
