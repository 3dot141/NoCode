# Document Creation Rules

> **When to read this**: When creating any document and you need to know the correct template, frontmatter, or storage location.

Rules for creating different types of documents in the MyJarvis system.

---

## Document Type Quick Reference

| Document Type | Template | Target Path | Frontmatter Type |
|---------------|----------|-------------|------------------|
| Daily Log | [template-daily-quick.md](template-daily-quick.md) | `Flow/04-Daily/YYMM/YYMMDD-Daily.md` | `type: daily-log` |
| Weekly Log | [template-weekly-quick.md](template-weekly-quick.md) | `Flow/03-Week/YYMM/YYMMDD-Weekly.md` | `type: weekly-log` |
| Monthly Plan | [template-monthly-quick.md](template-monthly-quick.md) | `Flow/02-Month/YYMM-Monthly-Plan.md` | `type: monthly-plan` |
| Regular Document | [knowledge-capture.md](knowledge-capture.md) | `Memory/Out/YYMM/yymmdd-<title>.md` | Standard full frontmatter |

---

## Frontmatter Selection Rules

### Flow Documents (Daily/Weekly/Monthly)

Use simplified frontmatter:

```yaml
---
type: daily-log    # or weekly-log, monthly-plan
date: YYYY-MM-DD
---
```

### Memory/Out Documents

Use standard full frontmatter:

```yaml
---
aliases:
draft: false
tags:
summary:
created_date: YYYY-MM-DD HH:MM
modified_date: YYYY-MM-DD HH:MM
permalink: posts/{uuid()}
---
```

### Knowledge Documents (After Migration)

Add source field to standard frontmatter:

```yaml
---
aliases:
draft: false
tags:
summary:
created_date: YYYY-MM-DD HH:MM
modified_date: YYYY-MM-DD HH:MM
permalink: posts/{uuid()}
source: "Memory/Out/2603/260304-original.md"  # Add this
---
```

---

## Document Naming Conventions

### Standard Format

```
yymmdd-<kebab-case-description>.md
```

**Components**:
- `yymmdd`: Date (e.g., `260304` for 2026-03-04)
- `kebab-case-description`: Short, descriptive name
  - Lowercase
  - Words separated by hyphens
  - No articles (a, an, the)
  - Be specific but concise

**Examples**:
- ✅ `260304-react-hooks-guide.md`
- ✅ `260228-project-retrospective.md`
- ✅ `260315-api-design-patterns.md`
- ❌ `react guide.md` (missing date, contains space)
- ❌ `260304-a-guide-to-react.md` (contains "a")

### Flow Document Naming

| Type | Format | Example |
|------|--------|---------|
| Daily | `YYMMDD-Daily.md` | `260304-Daily.md` |
| Weekly | `YYMMDD-Weekly.md` | `260303-Weekly.md` (Monday date) |
| Monthly | `YYMM-Monthly-Plan.md` | `2603-Monthly-Plan.md` |
| Annual | `year.md` | `2026.md` |

---

## Creation Flowchart

```
User: "Create document"
    │
    ├─→ Flow Document?
    │   ├─→ Daily → Flow/04-Daily/YYMM/YYMMDD-Daily.md
    │   ├─→ Weekly → Flow/03-Week/YYMM/YYMMDD-Weekly.md
    │   └─→ Monthly → Flow/02-Month/YYMM-Monthly-Plan.md
    │
    └─→ Regular Document?
        └─→ Memory/Out/YYMM/yymmdd-<title>.md
            └─→ Wait for explicit "capture" before migrating to Knowledge
```

---

## Forbidden Actions

❌ **Do NOT auto-migrate**: When user says "create document", don't automatically capture to Knowledge
❌ **Do NOT skip Memory**: Don't create documents directly in Knowledge/2-Outputs/AI/
❌ **Do NOT over-execute**: Analyze → Create document only, don't automatically "also" migrate
