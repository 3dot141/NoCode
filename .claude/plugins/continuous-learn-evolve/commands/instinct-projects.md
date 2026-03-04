---
name: instinct-projects
description: List known projects and their instinct statistics
command: true
---

# Instinct Projects Command

List project registry entries and per-project instinct/observation counts.

## Implementation

Run the instinct CLI:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learn-evolve/scripts/instinct-cli.py" projects
```

## Usage

```bash
/instinct-projects
```

## What to Do

1. Read `~/.claude/homunculus/projects.json` registry
2. For each project, display:
   - Project name and ID (hash)
   - Root path and git remote URL
   - Personal instinct count
   - Inherited instinct count
   - Observation event count
   - Last seen timestamp
3. Display global instinct totals

## Output Format

```
KNOWN PROJECTS
==============

my-react-app (a1b2c3d4e5f6)
  Path: /Users/dev/projects/my-react-app
  Remote: github.com/user/my-react-app
  Instincts: 12 personal, 3 inherited
  Observations: 1,247 events
  Last seen: 2025-01-15

my-python-api (f6e5d4c3b2a1)
  Path: /Users/dev/projects/my-python-api
  Remote: github.com/user/my-python-api
  Instincts: 8 personal, 5 inherited
  Observations: 892 events
  Last seen: 2025-01-14

GLOBAL
  Instincts: 25 personal, 10 inherited
```

## Registry Location

`~/.claude/homunculus/projects.json`

Format:
```json
{
  "projects": {
    "a1b2c3d4e5f6": {
      "name": "my-react-app",
      "root": "/Users/dev/projects/my-react-app",
      "remote": "github.com/user/my-react-app",
      "first_seen": "2025-01-01",
      "last_seen": "2025-01-15"
    }
  }
}
```
