---
name: prd
description: "Generate high-quality Product Requirements Documents (PRDs) for software systems and AI-powered features. Use when planning a feature, starting a new project, writing requirements, or when asked to create a PRD. Triggers on: 'create a prd', 'write prd for', 'plan this feature', 'requirements for', 'spec out', '设计 PRD', '写需求文档'."
---

# PRD Generator

Create detailed Product Requirements Documents that are clear, actionable, and suitable for implementation by developers of all levels.

## Workflow

### Step 1: Clarify Requirements

Ask 3-5 essential questions where the initial prompt is ambiguous. Use option format for quick responses:

```
1. What is the primary goal?
   A. Improve user experience
   B. Increase efficiency
   C. Reduce errors
   D. Other: [specify]
```

Focus areas:
- **Problem/Goal**: What problem does this solve?
- **Core Functionality**: What are the key actions?
- **Scope/Boundaries**: What should it NOT do?
- **Success Criteria**: How do we know it is done?

Wait for user answers before proceeding.

### Step 2: Generate PRD

Create PRD with the following structure:

#### 1. Executive Summary
Brief description of the feature and the problem it solves. Keep under 150 words.

#### 2. Goals
Specific, measurable objectives:
- Goal 1
- Goal 2

#### 3. User Stories

Format:
```
### US-001: [Title]
**Description**: As a [user], I want [feature] so that [benefit].

**Acceptance Criteria**:
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] Typecheck/lint passes
- [ ] **[UI stories only]** Verify in browser using agent-browser skill
```

Requirements:
- Number stories sequentially (US-001, US-002)
- Keep stories small and specific
- Acceptance criteria must be verifiable, not vague
- Include UI verification step for any UI changes

#### 4. Functional Requirements

Numbered list (FR-1, FR-2, etc.):
```
**FR-1**: [Requirement description]
- Priority: High/Medium/Low
- Notes: [any clarifications]
```

#### 5. Non-Goals (Out of Scope)

Explicitly state what this feature will NOT include. Critical for managing scope creep.

#### 6. Design Considerations (Optional)

UI/UX requirements, mockup links, component reuse notes.

#### 7. Technical Considerations

- **Constraints**: Technical limitations
- **Dependencies**: External services, libraries
- **Integrations**: APIs, data flows
- **Performance**: Response times, throughput requirements
- **AI-specific**: Model selection, prompt engineering, evaluation metrics (if applicable)

#### 8. Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Description] | High/Medium/Low | High/Medium/Low | [Strategy] |

#### 9. Success Metrics

How will success be measured? Include specific targets where possible.

#### 10. Open Questions

Remaining questions or areas needing clarification.

### Step 3: Save PRD

**Location**: `Memory/Out/YYMM/prd-[feature-name].md`

- Use current year-month for YYMM (e.g., 2603 for March 2026)
- Filename: kebab-case, descriptive
- Follow AGENTS.md formatting rules

## Writing Guidelines

### For Junior Developers

- Be explicit and unambiguous
- Avoid jargon or explain it
- Provide enough detail to understand purpose and core logic
- Number requirements for easy reference
- Use concrete examples where helpful

### AI-Powered Features

When the feature involves AI:

1. **Model Selection**: Document why specific model(s) were chosen
2. **Prompt Strategy**: Outline approach to prompt engineering
3. **Evaluation**: Define how to measure AI output quality
4. **Fallbacks**: Plan for model failures or edge cases
5. **Safety**: Consider bias, misuse, and content filtering

## Checklist

Before saving:
- [ ] Asked clarifying questions with lettered options
- [ ] Incorporated user answers
- [ ] User stories are small and specific with verifiable acceptance criteria
- [ ] Functional requirements numbered and unambiguous
- [ ] Non-goals define clear boundaries
- [ ] Risk analysis completed
- [ ] AI considerations included (if applicable)
- [ ] Saved to correct location following AGENTS.md rules
- [ ] Do NOT start implementation after creating PRD
