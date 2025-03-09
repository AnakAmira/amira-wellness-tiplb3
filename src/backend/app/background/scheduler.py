import datetime
import time
import threading
import signal
import typing
from typing import Dict, List, Any, Optional, Callable, Union

import pytz  # version: 2023.3+
from croniter import croniter  # version: 1.4.1+

from ..core.logging import get_logger  # Internal import
from ..core.config import settings  # Internal import
from .tasks import get_registered_tasks  # Internal import
from .worker import enqueue_task  # Internal import

# Initialize logger
logger = get_logger(__name__)

# Global list to store scheduled tasks
scheduled_tasks: List[Dict[str, Any]] = []

# Global variable to hold the scheduler thread
scheduler_thread: Optional[threading.Thread] = None

# Global flag to control the scheduler loop
running: bool = True


def schedule_task(task_name: str, cron_expression: str, task_params: Dict[str, Any]) -> str:
    """Schedule a task to run at specified intervals using cron syntax

    Args:
        task_name: Name of the task
        cron_expression: Cron syntax expression
        task_params: Dictionary of task parameters

    Returns:
        Scheduled task ID
    """
    # Validate that task_name exists in registered tasks
    if task_name not in get_registered_tasks():
        raise ValueError(f"Task {task_name} is not a registered task.")

    # Parse the cron_expression using croniter
    try:
        cron = croniter(cron_expression, datetime.datetime.now(pytz.timezone(settings.SCHEDULER_TIMEZONE)))
    except Exception as e:
        raise ValueError(f"Invalid cron expression: {cron_expression}. Error: {str(e)}")

    # Generate a unique ID for the scheduled task
    task_id = str(uuid.uuid4())

    # Create a scheduled task entry with task details and next run time
    next_run_time = calculate_next_run_time(cron_expression)
    task = {
        "task_id": task_id,
        "task_name": task_name,
        "cron_expression": cron_expression,
        "task_params": task_params,
        "next_run_time": next_run_time,
        "last_run_time": None,
    }

    # Add the scheduled task to the scheduled_tasks list
    scheduled_tasks.append(task)

    # Log task scheduling with task_name and cron_expression
    logger.info(f"Scheduled task {task_name} with cron expression: {cron_expression}")

    # Return the scheduled task ID
    return task_id


def unschedule_task(scheduled_task_id: str) -> bool:
    """Remove a scheduled task by ID

    Args:
        scheduled_task_id: ID of the scheduled task

    Returns:
        True if task was unscheduled, False if not found
    """
    # Find the scheduled task with the given ID
    for task in scheduled_tasks:
        if task["task_id"] == scheduled_task_id:
            # If found, remove it from the scheduled_tasks list
            scheduled_tasks.remove(task)

            # Log task unscheduling with task_name
            logger.info(f"Unscheduled task: {task['task_name']}")

            # Return True for successful unscheduling
            return True

    # If not found, log warning and return False
    logger.warning(f"Task with ID {scheduled_task_id} not found for unscheduling")
    return False


def get_scheduled_tasks() -> List[Dict[str, Any]]:
    """Get a list of all scheduled tasks

    Returns:
        List[Dict[str, Any]]: List of scheduled task information
    """
    # Create a list of dictionaries with scheduled task information
    task_list = []
    for task in scheduled_tasks:
        # Include task_id, task_name, cron_expression, next_run_time, and last_run_time for each task
        task_info = {
            "task_id": task["task_id"],
            "task_name": task["task_name"],
            "cron_expression": task["cron_expression"],
            "next_run_time": task["next_run_time"].isoformat() if task["next_run_time"] else None,
            "last_run_time": task["last_run_time"].isoformat() if task["last_run_time"] else None,
        }
        task_list.append(task_info)

    # Return the list of scheduled tasks
    return task_list


def calculate_next_run_time(cron_expression: str, base_time: Optional[datetime.datetime] = None) -> datetime.datetime:
    """Calculate the next run time for a scheduled task based on its cron expression

    Args:
        cron_expression: Cron syntax expression
        base_time: Optional base time for calculation (defaults to now)

    Returns:
        Next scheduled run time
    """
    # If base_time is not provided, use current time
    if base_time is None:
        base_time = datetime.datetime.now(pytz.timezone(settings.SCHEDULER_TIMEZONE))

    # Create a croniter instance with the cron_expression and base_time
    cron = croniter(cron_expression, base_time)

    # Get the next run time from croniter
    next_run = cron.get_next(datetime.datetime)

    # Return the next run time as a datetime object
    return next_run


def update_next_run_time(task: Dict[str, Any]) -> None:
    """Update the next run time for a scheduled task after execution

    Args:
        task: Task dictionary

    Returns:
        None: Updates the task in place
    """
    # Set the last_run_time to the current time
    task["last_run_time"] = datetime.datetime.now(pytz.timezone(settings.SCHEDULER_TIMEZONE))

    # Calculate the next run time using calculate_next_run_time
    next_run_time = calculate_next_run_time(task["cron_expression"])

    # Update the task's next_run_time field
    task["next_run_time"] = next_run_time


def process_due_tasks() -> int:
    """Process all tasks that are due for execution

    Args:
        None

    Returns:
        Number of tasks processed
    """
    # Get the current time
    now = datetime.datetime.now(pytz.timezone(settings.SCHEDULER_TIMEZONE))

    # Initialize counter for processed tasks
    processed_tasks = 0

    # Iterate through scheduled_tasks list
    for task in scheduled_tasks:
        # For each task, check if next_run_time is in the past
        if task["next_run_time"] <= now:
            # Enqueue it for execution using enqueue_task
            enqueue_task(task["task_name"], task["task_params"])

            # Update the next run time for the task
            update_next_run_time(task)

            # Increment the processed tasks counter
            processed_tasks += 1

            # Log task execution scheduling
            logger.info(f"Scheduled task {task['task_name']} for execution")

    # Return the number of processed tasks
    return processed_tasks


def scheduler_thread_function() -> None:
    """Main function for the scheduler thread that periodically checks for due tasks

    Args:
        None

    Returns:
        None: Function runs until shutdown
    """
    # Log scheduler thread startup
    logger.info("Scheduler thread started")

    # Enter main processing loop that runs while global running flag is True
    while running:
        try:
            # Process any due tasks using process_due_tasks
            process_due_tasks()

            # Sleep for a short interval (e.g., 1 second) to avoid CPU overuse
            time.sleep(1)
        except Exception as e:
            # Catch and log any unexpected exceptions in the scheduler thread
            logger.error(f"Scheduler thread encountered an error: {str(e)}")

        # Continue the loop after handling exceptions

    # Log scheduler thread shutdown on exit
    logger.info("Scheduler thread shutting down")


def start_scheduler() -> None:
    """Start the scheduler thread to process scheduled tasks

    Args:
        None

    Returns:
        None: Function starts scheduler thread
    """
    # Check if scheduler is already running
    if scheduler_thread and scheduler_thread.is_alive():
        logger.warning("Scheduler is already running, cannot start new scheduler")
        return

    # Set global running flag to True
    global running
    running = True

    # Create and start scheduler thread
    global scheduler_thread
    scheduler_thread = threading.Thread(target=scheduler_thread_function)
    scheduler_thread.daemon = True  # Allow the main program to exit even if this thread is running
    scheduler_thread.start()

    # Log scheduler startup
    logger.info("Scheduler started")


def stop_scheduler() -> None:
    """Stop the scheduler thread gracefully

    Args:
        None

    Returns:
        None: Function stops scheduler thread
    """
    # Set global running flag to False
    global running
    running = False

    # If scheduler_thread exists and is alive, wait for it to complete
    if scheduler_thread and scheduler_thread.is_alive():
        scheduler_thread.join()

    # Set scheduler_thread to None
    global scheduler_thread
    scheduler_thread = None

    # Log scheduler shutdown completion
    logger.info("Scheduler stopped")


def handle_signal(signum: int, frame: object) -> None:
    """Signal handler for graceful shutdown on system signals

    Args:
        signum: Signal number
        frame: Current stack frame

    Returns:
        None: Function handles signal and initiates shutdown
    """
    # Log signal reception
    logger.info(f"Received signal {signum}, shutting down scheduler...")

    # Call stop_scheduler to gracefully shut down scheduler thread
    stop_scheduler()

    # Exit the process with appropriate status code
    exit(0)


def setup_signal_handlers() -> None:
    """Configure signal handlers for graceful shutdown

    Args:
        None

    Returns:
        None: Function sets up signal handlers
    """
    # Register handle_signal for SIGINT (Ctrl+C)
    signal.signal(signal.SIGINT, handle_signal)

    # Register handle_signal for SIGTERM (termination signal)
    signal.signal(signal.SIGTERM, handle_signal)


def setup_default_schedules() -> None:
    """Set up default scheduled tasks for the application

    Args:
        None

    Returns:
        None: Function sets up default scheduled tasks
    """
    # Schedule emotion_analysis_task to run daily at off-peak hours
    schedule_task(
        task_name="emotion_analysis_task",
        cron_expression="0 2 * * *",  # Run at 2:00 AM daily
        task_params={},
    )

    # Schedule streak_calculation_task to run daily at midnight
    schedule_task(
        task_name="streak_calculation_task",
        cron_expression="0 0 * * *",  # Run at 00:00 AM daily
        task_params={},
    )

    # Schedule streak_reminder_task to run daily in the morning
    schedule_task(
        task_name="streak_reminder_task",
        cron_expression="0 8 * * *",  # Run at 8:00 AM daily
        task_params={},
    )

    # Schedule notification_delivery_task to run every hour
    schedule_task(
        task_name="notification_delivery_task",
        cron_expression="0 * * * *",  # Run every hour
        task_params={},
    )

    # Schedule recommendation_engine_task to run weekly
    schedule_task(
        task_name="recommendation_engine_task",
        cron_expression="0 0 * * 0",  # Run at 00:00 on Sunday
        task_params={},
    )

    # Schedule storage_cleanup_task to run weekly during off-peak hours
    schedule_task(
        task_name="storage_cleanup_task",
        cron_expression="0 3 * * 6",  # Run at 3:00 AM on Saturday
        task_params={},
    )

    # Log setup of default scheduled tasks
    logger.info("Default scheduled tasks setup completed")


def run_scheduler() -> None:
    """Main entry point to start the scheduler process

    Args:
        None

    Returns:
        None: Function runs until terminated
    """
    # Check if scheduler is enabled in settings
    if not settings.SCHEDULER_ENABLED:
        logger.warning("Scheduler is disabled in settings, exiting...")
        return

    # Log scheduler service startup
    logger.info("Starting scheduler service...")

    # Setup signal handlers for graceful shutdown
    setup_signal_handlers()

    # Setup default scheduled tasks
    setup_default_schedules()

    # Start scheduler thread
    start_scheduler()

    try:
        # Enter main monitoring loop
        while True:
            # Periodically log scheduler statistics
            logger.info(f"Scheduler statistics: {len(scheduled_tasks)} tasks scheduled")

            # Wait before next iteration
            time.sleep(60)
    except Exception as e:
        # Handle any unexpected exceptions
        logger.error(f"Scheduler service encountered an error: {str(e)}")
    finally:
        # Ensure scheduler is stopped on exit
        stop_scheduler()
        logger.info("Scheduler service stopped")


class ScheduledTask:
    """Class representing a scheduled task with its execution schedule"""

    def __init__(self, task_id: str, task_name: str, cron_expression: str, task_params: Dict[str, Any]):
        """Initialize a new scheduled task

        Args:
            task_id: Unique identifier for the task
            task_name: Name of the task
            cron_expression: Cron syntax expression
            task_params: Dictionary of task parameters
        """
        # Store task_id, task_name, cron_expression, and task_params
        self.task_id = task_id
        self.task_name = task_name
        self.cron_expression = cron_expression
        self.task_params = task_params

        # Initialize cron_iterator with the cron_expression
        self.cron_iterator = croniter(cron_expression, datetime.datetime.now(pytz.timezone(settings.SCHEDULER_TIMEZONE)))

        # Calculate initial next_run_time using cron_iterator
        self.next_run_time = self.cron_iterator.get_next(datetime.datetime)

        # Set last_run_time to None initially
        self.last_run_time: Optional[datetime.datetime] = None

    def is_due(self) -> bool:
        """Check if the task is due for execution

        Args:
            None

        Returns:
            True if the task is due, False otherwise
        """
        # Get the current time
        now = datetime.datetime.now(pytz.timezone(settings.SCHEDULER_TIMEZONE))

        # Compare next_run_time with current time
        # Return True if next_run_time is in the past, False otherwise
        return self.next_run_time <= now

    def update_next_run(self) -> None:
        """Update the next run time after task execution

        Args:
            None

        Returns:
            None: Updates the object in place
        """
        # Set last_run_time to current time
        self.last_run_time = datetime.datetime.now(pytz.timezone(settings.SCHEDULER_TIMEZONE))

        # Calculate next_run_time using cron_iterator.get_next()
        self.next_run_time = self.cron_iterator.get_next(datetime.datetime)

    def to_dict(self) -> Dict:
        """Convert the scheduled task to a dictionary

        Args:
            None

        Returns:
            Dictionary representation of the scheduled task
        """
        # Create a dictionary with task_id, task_name, cron_expression, task_params, next_run_time, and last_run_time
        task_dict = {
            "task_id": self.task_id,
            "task_name": self.task_name,
            "cron_expression": self.cron_expression,
            "task_params": self.task_params,
            "next_run_time": self.next_run_time.isoformat() if self.next_run_time else None,
            "last_run_time": self.last_run_time.isoformat() if self.last_run_time else None,
        }

        # Return the dictionary
        return task_dict