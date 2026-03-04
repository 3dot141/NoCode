---
name: instinct-evolve
description: Cluster related instincts into skills/commands/agents
command: true
---

# Instinct Evolve Command

Analyze instincts and cluster them into higher-level structures - commands, skills, or agents.

## Implementation

Run the instinct CLI:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learn-evolve/scripts/instinct-cli.py" evolve "$@"
```

## Usage

```bash
/instinct-evolve              # Analyze only
/instinct-evolve --generate   # Also create files in evolved/{skills,commands,agents}/
```

## What to Do

1. Read project and global instincts
2. Group by trigger patterns and domains
3. Identify evolution candidates based on:
   - Confidence thresholds (0.7+ for commands, 0.8+ for skills)
   - Related trigger patterns
   - Evidence quality
4. Suggest promotions (project -> global) for instincts appearing in 2+ projects

## Evolution Types

| Type | Trigger | Example |
|------|---------|---------|
| Command | User-invoked | `/new-table` from migration instincts |
| Skill | Auto-triggered | `functional-patterns` from style instincts |
| Agent | Complex multi-step | `debugger` from debug workflow instincts |

## Output

Without `--generate`: Shows analysis and suggestions
With `--generate`: Creates files in `evolved/{skills,commands,agents}/`

Generated files include YAML frontmatter with `evolved_from` listing source instincts.
