---
name: myjarvis-brain
description: Comprehensive personal knowledge and task management for MyJarvis Obsidian system. Combines hierarchical task lifecycle management (annual → monthly → weekly → daily) with knowledge capture workflows. Use when users need to create or manage plan documents, track task status, decompose goals, generate periodic summaries, or migrate/capture knowledge from Memory to Knowledge. Triggers on phrases like "创建计划", "管理任务", "总结", "沉淀知识", "迁移文档", "创建日记/周记".
---

# MyJarvis Brain Enhanced

Comprehensive personal knowledge and task management for the MyJarvis Obsidian-based knowledge system.

## Overview

This skill provides two integrated modules:

1. **Task Management**: Hierarchical planning from annual vision to daily execution
2. **Knowledge Capture**: Structured migration and creation of permanent knowledge

The skill uses smart intent recognition—no specific trigger words required. It understands natural requests for planning, task tracking, summarization, and knowledge management.

## Core Capabilities

### 1. Task Management

**Four-Level Hierarchy** (top-down planning, bottom-up summary):

| Level | Directory | Purpose | Template Focus |
|-------|-----------|---------|----------------|
| Annual | `Flow/01-Year/` | Vision and key objectives | Goals, milestones, themes |
| Monthly | `Flow/02-Month/` | Monthly planning | Goals derived from annual plan |
| Weekly | `Flow/03-Week/YYMM/` | Week execution | Tasks, time allocation, focus areas |
| Daily | `Flow/04-Daily/YYMM/` | Daily logs | Actionable tasks, quick notes |

**Supported Operations**:
- Create/update plan documents at any level
- Track task status (Todo → In Progress → Done)
- Decompose high-level goals into subtasks
- Generate periodic summaries (daily/weekly/monthly)
- Link tasks across hierarchy levels
- Set deadlines and priorities

### 2. Knowledge Capture

**文档创建原则**：所有新文档必须首先在 `Memory/Out/` 中创建。

| 操作类型 | 创建位置 | 说明 |
|----------|----------|------|
| 新文档创建 | `Memory/Out/YYMM/` | 所有新生成的文档必须放在此处 |
| 知识库迁移 | `Knowledge/2-Outputs/AI/` | 仅当用户明确说"沉淀到知识库"时才执行 |

**Supported Operations**:
- 在 Memory/Out 中创建新文档
- 将 Memory/Out 文档迁移到 Knowledge（需用户明确指示）
- Add categories and tags
- Create knowledge links (`[[concept]]`)
- Batch capture during plan summaries

## Workflow Decision Tree

```
User Request
    │
    ├─→ Task/Planning related?
    │   ├─→ Create plan document → Use task-management.md templates
    │   ├─→ Update task status → Modify existing document
    │   ├─→ Decompose goal → Create linked sub-tasks
    │   ├─→ Generate summary → Compile from lower-level documents
    │   └─→ Create diary/weekly note → Use daily/weekly templates
    │
    └─→ Knowledge/Document related?
        ├─→ Create new document → Create in Memory/Out/YYMM/ (default location)
        ├─→ Migrate to Knowledge → Only when user explicitly says "沉淀到知识库"
        └─→ Batch capture → Create in Memory/Out first, then offer to migrate
```

## Quick Start

### Creating a Plan Document

```markdown
User: "帮我创建3月的月度计划"
→ Create Flow/02-Month/2603-月度计划.md using monthly template
→ Check Flow/01-Year/year.md for context
→ Extract relevant annual goals
```

### Tracking Tasks

```markdown
User: "标记今天的前端开发任务已完成"
→ Open today's daily log (Flow/04-Daily/YYMM/YYMMDD-日记.md)
→ Find the task
→ Update status from [ ] to [x]
→ Add completion note if needed
```

### Creating Documents

```markdown
User: "帮我分析这个需求并生成文档"
→ Create document in Memory/Out/YYMM/yymmdd-<title>.md
→ Add proper frontmatter and structure
→ Save to Memory/Out only (do NOT auto-migrate to Knowledge)
```

### Migrating Knowledge (Explicit Only)

```markdown
User: "把 Memory/Out 里关于 React 的笔记整理到知识库"
→ Locate Memory/Out/YYMM/ 中的相关文档
→ Review and refine content
→ Create Knowledge/2-Outputs/AI/yymmdd-react-xxx.md
→ Add source reference and tags
→ Add backlinks in original document
→ Note: Only do this when user explicitly requests migration
```

## Module References

### Task Management
See [references/task-management.md](references/task-management.md) for:
- Detailed workflow patterns
- Status definitions and transitions
- Document templates for each level
- Cross-level linking conventions

### Knowledge Capture
See [references/knowledge-capture.md](references/knowledge-capture.md) for:
- Migration rules and procedures
- Document naming conventions
- Categorization guidelines
- Linking patterns

### Templates
See [references/templates.md](references/templates.md) for:
- Annual plan template
- Monthly plan template
- Weekly note template
- Daily log template
- Knowledge document template

## File Naming Conventions

**Flow Documents**:
- Weekly: `YYMMDD-周记.md` (Monday's date)
- Daily: `YYMMDD-日记.md`
- Monthly: `YYMM-月度计划.md`
- Annual: `year.md`

**Knowledge Documents**:
- `yymmdd-<kebab-case-description>.md`
- Example: `260302-react-hooks-guide.md`

**Memory Documents**:
- `yymmdd-<description>.md`

## Integration Points

### Task → Knowledge
During periodic summaries (especially weekly/monthly):
1. Review completed tasks
2. Identify insights worth preserving
3. Offer to capture as knowledge documents
4. Link back to originating tasks

### Knowledge → Task
When planning:
1. Reference relevant knowledge documents
2. Identify gaps requiring new tasks
3. Create discovery/learning tasks

## Common Phrase Patterns

The skill recognizes these intent patterns:

**Task Management**:
- "创建/生成 [年/月/周/日] [计划/总结/日记/周记]"
- "添加/更新/完成 任务"
- "分解/拆分 目标"
- "总结/回顾 [本周/本月]"

**Document Creation**:
- "创建/生成 文档" → Always create in Memory/Out/ first
- "创建知识文档" → Create in Memory/Out/ (do NOT auto-migrate)

**Knowledge Migration** (only when explicitly requested):
- "沉淀到知识库"
- "迁移到 Knowledge"
- "把 [Memory/某文档] 整理到知识库"

## Resources

### scripts/
- `task_helper.py`: Utilities for task operations, status tracking, decomposition
- `knowledge_helper.py`: Utilities for migration, linking, categorization

### references/
- `task-management.md`: Detailed task workflows and patterns
- `knowledge-capture.md`: Knowledge migration and creation guidelines
- `templates.md`: Document templates for all levels

### assets/
- None required (uses Obsidian-native templates)

---

**Note**: This skill extends existing myjarvis-brain functionality. It maintains backward compatibility while adding structured task hierarchy and integrated knowledge capture capabilities.
