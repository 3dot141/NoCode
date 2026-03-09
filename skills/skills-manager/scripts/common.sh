#!/bin/bash
# Shared helpers for skills-manager scripts.

NOCODE_DIR="${SKILLS_MANAGER_STATE_DIR:-$HOME/.nocode}"
RECORD_FILE="$NOCODE_DIR/skills-manager-installed.json"
CONFIG_FILE="$NOCODE_DIR/skills-manager-config.json"

DEFAULT_CENTRAL_REPO="$HOME/AI/NoCode/skills"
DEFAULT_GLOBAL_AGENTS_DIR="$HOME/.agents/skills"
DEFAULT_GLOBAL_CLAUDE_LINK="$HOME/.claude/skills"
RUN_TS="$(date -u +%Y%m%d%H%M%S)"

ensure_python() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Error: python3 is required."
        exit 1
    fi
}

relative_target() {
    ensure_python
    python3 - "$1" "$2" <<'PYEOF'
import os
import sys

link_path, target_path = sys.argv[1:3]
print(os.path.relpath(os.path.abspath(target_path), os.path.dirname(os.path.abspath(link_path))))
PYEOF
}

link_points_to() {
    ensure_python
    python3 - "$1" "$2" <<'PYEOF'
import os
import sys

link_path, expected_target = sys.argv[1:3]
if not os.path.islink(link_path):
    raise SystemExit(1)

actual = os.path.realpath(link_path)
expected = os.path.realpath(expected_target)
raise SystemExit(0 if actual == expected else 1)
PYEOF
}

move_entries_to_dir() {
    local src_dir=$1
    local dst_dir=$2

    [ -d "$src_dir" ] || return 0
    mkdir -p "$dst_dir"

    local backup_dir="$src_dir.legacy.$RUN_TS"
    local used_backup=false

    shopt -s dotglob nullglob
    local entry
    for entry in "$src_dir"/*; do
        local base
        base=$(basename "$entry")
        [ "$base" = "." ] && continue
        [ "$base" = ".." ] && continue

        if [ "$base" = ".DS_Store" ]; then
            rm -f "$entry"
            continue
        fi

        local dst="$dst_dir/$base"
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            mkdir -p "$backup_dir"
            used_backup=true
            local backup="$backup_dir/$base"
            local idx=1
            while [ -e "$backup" ] || [ -L "$backup" ]; do
                backup="$backup_dir/$base.$idx"
                idx=$((idx + 1))
            done
            mv "$entry" "$backup"
            continue
        fi

        mv "$entry" "$dst"
    done
    shopt -u dotglob nullglob

    if [ "$used_backup" = true ]; then
        echo "Warning: conflicts found while merging '$src_dir'; backups kept in '$backup_dir'."
    fi
}

ensure_real_skill_dir() {
    local skill_dir=$1

    if [ -L "$skill_dir" ]; then
        local migrate_tmp="$skill_dir.migrate.$RUN_TS"
        rm -rf "$migrate_tmp"
        mkdir -p "$migrate_tmp"
        cp -R "$skill_dir"/. "$migrate_tmp"/ 2>/dev/null || true
        rm "$skill_dir"
        mkdir -p "$skill_dir"
        cp -R "$migrate_tmp"/. "$skill_dir"/ 2>/dev/null || true
        rm -rf "$migrate_tmp"
        return 0
    fi

    if [ -e "$skill_dir" ] && [ ! -d "$skill_dir" ]; then
        echo "Error: '$skill_dir' exists and is not a directory"
        return 1
    fi

    mkdir -p "$skill_dir"
}

ensure_symlink_mapping() {
    local link_path=$1
    local target_path=$2

    mkdir -p "$(dirname "$link_path")"

    if [ -L "$link_path" ]; then
        if link_points_to "$link_path" "$target_path"; then
            return 0
        fi
        rm "$link_path"
    elif [ -e "$link_path" ]; then
        if [ -d "$link_path" ]; then
            move_entries_to_dir "$link_path" "$target_path"
            rmdir "$link_path" 2>/dev/null || {
                echo "Error: '$link_path' still contains files; cannot replace with symlink."
                return 1
            }
        else
            echo "Error: '$link_path' exists and is not a symlink/directory"
            return 1
        fi
    fi

    local rel_target
    rel_target=$(relative_target "$link_path" "$target_path")
    ln -s "$rel_target" "$link_path"
}

init_manager_config() {
    ensure_python

    local config_dir
    config_dir=$(dirname "$CONFIG_FILE")
    mkdir -p "$config_dir"

    if [ ! -f "$CONFIG_FILE" ]; then
        python3 - "$CONFIG_FILE" \
            "$DEFAULT_CENTRAL_REPO" "$DEFAULT_GLOBAL_AGENTS_DIR" "$DEFAULT_GLOBAL_CLAUDE_LINK" <<'PYEOF'
import json
import os
import sys

config_file, central_repo, global_agents_dir, global_claude_link = sys.argv[1:5]
config = {
    "central_repo": os.path.expanduser(central_repo),
    "global_agents_dir": os.path.expanduser(global_agents_dir),
    "global_claude_link": os.path.expanduser(global_claude_link),
    "project_agents_dir": ".agents/skills",
    "project_claude_link": ".claude/skills",
    "sync_mode": "copy"
}
with open(config_file, "w") as f:
    json.dump(config, f, indent=2)
PYEOF
    fi
}

load_manager_config() {
    ensure_python
    init_manager_config

    local idx=0
    while IFS= read -r line; do
        case $idx in
            0) CENTRAL_REPO="$line" ;;
            1) GLOBAL_AGENTS_DIR="$line" ;;
            2) GLOBAL_CLAUDE_LINK="$line" ;;
            3) PROJECT_AGENTS_REL="$line" ;;
            4) PROJECT_CLAUDE_REL="$line" ;;
        esac
        idx=$((idx + 1))
    done < <(python3 - "$CONFIG_FILE" <<'PYEOF'
import json
import os
import sys

cfg = {}
with open(sys.argv[1], "r") as f:
    cfg = json.load(f)

def e(value, default):
    return os.path.expanduser(cfg.get(value, default))

central_repo = e("central_repo", "~/AI/NoCode/skills")
global_agents_dir = e("global_agents_dir", cfg.get("global_agents_link", "~/.agents/skills"))
global_claude_link = e("global_claude_link", cfg.get("global_claude_dir", "~/.claude/skills"))
project_agents_dir = cfg.get("project_agents_dir", cfg.get("project_agents_link", ".agents/skills"))
project_claude_link = cfg.get("project_claude_link", cfg.get("project_claude_dir", ".claude/skills"))

print(central_repo)
print(global_agents_dir)
print(global_claude_link)
print(project_agents_dir)
print(project_claude_link)
PYEOF
)

    # Compatibility aliases for legacy scripts.
    GLOBAL_CLAUDE_DIR="$GLOBAL_AGENTS_DIR"
    GLOBAL_AGENTS_LINK="$GLOBAL_CLAUDE_LINK"
    PROJECT_CLAUDE_LEGACY="$PROJECT_CLAUDE_REL"
    PROJECT_AGENTS_LEGACY="$PROJECT_AGENTS_REL"

    export CENTRAL_REPO GLOBAL_AGENTS_DIR GLOBAL_CLAUDE_LINK PROJECT_AGENTS_REL PROJECT_CLAUDE_REL
    export GLOBAL_CLAUDE_DIR GLOBAL_AGENTS_LINK PROJECT_CLAUDE_LEGACY PROJECT_AGENTS_LEGACY
}

init_record_file() {
    mkdir -p "$NOCODE_DIR"

    # Migrate old record file if exists
    local old_record_file="$NOCODE_DIR/skills-manager.json"
    if [ -f "$old_record_file" ] && [ ! -f "$RECORD_FILE" ]; then
        mv "$old_record_file" "$RECORD_FILE"
        echo "Migrated: $old_record_file -> $RECORD_FILE"
    fi

    if [ ! -f "$RECORD_FILE" ]; then
        echo '{"skills": {}, "managed_projects": []}' > "$RECORD_FILE"
    fi
}

ensure_global_claude_link() {
    if ! ensure_real_skill_dir "$GLOBAL_AGENTS_DIR"; then
        return 1
    fi
    ensure_symlink_mapping "$GLOBAL_CLAUDE_LINK" "$GLOBAL_AGENTS_DIR"
}

ensure_project_claude_link() {
    local project_path=$1
    local project_agents_dir="$project_path/$PROJECT_AGENTS_REL"
    local project_claude_link="$project_path/$PROJECT_CLAUDE_REL"

    if ! ensure_real_skill_dir "$project_agents_dir"; then
        return 1
    fi
    ensure_symlink_mapping "$project_claude_link" "$project_agents_dir"
}

# Backward compatible names.
ensure_global_agents_link() {
    ensure_global_claude_link
}

ensure_project_agents_link() {
    ensure_project_claude_link "$1"
}

sync_skill_to_dir() {
    local skill_name=$1
    local target_dir=$2
    local source_path="$CENTRAL_REPO/$skill_name"
    local dest_path="$target_dir/$skill_name"
    if [ ! -d "$source_path" ]; then
        echo "Error: Skill '$skill_name' not found in central repository: $CENTRAL_REPO"
        return 1
    fi
    copy_dir_atomic "$source_path" "$dest_path"
}

# Backward compatible name.
link_skill_to_dir() {
    sync_skill_to_dir "$1" "$2"
}

sync_skill_to_central_from_dir() {
    local skill_name=$1
    local source_parent_dir=$2
    local source_path="$source_parent_dir/$skill_name"
    local dest_path="$CENTRAL_REPO/$skill_name"
    if [ ! -d "$source_path" ]; then
        echo "Error: Source skill directory not found: $source_path"
        return 1
    fi

    mkdir -p "$CENTRAL_REPO"
    copy_dir_atomic "$source_path" "$dest_path"
}

copy_dir_atomic() {
    local source_path=$1
    local dest_path=$2
    local dest_parent
    dest_parent=$(dirname "$dest_path")
    local dest_name
    dest_name=$(basename "$dest_path")
    local tmp_path="$dest_parent/.${dest_name}.tmp.$RUN_TS.$$"

    if [ ! -d "$source_path" ]; then
        echo "Error: Source directory not found: $source_path"
        return 1
    fi

    mkdir -p "$dest_parent"
    rm -rf "$tmp_path"
    mkdir -p "$tmp_path"
    cp -R "$source_path"/. "$tmp_path"/
    rm -rf "$dest_path"
    mv "$tmp_path" "$dest_path"
}

record_managed_project() {
    local project_path=$1
    init_record_file

    python3 - "$RECORD_FILE" "$project_path" <<'PYEOF'
import json
import sys

record_file, project_path = sys.argv[1:3]

try:
    with open(record_file, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}

data.setdefault('skills', {})
data.setdefault('managed_projects', [])
if project_path not in data['managed_projects']:
    data['managed_projects'].append(project_path)

with open(record_file, 'w') as f:
    json.dump(data, f, indent=2)
PYEOF
}

# Record skill installation/update in skills-manager-installed.json
record_skill() {
    local skill_name=$1
    local target=$2
    local source=$3
    local version=$4
    local project_id=$5
    local project_path=$6
    local global_agents_dir=$7
    local project_agents_rel=$8
    local git_url=$9
    local git_subdir=${10}

    init_record_file

    python3 - "$RECORD_FILE" "$skill_name" "$target" "$source" "$version" "$project_id" "$project_path" "$global_agents_dir" "$project_agents_rel" "$git_url" "$git_subdir" <<'PYEOF'
import json
import sys
from datetime import datetime, timezone

(record_file, skill_name, target, source, version,
 project_id, project_path, global_agents_dir, project_agents_rel, git_url, git_subdir) = sys.argv[1:12]

try:
    with open(record_file, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}

data.setdefault('skills', {})
data.setdefault('managed_projects', [])

timestamp = datetime.now(timezone.utc).isoformat()

# Create skill entry if not exists
if skill_name not in data['skills']:
    data['skills'][skill_name] = {
        'installed_at': timestamp,
        'source': source,
        'version': version if version else 'unknown',
        'locations': []
    }
else:
    # Update source and version if provided
    if source and source != 'unknown':
        data['skills'][skill_name]['source'] = source
    if version and version != 'unknown':
        data['skills'][skill_name]['version'] = version

# Save git info if provided
if git_url:
    data['skills'][skill_name]['git_url'] = git_url
if git_subdir:
    data['skills'][skill_name]['git_subdir'] = git_subdir

location = {
    'type': target,
    'linked_at': timestamp,
}

if target == 'global':
    location['path'] = global_agents_dir + '/' + skill_name
elif target == 'project':
    location['project_id'] = project_id
    location['project_path'] = project_path
    location['path'] = project_path + '/' + project_agents_rel + '/' + skill_name
    if project_path and project_path not in data['managed_projects']:
        data['managed_projects'].append(project_path)

# Check if location already exists
exists = False
for loc in data['skills'][skill_name]['locations']:
    if loc.get('type') != target:
        continue
    if target == 'project' and loc.get('project_id') != project_id:
        continue
    exists = True
    # Update existing location timestamp
    loc['linked_at'] = timestamp
    break

if not exists:
    data['skills'][skill_name]['locations'].append(location)

with open(record_file, 'w') as f:
    json.dump(data, f, indent=2)
PYEOF
}

copy_skill_to_central() {
    local skill_name=$1
    local source_path=$2

    mkdir -p "$CENTRAL_REPO"

    if [ -z "$source_path" ] || [ ! -d "$source_path" ]; then
        if [ -d "$CENTRAL_REPO/$skill_name" ]; then
            return 0
        fi
        echo "Error: Unable to locate source files for '$skill_name' from npx skills."
        return 1
    fi

    rm -rf "$CENTRAL_REPO/$skill_name"
    mkdir -p "$CENTRAL_REPO/$skill_name"
    cp -R "$source_path"/. "$CENTRAL_REPO/$skill_name"/
}

resolve_npx_skill_path() {
    local skill_name=$1
    npx skills get-path "$skill_name" 2>/dev/null || true
}
