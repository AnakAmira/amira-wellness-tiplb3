import threading  # version: standard library
import queue  # version: standard library
import time  # version: standard library
import signal  # version: standard library
import uuid  # version: standard library
from typing import Dict, Any, Optional, List, Tuple, Callable  # version: standard library

from ..core.logging import get_logger  # Internal import
from ..core.config import settings  # Internal import
from .tasks import get_task, TaskExecutionContext  # Internal import

# Initialize logger
logger = get_logger(__name__)

# Global task queue
task_queue: queue.Queue = queue.Queue(maxsize=settings.WORKER_QUEUE_SIZE)

# List to hold worker threads
worker_threads: List[threading.Thread] = []

# Flag to control worker loop
running: bool = True

# Dictionary to store task results
task_results: Dict[str, Any] = {}


def enqueue_task(task_name: str, task_params: Dict[str, Any]) -> str:
    """Add a task to the worker queue for asynchronous execution

    Args:
        task_name: Name of the task
        task_params: Dictionary of task parameters

    Returns:
        Task ID for tracking the task execution
    """
    # Generate a unique task ID using uuid.uuid4()
    task_id = str(uuid.uuid4())

    # Create a task dictionary with task_id, task_name, task_params, and status='queued'
    task = {
        "task_id": task_id,
        "task_name": task_name,
        "task_params": task_params,
        "status": "queued",
    }

    # Add the task to the task_queue
    task_queue.put(task)

    # Store the task in task_results with initial status
    task_results[task_id] = {
        "task_id": task_id,
        "task_name": task_name,
        "task_params": task_params,
        "status": "queued",
        "result": None,
        "error": None,
        "created_at": time.time(),
        "started_at": None,
        "completed_at": None,
        "retry_count": 0
    }

    # Log task enqueued with task_id and task_name
    logger.info(f"Enqueued task: {task_id} - {task_name}")

    # Return the task_id for tracking
    return task_id


def get_task_status(task_id: str) -> Dict[str, Any]:
    """Get the current status and result of a task by ID

    Args:
        task_id: Task ID

    Returns:
        Task status information including status, result, and error if any
    """
    # Check if task_id exists in task_results dictionary
    if task_id in task_results:
        # If found, return the task status information
        return task_results[task_id]
    # If not found, return a dictionary with status='unknown'
    else:
        return {"status": "unknown"}


def clear_completed_tasks(max_age_seconds: int) -> int:
    """Remove completed tasks from the results dictionary to free memory

    Args:
        max_age_seconds: Maximum age of completed tasks in seconds

    Returns:
        Number of tasks cleared
    """
    # Calculate the cutoff time based on current time minus max_age_seconds
    cutoff_time = time.time() - max_age_seconds

    # Identify completed tasks (status in ['completed', 'failed']) older than the cutoff
    cleared_tasks = 0
    tasks_to_clear = []
    for task_id, task_info in task_results.items():
        if task_info["status"] in ["completed", "failed"] and task_info["completed_at"] is not None and task_info["completed_at"] < cutoff_time:
            tasks_to_clear.append(task_id)

    # Remove identified tasks from task_results dictionary
    for task_id in tasks_to_clear:
        del task_results[task_id]
        cleared_tasks += 1

    # Log number of tasks cleared
    logger.info(f"Cleared {cleared_tasks} completed tasks from task results")

    # Return count of cleared tasks
    return cleared_tasks


def execute_task(task: Dict[str, Any]) -> Dict[str, Any]:
    """Execute a task with proper error handling and result tracking

    Args:
        task: Task dictionary

    Returns:
        Task execution result
    """
    # Extract task_id, task_name, and task_params from the task dictionary
    task_id = task["task_id"]
    task_name = task["task_name"]
    task_params = task["task_params"]

    # Update task status to 'running' in task_results
    task_results[task_id]["status"] = "running"
    task_results[task_id]["started_at"] = time.time()

    # Get the task function using get_task(task_name)
    task_func = get_task(task_name)

    # If task function not found, log error and return failure result
    if task_func is None:
        error_message = f"Task function not found: {task_name}"
        logger.error(error_message)
        task_results[task_id]["status"] = "failed"
        task_results[task_id]["error"] = error_message
        task_results[task_id]["completed_at"] = time.time()
        return {"error": error_message}

    # Create a TaskExecutionContext for the task
    try:
        with TaskExecutionContext(task_name=task_name) as task_context:
            # Execute the task function with task_params within the context
            result = task_func(**task_params)

            # Update task_results with successful execution result
            task_results[task_id]["status"] = "completed"
            task_results[task_id]["result"] = result
            task_results[task_id]["completed_at"] = time.time()

            # Return success result with task output
            return {"result": result}
    except Exception as e:
        # Catch and log any exceptions during execution
        error_message = f"Task {task_name} failed: {str(e)}"
        logger.error(error_message)

        # Update task_results with failure information
        task_results[task_id]["status"] = "failed"
        task_results[task_id]["error"] = error_message
        task_results[task_id]["completed_at"] = time.time()

        # Return failure result with error details
        return {"error": error_message}


def worker_thread_function(worker_id: int) -> None:
    """Main function for worker threads that process tasks from the queue

    Args:
        worker_id: Unique identifier for the worker thread

    Returns:
        None: Function runs until shutdown
    """
    # Log worker thread startup with worker_id
    logger.info(f"Worker thread {worker_id} started")

    # Enter main processing loop that runs while global running flag is True
    while running:
        try:
            # Try to get a task from the queue with a timeout
            task = task_queue.get(timeout=1)

            # If task retrieved, execute it with execute_task function
            result = execute_task(task)
            logger.debug(f"Worker {worker_id} processed task {task['task_id']}: {result}")
            task_queue.task_done()

        except queue.Empty:
            # Handle queue.Empty exception when no tasks are available
            # Continue the loop to check for more tasks
            continue
        except Exception as e:
            # Catch and log any unexpected exceptions in the worker thread
            logger.error(f"Worker thread {worker_id} encountered an error: {str(e)}")

    # Log worker thread shutdown on exit
    logger.info(f"Worker thread {worker_id} shutting down")


def retry_failed_task(task_id: str) -> bool:
    """Retry a previously failed task

    Args:
        task_id: ID of the failed task

    Returns:
        True if task was requeued, False otherwise
    """
    # Check if task_id exists in task_results
    if task_id not in task_results:
        logger.warning(f"Task not found for retry: {task_id}")
        return False

    # Verify that the task status is 'failed'
    if task_results[task_id]["status"] != "failed":
        logger.warning(f"Task is not in failed state, cannot retry: {task_id}")
        return False

    # Check if max retries has been reached
    if task_results[task_id]["retry_count"] >= settings.WORKER_MAX_RETRIES:
        logger.warning(f"Max retries reached for task: {task_id}")
        return False

    # Extract the original task_name and task_params
    task_name = task_results[task_id]["task_name"]
    task_params = task_results[task_id]["task_params"]

    # Create a new task with the same parameters
    new_task_id = str(uuid.uuid4())
    task = {
        "task_id": new_task_id,
        "task_name": task_name,
        "task_params": task_params,
        "status": "queued",
    }

    # Add the task to the queue
    task_queue.put(task)

    # Update the original task status to 'retried'
    task_results[task_id]["status"] = "retried"
    task_results[task_id]["retry_count"] += 1

    # Log task retry with task_id
    logger.info(f"Retrying task: {task_id}, new task id: {new_task_id}")

    # Return True for successful retry
    return True


def start_workers(num_workers: int) -> None:
    """Start worker threads to process tasks from the queue

    Args:
        num_workers: Number of worker threads to start

    Returns:
        None: Function starts worker threads
    """
    # Check if workers are already running
    if worker_threads:
        logger.warning("Workers are already running, cannot start new workers")
        return

    # Set global running flag to True
    global running
    running = True

    # Create and start worker threads up to num_workers
    for i in range(num_workers):
        thread = threading.Thread(target=worker_thread_function, args=(i + 1,))
        worker_threads.append(thread)
        thread.start()

    # Add each thread to the worker_threads list
    # Log worker startup with thread count
    logger.info(f"Started {num_workers} worker threads")


def stop_workers() -> None:
    """Stop all worker threads gracefully

    Args:
        None: Function stops worker threads

    Returns:
        None: Function stops worker threads
    """
    # Set global running flag to False
    global running
    running = False

    # Wait for each worker thread to complete
    for thread in worker_threads:
        thread.join()

    # Clear the worker_threads list
    worker_threads.clear()

    # Log worker shutdown completion
    logger.info("All worker threads stopped")


def handle_signal(signum, frame):
    """Signal handler for graceful shutdown on system signals

    Args:
        signum: Signal number
        frame: Current stack frame

    Returns:
        None: Function handles signal and initiates shutdown
    """
    # Log signal reception
    logger.info(f"Received signal {signum}, shutting down workers...")

    # Call stop_workers to gracefully shut down worker threads
    stop_workers()

    # Exit the process with appropriate status code
    exit(0)


def setup_signal_handlers() -> None:
    """Configure signal handlers for graceful shutdown

    Args:
        None: Function sets up signal handlers

    Returns:
        None: Function sets up signal handlers
    """
    # Register handle_signal for SIGINT (Ctrl+C)
    signal.signal(signal.SIGINT, handle_signal)

    # Register handle_signal for SIGTERM (termination signal)
    signal.signal(signal.SIGTERM, handle_signal)


def get_queue_stats() -> Dict[str, Any]:
    """Get statistics about the task queue and workers

    Args:
        None: Function gets queue statistics

    Returns:
        Queue statistics including size, worker count, and task counts by status
    """
    # Get current queue size from task_queue.qsize()
    queue_size = task_queue.qsize()

    # Count active worker threads
    active_workers = len(worker_threads)

    # Count tasks by status (queued, running, completed, failed)
    status_counts = {}
    for task_info in task_results.values():
        status = task_info["status"]
        if status in status_counts:
            status_counts[status] += 1
        else:
            status_counts[status] = 1

    # Return dictionary with all statistics
    return {
        "queue_size": queue_size,
        "active_workers": active_workers,
        "status_counts": status_counts,
    }


def run_worker() -> None:
    """Main entry point to start the worker process

    Args:
        None: Function runs until terminated

    Returns:
        None: Function runs until terminated
    """
    # Check if worker is enabled in settings
    if not settings.WORKER_ENABLED:
        logger.warning("Worker is disabled in settings, exiting...")
        return

    # Log worker service startup
    logger.info("Starting worker service...")

    # Setup signal handlers for graceful shutdown
    setup_signal_handlers()

    # Start worker threads with concurrency from settings
    start_workers(settings.WORKER_CONCURRENCY)

    try:
        # Enter main monitoring loop
        while running:
            # Periodically log queue statistics
            stats = get_queue_stats()
            logger.info(f"Queue statistics: {stats}")

            # Periodically clear old completed tasks
            cleared_count = clear_completed_tasks(max_age_seconds=3600)
            logger.info(f"Cleared {cleared_count} old completed tasks")

            # Wait before next iteration
            time.sleep(60)
    except Exception as e:
        # Handle any unexpected exceptions
        logger.error(f"Worker service encountered an error: {str(e)}")
    finally:
        # Ensure workers are stopped on exit
        stop_workers()
        logger.info("Worker service stopped")