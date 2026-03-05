---
name: skills-manager
description: Manage centralized skills repository with .agents/.claude mapping, install/update via npx skills, and sync to managed projects.
---

# Skills Manager

集中式管理 Skill：
- 中央仓库：`~/AI/NoCode/skills/`（可在配置中覆盖）
- 项目目录：`./.claude/skills/`（技能链接目录）
- Agent 目录：`./.agents/skills -> ./.claude/skills`（目录级软链接）

## Principles

- 技能实体只保留在中央仓库。
- 项目里只放符号链接，不做硬链接。
- `.agents/skills` 必须软链接到 `.claude/skills`。
- 从互联网安装和更新统一走 `npx skills`。
- 通过 `~/.nocode/skills-manager-config.json` 管理路径。

## Config

默认配置文件：
- `~/.nocode/skills-manager-config.json`

默认内容：

```json
{
  "central_repo": "~/AI/NoCode/skills",
  "global_claude_dir": "~/.claude/skills",
  "global_agents_link": "~/.agents/skills",
  "project_claude_dir": ".claude/skills",
  "project_agents_link": ".agents/skills"
}
```

安装记录：`~/.nocode/skills-manager.json`

## Commands

```bash
# 列出中央仓库 skills
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/list_skills.sh

# 从互联网安装（npx skills add），并链接到 global/project/both
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/install_skill.sh <skill> [global|project|both]

# 手动链接
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/link_global.sh <skill>
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/link_project.sh <skill>

# 从互联网更新（npx skills update），更新中央仓库并同步项目
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/update_skill.sh <skill>

# 将中央仓库链接状态同步到受管项目
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/sync_projects.sh [skill]

# 检查/修复链接（含 .agents -> .claude 映射）
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/check_links.sh

# 扫描 /Users/yes365 与 /Users/yes365/AI 子目录，修复映射并重建配置
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/rebuild_config.sh

# 删除
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/remove_skill.sh <skill> [--global|--project]
```

## Sync Behavior

- 修改中央仓库 skill 内容后：
  - 已链接项目会直接感知（skill 级链接指向中央仓库）。
  - 可运行 `sync_projects.sh` 修复/补齐各项目映射和链接。
- `update_skill.sh` 会自动触发按 skill 同步到受管项目。

## Directory Topology

```text
中央仓库
~/AI/NoCode/skills/<skill>

项目内
./.claude/skills/<skill> -> ~/AI/NoCode/skills/<skill>
./.agents/skills -> ./.claude/skills
```

## Notes

- 不要在 `.agents/skills` 和 `.claude/skills` 放实体文件。
- 修改 skill 请以中央仓库路径为准。
- 若路径定制，请修改配置文件而不是改脚本常量。
