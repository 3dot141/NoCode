---
name: skills-manager
description: Manage Claude Code skills centralized repository. Use when users need to install, list, link, check, or remove skills. Triggers on "install skill", "添加 skill", "管理 skills", "查看 skills", "链接 skill", "删除 skill".
---

# Skills Manager

Centralized management system for Claude Code skills.

## Principles

- **Single Source of Truth**: All skills must reside in `/Users/yes365/AI/NoCode/skills/`
- **Symlink Only**: Projects and global config must use symlinks, never direct copies
- **No Project-Specific Skills**: All skills go to central repository

## Quick Reference

| Operation | Command |
|-----------|---------|
| List all skills | `list_skills.sh` |
| Install skill | `install_skill.sh <skill> [target]` |
| Link to global | `link_global.sh <skill>` |
| Link to project | `link_project.sh <skill>` |
| Check/fix links | `check_links.sh` |
| Remove skill | `remove_skill.sh <skill>` |

## Operations

### 1. List Skills

View all skills in central repository:

```bash
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/list_skills.sh
```

### 2. Install Skill

Install a skill with optional non-interactive target specification.

**When AI is asked to install a skill:**
1. Ask user: "Where would you like to install this skill? 1) Global, 2) Project, 3) Both"
2. Run `install_skill.sh <skill> <target>` with the chosen target

**Usage:**
```bash
# Non-interactive mode (preferred for AI)
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/install_skill.sh <skill-name> <target>

# Interactive mode (prompts for target)
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/install_skill.sh <skill-name>
```

**Targets:** `global` (or `1`), `project` (or `2`), `both` (or `3`)

**Examples:**
```bash
bash install_skill.sh my-skill both      # Install to global and project
bash install_skill.sh my-skill global    # Install to global only
bash install_skill.sh my-skill 2         # Install to project only (numeric)
```

### 3. Link Skill Globally

Make a skill available globally:

```bash
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/link_global.sh <skill-name>
```

### 4. Link Skill to Project

Make a skill available in current project:

```bash
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/link_project.sh <skill-name>
```

### 5. Check and Fix Links

Verify all symlinks point to correct locations:

```bash
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/check_links.sh
```

### 6. Remove Skill

Delete skill from central repository and all symlinks:

```bash
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/remove_skill.sh <skill-name>
```

## Adding New Skills

1. Copy skill folder to `/Users/yes365/AI/NoCode/skills/<skill-name>/`
2. Create symlinks as needed using scripts above
3. Never add skills directly to project directories

## Modifying Skills

当需要修改 skill 内容时，必须在中央仓库进行操作并提交：

```bash
# 1. 进入中央仓库
cd /Users/yes365/AI/NoCode/skills/<skill-name>/

# 2. 修改 skill 文件（如 SKILL.md）
# ... 编辑文件 ...

# 3. 在中央仓库提交
cd /Users/yes365/AI/NoCode/skills/
git add <skill-name>/
git commit -m "update(<skill-name>): 描述修改内容"
git push

# 4. 返回原项目继续工作
cd /Users/yes365/AI/MyJarvis  # 或其他项目路径
```

### 工作流程示例

**场景：更新 skills-manager 的文档**

```bash
# 步骤 1：进入中央仓库的 skills-manager 目录
cd /Users/yes365/AI/NoCode/skills/skills-manager/

# 步骤 2：编辑 SKILL.md
# ... 进行修改 ...

# 步骤 3：提交到中央仓库
cd /Users/yes365/AI/NoCode/skills/
git add skills-manager/
git commit -m "update(skills-manager): 添加修改 skills 的工作流程"
git push

# 步骤 4：返回 MyJarvis 项目
cd /Users/yes365/AI/MyJarvis
```

**重要提醒**：
- 所有 skills 的修改必须在 `/Users/yes365/AI/NoCode/skills/` 中央仓库进行
- 提交后需要 `git push` 推送到远程
- 完成后再返回到原来的工作项目
- 项目中的 `.claude/skills/` 只是符号链接，不要直接修改

## Directory Structure

```
/Users/yes365/AI/NoCode/skills/     # Central repository (all skills here)
~/.claude/skills/                    # Global symlinks
./.claude/skills/                    # Project symlinks
```
