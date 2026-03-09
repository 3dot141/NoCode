---
name: skills-manager
description: Manage centralized skills repository with .agents/.claude mapping, install/update via npx skills or git, and sync to managed projects. Use when users need to install, update, sync, or manage Claude skills across projects.
---

# Skills Manager

Manage skills across centralized repository and projects.

## Quick Start

**Install a skill:**
```bash
bash ~/AI/NoCode/skills/skills-manager/scripts/install_skill.sh <skill> [global|project|both]
```

**Update a skill:**
```bash
bash ~/AI/NoCode/skills/skills-manager/scripts/update_skill.sh <skill>
```

**Sync to projects:**
```bash
bash ~/AI/NoCode/skills/skills-manager/scripts/sync_projects.sh [skill]
```

## Architecture

### Directory Structure

```
Central Repository (source of truth)
~/AI/NoCode/skills/<skill>/

Global Installation
~/.agents/skills/<skill>/       # Entity directory
~/.claude/skills -> ~/.agents/skills  # Symlink

Project Installation
./.agents/skills/<skill>/       # Entity directory (synced from central)
./.claude/skills -> .agents/skills    # Symlink
```

### Key Principles

- **Central repository** (`~/AI/NoCode/skills/`) is the single source of truth
- **`.agents/skills`** contains actual files; **`.claude/skills`** is only a directory symlink
- **Copy-based sync**: Skills are copied (not symlinked) from central to projects
- **Manual sync**: Run scripts explicitly; no automatic file watching

## Commands Reference

### Install Skills

| Command | Purpose |
|---------|---------|
| `install_skill.sh <skill> [target] [source]` | Install from npx, git, or local |
| `install_skill.sh owner/repo both git` | Install from GitHub repository |
| `install_skill.sh owner/repo both git path/to/skill my-skill` | Install subdirectory as named skill |

**Source types:**
- `npx` (default): Install via `npx skills add`
- `git`: Clone from git repository
- `local`: Use existing central repository copy

### Update Skills

| Command | Purpose |
|---------|---------|
| `update_skill.sh <skill>` | Auto-detect source and update |
| `update_skill.sh <skill> local` | Skip update, just sync existing |
| `update_skill.sh <skill> git` | Force update from git |
| `update_skill.sh <skill> npx` | Force update from npx |

**Auto-detection order:**
1. Check installation record (`~/.nocode/skills-manager.json`)
2. Detect from central repo: `.git/` → git, npx available → npx, else → local

### Sync Skills

| Command | Purpose |
|---------|---------|
| `sync_projects.sh [skill]` | Bidirectional sync (latest wins) |
| `sync_projects.sh [skill] --from-central` | Force central → projects |
| `promote_skill.sh <skill> [project_path]` | Project → central → all projects |

**Sync behavior:**
- Default: Compare directory mtime, copy from newest to all other locations
- `--from-central`: Always use central repository as source
- `promote_skill.sh`: Useful when editing skill in a project, want to propagate changes

### Maintenance

| Command | Purpose |
|---------|---------|
| `list_skills.sh` | List all skills in central repository |
| `check_links.sh` | Verify and fix `.claude -> .agents` mappings |
| `rebuild_config.sh` | Scan projects and rebuild configuration |
| `remove_skill.sh <skill> [--global\|--project]` | Remove skill from locations |

## Configuration

**Config file:** `~/.nocode/skills-manager-config.json`

```json
{
  "central_repo": "~/AI/NoCode/skills",
  "global_agents_dir": "~/.agents/skills",
  "global_claude_link": "~/.claude/skills",
  "project_agents_dir": ".agents/skills",
  "project_claude_link": ".claude/skills",
  "sync_mode": "copy"
}
```

**Installation record:** `~/.nocode/skills-manager-installed.json`

## Workflows

### Installing from Git

```bash
# Install from GitHub shorthand
bash scripts/install_skill.sh 3dot141/my-skills both git

# Install specific subdirectory as named skill
bash scripts/install_skill.sh 3dot141/my-skills both git skills/pdf-skill pdf-skill

# Install from full URL
bash scripts/install_skill.sh https://github.com/3dot141/my-skills.git both git
```

### Developing a Skill Locally

```bash
# 1. Edit skill in central repository
cd ~/AI/NoCode/skills/my-skill/
# ... make changes ...

# 2. Sync to all managed projects (no internet)
bash scripts/sync_projects.sh my-skill

# 3. Or use --from-central to force overwrite projects
bash scripts/sync_projects.sh my-skill --from-central
```

### Promoting Project Changes

```bash
# Skill edited in project, propagate to central and other projects
bash scripts/promote_skill.sh my-skill /path/to/project
```

## Git-Installed Skills

When installing from git, metadata is saved:
- `.skill-git-info` in central repo tracks URL and subdirectory
- `update_skill.sh` automatically re-clones from source
- Supports monorepo setups with subdirectory paths
