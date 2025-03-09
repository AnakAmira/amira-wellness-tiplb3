"""
Initialization module for the background jobs package in the Amira Wellness application.
This module exports the main entry points for all background job functions, making them accessible to the task scheduler and worker processes. It centralizes access to emotion analysis, streak calculation, notification delivery, recommendation engine, and storage cleanup jobs.
"""

from ..core.logging import get_logger  # Internal import
from .emotion_analysis import run_emotion_analysis_job  # Internal import
from .notification_delivery import process_notifications  # Internal import
from .recommendation_engine import run_recommendation_engine  # Internal import
from .storage_cleanup import run_storage_cleanup_job  # Internal import
from .streak_calculation import calculate_daily_streaks, send_streak_at_risk_reminders  # Internal import

# Configure logging for the module
logger = get_logger(__name__)

__all__ = [
    "run_emotion_analysis_job",
    "calculate_daily_streaks",
    "send_streak_at_risk_reminders",
    "process_notifications",
    "run_recommendation_engine",
    "run_storage_cleanup_job",
]