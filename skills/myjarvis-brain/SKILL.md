---
name: myjarvis-brain
description: Comprehensive personal knowledge and task management for MyJarvis Obsidian system. Use when users need to (1) create or manage plan documents (diary, weekly, monthly, annual), (2) track task status or decompose goals, (3) generate periodic summaries, (4) create documents in Memory/Out, (5) migrate knowledge to Knowledge/. Triggers on "create plan", "manage tasks", "summarize", "capture knowledge", "migrate document", "create diary/weekly note", "create markdown", "create md document", "generate document", "create document".
---

# MyJarvis Brain

Comprehensive personal knowledge and task management for the MyJarvis Obsidian-based knowledge system.

## Quick Navigation

**Need to know which template to use?** → See [references/templates.md](references/templates.md)

**Creating a document?** Read these in order:
1. [references/document-creation.md](references/document-creation.md) - What to create where
2. [references/link-format.md](references/link-format.md) - How to write links correctly
3. [references/storage-rules.md](references/storage-rules.md) - Where to store files

**Managing tasks?** → See [references/task-management.md](references/task-management.md)

**Migrating to Knowledge?** → See [references/knowledge-capture.md](references/knowledge-capture.md)

**Need enforcement rules?** → See CLAUDE.md `## Enforcement Mechanisms`

---

## Core Workflow

### Document Creation Decision Tree

```
User Request
    │
    ├─→ "Create diary/weekly/monthly/annual plan"
    │   └─→ Read [references/templates.md](references/templates.md)
    │       └─→ Create in Flow/ hierarchy
    │
    ├─→ "Create/generate document" (general)
    │   ├─→ Read [references/document-creation.md](references/document-creation.md)
    │   ├─→ Read [references/storage-rules.md](references/storage-rules.md)
    │   └─→ Create in Memory/Out/YYMM/
    │
    ├─→ "Manage tasks/update status/summarize"
    │   └─→ Read [references/task-management.md](references/task-management.md)
    │
    └─→ "Capture to Knowledge/migrate to Knowledge"
        └─→ Read [references/knowledge-capture.md](references/knowledge-capture.md)
            └─→ Migrate to Knowledge/2-Outputs/AI/
```

### Critical Rules (Summary)

| Rule | What | Where |
|------|------|-------|
| **Storage** | AI-generated content → `Memory/Out/YYMM/` | Never auto-migrate to Knowledge |
| **Links** | Use `[text](path)`, NOT `[[wikilink]]` | Relative paths only |
| **Naming** | `yymmdd-<title>.md` | Chinese titles allowed |
| **Migration** | Only when user explicitly says "capture" | Read [knowledge-capture.md](references/knowledge-capture.md) |

---

## Intent Patterns

### Task Management
- "Create/generate [annual/monthly/weekly/daily] [plan/summary/diary/weekly note]"
- "Add/update/complete task"
- "Decompose/split goal"
- "Summarize/review [this week/this month]"

### Document Creation
- "Create/generate document" → Create in Memory/Out/
- "Create knowledge document" → Create in Memory/Out/ (do NOT auto-migrate)

### Knowledge Migration (Explicit Only)
- "Capture to Knowledge", "Migrate to Knowledge"
- "Organize [Memory/some document] into Knowledge"

---

## Directory Structure

```
Knowledge/        # Permanent knowledge (only for migrated content)
├── 0-About/      # System documentation
├── 1-Inputs/     # External knowledge inputs
├── 2-Outputs/    # AI/, Card/, MOC/
├── 3-Tasks/      # Task-related content
├── 4-Outcomes/   # Deliverables
└── 5-Archive/    # Archived content

Flow/             # Planning & execution
├── 01-Year/      # Annual planning
├── 02-Month/     # Monthly planning
├── 03-Week/YYMM/ # Weekly logs (YYMMDD-Weekly.md)
└── 04-Daily/YYMM/# Daily logs (YYMMDD-Daily.md)

Memory/           # Working memory
├── In/YYMM/      # External inputs
├── Fleeting/YYMM/# Fleeting notes
└── Out/YYMM/     # AI-generated outputs

Meta/
├── Assets/       # Attachments (images, PDFs)
└── Templates/    # Templates
```

---

## Enforcement Checklist

Before creating ANY document:

```
□ Read [references/document-creation.md](references/document-creation.md) if unsure about document type
□ Read [references/templates.md](references/templates.md) for Flow documents
□ Frontmatter matches document type? (see templates.md table)
□ Path correct? (Memory/Out/ vs Flow/ vs Knowledge/)
□ Filename format: yymmdd-<title>.md?
□ Links use [text](path) format? (NOT [[wikilink]])
□ Not auto-migrating to Knowledge? (unless explicitly requested)
```

---

## Quick Examples

### Create Daily Log
```
User: "Create today's diary"
→ Read [references/template-daily-quick.md](references/template-daily-quick.md)
→ Create Flow/04-Daily/2603/260304-Daily.md
```

### Create Analysis Document
```
User: "Analyze this requirement and generate a document"
→ Read [references/knowledge-capture.md](references/knowledge-capture.md) section "Document Creation Rule"
→ Create Memory/Out/2603/260304-requirement-analysis.md
→ Do NOT migrate to Knowledge
```

### Migrate Knowledge
```
User: "Capture React notes from Memory/Out into Knowledge"
→ Read [references/knowledge-capture.md](references/knowledge-capture.md) section "Migration to Knowledge"
→ Create Knowledge/2-Outputs/AI/260304-react-guide.md
→ Add backlink in original document
```

---

## Resources

### scripts/
- `task_helper.py` - Task operations, status tracking
- `knowledge_helper.py` - Migration, linking utilities

### references/ (Load as needed)
- [document-creation.md](references/document-creation.md) - Document types and rules
- [link-format.md](references/link-format.md) - Link format specifications
- [storage-rules.md](references/storage-rules.md) - Storage locations
- [task-management.md](references/task-management.md) - Task workflows
- [knowledge-capture.md](references/knowledge-capture.md) - Migration rules
- [templates.md](references/templates.md) - Template quick reference

### templates/ (Quick load)
- [template-daily-quick.md](references/template-daily-quick.md)
- [template-weekly-quick.md](references/template-weekly-quick.md)
- [template-monthly-quick.md](references/template-monthly-quick.md)
