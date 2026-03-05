---
name: skills-manager
description: Manage centralized skills repository with .agents/.claude mapping, install/update via npx skills, and sync to managed projects.
---

# Skills Manager

集中式管理 Skill：
- 中央仓库：`~/AI/NoCode/skills/`（可在配置中覆盖）
- 主目录：`./.agents/skills/`（技能实体目录）
- Claude 目录：`./.claude/skills -> ./.agents/skills`（目录级软链接）

## Principles

- 项目内技能实体目录是 `.agents/skills`。
- `.claude/skills` 必须软链接到 `.agents/skills`。
- 项目内 skill 不再软链接到中央仓库，通过脚本同步（复制）内容。
- 不做实时自动监听同步；所有同步动作都通过脚本触发。
- 从互联网安装和更新统一走 `npx skills`。
- 通过 `~/.nocode/skills-manager-config.json` 管理路径。

## Config

默认配置文件：
- `~/.nocode/skills-manager-config.json`

默认内容：

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

安装记录：`~/.nocode/skills-manager.json`

## Commands

```bash
# 列出中央仓库 skills
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/list_skills.sh

# 从互联网安装（npx skills add），并同步到 global/project/both
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/install_skill.sh <skill> [global|project|both]

# 手动同步
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/link_global.sh <skill>
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/link_project.sh <skill>

# 从互联网更新（npx skills update），更新中央仓库并同步项目
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/update_skill.sh <skill>

# 双向同步（默认）：中央仓库 <-> 受管项目
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/sync_projects.sh [skill]

# 单向同步：中央仓库 -> 受管项目
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/sync_projects.sh [skill] --from-central

# 将项目 .agents/skills/<skill> 中转回中央仓库并向外同步
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/promote_skill.sh <skill> [project_path]

# 检查/修复映射（含 .claude -> .agents 映射）并修复误用的 skill 软链
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/check_links.sh

# 扫描 /Users/yes365 与 /Users/yes365/AI 子目录，修复映射并重建配置
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/rebuild_config.sh

# 删除
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/remove_skill.sh <skill> [--global|--project]
```

## Sync Behavior

同步规范（双向）：
- `sync_projects.sh` 默认双向同步（中央仓库 <-> 子仓库），按目录最新修改时间选择源，再复制到其他端。
- `sync_projects.sh --from-central` 强制中央仓库作为源，单向下发到子仓库。
- `install_skill.sh` / `update_skill.sh` 使用中央仓库作为权威源并下发。
- `promote_skill.sh` 先将项目改动中转到中央，再以中央为源下发。
- 默认不自动监听文件变化；需要手动执行同步脚本。

行为说明：
- 修改中央仓库 skill 内容后，执行 `sync_projects.sh` 可双向同步，或用 `--from-central` 强制下发。
- 修改项目 `.agents/skills/<skill>` 后，执行 `sync_projects.sh` 可自动回流中央；也可先 `promote_skill.sh` 再下发。
- `update_skill.sh` 会自动触发按 skill 同步到受管项目。

## Directory Topology

```text
中央仓库
~/AI/NoCode/skills/<skill>

项目内
./.agents/skills/<skill>   # 实体目录（由脚本从中央仓库同步）
./.claude/skills -> ../.agents/skills
```

## Notes

- `.agents/skills` 放实体文件，`.claude/skills` 只做目录映射。
- 修改 skill 请以中央仓库路径为准。
- 若路径定制，请修改配置文件而不是改脚本常量。
