# Knowledge Capture Reference

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

**默认文档创建位置**: `Memory/Out/YYMM/`  
**知识库存储位置**: `Knowledge/2-Outputs/AI/` (仅迁移时使用)

---

## Document Creation Rule

**核心原则**：所有新文档必须首先在 `Memory/Out/` 中创建。

### 默认创建流程

**Flow**: Input → `Memory/Out/YYMM/`

**When to use** (默认情况，适用于所有新文档生成):
- 用户要求"创建文档"、"生成文档"
- 分析内容后输出文档
- 整合多个来源生成新文档

**Procedure**:
1. Gather and analyze source material
2. Create structured document
3. Save to `Memory/Out/YYMM/yymmdd-<description>.md`
4. Add appropriate frontmatter and tags
5. **Do NOT auto-migrate to Knowledge**

### Migration to Knowledge (Explicit Only)

**Flow**: `Memory/Out/` → `Knowledge/2-Outputs/AI/`

**When to use** (仅当用户明确指示时):
- 用户说"沉淀到知识库"
- 用户说"迁移到 Knowledge"
- 用户明确指定将 Memory/Out 文档整理到知识库

**Procedure**:
1. Locate source document(s) in `Memory/Out/YYMM/`
2. Review and consolidate content
3. Reorganize into structured format
4. Create in `Knowledge/2-Outputs/AI/` with proper naming
5. Add `source` frontmatter field linking to original
6. Add backlink in original Memory document
7. Mark original as "已迁移" if appropriate

### 禁止行为

❌ **不要自动迁移**：用户说"创建文档"时，不要自动沉淀到 Knowledge  
❌ **不要跳过 Memory**：不要直接创建文档到 Knowledge/2-Outputs/AI/  
❌ **不要过度执行**：分析 → 创建文档 即可，不要自动"顺便"迁移

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
  - 别名1
  - 别名2
draft: false                # true = work in progress, false = finalized
tags:                       # Taxonomy tags
  - 技术/React
  - 概念/架构
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
project: "项目名称"
phase: "设计阶段"

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
# 概念名称

## 一句话定义
[核心概念的简明定义]

## 详细解释
[深入阐述]

## 为什么重要
[价值和应用场景]

## 关键要素
- 要素1: [说明]
- 要素2: [说明]

## 相关概念
- [[相关概念1]]
- [[相关概念2]]

## 实际案例
[具体例子]

## 参考资源
- [资源名称](链接)
```

### Type 2: How-To/Guide

```markdown
# 操作名称

## 目标
[要完成什么]

## 前提条件
- [ ] 条件1
- [ ] 条件2

## 步骤

### 步骤1: [名称]
[详细操作]
```代码示例```

### 步骤2: [名称]
...

## 验证
[如何确认成功]

## 常见问题

### 问题1
**解决方案**: [说明]

## 相关操作
- [[相关操作1]]
```

### Type 3: Reference/Documentation

```markdown
# 主题参考

## 快速参考表
| 字段 | 类型 | 说明 |
|------|------|------|
| ... | ... | ... |

## 详细说明

### 部分1
[内容]

### 部分2
[内容]

## 示例
```代码/示例```

## 版本历史
| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 日期 | 初始版本 |
```

### Type 4: Experience/Retrospective

```markdown
# 经历/项目回顾

## 背景
[项目/经历的上下文]

## 目标
[原定目标]

## 过程
[关键阶段和决策]

## 结果
[最终成果]

## 关键收获
- 收获1: [说明]
- 收获2: [说明]

## 可复用的模式
- 模式1: [说明]

## 改进点
- [ ] 改进1
- [ ] 改进2

## 相关项目
- [[相关项目]]
```

---

## Tag Taxonomy

### Format
Tags use hierarchy with `/` separator:
```yaml
tags:
  - 领域/子领域
  - 类型/子类型
  - 状态/当前状态
```

### Recommended Taxonomy

**Domain (领域)**:
- `技术/前端`, `技术/后端`, `技术/DevOps`
- `技术/语言/JavaScript`, `技术/语言/Python`
- `技术/框架/React`, `技术/框架/Vue`
- `产品/需求`, `产品/设计`, `产品/分析`
- `管理/项目`, `管理/团队`, `管理/流程`
- `个人/效率`, `个人/学习`, `个人/健康`

**Type (类型)**:
- `类型/概念` - Theoretical concepts
- `类型/实践` - Practical experiences
- `类型/教程` - Step-by-step guides
- `类型/参考` - Reference documentation
- `类型/回顾` - Retrospectives
- `类型/决策` - Decision records

**Status (状态)**:
- `状态/草稿` - Work in progress
- `状态/已验证` - Verified and tested
- `状态/归档` - Historical, may be outdated

**Priority (优先级)**:
- `优先级/核心` - Core knowledge, frequently referenced
- `优先级/重要` - Important but secondary
- `优先级/一般` - Nice to have

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

**Conceptual links** (思想关联):
```markdown
这个概念与 [[相关概念]] 密切相关。
```

**Sequential links** (流程关联):
```markdown
完成后，继续 [[下一步操作]]。
```

**Source links** (来源关联):
```markdown
源自 [[原始文档]] 的深入分析。
```

**Application links** (应用关联):
```markdown
这个模式在 [[实际项目]] 中得到了应用。
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

1. Review all "知识沉淀候选" sections from daily/weekly notes
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
