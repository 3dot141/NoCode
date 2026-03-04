# MyJarvis-Brain Enhanced Design Document

**Date**: 2026-03-02
**Status**: Draft
**Skill Name**: myjarvis-brain-enhanced

---

## 1. Purpose

This skill provides comprehensive personal knowledge and task management capabilities for the MyJarvis Obsidian-based knowledge system. It combines task lifecycle management (annual → monthly → weekly → daily) with knowledge capture and沉淀 workflows, enabling seamless integration between planning, execution, and learning.

---

## 2. Core Capabilities

### 2.1 Task Management Module

**Hierarchy Structure**:
- **Annual** (`Flow/01-Year/`): Vision, key objectives, milestones
- **Monthly** (`Flow/02-Month/`): Monthly goals derived from annual plan
- **Weekly** (`Flow/03-Week/`): Week notes with task breakdown
- **Daily** (`Flow/04-Daily/`): Daily logs with actionable tasks

**Key Features**:
1. **Document Creation**: Generate structured plan documents at each level
2. **Status Tracking**: Todo → In Progress → Done (or custom states)
3. **Task Decomposition**: Break down high-level goals into actionable tasks
4. **Plan Summary**: Generate periodic reviews (daily/weekly/monthly)
5. **Cross-Level Linking**: Associate daily tasks with weekly goals, weekly with monthly, etc.
6. **Scheduling**: Set deadlines, priorities, and reminders

**Workflow Direction**: Bidirectional (Top-down planning + Bottom-up summary)

**Templates**: Level-specific templates optimized for each planning horizon

### 2.2 Knowledge Capture Module

**Sources**:
- Memory/Out migration
- Direct creation in Knowledge/
- External inputs (web, documents)

**Key Features**:
1. **Migration**: Move polished notes from Memory/Out to Knowledge/2-Outputs/AI/
2. **Direct Creation**: Create structured knowledge documents without Memory intermediate
3. **Multi-Source Integration**: Aggregate knowledge from various inputs
4. **Categorization & Tagging**: Organize knowledge with taxonomy
5. **Knowledge Linking**: Create connections between related concepts (`[[link]]`)
6. **Task Integration**: Batch knowledge capture during plan summaries

**Capture Timing**: Batch processing during periodic reviews (not interruptive)

---

## 3. Trigger Mechanism

**Approach**: Smart Intent Recognition

The skill activates based on natural language understanding without requiring specific trigger words. Examples:

- "帮我创建这周的计划" → Task Management
- "把这篇笔记整理到知识库" → Knowledge Capture
- "总结一下这周的任务完成情况" → Plan Summary
- "将 Memory 里的文档迁移到 Knowledge" → Knowledge Migration

---

## 4. File Organization

```
MyJarvis Knowledge System:
├── Flow/
│   ├── 01-Year/              # Annual planning
│   ├── 02-Month/             # Monthly planning
│   ├── 03-Week/YYMM/         # Weekly notes
│   └── 04-Daily/YYMM/        # Daily logs
├── Memory/
│   ├── In/YYMM/              # External inputs
│   ├── Fleeting/YYMM/        # Quick thoughts
│   └── Out/YYMM/             # Processed outputs
└── Knowledge/
    └── 2-Outputs/AI/         # Permanent knowledge
```

---

## 5. Module Interactions

### Task → Knowledge Flow
1. User completes tasks during the week
2. During weekly summary, review completed tasks
3. Identify valuable insights/experiences
4. Batch capture as knowledge documents
5. Link knowledge to originating tasks

### Knowledge → Task Flow
1. User references knowledge while planning
2. Create tasks based on knowledge gaps
3. Schedule learning/discovery tasks

---

## 6. Reference Files Structure

The skill will include:

1. **references/task-management.md**: Detailed task workflow, status definitions, template structures
2. **references/knowledge-capture.md**: Knowledge migration rules, categorization guidelines, linking patterns
3. **references/templates.md**: Document templates for each level (year/month/week/day)
4. **scripts/task_helper.py**: Utility functions for task operations
5. **scripts/knowledge_helper.py**: Utility functions for knowledge operations

---

## 7. Implementation Notes

- Preserve existing myjarvis-brain functionality
- Add new capabilities as extensions
- Maintain backward compatibility
- Follow Obsidian-flavored Markdown conventions
- Use relative paths for all internal links
- Support YAML frontmatter with standard fields

---

## 8. Success Criteria

- [ ] Can create structured plan documents at all 4 levels
- [ ] Can track task status and perform state transitions
- [ ] Can decompose tasks across hierarchy levels
- [ ] Can generate periodic summaries
- [ ] Can migrate content from Memory to Knowledge
- [ ] Can create knowledge documents with proper linking
- [ ] Smart intent recognition works for common phrases
- [ ] Maintains compatibility with existing workflows
