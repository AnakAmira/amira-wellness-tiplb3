import pytest

# Import database fixtures
from .database import test_db, test_async_db, override_dependencies

# Import user fixtures
from .users import regular_user, premium_user, inactive_user, unverified_user, admin_user, suspended_user, latam_user

# Import journal fixtures
from .journals import short_journal, medium_journal, long_journal, favorite_journal, uploaded_journal, deleted_journal, premium_journal, journal_with_checkins, anxiety_to_calm_journal, sadness_to_joy_journal, multiple_journals

# Import emotion fixtures
from .emotions import joy_emotion, sadness_emotion, anxiety_emotion, calm_emotion, frustration_emotion, pre_journal_emotion, post_journal_emotion, emotion_pair, daily_emotion_trend, weekly_emotion_trend, monthly_emotion_trend, emotion_insight, multiple_emotion_checkins

# Import tool fixtures
from .tools import breathing_tool, meditation_tool, somatic_tool, gratitude_tool, journaling_tool, premium_tool, tool_favorite, tool_usage_completed, tool_usage_with_emotions, multiple_tools

# Import achievement fixtures
from .achievements import first_step_achievement, streak_3_days_achievement, streak_7_days_achievement, earned_achievement, in_progress_achievement, all_achievements

# Re-export database fixtures for tests
__all__ = [
    "test_db",
    "test_async_db",
    "override_dependencies",
    "regular_user",
    "premium_user",
    "inactive_user",
    "unverified_user",
    "admin_user",
    "suspended_user",
    "latam_user",
    "short_journal",
    "medium_journal",
    "long_journal",
    "favorite_journal",
    "uploaded_journal",
    "deleted_journal",
    "premium_journal",
    "journal_with_checkins",
    "anxiety_to_calm_journal",
    "sadness_to_joy_journal",
    "multiple_journals",
    "joy_emotion",
    "sadness_emotion",
    "anxiety_emotion",
    "calm_emotion",
    "frustration_emotion",
    "pre_journal_emotion",
    "post_journal_emotion",
    "emotion_pair",
    "daily_emotion_trend",
    "weekly_emotion_trend",
    "monthly_emotion_trend",
    "emotion_insight",
    "multiple_emotion_checkins",
    "breathing_tool",
    "meditation_tool",
    "somatic_tool",
    "gratitude_tool",
    "journaling_tool",
    "premium_tool",
    "tool_favorite",
    "tool_usage_completed",
    "tool_usage_with_emotions",
    "multiple_tools",
    "first_step_achievement",
    "streak_3_days_achievement",
    "streak_7_days_achievement",
    "earned_achievement",
    "in_progress_achievement",
    "all_achievements",
]