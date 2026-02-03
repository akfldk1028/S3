#!/usr/bin/env python3
"""
Spec Factory - Programmatic Spec Creation for Large Architecture Projects
=========================================================================

Design Agent가 대형 프로젝트를 분해할 때 사용하는 spec 생성 API.

핵심 기능:
- 프로그래밍 방식으로 child spec 생성
- parent_task 연결
- 의존성 설정 (depends_on)
- 우선순위 설정

Usage:
    from services.spec_factory import SpecFactory

    factory = SpecFactory(project_dir)

    # 단일 child spec 생성
    spec_dir = await factory.create_child_spec(
        parent_spec_id="001-design",
        task_description="Implement user authentication module",
        priority=1,
        depends_on=["002-database-schema"],
    )

    # 여러 child specs 일괄 생성
    specs = await factory.create_batch_specs(
        parent_spec_id="001-design",
        specs=[
            {"task": "Backend API", "priority": 1},
            {"task": "Frontend UI", "priority": 2, "depends_on": ["002-backend"]},
            {"task": "Integration tests", "priority": 3, "depends_on": ["002-backend", "003-frontend"]},
        ]
    )
"""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from services.task_daemon import TaskPriority


class SpecFactory:
    """
    Factory for creating specs programmatically.

    Design Agent나 Architecture Agent가 대형 프로젝트를 분해할 때,
    이 factory를 사용해서 child spec들을 자동 생성합니다.
    """

    def __init__(self, project_dir: Path):
        """
        Initialize SpecFactory.

        Args:
            project_dir: Project directory containing .auto-claude/specs/
        """
        self.project_dir = Path(project_dir).resolve()
        self.specs_dir = self.project_dir / ".auto-claude" / "specs"

        # Ensure specs directory exists
        self.specs_dir.mkdir(parents=True, exist_ok=True)

    def _generate_spec_id(self, task_description: str) -> str:
        """Generate a unique spec ID from task description."""
        # Get next sequence number
        existing = list(self.specs_dir.iterdir())
        max_num = 0
        for d in existing:
            if d.is_dir() and d.name[:3].isdigit():
                try:
                    num = int(d.name[:3])
                    max_num = max(max_num, num)
                except ValueError:
                    pass

        next_num = max_num + 1

        # Slugify task description
        slug = task_description.lower()
        slug = re.sub(r'[^a-z0-9\s-]', '', slug)
        slug = re.sub(r'[\s_]+', '-', slug)
        slug = re.sub(r'-+', '-', slug)
        slug = slug.strip('-')[:50]

        return f"{next_num:03d}-{slug}"

    async def create_child_spec(
        self,
        parent_spec_id: str,
        task_description: str,
        *,
        priority: int = TaskPriority.NORMAL,
        task_type: str = "impl",
        depends_on: list[str] | None = None,
        complexity: str = "standard",
        files_to_modify: list[str] | None = None,
        acceptance_criteria: list[str] | None = None,
        context: dict[str, Any] | None = None,
    ) -> Path:
        """
        Create a new child spec that will be picked up by the daemon.

        Args:
            parent_spec_id: ID of the parent spec (e.g., "001-design")
            task_description: Description of what this spec should implement
            priority: Task priority (0=CRITICAL, 1=HIGH, 2=NORMAL, 3=LOW)
            task_type: Type of task (design, architecture, impl, test, integration)
            depends_on: List of spec IDs that must complete before this one
            complexity: Complexity level (simple, standard, complex)
            files_to_modify: List of files this spec will likely modify
            acceptance_criteria: List of acceptance criteria
            context: Additional context to pass to the agent

        Returns:
            Path to the created spec directory
        """
        spec_id = self._generate_spec_id(task_description)
        spec_dir = self.specs_dir / spec_id
        spec_dir.mkdir(parents=True, exist_ok=True)

        now = datetime.now(timezone.utc).isoformat()

        # Create spec.md
        spec_content = self._generate_spec_md(
            task_description=task_description,
            parent_spec_id=parent_spec_id,
            acceptance_criteria=acceptance_criteria or [],
            files_to_modify=files_to_modify or [],
        )
        (spec_dir / "spec.md").write_text(spec_content, encoding="utf-8")

        # Create requirements.json
        requirements = {
            "task": task_description,
            "parent_spec": parent_spec_id,
            "complexity": complexity,
            "files_to_modify": files_to_modify or [],
            "acceptance_criteria": acceptance_criteria or [],
            "created_at": now,
            "created_by": "spec_factory",
        }
        (spec_dir / "requirements.json").write_text(
            json.dumps(requirements, indent=2),
            encoding="utf-8"
        )

        # Create implementation_plan.json (queued status for daemon)
        plan = {
            "status": "queue",
            "planStatus": "queue",
            "xstateState": "backlog",
            "executionPhase": "backlog",
            "taskType": task_type,
            "priority": priority,
            "parentTask": parent_spec_id,
            "dependsOn": depends_on or [],
            "complexity": complexity,
            "created_at": now,
            "updated_at": now,
            "phases": [],
            "subtasks": [],
        }

        if context:
            plan["context"] = context

        (spec_dir / "implementation_plan.json").write_text(
            json.dumps(plan, indent=2),
            encoding="utf-8"
        )

        # Create context.json
        ctx = {
            "parent_spec": parent_spec_id,
            "task_description": task_description,
            "files_to_modify": files_to_modify or [],
            "created_at": now,
        }
        if context:
            ctx.update(context)

        (spec_dir / "context.json").write_text(
            json.dumps(ctx, indent=2),
            encoding="utf-8"
        )

        return spec_dir

    async def create_batch_specs(
        self,
        parent_spec_id: str,
        specs: list[dict[str, Any]],
    ) -> list[Path]:
        """
        Create multiple child specs at once.

        Args:
            parent_spec_id: ID of the parent design spec
            specs: List of spec definitions, each with:
                - task: Task description (required)
                - priority: Priority level (optional, default: NORMAL)
                - task_type: Task type (optional, default: impl)
                - depends_on: Dependencies (optional)
                - complexity: Complexity (optional, default: standard)
                - files: Files to modify (optional)
                - criteria: Acceptance criteria (optional)

        Returns:
            List of created spec directory paths
        """
        created_specs = []

        for spec_def in specs:
            task = spec_def.get("task") or spec_def.get("task_description")
            if not task:
                continue

            spec_dir = await self.create_child_spec(
                parent_spec_id=parent_spec_id,
                task_description=task,
                priority=spec_def.get("priority", TaskPriority.NORMAL),
                task_type=spec_def.get("task_type", "impl"),
                depends_on=spec_def.get("depends_on"),
                complexity=spec_def.get("complexity", "standard"),
                files_to_modify=spec_def.get("files") or spec_def.get("files_to_modify"),
                acceptance_criteria=spec_def.get("criteria") or spec_def.get("acceptance_criteria"),
                context=spec_def.get("context"),
            )
            created_specs.append(spec_dir)

        return created_specs

    def _generate_spec_md(
        self,
        task_description: str,
        parent_spec_id: str,
        acceptance_criteria: list[str],
        files_to_modify: list[str],
    ) -> str:
        """Generate spec.md content."""
        lines = [
            f"# {task_description}",
            "",
            f"> Parent Spec: `{parent_spec_id}`",
            "",
            "## Overview",
            "",
            task_description,
            "",
        ]

        if acceptance_criteria:
            lines.extend([
                "## Acceptance Criteria",
                "",
            ])
            for criterion in acceptance_criteria:
                lines.append(f"- [ ] {criterion}")
            lines.append("")

        if files_to_modify:
            lines.extend([
                "## Files to Modify",
                "",
            ])
            for f in files_to_modify:
                lines.append(f"- `{f}`")
            lines.append("")

        lines.extend([
            "## Notes",
            "",
            "This spec was auto-generated by SpecFactory from a design task.",
            "",
        ])

        return "\n".join(lines)

    def get_child_specs(self, parent_spec_id: str) -> list[Path]:
        """Get all child specs of a parent spec."""
        children = []

        for spec_dir in self.specs_dir.iterdir():
            if not spec_dir.is_dir():
                continue

            plan_path = spec_dir / "implementation_plan.json"
            if not plan_path.exists():
                continue

            try:
                plan = json.loads(plan_path.read_text(encoding="utf-8"))
                parent = plan.get("parentTask") or plan.get("parent_task")
                if parent == parent_spec_id:
                    children.append(spec_dir)
            except (json.JSONDecodeError, OSError):
                continue

        return children

    def get_spec_manifest(self, parent_spec_id: str) -> dict[str, Any]:
        """Get manifest of all child specs for a parent."""
        children = self.get_child_specs(parent_spec_id)

        manifest = {
            "parent_spec_id": parent_spec_id,
            "child_count": len(children),
            "children": [],
        }

        for spec_dir in children:
            plan_path = spec_dir / "implementation_plan.json"
            req_path = spec_dir / "requirements.json"

            child_info = {
                "spec_id": spec_dir.name,
                "spec_dir": str(spec_dir),
            }

            if plan_path.exists():
                try:
                    plan = json.loads(plan_path.read_text(encoding="utf-8"))
                    child_info["status"] = plan.get("status", "unknown")
                    child_info["priority"] = plan.get("priority", 2)
                    child_info["depends_on"] = plan.get("dependsOn") or plan.get("depends_on") or []
                    child_info["task_type"] = plan.get("taskType") or plan.get("task_type", "impl")
                except (json.JSONDecodeError, OSError):
                    pass

            if req_path.exists():
                try:
                    req = json.loads(req_path.read_text(encoding="utf-8"))
                    child_info["task"] = req.get("task", "")
                except (json.JSONDecodeError, OSError):
                    pass

            manifest["children"].append(child_info)

        return manifest


# Convenience function
def create_spec_factory(project_dir: str | Path) -> SpecFactory:
    """Create a SpecFactory instance."""
    return SpecFactory(Path(project_dir))
