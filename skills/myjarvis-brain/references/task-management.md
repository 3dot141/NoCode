# Task Management Reference

> **When to read this**: When user requests task management operations (create/update tasks, track status, decompose goals, generate summaries).

Task management methodology and workflows.

---

## Hierarchy Structure

```
Annual Plan (Flow/01-Year/)
    │
    ▼
Monthly Plan (Flow/02-Month/)
    │
    ▼
Weekly Log (Flow/03-Week/YYMM/)
    │
    ▼
Daily Log (Flow/04-Daily/YYMM/)
```

**Flow**:
- **Top-down**: Annual goals → Monthly goals → Weekly tasks → Daily actions
- **Bottom-up**: Daily completion → Weekly summary → Monthly review → Annual assessment

---

## Status Definitions

```
[ ] Todo → [/] In Progress → [x] Done
            ↓
      [-] Cancelled/Blocked
```

| Status | Marker | Meaning |
|--------|--------|---------|
| Todo | `[ ]` | Not started, ready to execute |
| In Progress | `[/]` | Currently executing |
| Done | `[x]` | Completed |
| Cancelled | `[-]` | No longer needed or long-term blocked |

---

## Priorities

| Level | Meaning | Time Allocation |
|-------|---------|-----------------|
| P0 | Must complete | 40-50% |
| P1 | Should complete | 30-40% |
| P2 | Can complete | 10-20% |
| P3 | Optional | 0-10% |

---

## Periodic Summary Workflow

### Daily (at end of day)
1. Update completed task status
2. Decide on incomplete tasks: Move to tomorrow or cancel
3. Record blocking issues
4. Draft tomorrow's plan

### Weekly (Sunday evening)
1. Review all daily logs for the week
2. Calculate task completion rate
3. Identify patterns (productive days, blockers)
4. Evaluate monthly goal progress
5. Plan next week's focus

### Monthly (end of month)
1. Review all weekly logs
2. Assess goal completion status
3. Analyze time allocation patterns
4. Adjust next month's plan

---

## Related Documents

- [templates.md](templates.md) - Template quick selection
- [template-daily-quick.md](template-daily-quick.md) - Daily log template
- [template-weekly-quick.md](template-weekly-quick.md) - Weekly log template
- [template-monthly-quick.md](template-monthly-quick.md) - Monthly plan template
