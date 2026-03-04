#!/bin/bash
# Remove a skill from central repository and all symlinks
# 功能：选择删除范围（当前项目/全局），全局删除时通过 JSON 删除所有

SKILL_NAME=$1
REMOVE_SCOPE=$2
NOCODE_DIR="$HOME/.nocode"
RECORD_FILE="$NOCODE_DIR/skills-manager.json"
DRY_RUN=false

# Ensure npx is available
if ! command -v npx &> /dev/null; then
    echo "Warning: npx is not installed."
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --project|-p)
            REMOVE_SCOPE="project"
            shift
            ;;
        --global|-g)
            REMOVE_SCOPE="global"
            shift
            ;;
        *)
            if [ -z "$SKILL_NAME" ]; then
                SKILL_NAME=$1
            fi
            shift
            ;;
    esac
done

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: remove_skill.sh <skill-name> [scope] [--dry-run]"
    echo ""
    echo "Scopes:"
    echo "  --global, -g   Remove from all locations (using JSON record)"
    echo "  --project, -p  Remove only from current project"
    echo ""
    echo "Options:"
    echo "  --dry-run      Preview what will be removed without deleting"
    echo ""
    echo "If scope is not provided, interactive mode will be used."
    exit 1
fi

echo ""
echo "=== Remove Skill: $SKILL_NAME ==="
echo ""

# Check if skill exists in JSON record
check_skill_exists() {
    if [ -f "$RECORD_FILE" ]; then
        python3 << EOF 2>/dev/null
import json
import sys
try:
    with open('$RECORD_FILE', 'r') as f:
        data = json.load(f)
    if '$SKILL_NAME' in data.get('skills', {}):
        sys.exit(0)
    else:
        sys.exit(1)
except:
    sys.exit(1)
EOF
        return $?
    fi
    return 1
}

# Get all locations from JSON
get_all_locations() {
    if [ -f "$RECORD_FILE" ]; then
        python3 - "$SKILL_NAME" "$RECORD_FILE" << 'PYEOF' 2>/dev/null
import json
import os
import sys

skill_name = sys.argv[1]
record_file = sys.argv[2]

try:
    with open(record_file, 'r') as f:
        data = json.load(f)

    skill = data.get('skills', {}).get(skill_name, {})
    locations = skill.get('locations', [])

    for loc in locations:
        loc_type = loc.get('type', '')
        if loc_type == 'global':
            print(f"GLOBAL|{os.path.expanduser(f'~/.claude/skills/{skill_name}')}")
        elif loc_type == 'project':
            project_path = loc.get('project_path', '')
            if project_path:
                print(f"PROJECT|{project_path}/.claude/skills/{skill_name}")
except Exception as e:
    pass
PYEOF
    fi
}

# Get project ID for current directory (cross-platform)
get_project_id() {
    local hash_cmd="sha256sum"
    if ! command -v sha256sum &>/dev/null; then
        hash_cmd="shasum -a 256"
    fi

    if [ -d ".git" ]; then
        git remote get-url origin 2>/dev/null | $hash_cmd | cut -c1-12 || pwd | $hash_cmd | cut -c1-12
    else
        pwd | $hash_cmd | cut -c1-12
    fi
}

# Determine removal scope
if [ -z "$REMOVE_SCOPE" ]; then
    # Interactive mode
    echo "Where would you like to remove this skill from?"
    echo ""
    echo "  1) Current project only - Remove from ./.claude/skills/"
    echo "  2) Global - Remove from all locations (global + all projects)"
    echo "  3) Cancel"
    echo ""
    read -p "Enter choice (1-3): " scope_choice

    case $scope_choice in
        1) REMOVE_SCOPE="project" ;;
        2) REMOVE_SCOPE="global" ;;
        3) echo "Cancelled"; exit 0 ;;
        *) echo "Invalid choice. Cancelled."; exit 1 ;;
    esac
fi

# Collect targets to remove
TARGETS=()

if [ "$REMOVE_SCOPE" = "project" ]; then
    # Remove from current project only
    CURRENT_PROJECT_LINK="./.claude/skills/$SKILL_NAME"
    if [ -L "$CURRENT_PROJECT_LINK" ]; then
        TARGETS+=("$CURRENT_PROJECT_LINK")
    fi

    if [ ${#TARGETS[@]} -eq 0 ]; then
        echo "Skill '$SKILL_NAME' is not linked in current project."
        exit 0
    fi

    echo "Will remove from current project:"
    for target in "${TARGETS[@]}"; do
        echo "  - $target"
    done

elif [ "$REMOVE_SCOPE" = "global" ]; then
    # Remove from all locations using JSON record
    echo "Scanning JSON record for all locations..."

    if [ ! -f "$RECORD_FILE" ]; then
        echo "Warning: Record file not found: $RECORD_FILE"
        echo "Searching in standard locations only..."

        # Fast fallback: only check standard locations
        # 1. Global location
        if [ -L "$HOME/.claude/skills/$SKILL_NAME" ]; then
            TARGETS+=("$HOME/.claude/skills/$SKILL_NAME")
        fi

        # 2. Current project
        if [ -L "./.claude/skills/$SKILL_NAME" ]; then
            TARGETS+=("./.claude/skills/$SKILL_NAME")
        fi

        # 3. Common project directories (fast scan, not recursive)
        for dir in "$HOME/AI" "$HOME/Projects" "$HOME/workspace" "$HOME/code"; do
            if [ -d "$dir" ]; then
                # Only check immediate subdirectories for .claude/skills/
                for project in "$dir"/*; do
                    if [ -d "$project/.claude/skills" ]; then
                        link_path="$project/.claude/skills/$SKILL_NAME"
                        if [ -L "$link_path" ]; then
                            TARGETS+=("$link_path")
                        fi
                    fi
                done
            fi
        done
    else
        # Use JSON record
        while IFS='|' read -r type path; do
            if [ -n "$path" ] && [ -L "$path" ]; then
                TARGETS+=("$path")
            fi
        done < <(get_all_locations)

        # Also check global location
        GLOBAL_LINK="$HOME/.claude/skills/$SKILL_NAME"
        if [ -L "$GLOBAL_LINK" ]; then
            local_found=false
            for t in "${TARGETS[@]}"; do
                if [ "$t" = "$GLOBAL_LINK" ]; then
                    local_found=true
                    break
                fi
            done
            if [ "$local_found" = false ]; then
                TARGETS+=("$GLOBAL_LINK")
            fi
        fi
    fi

    if [ ${#TARGETS[@]} -eq 0 ]; then
        echo "No links found for skill '$SKILL_NAME'."
    else
        echo "Found ${#TARGETS[@]} location(s):"
        for target in "${TARGETS[@]}"; do
            echo "  - $target"
        done
    fi

    # Also remove from npx if available
    echo ""
    echo "Will also run: npx skills remove $SKILL_NAME"
else
    echo "Invalid scope: $REMOVE_SCOPE"
    exit 1
fi

# Dry run mode
if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "[DRY RUN] The following would be removed:"
    for target in "${TARGETS[@]}"; do
        echo "  - $target"
    done
    if [ "$REMOVE_SCOPE" = "global" ]; then
        echo "  - npx skills remove $SKILL_NAME"
        echo "  - JSON record from $RECORD_FILE"
    fi
    exit 0
fi

# Confirm removal
echo ""
read -p "Are you sure you want to remove '$SKILL_NAME'? This cannot be undone. [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Execute removal
echo ""
echo "=== Removing ==="

for target in "${TARGETS[@]}"; do
    if rm "$target" 2>/dev/null; then
        echo "✓ Removed: $target"
    else
        echo "✗ Failed to remove: $target"
    fi
done

# Run npx skills remove for global removal
if [ "$REMOVE_SCOPE" = "global" ]; then
    echo ""
    echo "Running: npx skills remove $SKILL_NAME"
    if npx skills remove "$SKILL_NAME" 2>/dev/null; then
        echo "✓ Removed via npx"
    else
        echo "⚠ npx remove failed or skill not found in npx"
    fi

    # Update JSON record - remove skill entry
    if [ -f "$RECORD_FILE" ]; then
        python3 << EOF 2>/dev/null
import json
try:
    with open('$RECORD_FILE', 'r') as f:
        data = json.load(f)

    if '$SKILL_NAME' in data.get('skills', {}):
        del data['skills']['$SKILL_NAME']
        with open('$RECORD_FILE', 'w') as f:
            json.dump(data, f, indent=2)
        print("✓ Removed from JSON record")
except Exception as e:
    print(f"⚠ Failed to update JSON record: {e}")
EOF
    fi

    # Try to remove from central repo
    CENTRAL_REPO="/Users/yes365/AI/NoCode/skills"
    if [ -d "$CENTRAL_REPO/$SKILL_NAME" ]; then
        if rm -rf "$CENTRAL_REPO/$SKILL_NAME" 2>/dev/null; then
            echo "✓ Removed from central repository"
        fi
    fi
fi

# Update JSON record for project-only removal
if [ "$REMOVE_SCOPE" = "project" ] && [ -f "$RECORD_FILE" ]; then
    PROJECT_ID=$(get_project_id)
    python3 << EOF 2>/dev/null
import json
try:
    with open('$RECORD_FILE', 'r') as f:
        data = json.load(f)

    skill = data.get('skills', {}).get('$SKILL_NAME', {})
    locations = skill.get('locations', [])

    # Filter out current project
    new_locations = [loc for loc in locations
                     if not (loc.get('type') == 'project' and
                            loc.get('project_id') == '$PROJECT_ID')]

    if len(new_locations) != len(locations):
        data['skills']['$SKILL_NAME']['locations'] = new_locations
        with open('$RECORD_FILE', 'w') as f:
            json.dump(data, f, indent=2)
        print("✓ Updated JSON record")
except Exception as e:
    pass
EOF
fi

echo ""
echo "=== Done ==="
echo "Skill '$SKILL_NAME' has been removed from $REMOVE_SCOPE scope."
