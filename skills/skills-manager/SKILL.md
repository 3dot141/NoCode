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
| Remove skill | `remove_skill.sh <skill> [scope]` |

## Features

- **npx Integration**: Install uses `npx skills add` for standardized skill management
- **JSON Record**: All installations tracked in `~/.nocode/skills-manager.json`
- **Scoped Removal**: Remove from current project only or globally from all locations

## Operations

### 1. List Skills

View all skills in central repository:

```bash
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/list_skills.sh
```

### 2. Install Skill

Install a skill using `npx skills add` and record relationships in JSON.

**Features:**
- Uses `npx skills add` for standardized installation
- Records all installations in `~/.nocode/skills-manager.json`
- Tracks project IDs and paths for later removal

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

**JSON Record Format:**
```json
{
  "skills": {
    "my-skill": {
      "installed_at": "2024-01-15T10:30:00Z",
      "locations": [
        {"type": "global", "linked_at": "2024-01-15T10:30:00Z"},
        {"type": "project", "linked_at": "2024-01-15T10:30:00Z", "project_id": "abc123", "project_path": "/path/to/project"}
      ]
    }
  }
}
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

Remove a skill with scope selection (project-only or global).

**Features:**
- **Project scope**: Remove only from current project
- **Global scope**: Remove from all locations using JSON record
- Uses `npx skills remove` for standardized uninstallation

**Usage:**
```bash
# Interactive mode (prompts for scope)
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/remove_skill.sh <skill-name>

# Remove from current project only
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/remove_skill.sh <skill-name> --project
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/remove_skill.sh <skill-name> -p

# Remove from all locations (global)
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/remove_skill.sh <skill-name> --global
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/remove_skill.sh <skill-name> -g

# Dry run - preview what will be removed
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/remove_skill.sh <skill-name> --dry-run
```

**Global removal process:**
1. Reads `~/.nocode/skills-manager.json` for all recorded locations
2. Removes all symlinks (global + all projects)
3. Runs `npx skills remove <skill-name>`
4. Removes entry from JSON record
5. Removes from central repository

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

## Data Structure

### JSON Record File (`~/.nocode/skills-manager.json`)

此文件记录所有 skill 的安装状态和位置信息，是全局删除功能的依据。

**完整数据结构：**

```json
{
  "skills": {
    "skill-name": {
      "installed_at": "2024-01-15T10:30:00Z",
      "source": "npx",
      "source_url": "https://github.com/owner/repo",
      "version": "1.0.0",
      "locations": [
        {
          "type": "global",
          "linked_at": "2024-01-15T10:30:00Z",
          "path": "~/.claude/skills/skill-name"
        },
        {
          "type": "project",
          "linked_at": "2024-01-15T10:35:00Z",
          "project_id": "a1b2c3d4e5f6",
          "project_path": "/Users/xxx/AI/MyProject",
          "path": "./.claude/skills/skill-name"
        }
      ]
    }
  },
  "metadata": {
    "version": "1.0",
    "last_updated": "2024-01-15T10:35:00Z"
  }
}
```

**字段说明：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `installed_at` | string | ISO 8601 格式的安装时间 |
| `source` | string | 安装来源：`npx`、`github`、`local` |
| `source_url` | string | 原始来源 URL（GitHub 地址或本地路径）|
| `version` | string | Skill 版本号 |
| `locations` | array | 该 skill 的所有安装位置 |
| `locations[].type` | string | 位置类型：`global` 或 `project` |
| `locations[].project_id` | string | 项目唯一标识（git remote URL 的哈希）|
| `locations[].project_path` | string | 项目绝对路径 |
| `locations[].path` | string | 软链接的实际路径 |

---

## 软链接机制

### 链接架构

```
中央仓库 (唯一实体)
    │
    ├── ~/.claude/skills/skill-name  →  /Users/xxx/AI/NoCode/skills/skill-name
    │       (全局软链接)
    │
    ├── ./.claude/skills/skill-name  →  /Users/xxx/AI/NoCode/skills/skill-name
    │       (项目软链接 A)
    │
    └── ~/OtherProject/.claude/skills/skill-name  →  /Users/xxx/AI/NoCode/skills/skill-name
            (项目软链接 B)
```

### 链接创建流程

1. **安装时** (`install_skill.sh`):
   - 运行 `npx skills add <skill>` 将 skill 下载到 npx 缓存
   - 复制到中央仓库 `/Users/yes365/AI/NoCode/skills/<skill>/`
   - 根据选择创建软链接到 `~/.claude/skills/` 或 `./.claude/skills/`
   - 记录到 `~/.nocode/skills-manager.json`

2. **链接时** (`link_global.sh` / `link_project.sh`):
   - 仅创建符号链接，不修改中央仓库
   - 更新 JSON 记录

### 链接删除流程

1. **Project 范围** (`remove_skill.sh --project`):
   - 仅删除 `./.claude/skills/<skill>`
   - 更新 JSON，移除当前 project_id 对应的记录

2. **Global 范围** (`remove_skill.sh --global`):
   - 从 JSON 中读取所有 `locations`
   - 删除所有记录的路径（global + 所有 project）
   - 运行 `npx skills remove <skill>`
   - 删除中央仓库中的 skill 目录
   - 从 JSON 中完全移除该 skill 记录

---

## Skill 来源

### 支持的来源

| 来源 | 命令示例 | 说明 |
|------|---------|------|
| **npx registry** | `npx skills add my-skill` | 从 npx skills registry 安装 |
| **GitHub URL** | `install_skill.sh owner/repo` | 从 GitHub 仓库克隆 |
| **本地路径** | `install_skill.sh ./local-skill` | 从本地目录复制 |

### 来源追踪

安装时 `source` 和 `source_url` 字段记录来源：

```bash
# 从 GitHub 安装
install_skill.sh https://github.com/affaan-m/everything-claude-code
# JSON 记录: "source": "github", "source_url": "https://github.com/affaan-m/everything-claude-code"

# 从 npx 安装
npx skills add my-skill
# JSON 记录: "source": "npx", "source_url": "npm:my-skill"
```

---

## Directory Structure

```
~/.nocode/                                 # nocode 配置目录
└── skills-manager.json                    # 安装记录 (JSON)

/Users/yes365/AI/NoCode/skills/            # 中央仓库 (所有 skills 实体)
├── skills-manager/                        # 本管理工具
│   ├── SKILL.md
│   └── scripts/
│       ├── install_skill.sh               # 安装脚本
│       ├── remove_skill.sh                # 删除脚本
│       ├── list_skills.sh
│       ├── link_global.sh
│       ├── link_project.sh
│       └── check_links.sh
├── skill-a/                               # Skill A 实体
│   └── SKILL.md
└── skill-b/                               # Skill B 实体
    └── SKILL.md

~/.claude/skills/                          # 全局软链接目录
├── skills-manager -> /Users/.../skills/skills-manager/
├── skill-a -> /Users/.../skills/skill-a/
└── skill-b -> /Users/.../skills/skill-b/

./MyProject/.claude/skills/                # 项目软链接目录
└── skill-a -> /Users/.../skills/skill-a/  # 仅该项目可用
```
