---
name: instinct-export
description: Export instincts to shareable YAML format
command: true
---

# Instinct Export Command

Export instincts to a shareable YAML format.

## Implementation

Run the instinct CLI:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learn-evolve/scripts/instinct-cli.py" export "$@"
```

## Usage

```bash
/instinct-export --output my-instincts.yaml
/instinct-export --scope project --output project-instincts.yaml
/instinct-export --domain workflow --min-confidence 0.7
```

## Flags

| Flag | Description |
|------|-------------|
| `--scope` | Export scope: `project`, `global`, or `all` (default: all) |
| `--domain` | Filter by domain (e.g., `workflow`, `code-style`, `security`) |
| `--min-confidence` | Minimum confidence threshold (0.3-0.9) |
| `--output` | Output file path (default: stdout) |

## What to Do

1. Detect project context
2. Read instincts from specified scope(s)
3. Apply filters (domain, confidence)
4. Export to YAML with full metadata

## Output Format

```yaml
instincts:
  - id: prefer-functional-style
    trigger: "when writing new functions"
    confidence: 0.8
    domain: code-style
    scope: project
    action: "Use functional patterns over classes"
    evidence:
      - "Observed 5 instances..."
      - "User corrected..."
exported_at: 2025-01-15T10:30:00Z
source_project: my-project
```
