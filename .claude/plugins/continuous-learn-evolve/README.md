# Continuous Learning v2.1 Plugin

> **Fork Source**: 本项目从 [affaan-m/everything-claude-code/skills/continuous-learning-v2](https://github.com/affaan-m/everything-claude-code/tree/main/skills/continuous-learning-v2) fork 并打包为 Claude Code 插件。

An advanced learning system that turns your Claude Code sessions into reusable knowledge through atomic "instincts" - small learned behaviors with confidence scoring.

**v2.1** adds **project-scoped instincts** — React patterns stay in your React project, Python conventions stay in your Python project, and universal patterns (like "always validate input") are shared globally.

---

## What's Inside

| Component | Count | Description |
|-----------|-------|-------------|
| Skills | 1 | `continuous-learn-evolve` - Core learning system |
| Commands | 6 | `/instinct-status`, `/evolve`, `/instinct-export`, `/instinct-import`, `/promote`, `/projects` |
| Agents | 1 | `observer` - Background pattern analyzer |
| Hooks | 2 | PreToolUse + PostToolUse observation hooks |

---

## Installation

### Option 1: Plugin Marketplace (when available)
```bash
/plugin install continuous-learn-evolve
```

### Option 2: Local Installation
```bash
# Clone or download this plugin
cd continuous-learn-evolve-plugin

# Install to Claude Code
cc --plugin-dir .
```

### Option 3: Manual Installation
```bash
# Copy to Claude Code plugins directory
cp -r continuous-learn-evolve-plugin ~/.claude/plugins/

# Or symlink for development
ln -s $(pwd)/continuous-learn-evolve-plugin ~/.claude/plugins/
```

---

## Quick Start

### 1. Enable Observation Hooks

The plugin automatically configures hooks, but you can verify in your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learn-evolve/hooks/observe.sh"
      }]
    }],
    "PostToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learn-evolve/hooks/observe.sh"
      }]
    }]
  }
}
```

### 2. Initialize Directory Structure

The system creates directories automatically on first use:

```
~/.claude/homunculus/
├── identity.json           # Your profile, technical level
├── projects.json           # Registry: project hash -> name/path/remote
├── observations.jsonl      # Global observations (fallback)
├── instincts/
│   ├── personal/           # Global auto-learned instincts
│   └── inherited/          # Global imported instincts
├── evolved/
│   ├── agents/             # Global generated agents
│   ├── skills/             # Global generated skills
│   └── commands/           # Global generated commands
└── projects/
    └── <project-hash>/     # Project-specific data
        ├── observations.jsonl
        ├── instincts/
        │   ├── personal/
        │   └── inherited/
        └── evolved/
```

### 3. Use the Commands

| Command | Purpose |
|---------|---------|
| `/instinct-status` | Show learned instincts (project + global) |
| `/evolve` | Cluster instincts into skills/commands/agents |
| `/instinct-export` | Export instincts to shareable YAML |
| `/instinct-import <file>` | Import instincts from others |
| `/promote [id]` | Promote project instincts to global |
| `/projects` | List all known projects |

---

## The Instinct Model

An instinct is a small learned behavior:

```yaml
---
id: prefer-functional-style
trigger: "when writing new functions"
confidence: 0.7
domain: "code-style"
source: "session-observation"
scope: project
project_id: "a1b2c3d4e5f6"
project_name: "my-react-app"
---

# Prefer Functional Style

## Action
Use functional patterns over classes when appropriate.

## Evidence
- Observed 5 instances of functional pattern preference
- User corrected class-based approach to functional on 2025-01-15
```

**Properties:**
- **Atomic** — one trigger, one action
- **Confidence-weighted** — 0.3 = tentative, 0.9 = near certain
- **Domain-tagged** — code-style, testing, git, debugging, workflow, etc.
- **Evidence-backed** — tracks what observations created it
- **Scope-aware** — `project` (default) or `global`

---

## How It Works

```
Session Activity (in a git repo)
      |
      | Hooks capture prompts + tool use (100% reliable)
      | + detect project context (git remote / repo path)
      v
+---------------------------------------------+
|  projects/<project-hash>/observations.jsonl  |
|   (prompts, tool calls, outcomes, project)   |
+---------------------------------------------+
      |
      | Observer agent reads (background, Haiku)
      v
+---------------------------------------------+
|          PATTERN DETECTION                   |
|   * User corrections -> instinct             |
|   * Error resolutions -> instinct            |
|   * Repeated workflows -> instinct           |
|   * Scope decision: project or global?       |
+---------------------------------------------+
      |
      | Creates/updates
      v
+---------------------------------------------+
|  projects/<project-hash>/instincts/personal/ |
|   * prefer-functional.yaml (0.7) [project]   |
|   * use-react-hooks.yaml (0.9) [project]     |
+---------------------------------------------+
|  instincts/personal/  (GLOBAL)               |
|   * always-validate-input.yaml (0.85) [global]|
|   * grep-before-edit.yaml (0.6) [global]     |
+---------------------------------------------+
      |
      | /evolve clusters + /promote
      v
+---------------------------------------------+
|  projects/<hash>/evolved/ (project-scoped)   |
|  evolved/ (global)                           |
|   * commands/new-feature.md                  |
|   * skills/testing-workflow.md               |
|   * agents/refactor-specialist.md            |
+---------------------------------------------+
```

---

## Project Detection

The system automatically detects your current project:

1. **`CLAUDE_PROJECT_DIR` env var** (highest priority)
2. **`git remote get-url origin`** — hashed to create a portable project ID
3. **`git rev-parse --show-toplevel`** — fallback using repo path
4. **Global fallback** — if no project detected, instincts go to global scope

Each project gets a 12-character hash ID (e.g., `a1b2c3d4e5f6`).

---

## Scope Decision Guide

| Pattern Type | Scope | Examples |
|-------------|-------|---------|
| Language/framework conventions | **project** | "Use React hooks", "Follow Django REST patterns" |
| File structure preferences | **project** | "Tests in `__tests__`/", "Components in src/components/" |
| Code style | **project** | "Use functional style", "Prefer dataclasses" |
| Error handling strategies | **project** | "Use Result type for errors" |
| Security practices | **global** | "Validate user input", "Sanitize SQL" |
| General best practices | **global** | "Write tests first", "Always handle errors" |
| Tool workflow preferences | **global** | "Grep before Edit", "Read before Write" |
| Git practices | **global** | "Conventional commits", "Small focused commits" |

---

## Instinct Promotion (Project -> Global)

When the same instinct appears in multiple projects with high confidence, it's a candidate for promotion to global scope.

**Auto-promotion criteria:**
- Same instinct ID in 2+ projects
- Average confidence >= 0.8

**How to promote:**
```bash
# Promote a specific instinct
/promote prefer-explicit-errors

# Auto-promote all qualifying instincts
/promote

# Preview without changes
/promote --dry-run
```

---

## Confidence Scoring

Confidence evolves over time:

| Score | Meaning | Behavior |
|-------|---------|----------|
| 0.3 | Tentative | Suggested but not enforced |
| 0.5 | Moderate | Applied when relevant |
| 0.7 | Strong | Auto-approved for application |
| 0.9 | Near-certain | Core behavior |

**Confidence increases** when:
- Pattern is repeatedly observed
- User doesn't correct the suggested behavior
- Similar instincts from other sources agree

**Confidence decreases** when:
- User explicitly corrects the behavior
- Pattern isn't observed for extended periods
- Contradicting evidence appears

---

## Configuration

Edit `~/.claude/homunculus/config.json` to control the background observer:

```json
{
  "version": "2.1",
  "observer": {
    "enabled": false,
    "run_interval_minutes": 5,
    "min_observations_to_analyze": 20
  }
}
```

| Key | Default | Description |
|-----|---------|-------------|
| `observer.enabled` | `false` | Enable the background observer agent |
| `observer.run_interval_minutes` | `5` | How often the observer analyzes observations |
| `observer.min_observations_to_analyze` | `20` | Minimum observations before analysis runs |

---

## Privacy

- Observations stay **local** on your machine
- Project-scoped instincts are isolated per project
- Only **instincts** (patterns) can be exported — not raw observations
- No actual code or conversation content is shared
- You control what gets exported and promoted

---

## File Structure

```
continuous-learn-evolve-plugin/
├── plugin.json              # Plugin manifest
├── README.md                # This file
├── commands/                # Slash commands
│   ├── evolve.md
│   ├── instinct-export.md
│   ├── instinct-import.md
│   ├── instinct-status.md
│   ├── promote.md
│   └── projects.md
└── skills/
    └── continuous-learn-evolve/
        ├── SKILL.md         # Core skill documentation
        ├── config.json      # Default configuration
        ├── agents/
        │   ├── observer.md          # Background analyzer
        │   └── start-observer.sh    # Launcher script
        ├── hooks/
        │   └── observe.sh           # Observation hook
        └── scripts/
            ├── detect-project.sh    # Project detection
            ├── instinct-cli.py      # CLI implementation
            └── test_parse_instinct.py
```

---

## Related

- [Skill Creator](https://skill-creator.app) - Generate instincts from repo history
- Homunculus - Community project that inspired the v2 instinct-based architecture
- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) - Continuous learning section

---

## Credits

- **Original Author**: [affaan-m](https://github.com/affaan-m) - 创建了 [continuous-learning-v2](https://github.com/affaan-m/everything-claude-code/tree/main/skills/continuous-learning-v2) skill
- **Fork & Plugin Packaging**: 本项目由原 skill 打包为 Claude Code 插件，保留所有核心功能和 MIT 许可证

---

## License

MIT

---

*Instinct-based learning: teaching Claude your patterns, one project at a time.*
