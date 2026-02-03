"""
Services Module
===============

Background services and orchestration for Auto Claude.

Key components:
- TaskDaemon: 24/7 headless task manager with parallel execution
- SpecFactory: Programmatic spec creation for design agents
- ServiceOrchestrator: Service coordination
- RecoveryManager: Stuck task recovery
"""

from .context import ServiceContext
from .orchestrator import ServiceOrchestrator
from .recovery import RecoveryManager
from .spec_factory import SpecFactory, create_spec_factory
from .task_daemon import TaskDaemon, create_daemon

__all__ = [
    "ServiceContext",
    "ServiceOrchestrator",
    "RecoveryManager",
    "TaskDaemon",
    "create_daemon",
    "SpecFactory",
    "create_spec_factory",
]
