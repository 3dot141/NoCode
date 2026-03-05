# Link Format Specifications

> **When to read this**: When creating or editing documents and you need to know the correct link format.

Rules for creating links in MyJarvis documents.

---

## Required Format

```
✅ REQUIRED: [display text](relative/path)
❌ PROHIBITED: [[...]] wikilink format
```

---

## Rules

1. **Link format**: Use standard Markdown links `[text](path)` exclusively
2. **Path type**: MUST use relative paths (e.g., `../../Memory/Out/2603/xxx.md`)
3. **Display text**: Link text MUST clearly describe target content
4. **Link targets**: ONLY link to actual document files; do NOT link to tasks/items

---

## Correct Examples

```markdown
<!-- Link to weekly log -->
[Weekly Log](Flow/03-Week/2602/260224-Weekly.md)

<!-- Link to generated document -->
[AI Points PRD](Memory/Out/2603/260303-fineReport-ai-points-prd.md)

<!-- Link to attachment with description -->
[System Architecture](../../../Meta/Assets/260228-project-architecture.svg)
```

---

## Incorrect Examples

```markdown
<!-- ❌ Uses wikilink -->
[[Weekly Log]]

<!-- ❌ Task without path -->
[Complete PRD Design]

<!-- ❌ Absolute path -->
[Doc](/Users/yes365/AI/MyJarvis/Memory/Out/2603/doc.md)

<!-- ❌ Wikilink with alias -->
[[Weekly Log|Last Week]]
```

---

## Relative Path Guide

| From | To | Relative Path |
|------|-----|---------------|
| `Flow/04-Daily/2603/` | `Memory/Out/2603/` | `../../Memory/Out/2603/file.md` |
| `Flow/03-Week/2603/` | `Knowledge/2-Outputs/AI/` | `../../Knowledge/2-Outputs/AI/file.md` |
| `Memory/Out/2603/` | `Meta/Assets/` | `../../Meta/Assets/file.svg` |
| `Knowledge/2-Outputs/AI/` | `Memory/Out/2603/` | `../../Memory/Out/2603/file.md` |

---

## Link Types

### Document Links

Link to actual document files only:

```markdown
[Requirements Analysis](Memory/Out/2603/260304-requirements.md)
[API Design](Knowledge/2-Outputs/AI/260301-api-design.md)
```

### Task References

Do NOT link to tasks. Use text description instead:

```markdown
<!-- ❌ Wrong -->
[Complete the design]

<!-- ✅ Correct -->
Complete the design task in today's daily log.
```

### Image/Attachment Links

```markdown
![Architecture Diagram](../../../Meta/Assets/260228-architecture.svg)
```
