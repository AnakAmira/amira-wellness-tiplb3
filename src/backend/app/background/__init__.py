"""
Initialization module for the background processing package in the Amira Wellness application.
This module exports the core functionality for background task scheduling, worker management, and task execution, providing a unified interface for asynchronous processing of computationally intensive operations.
"""

from ..core.logging import get_logger  # Internal import
from .tasks import register_task, task_wrapper, get_registered_tasks, get_task, TaskExecutionContext  # Internal import
from .worker import enqueue_task, get_task_status, retry_failed_task, start_workers, stop_workers, get_queue_stats, run_worker, TaskResult  # Internal import
from .scheduler import schedule_task, unschedule_task, get_scheduled_tasks, start_scheduler, stop_scheduler, run_scheduler, ScheduledTask  # Internal import

logger = get_logger(__name__)

__all__ = ["register_task", "task_wrapper", "get_registered_tasks", "get_task", "TaskExecutionContext", "enqueue_task", "get_task_status", "retry_failed_task", "start_workers", "stop_workers", "get_queue_stats", "run_worker", "TaskResult", "schedule_task", "unschedule_task", "get_scheduled_tasks", "start_scheduler", "stop_scheduler", "run_scheduler", "ScheduledTask"]


def initialize_background_services() -> None:
    """Initialize background processing services including scheduler and workers"""
    logger.info("Initializing background services...")
    start_scheduler()
    start_workers()
    logger.info("Background services initialized successfully.")


def shutdown_background_services() -> None:
    """Gracefully shut down background processing services"""
    logger.info("Shutting down background services...")
    stop_scheduler()
    stop_workers()
    logger.info("Background services shutdown successfully.")