---
name: instinct-promote
description: Promote project instincts to global scope
command: true
---

# Instinct Promote Command

Move instincts from project scope to global scope.

## Implementation

Run the instinct CLI:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learn-evolve/scripts/instinct-cli.py" promote "$@"
```

## Usage

```bash
/instinct-promote              # Auto-promote qualifying instincts
/instinct-promote <instinct-id>  # Promote specific instinct
/instinct-promote --dry-run    # Preview without changes
/instinct-promote --force      # Skip confirmation
```

## Auto-Promotion Criteria

An instinct is auto-promoted when:
- Same ID appears in 2+ projects
- Average confidence >= 0.8
- Pattern is language/framework agnostic

## What to Do

1. Detect current project
2. If instinct ID specified:
   - Validate it exists in project
   - Check promotion criteria
   - Copy to global scope
3. If no ID specified:
   - Scan all projects for cross-project patterns
   - Identify candidates meeting criteria
   - Promote all qualifying instincts

## Global Storage

Promoted instincts are written to:
`~/.claude/homunculus/instincts/personal/<instinct-id>.yaml`

With `scope: global` set in metadata.

## Examples

```bash
# Preview what would be promoted
/instinct-promote --dry-run

# Promote a specific instinct
/instinct-promote prefer-explicit-errors

# Force promote without confirmation
/instinct-promote always-validate-input --force
```
