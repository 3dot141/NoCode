#!/bin/bash
# Sync skills between central repository and managed project directories.
# Default mode is bidirectional. Use --from-central to force central -> projects.

set -euo pipefail

SKILL_NAME=""
SYNC_MODE="bidirectional"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for arg in "$@"; do
    case "$arg" in
        --from-central)
            SYNC_MODE="from-central"
            ;;
        --bidirectional)
            SYNC_MODE="bidirectional"
            ;;
        *)
            if [ -z "$SKILL_NAME" ]; then
                SKILL_NAME="$arg"
            else
                echo "Usage: sync_projects.sh [skill] [--from-central|--bidirectional]"
                exit 1
            fi
            ;;
    esac
done

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config
init_record_file

if [ "$SYNC_MODE" = "from-central" ] && [ -n "$SKILL_NAME" ] && [ ! -d "$CENTRAL_REPO/$SKILL_NAME" ]; then
    echo "Error: Skill '$SKILL_NAME' not found in central repository: $CENTRAL_REPO"
    exit 1
fi

if ! ensure_global_claude_link; then
    echo "Warning: failed to ensure global mapping ($GLOBAL_CLAUDE_LINK)."
fi

PROJECTS=()
while IFS= read -r line; do
    [ -n "$line" ] && PROJECTS+=("$line")
done < <(python3 - "$RECORD_FILE" <<'PYEOF'
import json
import sys

record_file = sys.argv[1]
try:
    with open(record_file, "r") as f:
        data = json.load(f)
except Exception:
    data = {}

projects = set(data.get("managed_projects", []))
for skill in data.get("skills", {}).values():
    for loc in skill.get("locations", []):
        if loc.get("type") == "project" and loc.get("project_path"):
            projects.add(loc["project_path"])

for p in sorted(projects):
    print(p)
PYEOF
)

VALID_PROJECTS=()
for project_path in "${PROJECTS[@]}"; do
    if [ ! -d "$project_path" ]; then
        echo "Skip missing project path: $project_path"
        continue
    fi
    if ! ensure_project_claude_link "$project_path"; then
        echo "Skip project due to invalid mapping: $project_path"
        continue
    fi
    VALID_PROJECTS+=("$project_path")
done

if [ ${#VALID_PROJECTS[@]} -eq 0 ]; then
    echo "No managed projects found in $RECORD_FILE"
    exit 0
fi

echo "=== Sync Projects ==="
echo "Mode: $SYNC_MODE"
echo "Central repository: $CENTRAL_REPO"
echo "Global agents dir: $GLOBAL_AGENTS_DIR"
[ -n "$SKILL_NAME" ] && echo "Skill filter: $SKILL_NAME"
echo ""

python3 - "$CENTRAL_REPO" "$GLOBAL_AGENTS_DIR" "$PROJECT_AGENTS_REL" "$RECORD_FILE" "$SYNC_MODE" "$SKILL_NAME" "${VALID_PROJECTS[@]}" <<'PYEOF'
import json
import os
import shutil
import sys
import tempfile
from pathlib import Path

central_repo = Path(sys.argv[1])
global_agents_dir = Path(sys.argv[2])
project_agents_rel = sys.argv[3]
record_file = Path(sys.argv[4])
sync_mode = sys.argv[5]
skill_filter = sys.argv[6]
projects = [Path(p) for p in sys.argv[7:]]

def dir_latest_mtime(path: Path) -> float:
    latest = path.stat().st_mtime
    for root, dirs, files in os.walk(path):
        for name in dirs + files:
            p = Path(root) / name
            try:
                m = p.stat().st_mtime
            except OSError:
                continue
            if m > latest:
                latest = m
    return latest

def copy_dir_atomic(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=f".{dst.name}.tmp.", dir=str(dst.parent)) as tmp_root:
        tmp = Path(tmp_root) / dst.name
        shutil.copytree(src, tmp, symlinks=True)
        if dst.exists() or dst.is_symlink():
            if dst.is_dir() and not dst.is_symlink():
                shutil.rmtree(dst)
            else:
                dst.unlink()
        tmp.rename(dst)

record = {}
try:
    record = json.loads(record_file.read_text())
except Exception:
    record = {}

skills_from_record = record.get("skills", {})

def list_skill_dirs(base: Path):
    if not base.is_dir():
        return set()
    return {
        p.name for p in base.iterdir()
        if p.is_dir() and not p.name.startswith(".")
    }

if skill_filter:
    skills = {skill_filter}
else:
    skills = set()
    skills.update(list_skill_dirs(central_repo))
    skills.update(list_skill_dirs(global_agents_dir))
    for project in projects:
        skills.update(list_skill_dirs(project / project_agents_rel))

errors = 0
for skill in sorted(skills):
    central_path = central_repo / skill
    global_path = global_agents_dir / skill
    project_paths = {project: project / project_agents_rel / skill for project in projects}

    candidates = []
    if central_path.is_dir():
        candidates.append(("central", central_path))
    if global_path.is_dir():
        candidates.append(("global", global_path))
    for project, path in project_paths.items():
        if path.is_dir():
            candidates.append((f"project:{project}", path))

    if not candidates:
        continue

    if sync_mode == "from-central":
        if not central_path.is_dir():
            print(f"Skip {skill}: central copy missing in from-central mode")
            continue
        source_label, source_path = "central", central_path
    else:
        ranked = []
        for label, path in candidates:
            ranked.append((dir_latest_mtime(path), label, path))
        ranked.sort(key=lambda x: (x[0], 1 if x[1] == "central" else 0, x[1]), reverse=True)
        source_mtime, source_label, source_path = ranked[0]
        _ = source_mtime

    destinations = set()
    destinations.add(central_path)
    destinations.add(global_path)

    record_projects = set()
    skill_detail = skills_from_record.get(skill, {})
    for loc in skill_detail.get("locations", []):
        if loc.get("type") == "project" and loc.get("project_path"):
            record_projects.add(Path(loc["project_path"]))

    for project in projects:
        if project in record_projects or project_paths[project].is_dir():
            destinations.add(project_paths[project])

    # Keep source itself in destination set for completeness but skip copy to itself.
    print(f"[{skill}] source={source_label} path={source_path}")
    for dst in sorted(destinations):
        if os.path.realpath(dst) == os.path.realpath(source_path):
            continue
        try:
            copy_dir_atomic(source_path, dst)
            print(f"  -> synced {dst}")
        except Exception as exc:
            errors += 1
            print(f"  !! failed {dst}: {exc}")

if errors:
    raise SystemExit(1)
PYEOF
