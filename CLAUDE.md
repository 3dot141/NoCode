# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code Skills Repository** - a centralized collection of skills that extend Claude's capabilities. Each skill is a modular package containing specialized knowledge, workflows, and tools.

**Key Paths:**
- Central repository: `/Users/yes365/AI/NoCode/skills/`
- Global symlinks: `~/.claude/skills/`
- Global agent mapping: `~/.agents/skills -> ~/.claude/skills`
- Project symlinks: `./.claude/skills/`
- Project agent mapping: `./.agents/skills -> ./.claude/skills`
- Manager config: `~/.nocode/skills-manager-config.json`
- Installation records: `~/.nocode/skills-manager.json`

## Skill Structure

Every skill follows this structure:

```
skills/<skill-name>/
├── SKILL.md              # Required: YAML frontmatter + Markdown instructions
├── scripts/              # Optional: Executable scripts (Python/Bash/Node)
├── references/           # Optional: Documentation loaded on demand
└── assets/               # Optional: Templates, images, fonts for output
```

**SKILL.md format:**
```yaml
---
name: skill-name
description: When to use this skill (triggers invocation)
---

# Skill Title

Instructions and workflows...
```

## Skills Manager Operations

Use `skills-manager` scripts for all skill operations:

```bash
# List all available skills
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/list_skills.sh

# Install/link skills
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/install_skill.sh <skill> [global|project|both]
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/update_skill.sh <skill>
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/sync_projects.sh [skill]
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/link_global.sh <skill>
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/link_project.sh <skill>

# Remove skills
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/remove_skill.sh <skill> [--global|--project]

# Check/fix symlinks
bash /Users/yes365/AI/NoCode/skills/skills-manager/scripts/check_links.sh
```

**Important Principles:**
- All skills reside in central repository (`/Users/yes365/AI/NoCode/skills/`)
- Projects use symlinks, never direct copies
- Project `.agents/skills` is a symlink to project `.claude/skills`
- Internet install/update must use `npx skills`
- Installation records stored in `~/.nocode/skills-manager.json`

## Creating New Skills

Use the `skill-creator` skill as reference. Key requirements:

1. **SKILL.md must have:**
   - YAML frontmatter with `name` and `description` fields
   - Description should clearly state when the skill triggers
   - Concise instructions (context window is shared)

2. **File organization:**
   - Put detailed docs in `references/`, not SKILL.md
   - Put scripts in `scripts/`
   - Put templates/assets in `assets/`

3. **After creating a skill:**
   ```bash
   cd /Users/yes365/AI/NoCode/skills/
   git add <skill-name>/
   git commit -m "feat: add <skill-name> skill"
   git push
   ```

## Modifying Skills

**All modifications must be done in central repository:**

```bash
# 1. Edit in central repository
cd /Users/yes365/AI/NoCode/skills/<skill-name>/
# ... make changes ...

# 2. Commit and push
cd /Users/yes365/AI/NoCode/skills/
git add <skill-name>/
git commit -m "update(<skill-name>): description"
git push

# 3. Return to working project
cd /Users/yes365/AI/YourProject
```

## Claude Plugins

Plugins are located in `.claude/plugins/` and follow a different structure:

```
.claude/plugins/
├── .claude-plugin/marketplace.json     # Plugin registry
└── <plugin-name>/                      # Plugin directory
    ├── plugin.json                     # Plugin manifest
    ├── commands/                       # Slash commands
    └── skills/                         # Bundled skills
```

## Git Workflow

**Always commit skill changes from the central skills directory:**

```bash
cd /Users/yes365/AI/NoCode/skills/
git add <skill-name>/
git commit -m "type(skill-name): description"
git push
```

**Commit message format:**
- `feat(skill-name):` - New skill or feature
- `fix(skill-name):` - Bug fix
- `update(skill-name):` - Documentation or minor updates
- `refactor(skill-name):` - Code restructuring

## Special Skills

| Skill | Purpose |
|-------|---------|
| `skills-manager` | Manage skill installation/linking/removal |
| `skill-creator` | Guide for creating new skills |
| `drawio` | AI-powered Draw.io diagram creation |
| `excalidraw-diagram` | Generate Excalidraw diagrams from text |
| `mermaid-diagrams` | Create diagrams using Mermaid syntax |
| `humanizer-zh` | Remove AI-generated text patterns (Chinese) |
| `regex-vs-llm-structured-text` | Decision framework for text parsing |

## Important Notes

- **Context Window:** Skills share context with system prompt and conversation. Keep SKILL.md concise.
- **Symlinks:** Never modify files in `~/.claude/skills/` or `./.claude/skills/` directly - they are symlinks.
- **Node Modules:** Add `node_modules/` to `.gitignore` for skills with Node.js dependencies.
- **Testing:** Test scripts independently before including in skills.
