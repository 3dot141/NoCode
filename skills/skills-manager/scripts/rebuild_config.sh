#!/bin/bash
# Scan configured roots, repair .agents/.claude mapping, and rebuild manager config.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
ensure_python

SCAN_HOME="${1:-$HOME}"
SCAN_AI_ROOT="${2:-$HOME/AI}"

mkdir -p "$(dirname "$CONFIG_FILE")"

python3 - "$CONFIG_FILE" "$RECORD_FILE" \
    "$DEFAULT_CENTRAL_REPO" "$DEFAULT_GLOBAL_CLAUDE_DIR" "$DEFAULT_GLOBAL_AGENTS_LINK" \
    "$SCAN_HOME" "$SCAN_AI_ROOT" <<'PYEOF'
import json
import os
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

(
    config_file,
    record_file,
    default_central_repo,
    default_global_claude_dir,
    default_global_agents_link,
    scan_home,
    scan_ai_root,
) = sys.argv[1:8]

scan_home_path = Path(scan_home).expanduser().resolve()
scan_ai_root_path = Path(scan_ai_root).expanduser().resolve()
config_path = Path(config_file).expanduser()
record_path = Path(record_file).expanduser()

existing_cfg = {}
if config_path.exists():
    try:
        existing_cfg = json.loads(config_path.read_text())
    except Exception:
        existing_cfg = {}

def expanded(cfg_key: str, default_value: str) -> str:
    return os.path.expanduser(existing_cfg.get(cfg_key, default_value))

central_repo = expanded("central_repo", default_central_repo)
global_claude_dir = expanded("global_claude_dir", default_global_claude_dir)
global_agents_link = expanded("global_agents_link", default_global_agents_link)
if os.path.abspath(global_agents_link) == os.path.abspath(global_claude_dir):
    global_agents_link = os.path.expanduser(default_global_agents_link)
project_claude_dir = existing_cfg.get("project_claude_dir", ".claude/skills")
project_agents_link = existing_cfg.get("project_agents_link", ".agents/skills")

roots = [scan_home_path]
if scan_ai_root_path.is_dir():
    for child in sorted(scan_ai_root_path.iterdir(), key=lambda p: p.name.lower()):
        if child.is_dir():
            roots.append(child.resolve())

managed_projects = []
report = []
run_ts = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")

def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)

def migrate_and_link_agents(agents_skills: Path, claude_skills: Path, expected_target: str) -> dict:
    result = {"status": "ok", "moved": [], "conflicts": [], "backed_up_conflicts": []}

    if agents_skills.is_symlink():
        current_target = os.readlink(agents_skills)
        expected_abs = str(claude_skills)
        if current_target not in (expected_target, expected_abs):
            agents_skills.unlink()
            agents_skills.symlink_to(expected_target)
            result["status"] = "relinked"
        else:
            result["status"] = "already_linked"
        return result

    if agents_skills.exists():
        if agents_skills.is_dir():
            for entry in sorted(agents_skills.iterdir(), key=lambda p: p.name.lower()):
                if entry.name == ".DS_Store":
                    try:
                        entry.unlink()
                    except Exception:
                        pass
                    continue

                dst = claude_skills / entry.name
                if dst.exists() or dst.is_symlink():
                    same_symlink = (
                        entry.is_symlink()
                        and dst.is_symlink()
                        and os.readlink(entry) == os.readlink(dst)
                    )
                    if same_symlink:
                        entry.unlink()
                    else:
                        result["conflicts"].append(str(entry))
                    continue

                shutil.move(str(entry), str(dst))
                result["moved"].append(entry.name)

            if result["conflicts"]:
                backup_dir = agents_skills.parent / f"{agents_skills.name}.legacy.{run_ts}"
                ensure_dir(backup_dir)
                for src in result["conflicts"]:
                    src_path = Path(src)
                    if not src_path.exists() and not src_path.is_symlink():
                        continue
                    dst = backup_dir / src_path.name
                    idx = 1
                    while dst.exists() or dst.is_symlink():
                        dst = backup_dir / f"{src_path.name}.{idx}"
                        idx += 1
                    shutil.move(str(src_path), str(dst))
                    result["backed_up_conflicts"].append(str(dst))
                result["conflicts"] = []

            if not any(agents_skills.iterdir()):
                agents_skills.rmdir()
                agents_skills.symlink_to(expected_target)
                if result["backed_up_conflicts"]:
                    result["status"] = "migrated_with_backup_and_linked"
                else:
                    result["status"] = "migrated_and_linked"
            else:
                result["status"] = "partial_conflict"
            return result

        backup = agents_skills.with_name(f"{agents_skills.name}.bak")
        agents_skills.rename(backup)
        agents_skills.symlink_to(expected_target)
        result["status"] = "backed_up_file_and_linked"
        result["moved"].append(f"backup:{backup}")
        return result

    ensure_dir(agents_skills.parent)
    agents_skills.symlink_to(expected_target)
    result["status"] = "created_link"
    return result

def repair_claude_entries(claude_skills: Path, central_repo_path: Path) -> list:
    repaired = []
    if not claude_skills.is_dir():
        return repaired

    for skill_link in sorted(claude_skills.iterdir(), key=lambda p: p.name.lower()):
        if not skill_link.is_symlink():
            continue
        target = os.readlink(skill_link)
        if ".agents/skills" not in target:
            continue

        candidate = central_repo_path / skill_link.name
        if candidate.is_dir():
            skill_link.unlink()
            skill_link.symlink_to(str(candidate))
            repaired.append(skill_link.name)
    return repaired

for root in roots:
    agents_dir = root / ".agents"
    claude_dir = root / ".claude"
    cladue_dir = root / ".cladue"

    if not (agents_dir.exists() or claude_dir.exists() or cladue_dir.exists()):
        continue

    item = {
        "root": str(root),
        "renamed_cladue": False,
        "agents_fix": None,
        "repaired_claude_links": [],
    }

    if cladue_dir.exists() and not claude_dir.exists():
        cladue_dir.rename(claude_dir)
        item["renamed_cladue"] = True

    ensure_dir(claude_dir / "skills")
    ensure_dir(agents_dir)

    agents_skills = agents_dir / "skills"
    claude_skills = claude_dir / "skills"

    is_global = root == scan_home_path
    expected_target = str(claude_skills) if is_global else "../.claude/skills"
    item["agents_fix"] = migrate_and_link_agents(agents_skills, claude_skills, expected_target)

    repaired = repair_claude_entries(claude_skills, Path(central_repo))
    if repaired:
        item["repaired_claude_links"] = repaired

    if not is_global:
        managed_projects.append(str(root))

    report.append(item)

managed_projects = sorted(set(managed_projects))

new_config = {
    "central_repo": central_repo,
    "global_claude_dir": global_claude_dir,
    "global_agents_link": global_agents_link,
    "project_claude_dir": project_claude_dir,
    "project_agents_link": project_agents_link,
    "scan_roots": [str(scan_home_path), str(scan_ai_root_path)],
    "managed_projects": managed_projects,
}
config_path.write_text(json.dumps(new_config, indent=2, ensure_ascii=False) + "\n")

record_data = {"skills": {}, "managed_projects": managed_projects}
if record_path.exists():
    try:
        old_record = json.loads(record_path.read_text())
        record_data["skills"] = old_record.get("skills", {})
        merged = set(old_record.get("managed_projects", []))
        merged.update(managed_projects)
        record_data["managed_projects"] = sorted(merged)
    except Exception:
        pass
else:
    record_path.parent.mkdir(parents=True, exist_ok=True)

record_path.write_text(json.dumps(record_data, indent=2, ensure_ascii=False) + "\n")

print("=== Rebuild Complete ===")
print(f"config_file={config_path}")
print(f"record_file={record_path}")
print(f"managed_projects={len(record_data['managed_projects'])}")
print("")
for item in report:
    fix = item["agents_fix"] or {}
    print(f"[{item['root']}] agents={fix.get('status', 'n/a')}")
    if item["renamed_cladue"]:
        print("  - renamed .cladue -> .claude")
    if fix.get("moved"):
        print(f"  - moved_to_claude={','.join(fix['moved'])}")
    if fix.get("backed_up_conflicts"):
        print(f"  - backed_up_conflicts={len(fix['backed_up_conflicts'])}")
    if fix.get("conflicts"):
        print(f"  - conflicts={len(fix['conflicts'])}")
    if item["repaired_claude_links"]:
        print(f"  - repaired_links={','.join(item['repaired_claude_links'])}")
PYEOF
