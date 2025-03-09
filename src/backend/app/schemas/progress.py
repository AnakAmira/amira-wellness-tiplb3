from enum import Enum
from typing import List, Dict, Optional, Any
from datetime import datetime, date
import uuid

from pydantic import BaseModel, Field, model_validator, field_validator

from .common import (
    BaseSchema, 
    IDSchema, 
    TimestampSchema, 
    PaginationParams, 
    PaginatedResponse,
    DateRangeParams
)
from ..constants.achievements import (
    AchievementType, 
    AchievementCategory, 
    CriteriaType, 
    ActionType
)


class ActivityType(Enum):
    """Enumeration of activity types that can be tracked in the system"""
    APP_USAGE = "APP_USAGE"
    VOICE_JOURNAL = "VOICE_JOURNAL"
    EMOTIONAL_CHECK_IN = "EMOTIONAL_CHECK_IN"
    TOOL_USAGE = "TOOL_USAGE"
    ACHIEVEMENT_EARNED = "ACHIEVEMENT_EARNED"


class ActivityBase(BaseSchema):
    """Base schema for user activity data"""
    activity_type: ActivityType
    user_id: uuid.UUID
    related_item_id: Optional[uuid.UUID] = None
    description: Optional[str] = None
    metadata: Optional[Dict] = None


class ActivityCreate(ActivityBase):
    """Schema for creating a new activity record"""
    pass


class Activity(ActivityBase, IDSchema, TimestampSchema):
    """Schema for activity data returned to clients"""
    pass


class ActivityList(PaginatedResponse[Activity]):
    """Schema for paginated list of activities"""
    pass


class AchievementBase(BaseSchema):
    """Base schema for user achievement data"""
    achievement_type: AchievementType
    user_id: uuid.UUID
    points: Optional[int] = None
    metadata: Optional[Dict] = None


class AchievementCreate(AchievementBase):
    """Schema for creating a new achievement record"""
    pass


class Achievement(AchievementBase, IDSchema, TimestampSchema):
    """Schema for achievement data returned to clients"""
    name: str
    description: str
    icon_url: str
    category: AchievementCategory
    is_hidden: bool = False
    earned_at: datetime


class AchievementList(PaginatedResponse[Achievement]):
    """Schema for paginated list of achievements"""
    pass


class StreakBase(BaseSchema):
    """Base schema for user streak data"""
    user_id: uuid.UUID
    current_streak: int = 0
    longest_streak: int = 0
    last_activity_date: date
    total_days_active: int = 0
    streak_history: Optional[Dict] = None
    grace_period_used_count: Optional[int] = 0
    grace_period_reset_date: Optional[date] = None
    grace_period_active: Optional[bool] = False


class StreakUpdate(BaseSchema):
    """Schema for updating a user's streak"""
    activity_date: date
    use_grace_period: Optional[bool] = False
    
    @field_validator('activity_date')
    @classmethod
    def validate_activity_date(cls, v: date) -> date:
        """Validates that activity_date is not in the future"""
        if v > date.today():
            raise ValueError("Activity date cannot be in the future")
        return v


class Streak(StreakBase, IDSchema, TimestampSchema):
    """Schema for streak data returned to clients"""
    next_milestone: int
    milestone_progress: float


class TrendDirection(Enum):
    """Enumeration of trend directions for emotional data"""
    INCREASING = "INCREASING"
    DECREASING = "DECREASING"
    STABLE = "STABLE"
    FLUCTUATING = "FLUCTUATING"


class TrendDataPoint(BaseSchema):
    """Schema for a single data point in a trend"""
    date: date
    value: float
    context: Optional[str] = None


class EmotionalTrend(BaseSchema):
    """Schema for emotional trend data"""
    emotion_type: str
    data_points: List[TrendDataPoint]
    overall_trend: TrendDirection
    average_intensity: float
    peak_intensity: float
    peak_date: date


class EmotionalTrendList(BaseSchema):
    """Schema for a list of emotional trends"""
    trends: List[EmotionalTrend]
    start_date: date
    end_date: date


class CategoryUsage(BaseSchema):
    """Schema for tool usage by category"""
    category: str
    usage_count: int
    total_duration: int


class TimeOfDay(Enum):
    """Enumeration of time periods during the day"""
    MORNING = "MORNING"
    AFTERNOON = "AFTERNOON"
    EVENING = "EVENING"
    NIGHT = "NIGHT"


class DayOfWeek(Enum):
    """Enumeration of days of the week"""
    MONDAY = "MONDAY"
    TUESDAY = "TUESDAY"
    WEDNESDAY = "WEDNESDAY"
    THURSDAY = "THURSDAY"
    FRIDAY = "FRIDAY"
    SATURDAY = "SATURDAY"
    SUNDAY = "SUNDAY"


class UsageStatistics(BaseSchema):
    """Schema for usage statistics data"""
    total_journal_entries: int
    total_journaling_minutes: int
    total_check_ins: int
    total_tool_usage: int
    tool_usage_by_category: List[CategoryUsage]
    active_time_of_day: TimeOfDay
    most_productive_day: DayOfWeek


class InsightType(Enum):
    """Enumeration of insight types for progress data"""
    PATTERN = "PATTERN"
    TRIGGER = "TRIGGER"
    IMPROVEMENT = "IMPROVEMENT"
    CORRELATION = "CORRELATION"
    RECOMMENDATION = "RECOMMENDATION"


class ProgressInsight(BaseSchema):
    """Schema for insights generated from progress data"""
    type: InsightType
    title: str
    description: str
    supporting_data: str
    actionable_steps: List[str]
    related_tools: List[str]


class ProgressInsightList(BaseSchema):
    """Schema for a list of progress insights"""
    insights: List[ProgressInsight]


class ProgressDashboard(BaseSchema):
    """Schema for the complete progress dashboard data"""
    streak_info: Streak
    emotional_trends: EmotionalTrendList
    most_frequent_emotions: List[Dict]
    activity_by_day: Dict[str, int]
    recent_achievements: List[Achievement]
    insights: ProgressInsightList