---
name: instinct-status
description: Show all learned instincts (project + global) with confidence scores
command: true
---

# Instinct Status Command

Display learned instincts for the current project plus global instincts, grouped by domain.

## Implementation

Run the instinct CLI:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learn-evolve/scripts/instinct-cli.py" status
```

## Usage

```bash
/instinct-status
```

## What to Do

1. Detect project context (git remote URL or repo path)
2. Read instincts from:
   - `~/.claude/homunculus/projects/<project-id>/instincts/` (project-scoped)
   - `~/.claude/homunculus/instincts/` (global)
3. Merge them with project instincts taking precedence
4. Display with confidence bars and observation stats

## Output Format

```
PROJECT-SCOPED (my-project)
├── WORKFLOW (3 instincts)
│   ├── prefer-functional-style [████████░░] 0.80
│   └── ...
└── SECURITY (1 instinct)
    └── ...

GLOBAL
├── WORKFLOW (5 instincts)
│   └── ...
└── CODE-STYLE (2 instincts)
    └── ...
```
