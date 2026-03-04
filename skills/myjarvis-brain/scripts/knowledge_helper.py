#!/usr/bin/env python3
"""
Knowledge Capture Helper for MyJarvis-Brain

Utilities for migration, linking, and categorization.
"""

import re
import uuid
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict, Any
import yaml


class FrontmatterHelper:
    """Helper for YAML frontmatter operations."""

    @staticmethod
    def parse_frontmatter(content: str) -> Tuple[Optional[Dict], str]:
        """
        Parse YAML frontmatter from markdown content.

        Args:
            content: Markdown content

        Returns:
            Tuple of (frontmatter_dict, body_content)
        """
        if not content.startswith('---'):
            return None, content

        parts = content.split('---', 2)
        if len(parts) < 3:
            return None, content

        try:
            frontmatter = yaml.safe_load(parts[1])
            body = parts[2].strip()
            return frontmatter, body
        except yaml.YAMLError:
            return None, content

    @staticmethod
    def generate_frontmatter(data: Dict[str, Any]) -> str:
        """
        Generate YAML frontmatter string.

        Args:
            data: Frontmatter data

        Returns:
            YAML frontmatter string
        """
        yaml_content = yaml.dump(data, allow_unicode=True, sort_keys=False)
        return f"---\n{yaml_content}---\n"

    @staticmethod
    def update_frontmatter(content: str, updates: Dict[str, Any]) -> str:
        """
        Update frontmatter in content.

        Args:
            content: Original markdown content
            updates: Fields to update

        Returns:
            Updated content
        """
        frontmatter, body = FrontmatterHelper.parse_frontmatter(content)

        if frontmatter is None:
            frontmatter = {}

        frontmatter.update(updates)
        # Always update modified_date
        frontmatter['modified_date'] = datetime.now().strftime('%Y-%m-%d %H:%M')

        return FrontmatterHelper.generate_frontmatter(frontmatter) + body


class NamingHelper:
    """Helper for document naming conventions."""

    @staticmethod
    def to_kebab_case(text: str) -> str:
        """
        Convert text to kebab-case.

        Args:
            text: Input text

        Returns:
            Kebab-case text
        """
        # Remove special characters, keep alphanumeric and spaces/hyphens
        text = re.sub(r'[^\w\s-]', '', text.lower())
        # Replace spaces and multiple hyphens with single hyphen
        text = re.sub(r'[-\s]+', '-', text).strip('-')
        # Remove articles
        articles = ['a-', 'an-', 'the-']
        for article in articles:
            if text.startswith(article):
                text = text[len(article):]
        return text

    @staticmethod
    def generate_knowledge_filename(date: datetime, title: str) -> str:
        """
        Generate filename for knowledge document.

        Args:
            date: Document date
            title: Document title

        Returns:
            Filename (without path)
        """
        yymmdd = date.strftime("%y%m%d")
        kebab_title = NamingHelper.to_kebab_case(title)
        return f"{yymmdd}-{kebab_title}.md"

    @staticmethod
    def parse_filename(filename: str) -> Optional[Dict]:
        """
        Parse a knowledge document filename.

        Args:
            filename: Filename like "260302-react-hooks.md"

        Returns:
            Dict with date and title, or None if invalid
        """
        pattern = r'^(\d{6})-(.+)\.md$'
        match = re.match(pattern, filename)

        if not match:
            return None

        date_str = match.group(1)
        title = match.group(2).replace('-', ' ')

        try:
            year = 2000 + int(date_str[:2])
            month = int(date_str[2:4])
            day = int(date_str[4:6])
            date = datetime(year, month, day)

            return {
                'date': date,
                'title': title,
                'yymmdd': date_str
            }
        except ValueError:
            return None


class LinkHelper:
    """Helper for Obsidian wikilink operations."""

    @staticmethod
    def create_wikilink(target: str, display: Optional[str] = None) -> str:
        """Create a wikilink."""
        if display:
            return f"[[{target}|{display}]]"
        return f"[[{target}]]"

    @staticmethod
    def create_backlink(source_path: Path, target_path: Path, source_title: str) -> str:
        """
        Create a backlink from target to source.

        Args:
            source_path: Path to source document
            target_path: Path to target document
            source_title: Title to display

        Returns:
            Wikilink string
        """
        try:
            rel_path = target_path.relpath(source_path.parent)
            return LinkHelper.create_wikilink(str(rel_path), source_title)
        except ValueError:
            return LinkHelper.create_wikilink(str(target_path), source_title)

    @staticmethod
    def extract_links(content: str) -> List[str]:
        """
        Extract all wikilinks from content.

        Args:
            content: Markdown content

        Returns:
            List of link targets (without display text)
        """
        pattern = r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]'
        matches = re.findall(pattern, content)
        return matches

    @staticmethod
    def has_link_to(content: str, target: str) -> bool:
        """Check if content contains a link to target."""
        links = LinkHelper.extract_links(content)
        return any(target in link for link in links)


class MigrationHelper:
    """Helper for document migration."""

    @staticmethod
    def prepare_migration(source_content: str, source_path: Path) -> Dict[str, Any]:
        """
        Prepare content for migration from Memory to Knowledge.

        Args:
            source_content: Original content
            source_path: Path to source document

        Returns:
            Dict with prepared content and metadata
        """
        frontmatter, body = FrontmatterHelper.parse_frontmatter(source_content)

        if frontmatter is None:
            frontmatter = {}

        # Update frontmatter for Knowledge
        now = datetime.now()
        frontmatter.update({
            'created_date': frontmatter.get('created_date', now.strftime('%Y-%m-%d %H:%M')),
            'modified_date': now.strftime('%Y-%m-%d %H:%M'),
            'source': str(source_path.relative_to(Path.cwd())),
            'draft': False
        })

        # Add permalink if not present
        if 'permalink' not in frontmatter:
            frontmatter['permalink'] = f"posts/{uuid.uuid4().hex[:16]}"

        # Prepare body with backlink
        backlink = f"\n\n---\n\n**来源**: [[../../../{source_path}|原始文档]]"
        if '来源' not in body and 'Source' not in body:
            body += backlink

        return {
            'frontmatter': frontmatter,
            'body': body,
            'full_content': FrontmatterHelper.generate_frontmatter(frontmatter) + body
        }

    @staticmethod
    def mark_source_migrated(source_content: str, target_path: Path) -> str:
        """
        Mark source document as migrated.

        Args:
            source_content: Original source content
            target_path: Path to target (migrated) document

        Returns:
            Updated source content
        """
        frontmatter, body = FrontmatterHelper.parse_frontmatter(source_content)

        if frontmatter is None:
            frontmatter = {}

        frontmatter['migrated_to'] = str(target_path)
        frontmatter['migrated_date'] = datetime.now().strftime('%Y-%m-%d %H:%M')

        # Add migration notice to body
        migration_note = f"\n\n\u003e 此文档已迁移至: [[{target_path}|新位置]]\n"
        if '\u003e 此文档已迁移' not in body and 'migrated_to' not in body:
            body += migration_note

        return FrontmatterHelper.generate_frontmatter(frontmatter) + body


class TagHelper:
    """Helper for tag management."""

    VALID_DOMAINS = [
        '技术', '产品', '管理', '个人',
        '技术/前端', '技术/后端', '技术/DevOps',
        '技术/语言', '技术/框架',
        '产品/需求', '产品/设计', '产品/分析',
        '管理/项目', '管理/团队', '管理/流程',
        '个人/效率', '个人/学习', '个人/健康'
    ]

    VALID_TYPES = [
        '类型/概念', '类型/实践', '类型/教程',
        '类型/参考', '类型/回顾', '类型/决策'
    ]

    VALID_STATUSES = [
        '状态/草稿', '状态/已验证', '状态/归档'
    ]

    VALID_PRIORITIES = [
        '优先级/核心', '优先级/重要', '优先级/一般'
    ]

    @staticmethod
    def validate_tag(tag: str) -> Tuple[bool, Optional[str]]:
        """
        Validate a tag against known taxonomy.

        Args:
            tag: Tag string

        Returns:
            (is_valid, category_or_error)
        """
        if not tag:
            return False, "Empty tag"

        if '/' not in tag:
            return False, "Tag must use hierarchy format: category/subcategory"

        category = tag.split('/')[0]

        all_valid = (
            TagHelper.VALID_DOMAINS +
            TagHelper.VALID_TYPES +
            TagHelper.VALID_STATUSES +
            TagHelper.VALID_PRIORITIES
        )

        if tag in all_valid:
            return True, category

        # Check if it's a custom domain
        valid_categories = ['技术', '产品', '管理', '个人', '类型', '状态', '优先级']
        if category in valid_categories:
            return True, category  # Accept as custom subcategory

        return False, f"Unknown category: {category}"

    @staticmethod
    def suggest_tags(content: str) -> List[str]:
        """
        Suggest tags based on content analysis.

        Args:
            content: Document content

        Returns:
            List of suggested tags
        """
        suggestions = []
        content_lower = content.lower()

        # Technical keywords
        tech_keywords = {
            'react': '技术/前端/React',
            'vue': '技术/前端/Vue',
            'javascript': '技术/语言/JavaScript',
            'typescript': '技术/语言/TypeScript',
            'python': '技术/语言/Python',
            'docker': '技术/DevOps/Docker',
            'kubernetes': '技术/DevOps/Kubernetes'
        }

        for keyword, tag in tech_keywords.items():
            if keyword in content_lower:
                suggestions.append(tag)

        # Type detection
        type_indicators = {
            '类型/教程': ['how to', '步骤', 'guide', '教程'],
            '类型/概念': ['什么是', '概念', '定义', '理论'],
            '类型/实践': ['经验', '实践', '案例', '回顾'],
            '类型/参考': ['reference', 'api', '参数', '配置']
        }

        for tag_type, indicators in type_indicators.items():
            if any(ind in content_lower for ind in indicators):
                suggestions.append(tag_type)
                break

        return list(set(suggestions))


class KnowledgeCaptureHelper:
    """Main helper for knowledge capture operations."""

    @staticmethod
    def create_knowledge_frontmatter(
        title: str,
        tags: List[str],
        aliases: Optional[List[str]] = None,
        source: Optional[str] = None,
        summary: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create standard frontmatter for knowledge document.

        Args:
            title: Document title
            tags: List of tags
            aliases: Alternative names
            source: Source document path
            summary: One-line summary

        Returns:
            Frontmatter dictionary
        """
        now = datetime.now()

        frontmatter = {
            'aliases': aliases or [],
            'draft': False,
            'tags': tags,
            'created_date': now.strftime('%Y-%m-%d %H:%M'),
            'modified_date': now.strftime('%Y-%m-%d %H:%M'),
            'summary': summary or title,
            'permalink': f"posts/{uuid.uuid4().hex[:16]}"
        }

        if source:
            frontmatter['source'] = source

        return frontmatter

    @staticmethod
    def find_knowledge_candidates(daily_content: str) -> List[Dict]:
        """
        Find potential knowledge candidates in daily/weekly content.

        Args:
            daily_content: Content from daily log or weekly note

        Returns:
            List of candidate dicts with text and category
        """
        candidates = []

        # Look for "知识沉淀候选" section
        pattern = r'## 知识沉淀候选.*?(?=##|$)'
        match = re.search(pattern, daily_content, re.DOTALL)

        if match:
            section = match.group(0)
            # Extract bullet points
            bullet_pattern = r'- \[.?\] (.+)'
            bullets = re.findall(bullet_pattern, section)

            for bullet in bullets:
                # Try to identify category
                category = "经验"  # default
                if any(kw in bullet.lower() for kw in ['技术', '代码', 'api', '工具']):
                    category = "技术"
                elif any(kw in bullet.lower() for kw in ['流程', '方法', '框架']):
                    category = "流程"

                candidates.append({
                    'text': bullet,
                    'category': category,
                    'source_section': '知识沉淀候选'
                })

        return candidates


def main():
    """Demo/test function."""
    print("=== Naming Helper Demo ===")
    titles = [
        "React Hooks Guide",
        "A Guide to Python",
        "The API Design Patterns",
        "个人效率提升方法"
    ]
    for title in titles:
        kebab = NamingHelper.to_kebab_case(title)
        filename = NamingHelper.generate_knowledge_filename(datetime.now(), title)
        print(f"'{title}' -> '{kebab}' -> '{filename}'")

    print("\n=== Frontmatter Helper Demo ===")
    test_content = """---
title: 测试文档
created: 2026-01-01
---

这是正文内容。
"""
    fm, body = FrontmatterHelper.parse_frontmatter(test_content)
    print(f"Parsed frontmatter: {fm}")
    print(f"Body: {body[:50]}...")

    print("\n=== Tag Helper Demo ===")
    test_tags = ['技术/前端/React', '类型/教程', '无效标签', '未知/分类']
    for tag in test_tags:
        valid, msg = TagHelper.validate_tag(tag)
        print(f"'{tag}': {'✓' if valid else '✗'} {msg}")

    print("\n=== Knowledge Capture Demo ===")
    test_daily = """
## 知识沉淀候选
- [ ] React hooks 最佳实践: 今天学习了 useEffect 的依赖数组使用方法
- [ ] 会议效率: 发现提前发送议程能节省30%时间
- [ ] 代码审查技巧
"""
    candidates = KnowledgeCaptureHelper.find_knowledge_candidates(test_daily)
    print(f"Found {len(candidates)} candidates:")
    for c in candidates:
        print(f"  - [{c['category']}] {c['text'][:50]}...")


if __name__ == "__main__":
    main()
