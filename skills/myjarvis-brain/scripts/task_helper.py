#!/usr/bin/env python3
"""
Task Management Helper for MyJarvis-Brain

Utilities for task operations, status tracking, and decomposition.
"""

import re
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Optional, Tuple


class TaskStatus:
    """Task status definitions."""
    TODO = " "
    IN_PROGRESS = "/"
    DONE = "x"
    CANCELLED = "-"


class TaskManager:
    """Manager for task operations."""

    STATUS_MAP = {
        " ": "Todo",
        "/": "In Progress",
        "x": "Done",
        "-": "Cancelled"
    }

    VALID_TRANSITIONS = {
        " ": ["/", "x", "-"],      # Todo → In Progress, Done, Cancelled
        "/": ["x", "-", " "],      # In Progress → Done, Cancelled, Todo
        "x": [],                    # Done → (no transitions, create new task)
        "-": []                     # Cancelled → (no transitions, create new task)
    }

    @staticmethod
    def parse_task_line(line: str) -> Optional[dict]:
        """
        Parse a task line from markdown.

        Args:
            line: A markdown line potentially containing a task

        Returns:
            Dict with task info or None if not a task line
        """
        # Match patterns:
        # - [ ] task text
        # - [/] task text
        # - [x] task text
        # - [-] task text
        # - [ ] task text | priority | other info
        pattern = r'^[\s]*- \[([ /x-])\] (.+)$'
        match = re.match(pattern, line)

        if not match:
            return None

        status = match.group(1)
        content = match.group(2)

        # Parse metadata after | if present
        parts = [p.strip() for p in content.split('|')]
        task_text = parts[0]
        metadata = parts[1:] if len(parts) > 1 else []

        return {
            "status": status,
            "text": task_text,
            "metadata": metadata,
            "original_line": line
        }

    @staticmethod
    def update_task_status(line: str, new_status: str) -> str:
        """
        Update the status of a task line.

        Args:
            line: Original task line
            new_status: New status character ( , /, x, -)

        Returns:
            Updated task line
        """
        task = TaskManager.parse_task_line(line)
        if not task:
            return line

        return line.replace(f"[{task['status']}]", f"[{new_status}]")

    @staticmethod
    def is_valid_transition(current: str, new: str) -> bool:
        """Check if status transition is valid."""
        return new in TaskManager.VALID_TRANSITIONS.get(current, [])

    @staticmethod
    def get_completion_stats(content: str) -> dict:
        """
        Get task completion statistics from content.

        Args:
            content: Markdown content

        Returns:
            Dict with task counts
        """
        lines = content.split('\n')
        stats = {
            "total": 0,
            "todo": 0,
            "in_progress": 0,
            "done": 0,
            "cancelled": 0
        }

        for line in lines:
            task = TaskManager.parse_task_line(line)
            if task:
                stats["total"] += 1
                status = task["status"]
                if status == TaskStatus.TODO:
                    stats["todo"] += 1
                elif status == TaskStatus.IN_PROGRESS:
                    stats["in_progress"] += 1
                elif status == TaskStatus.DONE:
                    stats["done"] += 1
                elif status == TaskStatus.CANCELLED:
                    stats["cancelled"] += 1

        return stats


class DateHelper:
    """Helper for date calculations."""

    @staticmethod
    def get_week_start(date: datetime) -> datetime:
        """Get Monday of the week for a given date."""
        return date - timedelta(days=date.weekday())

    @staticmethod
    def get_week_end(date: datetime) -> datetime:
        """Get Sunday of the week for a given date."""
        return DateHelper.get_week_start(date) + timedelta(days=6)

    @staticmethod
    def format_yymmdd(date: datetime) -> str:
        """Format date as YYMMDD."""
        return date.strftime("%y%m%d")

    @staticmethod
    def format_yymm(date: datetime) -> str:
        """Format date as YYMM."""
        return date.strftime("%y%m")

    @staticmethod
    def parse_yymmdd(date_str: str) -> Optional[datetime]:
        """Parse YYMMDD string to datetime."""
        try:
            # Assume 20xx for years
            year = 2000 + int(date_str[:2])
            month = int(date_str[2:4])
            day = int(date_str[4:6])
            return datetime(year, month, day)
        except (ValueError, IndexError):
            return None


class PathHelper:
    """Helper for path calculations."""

    @staticmethod
    def get_daily_path(base_path: Path, date: datetime) -> Path:
        """Get path for daily log."""
        yymm = DateHelper.format_yymm(date)
        yymmdd = DateHelper.format_yymmdd(date)
        return base_path / "Flow" / "04-Daily" / yymm / f"{yymmdd}-日记.md"

    @staticmethod
    def get_weekly_path(base_path: Path, date: datetime) -> Path:
        """Get path for weekly note (uses Monday's date)."""
        week_start = DateHelper.get_week_start(date)
        yymm = DateHelper.format_yymm(week_start)
        yymmdd = DateHelper.format_yymmdd(week_start)
        return base_path / "Flow" / "03-Week" / yymm / f"{yymmdd}-周记.md"

    @staticmethod
    def get_monthly_path(base_path: Path, date: datetime) -> Path:
        """Get path for monthly plan."""
        yymm = DateHelper.format_yymm(date)
        return base_path / "Flow" / "02-Month" / f"{yymm}-月度计划.md"

    @staticmethod
    def get_annual_path(base_path: Path, year: int) -> Path:
        """Get path for annual plan."""
        return base_path / "Flow" / "01-Year" / "year.md"

    @staticmethod
    def get_knowledge_path(base_path: Path, date: datetime, title: str) -> Path:
        """Get path for knowledge document."""
        yymmdd = DateHelper.format_yymmdd(date)
        # Convert title to kebab-case
        kebab_title = re.sub(r'[^\w\s-]', '', title.lower())
        kebab_title = re.sub(r'[-\s]+', '-', kebab_title).strip('-')
        return base_path / "Knowledge" / "2-Outputs" / "AI" / f"{yymmdd}-{kebab_title}.md"


class TaskDecomposer:
    """Helper for task decomposition."""

    @staticmethod
    def decompose_goal(goal: str, level: str) -> List[str]:
        """
        Generate sub-tasks for a goal based on level.

        Args:
            goal: The goal text
            level: 'annual', 'monthly', 'weekly', or 'daily'

        Returns:
            List of suggested sub-tasks
        """
        templates = {
            "annual": [
                f"分解 {goal} 为季度里程碑",
                f"制定 {goal} 的执行策略",
                f"识别 {goal} 所需资源",
                f"设定 {goal} 的检查点"
            ],
            "monthly": [
                f"将 {goal} 分解为周任务",
                f"确定 {goal} 的关键路径",
                f"分配 {goal} 的时间预算",
                f"准备 {goal} 的验收标准"
            ],
            "weekly": [
                f"将 {goal} 分解为每日行动",
                f"估算 {goal} 各子任务时间",
                f"识别 {goal} 的依赖项",
                f"设置 {goal} 的优先级"
            ],
            "daily": [
                f"开始执行: {goal}",
                f"记录 {goal} 的进展",
                f"解决 {goal} 的阻塞",
                f"完成 {goal} 的验收"
            ]
        }

        return templates.get(level, [f"分解: {goal}"])


class LinkGenerator:
    """Helper for generating Obsidian wikilinks."""

    @staticmethod
    def generate_link(target: str, display: Optional[str] = None) -> str:
        """Generate a wikilink."""
        if display:
            return f"[[{target}|{display}]]"
        return f"[[{target}]]"

    @staticmethod
    def generate_heading_link(target: str, heading: str, display: Optional[str] = None) -> str:
        """Generate a wikilink to a heading."""
        link_target = f"{target}#{heading}"
        if display:
            return f"[[{link_target}|{display}]]"
        return f"[[{link_target}]]"


def main():
    """Demo/test function."""
    # Test task parsing
    test_lines = [
        "- [ ] 这是一个待办任务",
        "- [/] 这是一个进行中的任务",
        "- [x] 这是一个已完成的任务",
        "- [-] 这是一个取消的任务",
        "- [ ] 带元数据的任务 | P0 | 预计2小时",
        "普通文本，不是任务"
    ]

    print("=== Task Parsing Demo ===")
    for line in test_lines:
        task = TaskManager.parse_task_line(line)
        if task:
            print(f"Parsed: {task}")
        else:
            print(f"Not a task: {line}")

    # Test completion stats
    test_content = """
# 测试文档

## 任务列表
- [ ] 任务1
- [/] 任务2
- [x] 任务3
- [ ] 任务4
- [-] 任务5
- [x] 任务6
"""
    print("\n=== Completion Stats Demo ===")
    stats = TaskManager.get_completion_stats(test_content)
    print(f"Stats: {stats}")
    print(f"Completion rate: {stats['done']}/{stats['total']} ({stats['done']/stats['total']*100:.1f}%)")

    # Test date calculations
    print("\n=== Date Helper Demo ===")
    today = datetime.now()
    print(f"Today: {today.strftime('%Y-%m-%d')}")
    print(f"Week start (Monday): {DateHelper.get_week_start(today).strftime('%Y-%m-%d')}")
    print(f"Week end (Sunday): {DateHelper.get_week_end(today).strftime('%Y-%m-%d')}")
    print(f"YYMMDD: {DateHelper.format_yymmdd(today)}")
    print(f"YYMM: {DateHelper.format_yymm(today)}")

    # Test task decomposition
    print("\n=== Task Decomposition Demo ===")
    goal = "发布新产品功能"
    for level in ["annual", "monthly", "weekly", "daily"]:
        subtasks = TaskDecomposer.decompose_goal(goal, level)
        print(f"\n{level} level:")
        for task in subtasks:
            print(f"  - {task}")


if __name__ == "__main__":
    main()
