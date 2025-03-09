import os  # package_version: standard library
import pytest  # package_version: ^7.0.0

from ..fixtures import (  # src_path: src/backend/tests/fixtures/__init__.py
    test_db,
    test_async_db,
    override_dependencies,
    regular_user,
    premium_user,
    inactive_user,
    unverified_user,
    admin_user,
    suspended_user,
    latam_user,
    short_journal,
    medium_journal,
    long_journal,
    favorite_journal,
    uploaded_journal,
    deleted_journal,
    premium_journal,
    journal_with_checkins,
    anxiety_to_calm_journal,
    sadness_to_joy_journal,
    multiple_journals,
    joy_emotion,
    sadness_emotion,
    anxiety_emotion,
    calm_emotion,
    frustration_emotion,
    pre_journal_emotion,
    post_journal_emotion,
    emotion_pair,
    daily_emotion_trend,
    weekly_emotion_trend,
    monthly_emotion_trend,
    emotion_insight,
    multiple_emotion_checkins,
    breathing_tool,
    meditation_tool,
    somatic_tool,
    gratitude_tool,
    journaling_tool,
    premium_tool,
    tool_favorite,
    tool_usage_completed,
    tool_usage_with_emotions,
    multiple_tools,
    first_step_achievement,
    streak_3_days_achievement,
    streak_7_days_achievement,
    earned_achievement,
    in_progress_achievement,
    all_achievements,
)

# Define a global variable to indicate unit test mode
UNIT_TEST_MODE = True


def setup_unit_test_environment() -> None:
    """Sets up the unit test environment with appropriate configuration."""
    # Step 1: Set environment variables specific to unit testing
    os.environ["UNIT_TEST_ENVIRONMENT"] = "True"
    # Step 2: Configure test isolation settings
    # This might involve setting up a separate database or file storage location
    # Step 3: Set up mocking defaults for unit tests
    # This could involve patching external services or dependencies
    pass


pytest_plugins = [
    "src.backend.tests.fixtures",
]  # List[str]: List of pytest plugins to be loaded for unit tests