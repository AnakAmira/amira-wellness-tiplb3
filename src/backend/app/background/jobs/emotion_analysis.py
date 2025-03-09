# src/backend/app/background/jobs/emotion_analysis.py
"""
Background job for analyzing emotional data in the Amira Wellness application.
This module processes user emotional check-ins to generate trends, detect patterns, and create insights that help users understand their emotional health over time.
"""

import typing
from typing import List, Dict, Optional, Any, Tuple
import uuid
import datetime

import sqlalchemy  # sqlalchemy==2.0+
import pandas  # pandas==2.1+
from tqdm import tqdm  # tqdm==4.66+
from sqlalchemy.orm import Session  # sqlalchemy==2.0+

from ..core.logging import get_logger  # Internal import
from ..core.config import settings  # Internal import
from ..db.session import db_session  # Internal import
from ..crud import emotion  # Internal import
from ..models.user import User  # Internal import
from ..models.emotion import EmotionalCheckin  # Internal import
from ..models.emotion import EmotionalTrend  # Internal import
from ..models.emotion import EmotionalInsight  # Internal import
from ..constants.emotions import PeriodType  # Internal import
from ..services.emotion import EmotionAnalysisService  # Internal import

# Initialize logger
logger = get_logger(__name__)


class EmotionAnalysisResult:
    """
    Data class for storing emotion analysis job results
    """

    def __init__(self):
        """Initialize the emotion analysis result object"""
        self.users_processed: int = 0
        self.trends_generated: int = 0
        self.insights_created: int = 0
        self.start_time: datetime.datetime = datetime.datetime.now()
        self.end_time: Optional[datetime.datetime] = None
        self.execution_time_seconds: float = 0.0

    def complete(self):
        """Mark the analysis as complete and calculate execution time"""
        self.end_time = datetime.datetime.now()
        self.execution_time_seconds = (self.end_time - self.start_time).total_seconds()

    def to_dict(self) -> Dict[str, Any]:
        """Convert the result to a dictionary for reporting"""
        result = {
            "users_processed": self.users_processed,
            "trends_generated": self.trends_generated,
            "insights_created": self.insights_created,
            "start_time": self.start_time.isoformat(),
            "end_time": self.end_time.isoformat() if self.end_time else None,
            "execution_time_seconds": self.execution_time_seconds,
        }
        return result


def get_active_users(db: Session, days: int, limit: int, offset: int) -> List[uuid.UUID]:
    """
    Get a list of active users who have emotional check-ins

    Args:
        db (sqlalchemy.orm.Session): db
        days (int): days
        limit (int): limit
        offset (int): offset

    Returns:
        List[uuid.UUID]: List of user IDs for active users
    """
    cutoff_date = datetime.datetime.now() - datetime.timedelta(days=days)
    query = (
        sqlalchemy.select(User.id)
        .join(EmotionalCheckin, User.id == EmotionalCheckin.user_id)
        .where(EmotionalCheckin.created_at >= cutoff_date)
        .limit(limit)
        .offset(offset)
    )
    user_ids = db.execute(query).scalars().all()
    return list(user_ids)


def process_user_emotional_data(db: Session, user_id: uuid.UUID, start_date: datetime.datetime, end_date: datetime.datetime) -> Dict[str, Any]:
    """
    Process emotional data for a single user

    Args:
        db (sqlalchemy.orm.Session): db
        user_id (uuid.UUID): user_id
        start_date (datetime.datetime): start_date
        end_date (datetime.datetime): end_date

    Returns:
        Dict[str, Any]: Processing results with statistics
    """
    checkins = emotion.get_by_date_range(db, start_date, end_date, user_id=user_id)
    if len(checkins) < settings.EMOTION_ANALYSIS_MIN_CHECKINS:
        logger.info(f"Not enough check-ins for user {user_id} to perform analysis.")
        return {"trends_generated": 0, "insights_created": 0}

    daily_trends = emotional_trend.calculate_trends(db, user_id, start_date, end_date, PeriodType.DAY)
    weekly_trends = emotional_trend.calculate_trends(db, user_id, start_date, end_date, PeriodType.WEEK)
    monthly_trends = emotional_trend.calculate_trends(db, user_id, start_date, end_date, PeriodType.MONTH)

    insights = emotion.generate_insights(db, user_id, start_date, end_date)

    analysis_service = EmotionAnalysisService()
    analysis_service.analyze_emotional_health(db, user_id, start_date, end_date)

    logger.info(f"Processed emotional data for user {user_id}")
    return {"trends_generated": len(daily_trends) + len(weekly_trends) + len(monthly_trends), "insights_created": len(insights)}


def run_emotion_analysis_job() -> Dict[str, Any]:
    """
    Main entry point for the emotion analysis background job

    Args:

    Returns:
        Dict[str, Any]: Job execution results with statistics
    """
    logger.info("Emotion analysis job started")
    result = EmotionAnalysisResult()

    start_date = datetime.datetime.now() - datetime.timedelta(days=settings.EMOTION_ANALYSIS_LOOKBACK_DAYS)
    end_date = datetime.datetime.now()

    offset = 0
    with db_session() as db:
        while True:
            user_ids = get_active_users(db, settings.EMOTION_ANALYSIS_LOOKBACK_DAYS, settings.EMOTION_ANALYSIS_BATCH_SIZE, offset)
            if not user_ids:
                break

            for user_id in tqdm(user_ids, desc="Processing users"):
                user_result = process_user_emotional_data(db, user_id, start_date, end_date)
                result.users_processed += 1
                result.trends_generated += user_result["trends_generated"]
                result.insights_created += user_result["insights_created"]

            offset += settings.EMOTION_ANALYSIS_BATCH_SIZE

    result.complete()
    logger.info(f"Emotion analysis job completed. {result.to_dict()}")
    return result.to_dict()