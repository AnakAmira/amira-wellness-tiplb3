from typing import List, Optional

from datetime import date
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

# Import internal modules and dependencies
from ..api import deps
from ..models.user import User
from ..core.logging import get_logger
from ..schemas.common import PaginationParams, DateRangeParams
from ..schemas.progress import (
    ActivityType,
    Activity,
    ActivityList,
    ActivityCreate,
    Achievement,
    AchievementList,
    Streak,
    StreakUpdate,
    EmotionalTrend,
    EmotionalTrendList,
    UsageStatistics,
    ProgressInsight,
    ProgressInsightList,
    ProgressDashboard
)
from ..services.progress import (
    record_user_activity,
    get_user_activities,
    get_user_activities_by_date_range,
    get_activity_distribution_by_day,
    get_activity_distribution_by_time,
    get_usage_statistics,
    update_usage_statistics,
    generate_progress_insights,
    get_user_progress_insights,
    get_progress_dashboard,
    progress_analysis_service
)
from ..services.streak import (
    get_user_streak,
    update_user_streak,
    reset_user_streak,
    use_grace_period,
    get_next_streak_milestone
)
from ..services.emotion import analyze_emotional_trends
from ..core.exceptions import ResourceNotFoundException, ValidationException

# Initialize logger
logger = get_logger(__name__)

# Define API router for progress endpoints
router = APIRouter(prefix="/progress", tags=["progress"])

@router.get("/streak", response_model=Streak)
def get_user_streak_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user)
):
    """Endpoint to get a user's current streak information"""
    logger.info(f"Getting streak for user {User.id}")
    streak = get_user_streak(db, User.id)
    return streak

@router.post("/streak", response_model=Streak)
def update_user_streak_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    streak_update: StreakUpdate = Depends()
):
    """Endpoint to update a user's streak with activity"""
    logger.info(f"Updating streak for user {User.id}")
    updated_streak, _ = update_user_streak(db, User.id, streak_update.activity_date, streak_update.use_grace_period)
    return updated_streak

@router.delete("/streak", response_model=Streak)
def reset_user_streak_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user)
):
    """Endpoint to reset a user's streak to zero"""
    logger.info(f"Resetting streak for user {User.id}")
    reset_streak = reset_user_streak(db, User.id)
    return reset_streak

@router.post("/streak/grace-period", response_model=dict)
def use_grace_period_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user)
):
    """Endpoint to use a grace period for a user's streak"""
    logger.info(f"Using grace period for user {User.id}")
    grace_period_used = use_grace_period(db, User.id)
    return {"success": grace_period_used}

@router.get("/streak/next-milestone", response_model=dict)
def get_next_streak_milestone_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user)
):
    """Endpoint to get the next milestone for a user's streak"""
    logger.info(f"Getting next milestone for user {User.id}")
    next_milestone = get_next_streak_milestone(db, User.id)
    return {"milestone": next_milestone}

@router.get("/achievements", response_model=AchievementList)
def get_user_achievements_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    pagination: PaginationParams = Depends()
):
    """Endpoint to get a user's achievements"""
    logger.info(f"Getting achievements for user {User.id}")
    skip = (pagination.page - 1) * pagination.page_size
    limit = pagination.page_size
    achievements, total = get_user_activities(db, User.id, skip, limit)
    return AchievementList(items=achievements, total=total, page=pagination.page, page_size=pagination.page_size)

@router.get("/activities", response_model=ActivityList)
def get_user_activities_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    pagination: PaginationParams = Depends()
):
    """Endpoint to get a user's activity history"""
    logger.info(f"Getting activities for user {User.id}")
    skip = (pagination.page - 1) * pagination.page_size
    limit = pagination.page_size
    activities, total = get_user_activities(db, User.id, skip, limit)
    return ActivityList(items=activities, total=total, page=pagination.page, page_size=pagination.page_size)

@router.get("/activities/date-range", response_model=List[Activity])
def get_user_activities_by_date_range_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    date_range: DateRangeParams = Depends(),
    activity_type: Optional[ActivityType] = None
):
    """Endpoint to get a user's activities within a date range"""
    logger.info(f"Getting activities for user {User.id} by date range")
    activities = get_user_activities_by_date_range(db, User.id, date_range.start_date, date_range.end_date, activity_type)
    return activities

@router.post("/activities", response_model=Activity)
def record_user_activity_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    activity: ActivityCreate = Depends()
):
    """Endpoint to record a user activity"""
    logger.info(f"Recording activity for user {User.id}")
    recorded_activity = record_user_activity(db, User.id, activity.activity_type, activity.metadata)
    return recorded_activity["activity"]

@router.get("/activities/distribution/day", response_model=dict)
def get_activity_distribution_by_day_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    date_range: DateRangeParams = Depends()
):
    """Endpoint to get activity distribution by day of week"""
    logger.info(f"Getting activity distribution by day for user {User.id}")
    distribution = get_activity_distribution_by_day(db, User.id, date_range.start_date, date_range.end_date)
    return distribution

@router.get("/activities/distribution/time", response_model=dict)
def get_activity_distribution_by_time_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    date_range: DateRangeParams = Depends()
):
    """Endpoint to get activity distribution by time of day"""
    logger.info(f"Getting activity distribution by time for user {User.id}")
    distribution = get_activity_distribution_by_time(db, User.id, date_range.start_date, date_range.end_date)
    return distribution

@router.get("/statistics/{period_type}/{period_value}", response_model=UsageStatistics)
def get_usage_statistics_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    period_type: str = Depends(),
    period_value: str = Depends()
):
    """Endpoint to get usage statistics for a period"""
    logger.info(f"Getting usage statistics for user {User.id}")
    statistics = get_usage_statistics(db, User.id, period_type, period_value)
    return statistics

@router.post("/statistics/{period_type}/{period_value}", response_model=UsageStatistics)
def update_usage_statistics_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    period_type: str = Depends(),
    period_value: str = Depends()
):
    """Endpoint to update usage statistics for a period"""
    logger.info(f"Updating usage statistics for user {User.id}")
    updated_statistics = update_usage_statistics(db, User.id, period_type, period_value)
    return updated_statistics

@router.get("/emotional-trends", response_model=EmotionalTrendList)
def get_emotional_trends_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    date_range: DateRangeParams = Depends()
):
    """Endpoint to get emotional trends for a date range"""
    logger.info(f"Getting emotional trends for user {User.id}")
    trends = analyze_emotional_trends(db, User.id, date_range)
    return EmotionalTrendList(trends=trends, start_date=date_range.start_date, end_date=date_range.end_date)

@router.post("/insights", response_model=ProgressInsightList)
def generate_progress_insights_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    date_range: DateRangeParams = Depends()
):
    """Endpoint to generate insights from progress data"""
    logger.info(f"Generating progress insights for user {User.id}")
    insights = generate_progress_insights(db, User.id, date_range.start_date, date_range.end_date)
    return ProgressInsightList(insights=insights)

@router.get("/insights", response_model=ProgressInsightList)
def get_progress_insights_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    limit: int = 5
):
    """Endpoint to get existing progress insights"""
    logger.info(f"Getting progress insights for user {User.id}")
    insights = get_user_progress_insights(db, User.id, limit)
    return ProgressInsightList(insights=insights)

@router.get("/dashboard", response_model=ProgressDashboard)
def get_progress_dashboard_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    date_range: DateRangeParams = Depends()
):
    """Endpoint to get comprehensive progress dashboard data"""
    logger.info(f"Getting progress dashboard for user {User.id}")
    dashboard = get_progress_dashboard(db, User.id, date_range.start_date, date_range.end_date)
    return dashboard

@router.get("/analysis/activity-patterns", response_model=dict)
def analyze_activity_patterns_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    date_range: DateRangeParams = Depends()
):
    """Endpoint to analyze patterns in user activities"""
    logger.info(f"Analyzing activity patterns for user {User.id}")
    analysis = progress_analysis_service.analyze_activity_patterns(db, User.id, date_range.start_date, date_range.end_date)
    return analysis

@router.get("/analysis/progress-trends", response_model=dict)
def analyze_progress_trends_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    date_range: DateRangeParams = Depends()
):
    """Endpoint to analyze trends in user progress"""
    logger.info(f"Analyzing progress trends for user {User.id}")
    analysis = progress_analysis_service.analyze_progress_trends(db, User.id, date_range.start_date, date_range.end_date)
    return analysis

@router.get("/recommendations", response_model=List)
def generate_personalized_recommendations_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    date_range: DateRangeParams = Depends()
):
    """Endpoint to generate personalized recommendations"""
    logger.info(f"Generating personalized recommendations for user {User.id}")
    analysis = progress_analysis_service.analyze_activity_patterns(db, User.id, date_range.start_date, date_range.end_date)
    recommendations = progress_analysis_service.generate_personalized_recommendations(db, User.id, analysis)
    return recommendations

@router.get("/wellness-score", response_model=dict)
def calculate_wellness_score_endpoint(
    db: Session = Depends(deps.get_db),
    User: User = Depends(deps.get_current_user),
    date_range: DateRangeParams = Depends()
):
    """Endpoint to calculate overall wellness score"""
    logger.info(f"Calculating wellness score for user {User.id}")
    score = progress_analysis_service.calculate_wellness_score(db, User.id, date_range.start_date, date_range.end_date)
    return score