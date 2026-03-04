---
name: instinct-import
description: Import instincts from YAML files or URLs
command: true
---

# Instinct Import Command

Import instincts from YAML files or URLs into project or global scope.

## Implementation

Run the instinct CLI:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learn-evolve/scripts/instinct-cli.py" import "$@"
```

## Usage

```bash
/instinct-import <file-or-url>
/instinct-import team-instincts.yaml --scope global
/instinct-import https://example.com/instincts.yaml --dry-run
```

## Flags

| Flag | Description |
|------|-------------|
| `--scope` | Target scope: `project` or `global` (default: project) |
| `--min-confidence` | Minimum confidence threshold to import |
| `--dry-run` | Preview without importing |
| `--force` | Skip confirmation prompts |

## What to Do

1. Fetch instinct file from local path or HTTP(S) URL
2. Validate YAML structure and required fields
3. Detect duplicates (compare by instinct ID)
4. Apply merge strategy:
   - Higher confidence imports -> update existing
   - Lower/equal confidence -> skip
5. Write to target scope with source tracking

## Storage Locations

- Project scope: `~/.claude/homunculus/projects/<id>/instincts/inherited/`
- Global scope: `~/.claude/homunculus/instincts/inherited/`

## Import Metadata

Imported instincts are tagged with:
- `source: imported`
- `imported_from`: Original source
- `imported_at`: Timestamp
