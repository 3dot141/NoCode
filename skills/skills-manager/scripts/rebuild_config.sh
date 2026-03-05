#!/bin/bash
# Scan roots, repair .agents/.claude mapping, and rebuild manager config.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
ensure_python

SCAN_HOME="${1:-$HOME}"
SCAN_AI_ROOT="${2:-$HOME/AI}"

mkdir -p "$(dirname "$CONFIG_FILE")"

python3 - "$CONFIG_FILE" "$RECORD_FILE" \
    "$DEFAULT_CENTRAL_REPO" "$DEFAULT_GLOBAL_AGENTS_DIR" "$DEFAULT_GLOBAL_CLAUDE_LINK" \
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
    default_global_agents_dir,
    default_global_claude_link,
    scan_home,
    scan_ai_root,
) = sys.argv[1:8]

run_ts = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
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

def e(cfg_key: str, default_value: str) -> str:
    return os.path.expanduser(existing_cfg.get(cfg_key, default_value))

central_repo = e("central_repo", default_central_repo)
global_agents_dir = e("global_agents_dir", existing_cfg.get("global_agents_link", default_global_agents_dir))
global_claude_link = e("global_claude_link", existing_cfg.get("global_claude_dir", default_global_claude_link))
project_agents_dir = existing_cfg.get("project_agents_dir", existing_cfg.get("project_agents_link", ".agents/skills"))
project_claude_link = existing_cfg.get("project_claude_link", existing_cfg.get("project_claude_dir", ".claude/skills"))

roots = [scan_home_path]
if scan_ai_root_path.is_dir():
    for child in sorted(scan_ai_root_path.iterdir(), key=lambda p: p.name.lower()):
        if child.is_dir():
            roots.append(child.resolve())

managed_projects = []
report = []

def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)

def backup_path(path: Path, suffix: str) -> Path:
    candidate = path.parent / f"{path.name}.{suffix}.{run_ts}"
    idx = 1
    while candidate.exists() or candidate.is_symlink():
        candidate = path.parent / f"{path.name}.{suffix}.{run_ts}.{idx}"
        idx += 1
    return candidate

def backup_into_bucket(path: Path, bucket: Path) -> Path:
    ensure_dir(bucket)
    candidate = bucket / path.name
    idx = 1
    while candidate.exists() or candidate.is_symlink():
        candidate = bucket / f"{path.name}.{idx}"
        idx += 1
    return candidate

def move_entries(src: Path, dst: Path) -> tuple[list[str], list[str]]:
    moved = []
    conflicts = []
    ensure_dir(dst)
    if not src.is_dir():
        return moved, conflicts
    backup_bucket = src.parent / f"{src.name}.legacy.{run_ts}"

    for entry in sorted(src.iterdir(), key=lambda p: p.name.lower()):
        if entry.name in (".DS_Store",):
            try:
                entry.unlink()
            except Exception:
                pass
            continue

        target = dst / entry.name
        if target.exists() or target.is_symlink():
            ensure_dir(backup_bucket)
            conflict_backup = backup_bucket / entry.name
            idx = 1
            while conflict_backup.exists() or conflict_backup.is_symlink():
                conflict_backup = backup_bucket / f"{entry.name}.{idx}"
                idx += 1
            shutil.move(str(entry), str(conflict_backup))
            conflicts.append(str(conflict_backup))
            continue

        shutil.move(str(entry), str(target))
        moved.append(entry.name)

    return moved, conflicts

def sync_one_skill_from_central(skill_name: str, dst_path: Path) -> bool:
    src = Path(central_repo) / skill_name
    if not src.is_dir():
        return False

    tmp = dst_path.parent / f".{skill_name}.tmp.{run_ts}"
    if tmp.exists():
        shutil.rmtree(tmp)
    ensure_dir(tmp)
    for child in src.iterdir():
        src_child = child
        dst_child = tmp / child.name
        if src_child.is_dir():
            shutil.copytree(src_child, dst_child, symlinks=True)
        else:
            shutil.copy2(src_child, dst_child, follow_symlinks=False)
    if dst_path.exists() or dst_path.is_symlink():
        if dst_path.is_dir() and not dst_path.is_symlink():
            shutil.rmtree(dst_path)
        else:
            dst_path.unlink()
    tmp.rename(dst_path)
    return True

def ensure_real_agents_dir(agents_skills: Path, item: dict) -> None:
    if agents_skills.is_symlink():
        migrated_dir = backup_path(agents_skills, "symlink")
        ensure_dir(migrated_dir)
        try:
            for child in agents_skills.iterdir():
                if child.name == ".DS_Store":
                    continue
                target = migrated_dir / child.name
                if child.is_dir():
                    shutil.copytree(child, target, symlinks=True)
                else:
                    shutil.copy2(child, target, follow_symlinks=False)
        except Exception:
            pass
        agents_skills.unlink()
        ensure_dir(agents_skills)
        for child in migrated_dir.iterdir():
            target = agents_skills / child.name
            if target.exists() or target.is_symlink():
                continue
            shutil.move(str(child), str(target))
        shutil.rmtree(migrated_dir, ignore_errors=True)
        item["agents_fix"].append("replaced_symlink_with_dir")
        return

    if agents_skills.exists() and not agents_skills.is_dir():
        backup = backup_path(agents_skills, "bak")
        agents_skills.rename(backup)
        item["agents_fix"].append(f"backup_non_dir:{backup}")

    ensure_dir(agents_skills)

def ensure_claude_link(claude_skills: Path, agents_skills: Path, item: dict) -> None:
    if claude_skills.is_symlink():
        if claude_skills.resolve() == agents_skills.resolve():
            return
        claude_skills.unlink()
        rel = os.path.relpath(str(agents_skills), str(claude_skills.parent))
        claude_skills.symlink_to(rel)
        item["claude_fix"].append("relinked")
        return

    if claude_skills.exists():
        if claude_skills.is_dir():
            moved, conflicts = move_entries(claude_skills, agents_skills)
            if moved:
                item["moved_from_claude"].extend(moved)
            if conflicts:
                item["backups"].extend(conflicts)
            try:
                claude_skills.rmdir()
            except OSError:
                residue_backup = claude_skills.parent / f"{claude_skills.name}.legacy.{run_ts}"
                ensure_dir(residue_backup)
                for child in sorted(claude_skills.iterdir(), key=lambda p: p.name.lower()):
                    dst = residue_backup / child.name
                    idx = 1
                    while dst.exists() or dst.is_symlink():
                        dst = residue_backup / f"{child.name}.{idx}"
                        idx += 1
                    shutil.move(str(child), str(dst))
                    item["backups"].append(str(dst))
                claude_skills.rmdir()
                item["claude_fix"].append("moved_residue_and_replaced")
        else:
            backup = backup_path(claude_skills, "bak")
            claude_skills.rename(backup)
            item["backups"].append(str(backup))

    ensure_dir(claude_skills.parent)
    rel = os.path.relpath(str(agents_skills), str(claude_skills.parent))
    claude_skills.symlink_to(rel)
    item["claude_fix"].append("created_link")

def normalize_agent_entries(agents_skills: Path, item: dict) -> None:
    if not agents_skills.is_dir():
        return
    legacy_bucket = agents_skills.parent / f"{agents_skills.name}.legacy.{run_ts}"

    for entry in sorted(agents_skills.iterdir(), key=lambda p: p.name.lower()):
        if entry.name in (".DS_Store",):
            try:
                entry.unlink()
            except Exception:
                pass
            continue

        if entry.is_symlink():
            if sync_one_skill_from_central(entry.name, entry):
                item["resynced_links"].append(entry.name)
                continue
            backup = backup_into_bucket(entry, legacy_bucket)
            entry.rename(backup)
            item["backups"].append(str(backup))
            continue

        if not entry.is_dir():
            backup = backup_into_bucket(entry, legacy_bucket)
            entry.rename(backup)
            item["backups"].append(str(backup))

for root in roots:
    agents_dir = root / ".agents"
    claude_dir = root / ".claude"
    cladue_dir = root / ".cladue"

    has_markers = agents_dir.exists() or claude_dir.exists() or cladue_dir.exists()
    if root != scan_home_path and not has_markers:
        continue

    item = {
        "root": str(root),
        "renamed_cladue": False,
        "agents_fix": [],
        "claude_fix": [],
        "moved_from_claude": [],
        "resynced_links": [],
        "backups": [],
    }

    if cladue_dir.exists() and not claude_dir.exists():
        cladue_dir.rename(claude_dir)
        item["renamed_cladue"] = True

    is_global = root == scan_home_path
    if is_global:
        agents_skills = Path(global_agents_dir).expanduser()
        claude_skills = Path(global_claude_link).expanduser()
    else:
        agents_skills = root / project_agents_dir
        claude_skills = root / project_claude_link

    ensure_dir(agents_skills.parent)
    ensure_dir(claude_skills.parent)

    ensure_real_agents_dir(agents_skills, item)
    ensure_claude_link(claude_skills, agents_skills, item)
    normalize_agent_entries(agents_skills, item)

    if not is_global:
        managed_projects.append(str(root))
    report.append(item)

managed_projects = sorted(set(managed_projects))

new_config = {
    "central_repo": central_repo,
    "global_agents_dir": global_agents_dir,
    "global_claude_link": global_claude_link,
    "project_agents_dir": project_agents_dir,
    "project_claude_link": project_claude_link,
    "sync_mode": "copy",
    # Legacy compatibility keys.
    "global_claude_dir": global_agents_dir,
    "global_agents_link": global_claude_link,
    "project_claude_dir": project_claude_link,
    "project_agents_link": project_agents_dir,
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
    print(f"[{item['root']}]")
    if item["renamed_cladue"]:
        print("  - renamed .cladue -> .claude")
    if item["agents_fix"]:
        print(f"  - agents_fix={','.join(item['agents_fix'])}")
    if item["claude_fix"]:
        print(f"  - claude_fix={','.join(item['claude_fix'])}")
    if item["moved_from_claude"]:
        print(f"  - moved_from_claude={','.join(item['moved_from_claude'])}")
    if item["resynced_links"]:
        print(f"  - resynced_links={','.join(item['resynced_links'])}")
    if item["backups"]:
        print(f"  - backups={len(item['backups'])}")
PYEOF
