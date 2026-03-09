#!/bin/bash
# Update a skill based on its recorded source type, then sync to managed projects.

SKILL_NAME=$1
FORCE_SOURCE=$2  # Optional: force source type (npx, git, local)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config
init_record_file

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: update_skill.sh <skill-name> [force-source]"
    echo ""
    echo "Force source (optional):"
    echo "  npx    - Force update from npx skills"
    echo "  git    - Force update from git repository"
    echo "  local  - Skip update, just sync from central repo"
    echo ""
    exit 1
fi

echo "=== Update Skill: $SKILL_NAME ==="
echo ""

# Check if skill exists in central repo
if [ ! -d "$CENTRAL_REPO/$SKILL_NAME" ]; then
    echo "Error: Skill '$SKILL_NAME' not found in central repository: $CENTRAL_REPO"
    exit 1
fi

# Determine source type
SOURCE_TYPE="$FORCE_SOURCE"
if [ -z "$SOURCE_TYPE" ]; then
    # Try to get source from record file
    SOURCE_TYPE=$(python3 - "$RECORD_FILE" "$SKILL_NAME" 2>/dev/null <<'PYEOF'
import json
import sys
record_file, skill_name = sys.argv[1:3]
try:
    with open(record_file, 'r') as f:
        data = json.load(f)
    skills = data.get('skills', {})
    if skill_name in skills:
        print(skills[skill_name].get('source', 'unknown'))
    else:
        print('unknown')
except:
    print('unknown')
PYEOF
)
fi

# Try to get git URL and subdir if source is git
GIT_URL=""
GIT_SUBDIR=""
if [ "$SOURCE_TYPE" == "git" ]; then
    GIT_URL=$(python3 - "$RECORD_FILE" "$SKILL_NAME" 2>/dev/null <<'PYEOF'
import json
import sys
record_file, skill_name = sys.argv[1:3]
try:
    with open(record_file, 'r') as f:
        data = json.load(f)
    skills = data.get('skills', {})
    if skill_name in skills:
        print(skills[skill_name].get('git_url', ''))
except:
    pass
PYEOF
)
    GIT_SUBDIR=$(python3 - "$RECORD_FILE" "$SKILL_NAME" 2>/dev/null <<'PYEOF'
import json
import sys
record_file, skill_name = sys.argv[1:3]
try:
    with open(record_file, 'r') as f:
        data = json.load(f)
    skills = data.get('skills', {})
    if skill_name in skills:
        print(skills[skill_name].get('git_subdir', ''))
except:
    pass
PYEOF
)
fi

if [ -z "$SOURCE_TYPE" ] || [ "$SOURCE_TYPE" == "unknown" ]; then
    # Try to detect from central repo
    if [ -d "$CENTRAL_REPO/$SKILL_NAME/.git" ]; then
        SOURCE_TYPE="git"
        cd "$CENTRAL_REPO/$SKILL_NAME" && GIT_URL=$(git remote get-url origin 2>/dev/null || echo "")
        cd - > /dev/null
    elif command -v npx >/dev/null 2>&1 && npx skills info "$SKILL_NAME" >/dev/null 2>&1; then
        SOURCE_TYPE="npx"
    else
        SOURCE_TYPE="local"
    fi
    echo "Auto-detected source type: $SOURCE_TYPE"
else
    echo "Source type: $SOURCE_TYPE"
fi

SKILL_VERSION="unknown"
TEMP_DIR=""

# Update based on source type
case "$SOURCE_TYPE" in
    npx)
        if ! command -v npx >/dev/null 2>&1; then
            echo "Error: npx is not installed. Please install Node.js first."
            exit 1
        fi

        echo "Running: npx skills update $SKILL_NAME"
        if ! npx skills update "$SKILL_NAME" 2>&1; then
            echo "Warning: npx skills update failed. Trying npx skills add..."
            npx skills add "$SKILL_NAME" 2>&1 || true
        fi

        SKILL_VERSION=$(npx skills info "$SKILL_NAME" --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('version','unknown'))" 2>/dev/null || echo "unknown")
        NPX_SKILL_PATH=$(resolve_npx_skill_path "$SKILL_NAME")

        if ! copy_skill_to_central "$SKILL_NAME" "$NPX_SKILL_PATH"; then
            exit 1
        fi
        echo "✓ Updated from npx"
        ;;

    git)
        # Try to read saved git info (will override values from record file if exists)
        if [ -f "$CENTRAL_REPO/$SKILL_NAME/.skill-git-info" ]; then
            echo "Found saved git info"
            # shellcheck source=/dev/null
            source "$CENTRAL_REPO/$SKILL_NAME/.skill-git-info"
        fi

        if [ -z "$GIT_URL" ]; then
            # Try to get from record file or existing repo
            if [ -d "$CENTRAL_REPO/$SKILL_NAME/.git" ]; then
                cd "$CENTRAL_REPO/$SKILL_NAME" && GIT_URL=$(git remote get-url origin 2>/dev/null || echo "")
                cd - > /dev/null
            fi
        fi

        if [ -z "$GIT_URL" ]; then
            echo "Error: Cannot determine git URL for '$SKILL_NAME'"
            echo "Please reinstall with: install_skill.sh <git-url> both git [subdir]"
            exit 1
        fi

        echo "Updating from git: $GIT_URL"
        [ -n "$GIT_SUBDIR" ] && echo "Subdirectory: $GIT_SUBDIR"

        TEMP_DIR=$(mktemp -d)
        REPO_NAME=${REPO_NAME:-$(basename "$GIT_URL" .git)}

        if ! git clone --depth 1 "$GIT_URL" "$TEMP_DIR/$REPO_NAME" 2>&1; then
            echo "Error: Failed to clone repository"
            rm -rf "$TEMP_DIR"
            exit 1
        fi

        # Determine source path
        SOURCE_PATH="$TEMP_DIR/$REPO_NAME"
        if [ -n "$GIT_SUBDIR" ]; then
            SOURCE_PATH="$TEMP_DIR/$REPO_NAME/$GIT_SUBDIR"
            if [ ! -d "$SOURCE_PATH" ]; then
                echo "Error: Subdirectory not found: $GIT_SUBDIR"
                rm -rf "$TEMP_DIR"
                exit 1
            fi
        fi

        # Get version from git
        cd "$TEMP_DIR/$REPO_NAME" && SKILL_VERSION=$(git describe --tags --always 2>/dev/null || echo "unknown")
        cd - > /dev/null

        # Copy to central repo
        rm -rf "$CENTRAL_REPO/$SKILL_NAME"
        mkdir -p "$CENTRAL_REPO"
        cp -R "$SOURCE_PATH" "$CENTRAL_REPO/$SKILL_NAME"
        rm -rf "$TEMP_DIR"

        # Save git info
        GIT_INFO_FILE="$CENTRAL_REPO/$SKILL_NAME/.skill-git-info"
        echo "GIT_URL=$GIT_URL" > "$GIT_INFO_FILE"
        echo "GIT_SUBDIR=$GIT_SUBDIR" >> "$GIT_INFO_FILE"
        echo "REPO_NAME=$REPO_NAME" >> "$GIT_INFO_FILE"

        echo "✓ Updated from git"
        ;;

    local)
        echo "Local source - skipping update, syncing existing version"
        if [ -f "$CENTRAL_REPO/$SKILL_NAME/SKILL.md" ]; then
            SKILL_VERSION=$(grep -E "^version:" "$CENTRAL_REPO/$SKILL_NAME/SKILL.md" | cut -d: -f2 | tr -d ' ' || echo "unknown")
        fi
        ;;

    *)
        echo "Warning: Unknown source type '$SOURCE_TYPE'. Treating as local."
        SOURCE_TYPE="local"
        ;;
esac

echo "Central repository refreshed: $CENTRAL_REPO/$SKILL_NAME"
echo "Version: $SKILL_VERSION"
echo ""

# Update version in record
python3 - "$RECORD_FILE" "$SKILL_NAME" "$SKILL_VERSION" "$SOURCE_TYPE" "$GIT_URL" 2>/dev/null <<'PYEOF'
import json
import sys
from datetime import datetime, timezone

record_file, skill_name, version, source, git_url = sys.argv[1:6]

try:
    with open(record_file, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}

data.setdefault('skills', {})

if skill_name in data['skills']:
    data['skills'][skill_name]['version'] = version
    data['skills'][skill_name]['source'] = source
    if git_url:
        data['skills'][skill_name]['git_url'] = git_url
    data['skills'][skill_name]['updated_at'] = datetime.now(timezone.utc).isoformat()

    with open(record_file, 'w') as f:
        json.dump(data, f, indent=2)
PYEOF

# Sync to all managed locations
echo "Syncing to managed projects..."
"$SCRIPT_DIR/sync_projects.sh" "$SKILL_NAME" --from-central

echo ""
echo "Done. '$SKILL_NAME' has been updated and synced."
