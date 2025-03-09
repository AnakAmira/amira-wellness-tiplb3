# src/backend/app/background/tasks.py
"""
Central registry for background tasks in the Amira Wellness application.
This module defines and registers all background jobs, provides task execution wrappers with error handling, and exposes an interface for the scheduler and worker components to access registered tasks.
"""

import time  # standard library
import datetime  # standard library
import traceback  # standard library
import functools  # standard library
from typing import Dict, Any, Callable, Optional  # standard library

from ..core.logging import get_logger  # Internal import
from ..core.config import settings  # Internal import
from .jobs.emotion_analysis import run_emotion_analysis_job  # Internal import
from .jobs.streak_calculation import calculate_daily_streaks, send_streak_at_risk_reminders  # Internal import
from .jobs.notification_delivery import process_notifications  # Internal import
from .jobs.recommendation_engine import run_recommendation_engine  # Internal import
from .jobs.storage_cleanup import run_storage_cleanup_job  # Internal import

# Initialize logger
logger = get_logger(__name__)

# Global dictionary to store registered tasks
REGISTERED_TASKS: Dict[str, Callable] = {}


def register_task(name: str) -> Callable:
    """Decorator to register a function as a background task

    Args:
        name: Name of the task

    Returns:
        Callable: Decorator function that registers the task
    """
    def decorator(task_func: Callable) -> Callable:
        """Registers the task function in REGISTERED_TASKS dictionary with the given name"""
        REGISTERED_TASKS[name] = task_func
        logger.info(f"Registered background task: {name}")
        return task_func  # Return the original task function unchanged
    return decorator  # Return the decorator function


def task_wrapper(task_func: Callable) -> Callable:
    """Wrapper function that adds logging, timing, and error handling to task execution

    Args:
        task_func: The task function to wrap

    Returns:
        Callable: Wrapped task function with additional functionality
    """
    @functools.wraps(task_func)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        """Wrapper function that takes task parameters"""
        task_name = task_func.__name__
        logger.info(f"Executing task: {task_name} with args={args} kwargs={kwargs}")
        start_time = time.time()  # Record start time for performance measurement
        try:
            result = task_func(*args, **kwargs)  # Execute the task function with provided parameters
            execution_time = time.time() - start_time  # Calculate execution time
            logger.info(f"Task {task_name} completed successfully in {execution_time:.2f} seconds")
            return result  # Return the task result
        except Exception as e:
            execution_time = time.time() - start_time
            logger.error(f"Task {task_name} failed after {execution_time:.2f} seconds: {str(e)}\n{traceback.format_exc()}")
            return {"error": str(e)}  # Return error information if task fails
    return wrapper  # Return the wrapper function


def get_registered_tasks() -> Dict[str, Callable]:
    """Returns the dictionary of all registered background tasks

    Returns:
        Dict[str, Callable]: Dictionary of registered task names and functions
    """
    return REGISTERED_TASKS  # Return the REGISTERED_TASKS global dictionary


def get_task(task_name: str) -> Optional[Callable]:
    """Get a specific task function by name

    Args:
        task_name: Name of the task to retrieve

    Returns:
        Optional[Callable]: Task function if found, None otherwise
    """
    return REGISTERED_TASKS.get(task_name)  # Return the task function from REGISTERED_TASKS if it exists


@register_task(name='emotion_analysis_task')
@task_wrapper
def emotion_analysis_task() -> Dict[str, Any]:
    """Background task for analyzing emotional data and generating insights

    Returns:
        Dict[str, Any]: Results of the emotion analysis job
    """
    return run_emotion_analysis_job()  # Call run_emotion_analysis_job from emotion_analysis module


@register_task(name='streak_calculation_task')
@task_wrapper
def streak_calculation_task() -> Dict[str, Any]:
    """Background task for calculating user streaks based on activity

    Returns:
        Dict[str, Any]: Results of the streak calculation job
    """
    return calculate_daily_streaks()  # Call calculate_daily_streaks from streak_calculation module


@register_task(name='streak_reminder_task')
@task_wrapper
def streak_reminder_task() -> Dict[str, Any]:
    """Background task for sending reminders to users with streaks at risk

    Returns:
        Dict[str, Any]: Results of the streak reminder job
    """
    return send_streak_at_risk_reminders()  # Call send_streak_at_risk_reminders from streak_calculation module


@register_task(name='notification_delivery_task')
@task_wrapper
def notification_delivery_task(batch_size: Optional[int] = None) -> Dict[str, Any]:
    """Background task for processing and delivering pending notifications

    Args:
        batch_size: The number of notifications to process in a batch

    Returns:
        Dict[str, Any]: Results of the notification delivery job
    """
    return process_notifications(batch_size=batch_size)  # Call process_notifications from notification_delivery module with batch_size


@register_task(name='recommendation_engine_task')
@task_wrapper
def recommendation_engine_task(batch_size: Optional[int] = None) -> Dict[str, Any]:
    """Background task for generating personalized tool recommendations

    Args:
        batch_size: The number of users to process in a batch

    Returns:
        Dict[str, Any]: Results of the recommendation engine job
    """
    return run_recommendation_engine(batch_size=batch_size)  # Call run_recommendation_engine from recommendation_engine module with batch_size


@register_task(name='storage_cleanup_task')
@task_wrapper
def storage_cleanup_task() -> Dict[str, Any]:
    """Background task for cleaning up orphaned and expired files from storage

    Returns:
        Dict[str, Any]: Results of the storage cleanup job
    """
    return run_storage_cleanup_job()  # Call run_storage_cleanup_job from storage_cleanup module


class TaskExecutionContext:
    """Context manager for task execution with timeout and resource tracking"""

    def __init__(self, task_name: str, timeout: Optional[int] = None):
        """Initialize the task execution context

        Args:
            task_name: Name of the task being executed
            timeout: Timeout in seconds for the task execution
        """
        self.task_name = task_name  # Store task_name for logging and metrics
        self.timeout = timeout or settings.TASK_EXECUTION_TIMEOUT  # Set timeout from parameter or default from settings
        self.start_time: Optional[float] = None  # Initialize start_time and end_time to None initially
        self.end_time: Optional[float] = None
        self.metrics: Dict[str, Any] = {}  # Initialize metrics dictionary for resource tracking

    def __enter__(self) -> 'TaskExecutionContext':
        """Enter the context manager, starting task execution tracking

        Returns:
            TaskExecutionContext: Returns self for context manager protocol
        """
        self.start_time = time.time()  # Record start_time using time.time()
        logger.info(f"Task {self.task_name} execution started")  # Log task execution start
        return self  # Return self for context manager protocol

    def __exit__(self, exc_type: Optional[type], exc_val: Optional[Exception], exc_tb: Optional[traceback]) -> bool:
        """Exit the context manager, completing task execution tracking

        Args:
            exc_type: Exception type if an exception occurred
            exc_val: Exception instance if an exception occurred
            exc_tb: Traceback object if an exception occurred

        Returns:
            bool: True if exception was handled, False otherwise
        """
        self.end_time = time.time()  # Record end_time using time.time()
        execution_time = self.end_time - self.start_time  # Calculate execution_time as end_time - start_time
        self.metrics["execution_time"] = execution_time  # Add execution_time to metrics

        if exc_type:
            logger.error(f"Task {self.task_name} failed: {str(exc_val)}\n{traceback.format_exc()}")  # If exception occurred, log error with traceback
        else:
            logger.info(f"Task {self.task_name} completed successfully in {execution_time:.2f} seconds")  # If no exception, log successful completion with execution time

        return False  # Return False to propagate exceptions (not handling them)

    def get_metrics(self) -> Dict[str, Any]:
        """Get execution metrics including timing information

        Returns:
            Dict[str, Any]: Dictionary of execution metrics
        """
        if self.start_time and self.end_time:
            execution_time = self.end_time - self.start_time  # Calculate execution_time if both start_time and end_time are set
            self.metrics["execution_time"] = execution_time  # Add execution_time to metrics dictionary
        return self.metrics  # Return the metrics dictionary