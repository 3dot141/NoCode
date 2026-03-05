#!/bin/bash
# Install a skill using npx skills and sync it via central repository.

SKILL_NAME=$1
INSTALL_TARGET=$2
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config
init_record_file

if ! command -v npx >/dev/null 2>&1; then
    echo "Error: npx is not installed. Please install Node.js first."
    exit 1
fi

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: install_skill.sh <skill-name> [target]"
    echo ""
    echo "Targets:"
    echo "  global   - Sync to configured global agents skills directory"
    echo "  project  - Sync to current project (.agents/skills + .claude/skills mapping)"
    echo "  both     - Sync to both locations"
    echo ""
    exit 1
fi

echo ""
echo "=== Install Skill: $SKILL_NAME ==="
echo ""

echo "Running: npx skills add $SKILL_NAME"
if npx skills add "$SKILL_NAME" 2>&1; then
    SKILL_SOURCE="npx"
else
    echo "Warning: npx skills add failed or skill already exists; continuing."
    SKILL_SOURCE="npx"
fi

SKILL_VERSION=$(npx skills info "$SKILL_NAME" --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('version','unknown'))" 2>/dev/null || echo "unknown")
NPX_SKILL_PATH=$(resolve_npx_skill_path "$SKILL_NAME")

if ! copy_skill_to_central "$SKILL_NAME" "$NPX_SKILL_PATH"; then
    exit 1
fi

echo "Central repository ready: $CENTRAL_REPO/$SKILL_NAME"
echo ""

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
    echo "Where would you like to sync this skill?"
    echo ""
    echo "  1) Global ($GLOBAL_AGENTS_DIR)"
    echo "  2) Project (./.agents/skills + ./.claude/skills -> ./.agents/skills)"
    echo "  3) Both"
    echo "  4) Cancel"
    echo ""
    read -r -p "Enter choice (1-4): " choice
fi

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

update_record() {
    local target=$1
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    python3 - "$RECORD_FILE" "$SKILL_NAME" "$timestamp" "$target" "$PROJECT_ID" "$PROJECT_PATH" "$SKILL_SOURCE" "$SKILL_VERSION" "$GLOBAL_AGENTS_DIR" "$PROJECT_AGENTS_REL" <<'PYEOF'
import json
import os
import sys

(record_file, skill_name, timestamp, target, project_id, project_path,
 source, version, global_agents_dir, project_agents_rel) = sys.argv[1:11]

try:
    with open(record_file, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}

data.setdefault('skills', {})
data.setdefault('managed_projects', [])

if skill_name not in data['skills']:
    data['skills'][skill_name] = {
        'installed_at': timestamp,
        'source': source,
        'version': version,
        'locations': []
    }

location = {
    'type': target,
    'linked_at': timestamp,
}

if target == 'global':
    location['path'] = os.path.join(global_agents_dir, skill_name)
elif target == 'project':
    location['project_id'] = project_id
    location['project_path'] = project_path
    location['path'] = os.path.join(project_path, project_agents_rel, skill_name)
    if project_path not in data['managed_projects']:
        data['managed_projects'].append(project_path)

exists = False
for loc in data['skills'][skill_name]['locations']:
    if loc.get('type') != target:
        continue
    if target == 'project' and loc.get('project_id') != project_id:
        continue
    exists = True
    break

if not exists:
    data['skills'][skill_name]['locations'].append(location)

with open(record_file, 'w') as f:
    json.dump(data, f, indent=2)
PYEOF
}

link_global() {
    echo "  Syncing globally..."
    mkdir -p "$GLOBAL_AGENTS_DIR"
    if ! ensure_global_claude_link; then
        return 1
    fi

    if sync_skill_to_dir "$SKILL_NAME" "$GLOBAL_AGENTS_DIR"; then
        echo "  ✓ Synced: $GLOBAL_AGENTS_DIR/$SKILL_NAME"
        echo "  ✓ Mapping: $GLOBAL_CLAUDE_LINK -> $GLOBAL_AGENTS_DIR"
        update_record "global"
    else
        echo "  ✗ Failed global sync"
        return 1
    fi
}

link_project() {
    echo "  Syncing to current project..."

    if ! ensure_project_claude_link "$PROJECT_PATH"; then
        return 1
    fi

    if sync_skill_to_dir "$SKILL_NAME" "$PROJECT_PATH/$PROJECT_AGENTS_REL"; then
        echo "  ✓ Synced: $PROJECT_PATH/$PROJECT_AGENTS_REL/$SKILL_NAME"
        echo "  ✓ Mapping: $PROJECT_PATH/$PROJECT_CLAUDE_REL -> $PROJECT_PATH/$PROJECT_AGENTS_REL"
        record_managed_project "$PROJECT_PATH"
        update_record "project"
    else
        echo "  ✗ Failed project sync"
        return 1
    fi
}

case "$choice" in
    1)
        link_global || exit 1
        echo ""
        echo "Done! Skill '$SKILL_NAME' is now available globally."
        ;;
    2)
        link_project || exit 1
        echo ""
        echo "Done! Skill '$SKILL_NAME' is now available in this project."
        ;;
    3)
        link_global || exit 1
        link_project || exit 1
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
