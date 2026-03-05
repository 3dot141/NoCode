# Knowledge Capture Reference

> **When to read this**: When migrating content to Knowledge or creating permanent knowledge documents.

Guidelines for migrating and creating permanent knowledge in the MyJarvis Knowledge system.

---

## Knowledge Architecture

```
Knowledge/
├── 2-Outputs/
│   ├── AI/                    # AI-enhanced/organized knowledge
│   ├── Card/                  # Atomic knowledge cards
│   └── MOC/                   # Maps of Content (topic indexes)
├── 0-About/                   # System documentation
├── 1-Inputs/                  # Curated external inputs
└── 4-Outcomes/                # Final outputs
```

**Default document creation location**: `Memory/Out/YYMM/`
**Knowledge storage location**: `Knowledge/2-Outputs/AI/` (only for migration)

---

## Document Creation Rule

**Core Principle**: All new documents must first be created in `Memory/Out/`.

### Default Creation Flow

**Flow**: Input → `Memory/Out/YYMM/`

**When to use** (default case, applies to all new document generation):
- User requests "create document" or "generate document"
- Analyzing content and outputting documents
- Integrating multiple sources to generate new documents

**Procedure**:
1. Gather and analyze source material
2. Create structured document
3. Save to `Memory/Out/YYMM/yymmdd-<description>.md`
4. Add appropriate frontmatter and tags
5. **Do NOT auto-migrate to Knowledge**

### Migration to Knowledge (Explicit Only)

**Flow**: `Memory/Out/` → `Knowledge/2-Outputs/AI/`

**When to use** (only when user explicitly instructs):
- User says "capture to Knowledge"
- User says "migrate to Knowledge"
- User explicitly requests organizing Memory/Out documents into Knowledge

**Procedure**:
1. Locate source document(s) in `Memory/Out/YYMM/`
2. Review and consolidate content
3. Reorganize into structured format
4. Create in `Knowledge/2-Outputs/AI/` with proper naming
5. Add `source` frontmatter field linking to original
6. Add backlink in original Memory document
7. Mark original as "migrated" if appropriate

### Forbidden Actions

❌ **Don't auto-migrate**: When user says "create document", don't automatically capture to Knowledge
❌ **Don't skip Memory**: Don't create documents directly in Knowledge/2-Outputs/AI/
❌ **Don't over-execute**: Analyze → Create document only, don't automatically "also" migrate

---

## Document Naming Conventions

### Standard Format

```
yymmdd-<kebab-case-description>.md
```

**Components**:
- `yymmdd`: Date (e.g., `260302` for 2026-03-02)
- `kebab-case-description`: Short, descriptive name
  - Lowercase
  - Words separated by hyphens
  - No articles (a, an, the)
  - Be specific but concise

**Examples**:
- ✅ `260302-react-hooks-guide.md`
- ✅ `260228-project-retrospective.md`
- ✅ `260315-api-design-patterns.md`
- ❌ `react guide.md` (missing date, contains space)
- ❌ `260302-a-guide-to-react.md` (contains "a")

### Special Cases

**Series documents**:
```
260302-react-hooks-part1.md
260302-react-hooks-part2.md
```

**Updated versions**:
```
260302-react-hooks-v2.md
```

---

## Frontmatter Standards

### Required Fields

```yaml
---
aliases:                    # Alternative names for this concept
  - alias1
  - alias2
draft: false                # true = work in progress, false = finalized
tags:                       # Taxonomy tags
  - tech/React
  - concept/Architecture
created_date: YYYY-MM-DD HH:MM
modified_date: YYYY-MM-DD HH:MM
summary: "One-line description of the content"
permalink: posts/{uuid()}   # Unique identifier for external linking
---
```

### Optional Fields

```yaml
---
# For migrated content
source: "Memory/Out/2602/260228-original-note.md"

# For technical knowledge
tech_stack:
  - React
  - TypeScript

# For project knowledge
project: "Project Name"
phase: "Design Phase"

# For learning resources
resource_type: tutorial|reference|concept|howto
difficulty: beginner|intermediate|advanced
estimated_time: "30 minutes"

# For relationships
related:
  - "[[related-doc-1]]"
  - "[[related-doc-2]]"
prerequisites:
  - "[[prereq-1]]"
  - "[[prereq-2]]"
---
```

---

## Content Structure Templates

### Type 1: Concept/Theory

```markdown
# Concept Name

## One-sentence Definition
[Core concept concise definition]

## Detailed Explanation
[In-depth elaboration]

## Why It Matters
[Value and application scenarios]

## Key Elements
- Element 1: [description]
- Element 2: [description]

## Related Concepts
- [[Related Concept 1]]
- [[Related Concept 2]]

## Real-world Examples
[Specific examples]

## Reference Resources
- [Resource Name](link)
```

### Type 2: How-To/Guide

```markdown
# Operation Name

## Goal
[What to accomplish]

## Prerequisites
- [ ] Condition 1
- [ ] Condition 2

## Steps

### Step 1: [Name]
[Detailed operation]
```code example```

### Step 2: [Name]
...

## Verification
[How to confirm success]

## Common Issues

### Issue 1
**Solution**: [description]

## Related Operations
- [[Related Operation 1]]
```

### Type 3: Reference/Documentation

```markdown
# Topic Reference

## Quick Reference Table
| Field | Type | Description |
|-------|------|-------------|
| ... | ... | ... |

## Detailed Explanation

### Section 1
[Content]

### Section 2
[Content]

## Examples
```code/example```

## Version History
| Version | Date | Changes |
|---------|------|---------|
| v1.0 | Date | Initial version |
```

### Type 4: Experience/Retrospective

```markdown
# Experience/Project Retrospective

## Background
[Project/experience context]

## Goals
[Original goals]

## Process
[Key phases and decisions]

## Results
[Final outcomes]

## Key Takeaways
- Takeaway 1: [description]
- Takeaway 2: [description]

## Reusable Patterns
- Pattern 1: [description]

## Improvements
- [ ] Improvement 1
- [ ] Improvement 2

## Related Projects
- [[Related Project]]
```

---

## Tag Taxonomy

### Format
Tags use hierarchy with `/` separator:
```yaml
tags:
  - domain/subdomain
  - type/subtype
  - status/current_status
```

### Recommended Taxonomy

**Domain**:
- `tech/frontend`, `tech/backend`, `tech/DevOps`
- `tech/language/JavaScript`, `tech/language/Python`
- `tech/framework/React`, `tech/framework/Vue`
- `product/requirements`, `product/design`, `product/analysis`
- `management/project`, `management/team`, `management/process`
- `personal/productivity`, `personal/learning`, `personal/health`

**Type**:
- `type/concept` - Theoretical concepts
- `type/practice` - Practical experiences
- `type/tutorial` - Step-by-step guides
- `type/reference` - Reference documentation
- `type/retrospective` - Retrospectives
- `type/decision` - Decision records

**Status**:
- `status/draft` - Work in progress
- `status/verified` - Verified and tested
- `status/archived` - Historical, may be outdated

**Priority**:
- `priority/core` - Core knowledge, frequently referenced
- `priority/important` - Important but secondary
- `priority/general` - Nice to have

---

## Linking Patterns

### Internal Links (Wikilinks)

Use Obsidian wikilink format:
```markdown
[[target-document]]
[[target-document|display text]]
[[target-document#heading]]
[[target-document#heading|display text]]
```

### Link Types

**Conceptual links** (thought connections):
```markdown
This concept is closely related to [[Related Concept]].
```

**Sequential links** (process connections):
```markdown
After completion, proceed to [[Next Step]].
```

**Source links** (origin connections):
```markdown
In-depth analysis derived from [[Original Document]].
```

**Application links** (usage connections):
```markdown
This pattern was applied in [[Actual Project]].
```

### Link Graph Maintenance

**Good practices**:
- Every knowledge document should have at least 2-3 outbound links
- Every knowledge document should be linked from at least 1 other document
- Use aliases for concepts with multiple names
- Create MOC (Map of Content) documents for topic clusters

---

## Migration Checklist

Before considering a Memory document ready for migration:

- [ ] Content is complete (not placeholder/draft)
- [ ] Key insights are extracted and highlighted
- [ ] Format is clean and structured
- [ ] Links are working (not broken)
- [ ] Tags are appropriate
- [ ] Source is cited if external
- [ ] Backward link added in original

---

## Batch Knowledge Capture

During periodic summaries (weekly/monthly):

1. Review all "knowledge capture candidates" sections from daily/weekly notes
2. Group related candidates together
3. For each group:
   - Determine if worth preserving
   - Choose appropriate template type
   - Create consolidated knowledge document
   - Add cross-references
4. Update source documents with links to created knowledge

---

## Quality Standards

### Good Knowledge Document

- ✅ Clear, specific title
- ✅ Complete frontmatter
- ✅ Single focus (one concept/topic per doc)
- ✅ Well-structured with headings
- ✅ Includes examples
- ✅ Has relevant links
- ✅ Tagged appropriately
- ✅ Written for future self (clear even after months)

### Poor Knowledge Document

- ❌ Vague or overly broad title
- ❌ Missing frontmatter
- ❌ Multiple unrelated topics
- ❌ Wall of text without structure
- ❌ No examples
- ❌ Orphaned (no links in or out)
- ❌ Untagged or mis-tagged
- ❌ Context-dependent (won't make sense later)
