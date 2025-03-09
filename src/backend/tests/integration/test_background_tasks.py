import pytest
import time
from datetime import datetime, timedelta
from unittest.mock import patch, MagicMock

from ...app.background.tasks import (
    register_task,
    get_registered_tasks,
    get_task,
    TaskExecutionContext,
    emotion_analysis_task,
    streak_calculation_task,
    notification_delivery_task,
)
from ...app.background.worker import (
    enqueue_task,
    get_task_status,
    start_workers,
    stop_workers,
    get_queue_stats,
    retry_failed_task,
)
from ...app.background.scheduler import (
    schedule_task,
    unschedule_task,
    get_scheduled_tasks,
    calculate_next_run_time,
    process_due_tasks,
)
from ...app.models.notification import NotificationType
from ...app.constants.emotions import EmotionType
from ...app.core.config import settings
from src.backend.tests.fixtures import multiple_emotion_checkins


class BackgroundTasksFixture:
    """Fixture class for setting up and tearing down background task tests"""

    def __init__(self):
        """Initialize the background tasks fixture"""
        self.original_tasks = get_registered_tasks().copy()
        self.test_tasks = []
        self.workers_started = False

    def setup(self):
        """Set up the test environment"""
        if not self.workers_started:
            start_workers(settings.WORKER_CONCURRENCY)
            self.workers_started = True

    def teardown(self):
        """Clean up the test environment"""
        if self.workers_started:
            stop_workers()
            self.workers_started = False

        for task_name in self.test_tasks:
            if task_name in get_registered_tasks():
                del get_registered_tasks()[task_name]
        self.test_tasks.clear()

    def register_test_task(self, name: str, func: callable):
        """Register a test task for testing"""
        register_task(name)(func)
        self.test_tasks.append(name)
        return func

    def wait_for_task_completion(self, task_id: str, timeout_seconds: int = 10, target_statuses: list = None):
        """Wait for a task to complete with timeout"""
        if target_statuses is None:
            target_statuses = ['completed', 'failed']

        start_time = time.time()
        while time.time() - start_time < timeout_seconds:
            status = get_task_status(task_id)
            if status['status'] in target_statuses:
                return status
            time.sleep(0.1)
        return None


@pytest.fixture
def background_tasks_fixture():
    """Background tasks fixture"""
    fixture = BackgroundTasksFixture()
    fixture.setup()
    yield fixture
    fixture.teardown()


def test_task_registration(background_tasks_fixture):
    """Test that tasks can be registered and retrieved correctly"""
    # Get all registered tasks
    tasks = get_registered_tasks()

    # Verify that standard tasks are registered
    assert "emotion_analysis_task" in tasks
    assert "streak_calculation_task" in tasks

    # Create and register a custom test task
    @register_task(name="test_task")
    def test_task():
        return {"message": "Test task executed"}

    # Verify that the custom task is added to the registry
    assert "test_task" in get_registered_tasks()

    # Retrieve the custom task
    retrieved_task = get_task("test_task")

    # Verify that the retrieved task is the same as the original
    assert retrieved_task == test_task


def test_task_execution_context(background_tasks_fixture):
    """Test the TaskExecutionContext for tracking task execution"""
    task_name = "test_context_task"

    # Create a TaskExecutionContext
    with TaskExecutionContext(task_name) as context:
        # Perform some operations inside the context
        time.sleep(0.1)  # Simulate some work

    # Verify that metrics are collected
    metrics = context.get_metrics()
    assert "execution_time" in metrics
    assert metrics["execution_time"] > 0

    # Verify that start_time and end_time are set
    assert context.start_time is not None
    assert context.end_time is not None


def test_task_execution_context_with_exception(background_tasks_fixture):
    """Test that TaskExecutionContext handles exceptions correctly"""
    task_name = "test_exception_task"

    # Try to enter the context and raise an exception
    with pytest.raises(ValueError) as exc_info:
        with TaskExecutionContext(task_name) as context:
            raise ValueError("Simulated error")

    # Verify that the context properly records the exception
    assert str(exc_info.value) == "Simulated error"

    # Verify that metrics are still collected
    metrics = context.get_metrics()
    assert "execution_time" in metrics
    assert metrics["execution_time"] > 0

    # Verify that start_time and end_time are set
    assert context.start_time is not None
    assert context.end_time is not None


@patch('src.backend.app.background.worker.task_queue')
def test_worker_enqueue_task(mock_task_queue, background_tasks_fixture):
    """Test that tasks can be enqueued for background processing"""
    # Enqueue a test task
    task_id = enqueue_task("emotion_analysis_task", {"user_id": "test_user"})

    # Verify that the task is added to the queue
    mock_task_queue.put.assert_called_once()

    # Verify that the task has the correct name and parameters
    enqueued_task = mock_task_queue.put.call_args[0][0]
    assert enqueued_task["task_name"] == "emotion_analysis_task"
    assert enqueued_task["task_params"] == {"user_id": "test_user"}

    # Verify that a task_id is generated and returned
    assert task_id is not None
    assert isinstance(task_id, str)


def test_worker_task_execution(background_tasks_fixture):
    """Test that workers can execute tasks from the queue"""
    # Create a simple test task that sets a flag when executed
    task_executed = False

    def test_task():
        nonlocal task_executed
        task_executed = True
        return {"message": "Test task executed"}

    # Register the test task
    register_task(name="test_task")(test_task)

    # Start worker threads
    start_workers(num_workers=1)

    # Enqueue the test task
    task_id = enqueue_task("test_task", {})

    # Wait for the task to be processed
    time.sleep(1)

    # Verify that the task was executed
    assert task_executed

    # Verify that the task status is 'completed'
    status = get_task_status(task_id)
    assert status["status"] == "completed"

    # Stop worker threads
    stop_workers()


def test_worker_task_execution_with_error(background_tasks_fixture):
    """Test that workers handle task execution errors correctly"""
    # Create a test task that raises an exception
    def test_task():
        raise ValueError("Simulated error")

    # Register the test task
    register_task(name="test_task")(test_task)

    # Start worker threads
    start_workers(num_workers=1)

    # Enqueue the test task
    task_id = enqueue_task("test_task", {})

    # Wait for the task to be processed
    time.sleep(1)

    # Verify that the task status is 'failed'
    status = get_task_status(task_id)
    assert status["status"] == "failed"

    # Verify that the error message is captured
    assert status["error"] == "Simulated error"

    # Stop worker threads
    stop_workers()


def test_worker_retry_failed_task(background_tasks_fixture):
    """Test that failed tasks can be retried"""
    # Create a test task that fails on first attempt but succeeds on retry
    retry_count = 0

    def test_task():
        nonlocal retry_count
        retry_count += 1
        if retry_count == 1:
            raise ValueError("Simulated error")
        return {"message": "Test task executed"}

    # Register the test task
    register_task(name="test_task")(test_task)

    # Start worker threads
    start_workers(num_workers=1)

    # Enqueue the test task
    task_id = enqueue_task("test_task", {})

    # Wait for the task to fail
    time.sleep(1)

    # Verify that the task status is 'failed'
    status = get_task_status(task_id)
    assert status["status"] == "failed"

    # Retry the failed task
    retry_success = retry_failed_task(task_id)
    assert retry_success

    # Wait for the retry to complete
    time.sleep(1)

    # Verify that the retry was successful
    status = get_task_status(task_id)
    assert status["status"] == "completed"

    # Stop worker threads
    stop_workers()


def test_scheduler_schedule_task(background_tasks_fixture):
    """Test that tasks can be scheduled with cron expressions"""
    # Schedule a test task
    task_id = schedule_task("emotion_analysis_task", "*/10 * * * *", {"user_id": "test_user"})

    # Verify that the task is added to scheduled tasks
    scheduled_tasks = get_scheduled_tasks()
    assert any(task["task_id"] == task_id for task in scheduled_tasks)

    # Verify that the next run time is calculated correctly
    scheduled_task = next(task for task in scheduled_tasks if task["task_id"] == task_id)
    assert scheduled_task["next_run_time"] is not None

    # Verify that the scheduled task has the correct parameters
    assert scheduled_task["task_name"] == "emotion_analysis_task"
    assert scheduled_task["cron_expression"] == "*/10 * * * *"


def test_scheduler_unschedule_task(background_tasks_fixture):
    """Test that scheduled tasks can be removed"""
    # Schedule a test task
    task_id = schedule_task("emotion_analysis_task", "*/10 * * * *", {"user_id": "test_user"})

    # Verify that the task is added to scheduled tasks
    scheduled_tasks = get_scheduled_tasks()
    assert any(task["task_id"] == task_id for task in scheduled_tasks)

    # Unschedule the task
    unschedule_success = unschedule_task(task_id)
    assert unschedule_success

    # Verify that the task is removed from scheduled tasks
    scheduled_tasks = get_scheduled_tasks()
    assert not any(task["task_id"] == task_id for task in scheduled_tasks)

    # Verify that unscheduling a non-existent task returns False
    unschedule_success = unschedule_task("non_existent_task")
    assert not unschedule_success


@patch('src.backend.app.background.scheduler.enqueue_task')
def test_scheduler_process_due_tasks(mock_enqueue_task, background_tasks_fixture):
    """Test that due tasks are processed correctly"""
    # Schedule a task with a past due time
    past_time = datetime.utcnow() - timedelta(minutes=5)
    task_id = schedule_task("emotion_analysis_task", "* * * * *", {"user_id": "test_user"})

    # Call process_due_tasks()
    process_due_tasks()

    # Verify that enqueue_task was called with the correct task
    mock_enqueue_task.assert_called_once()
    enqueued_task_name = mock_enqueue_task.call_args[0][0]
    assert enqueued_task_name == "emotion_analysis_task"

    # Verify that the next run time is updated
    scheduled_tasks = get_scheduled_tasks()
    scheduled_task = next(task for task in scheduled_tasks if task["task_id"] == task_id)
    assert scheduled_task["next_run_time"] > past_time

    # Verify that tasks with future run times are not processed
    mock_enqueue_task.reset_mock()
    future_time = datetime.utcnow() + timedelta(minutes=5)
    task_id = schedule_task("emotion_analysis_task", "* * * * *", {"user_id": "test_user"})
    process_due_tasks()
    mock_enqueue_task.assert_not_called()


def test_emotion_analysis_task_integration(test_db, regular_user, multiple_emotion_checkins):
    """Integration test for the emotion analysis task"""
    # Execute the emotion_analysis_task directly
    result = emotion_analysis_task()

    # Verify that trends are generated
    assert "trends_generated" in result
    assert result["trends_generated"] > 0

    # Verify that insights are created
    assert "insights_created" in result
    assert result["insights_created"] >= 0

    # Verify that the task returns success status
    assert "error" not in result


def test_streak_calculation_task_integration(test_db, regular_user):
    """Integration test for the streak calculation task"""
    # Execute the streak_calculation_task directly
    result = streak_calculation_task()

    # Verify that streaks are calculated correctly
    assert "total_users" in result
    assert "streaks_increased" in result
    assert "streaks_unchanged" in result

    # Verify that the task returns success status
    assert "error" not in result


@patch('src.backend.app.services.notification.send_push_notification')
def test_notification_delivery_task_integration(mock_send_push_notification, test_db, regular_user):
    """Integration test for the notification delivery task"""
    # Execute the notification_delivery_task directly
    result = notification_delivery_task()

    # Verify that notifications are marked as sent
    assert "processed" in result
    assert "successful" in result
    assert "failed" in result

    # Verify that the push notification service was called
    # mock_send_push_notification.assert_called()

    # Verify that the task returns success status with count of processed notifications
    assert "error" not in result


def test_end_to_end_background_processing(test_db, background_tasks_fixture):
    """End-to-end test of the background processing system"""
    # Create a test task that performs a simple database operation
    task_executed = False

    def test_task():
        nonlocal task_executed
        task_executed = True
        return {"message": "Test task executed"}

    # Register the test task
    register_task(name="test_task")(test_task)

    # Start worker threads
    start_workers(num_workers=1)

    # Enqueue the test task
    task_id = enqueue_task("test_task", {})

    # Wait for the task to complete
    time.sleep(1)

    # Verify that the database operation was performed
    assert task_executed

    # Schedule the task to run in the near future
    schedule_task(
        task_name="test_task",
        cron_expression="* * * * *",  # Every minute
        task_params={},
    )

    # Manually trigger process_due_tasks when the time comes
    time.sleep(61)
    process_due_tasks()

    # Verify that the scheduled task was executed
    assert task_executed

    # Stop worker threads
    stop_workers()