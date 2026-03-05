# Storage Rules

> **When to read this**: When determining where to save AI-generated content or attachments.

Rules for storing files in the MyJarvis system.

---

## Generated Content Storage

**ALL AI-generated content MUST be written to Memory/Out/YYMM/ directory**.

This includes:
- Generated Markdown documents (analysis, summaries, PRDs, etc.)
- Generated diagram files (.drawio, .svg, .png, etc.)
- Exported reports, documents, etc.

### Rules

1. **Generation = Output**: All AI-generated artifacts MUST be placed in `Memory/Out/YYMM/`
2. **Naming format**: `yymmdd-<description>.ext` (e.g., `260304-project-gantt.drawio`)
3. **Cross-referencing**: Use relative paths `[description](../../Memory/Out/2603/xxx.drawio)`

---

## Attachment Management

Non-generated external attachments (user uploads, screenshots, external documents, etc.) MUST be stored in **Meta/Assets/** directory.

### Directory Structure

```
Meta/Assets/
├── yymmdd-<description>.svg       # Diagram attachments
├── yymmdd-<description>.png       # Screenshot attachments
└── yymmdd-<description>.pdf       # Document attachments
```

### Rules

1. **Location**: All attachments MUST be placed in `Meta/Assets/`, NEVER in Temp/ or other temporary directories
2. **Naming format**: `yymmdd-<description>.ext` (e.g., `260228-project-architecture.svg`)
3. **Reference method**: Use relative path `![description](../../../Meta/Assets/yymmdd-name.svg)`
4. **Cleanup requirement**: Delete temporary .mmd source files after diagram generation

---

## Storage Location Summary

| Content Type | Storage Location | Example |
|--------------|------------------|---------|
| AI-generated MD documents | `Memory/Out/YYMM/` | `Memory/Out/2603/260304-analysis.md` |
| AI-generated diagrams | `Memory/Out/YYMM/` | `Memory/Out/2603/260304-gantt.drawio` |
| External attachments | `Meta/Assets/` | `Meta/Assets/260228-screenshot.png` |
| Flow documents | `Flow/` hierarchy | `Flow/04-Daily/2603/260304-Daily.md` |
| Migrated knowledge | `Knowledge/2-Outputs/AI/` | `Knowledge/2-Outputs/AI/260304-guide.md` |

---

## Mermaid Diagram Processing

### Default Behavior

Create `.mmd` source files or Markdown code blocks, **NO format conversion**.

### Exceptions

SVG/PNG conversion ONLY when user explicitly requests:
- "convert to SVG"
- "generate image"
- "export as PNG"

### Prohibited

DO NOT actively render Mermaid to image formats by default.

---

## Migration Path

Only migrate when user explicitly says "capture to Knowledge":

```
Memory/Out/YYMM/file.md  →  Knowledge/2-Outputs/AI/file.md
```

See [knowledge-capture.md](knowledge-capture.md) for migration procedures.
