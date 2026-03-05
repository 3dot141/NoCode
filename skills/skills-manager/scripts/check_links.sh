#!/bin/bash
# Check and repair skills directory mapping and local synced skill copies.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config

check_skill_entries() {
    local dir=$1
    local name=$2

    if [ ! -d "$dir" ]; then
        return
    fi

    echo "=== Checking $name ($dir) ==="

    local entry
    shopt -s nullglob dotglob
    for entry in "$dir"/*; do
        local skill_name
        skill_name=$(basename "$entry")
        [ "$skill_name" = ".DS_Store" ] && continue

        if [ -L "$entry" ]; then
            local target
            target=$(readlink "$entry")
            echo "Warning: $skill_name is a symlink ($target), expected local directory."
            if [ -d "$CENTRAL_REPO/$skill_name" ]; then
                if sync_skill_to_dir "$skill_name" "$dir"; then
                    echo "  Fixed: replaced symlink with synced local copy."
                fi
            else
                echo "  Warning: skill not found in central repository; not auto-fixed."
            fi
            continue
        fi

        if [ -d "$entry" ]; then
            echo "OK: $skill_name (local directory)"
            continue
        fi

        echo "Warning: $skill_name is neither directory nor symlink."
    done
    shopt -u nullglob dotglob
}

check_global_mapping() {
    echo "=== Checking Global Mapping ==="
    if ensure_global_claude_link; then
        echo "OK: $GLOBAL_CLAUDE_LINK -> $(readlink "$GLOBAL_CLAUDE_LINK")"
    fi
}

check_project_mapping() {
    local project_path
    project_path=$(pwd)

    echo "=== Checking Project Mapping ==="
    if ensure_project_claude_link "$project_path"; then
        echo "OK: $project_path/$PROJECT_CLAUDE_REL -> $(readlink "$project_path/$PROJECT_CLAUDE_REL")"
    fi
}

check_global_mapping
check_project_mapping
check_skill_entries "$GLOBAL_AGENTS_DIR" "Global skills"
check_skill_entries "$(pwd)/$PROJECT_AGENTS_REL" "Project skills"
