#!/bin/bash
# Check and fix broken symlinks

CENTRAL_REPO="/Users/yes365/Run/NoCode/skills"

check_directory() {
    local dir=$1
    local name=$2

    if [ ! -d "$dir" ]; then
        return
    fi

    echo "=== Checking $name ==="

    for link in "$dir"/*; do
        if [ -L "$link" ]; then
            skill_name=$(basename "$link")
            if [ ! -e "$link" ]; then
                echo "Broken link: $skill_name"
                if [ -d "$CENTRAL_REPO/$skill_name" ]; then
                    rm "$link"
                    ln -s "$CENTRAL_REPO/$skill_name" "$link"
                    echo "  Fixed: relinked to central repository"
                else
                    echo "  Warning: skill not found in central repository"
                fi
            else
                target=$(readlink "$link")
                if [[ "$target" == "$CENTRAL_REPO"* ]]; then
                    echo "OK: $skill_name -> $target"
                else
                    echo "Warning: $skill_name points to non-standard location: $target"
                fi
            fi
        fi
    done
}

check_directory "$HOME/.claude/skills" "Global"
check_directory "./.claude/skills" "Project"
