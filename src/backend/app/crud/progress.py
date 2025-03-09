"""
CRUD operations for progress tracking in the Amira Wellness application.
This module provides database access methods for user activities, usage statistics,
and progress insights to support progress visualization and gamification features.
"""

from typing import List, Optional, Dict, Union, Any
import datetime
import uuid

from sqlalchemy import select, func, and_, or_, desc
from sqlalchemy.orm import Session

from .base import CRUDBase
from ..models.progress import UserActivity, UsageStatistics, ProgressInsight
from ..constants.emotions import PeriodType
from ..constants.achievements import ActionType, InsightType
from ..core.logging import get_logger
from ..core.exceptions import ResourceNotFoundException

# Initialize logger
logger = get_logger(__name__)


class CRUDUserActivity(CRUDBase[UserActivity, Dict[str, Any], Dict[str, Any]]):
    """CRUD operations for UserActivity model"""
    
    def __init__(self):
        """Initialize with UserActivity model"""
        super().__init__(UserActivity)
    
    def get_by_user(
        self, db: Session, user_id: uuid.UUID, skip: int = 0, limit: int = 100
    ) -> List[UserActivity]:
        """
        Get activities for a specific user
        
        Args:
            db: Database session
            user_id: ID of the user
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of user activities
        """
        query = (
            select(UserActivity)
            .where(UserActivity.user_id == user_id)
            .order_by(desc(UserActivity.activity_date))
            .offset(skip)
            .limit(limit)
        )
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_by_user_and_type(
        self, db: Session, user_id: uuid.UUID, activity_type: ActionType, skip: int = 0, limit: int = 100
    ) -> List[UserActivity]:
        """
        Get activities for a user filtered by activity type
        
        Args:
            db: Database session
            user_id: ID of the user
            activity_type: Type of activity to filter by
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of user activities of the specified type
        """
        query = (
            select(UserActivity)
            .where(and_(
                UserActivity.user_id == user_id,
                UserActivity.activity_type == activity_type
            ))
            .order_by(desc(UserActivity.activity_date))
            .offset(skip)
            .limit(limit)
        )
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_by_date_range(
        self, 
        db: Session, 
        user_id: uuid.UUID, 
        start_date: datetime.datetime, 
        end_date: datetime.datetime,
        activity_type: Optional[ActionType] = None
    ) -> List[UserActivity]:
        """
        Get activities for a user within a date range
        
        Args:
            db: Database session
            user_id: ID of the user
            start_date: Start date for filtering
            end_date: End date for filtering
            activity_type: Optional activity type to filter by
            
        Returns:
            List of user activities within the date range
        """
        conditions = [
            UserActivity.user_id == user_id,
            UserActivity.activity_date >= start_date,
            UserActivity.activity_date <= end_date
        ]
        
        if activity_type:
            conditions.append(UserActivity.activity_type == activity_type)
        
        query = (
            select(UserActivity)
            .where(and_(*conditions))
            .order_by(desc(UserActivity.activity_date))
        )
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_activity_count_by_day(
        self, db: Session, user_id: uuid.UUID, start_date: datetime.datetime, end_date: datetime.datetime
    ) -> Dict[str, int]:
        """
        Get activity count grouped by day for a user
        
        Args:
            db: Database session
            user_id: ID of the user
            start_date: Start date for filtering
            end_date: End date for filtering
            
        Returns:
            Dictionary with day as key and activity count as value
        """
        query = (
            select(UserActivity.day_of_week, func.count(UserActivity.id))
            .where(and_(
                UserActivity.user_id == user_id,
                UserActivity.activity_date >= start_date,
                UserActivity.activity_date <= end_date
            ))
            .group_by(UserActivity.day_of_week)
        )
        
        result = db.execute(query).all()
        return {day: count for day, count in result}
    
    def get_activity_count_by_time(
        self, db: Session, user_id: uuid.UUID, start_date: datetime.datetime, end_date: datetime.datetime
    ) -> Dict[str, int]:
        """
        Get activity count grouped by time of day for a user
        
        Args:
            db: Database session
            user_id: ID of the user
            start_date: Start date for filtering
            end_date: End date for filtering
            
        Returns:
            Dictionary with time of day as key and activity count as value
        """
        query = (
            select(UserActivity.time_of_day, func.count(UserActivity.id))
            .where(and_(
                UserActivity.user_id == user_id,
                UserActivity.activity_date >= start_date,
                UserActivity.activity_date <= end_date
            ))
            .group_by(UserActivity.time_of_day)
        )
        
        result = db.execute(query).all()
        return {time_of_day: count for time_of_day, count in result}
    
    def record_activity(
        self, 
        db: Session, 
        user_id: uuid.UUID, 
        activity_type: ActionType, 
        metadata: Optional[Dict] = None,
        activity_date: Optional[datetime.datetime] = None
    ) -> UserActivity:
        """
        Record a new user activity
        
        Args:
            db: Database session
            user_id: ID of the user
            activity_type: Type of activity
            metadata: Additional activity data
            activity_date: When the activity occurred (defaults to current time)
            
        Returns:
            The created activity record
        """
        # Use current time if not provided
        if not activity_date:
            activity_date = datetime.datetime.utcnow()
        
        # Calculate time of day and day of week
        time_of_day = UserActivity.get_time_of_day(activity_date)
        day_of_week = UserActivity.get_day_of_week(activity_date)
        
        # Create new activity
        activity = UserActivity(
            user_id=user_id,
            activity_type=activity_type,
            activity_date=activity_date,
            time_of_day=time_of_day,
            day_of_week=day_of_week,
            metadata=metadata or {}
        )
        
        db.add(activity)
        db.commit()
        db.refresh(activity)
        
        logger.info(
            f"Recorded activity: {activity_type.value} for user {user_id}",
            extra={"user_id": str(user_id), "activity_type": activity_type.value}
        )
        
        return activity


class CRUDUsageStatistics(CRUDBase[UsageStatistics, Dict[str, Any], Dict[str, Any]]):
    """CRUD operations for UsageStatistics model"""
    
    def __init__(self):
        """Initialize with UsageStatistics model"""
        super().__init__(UsageStatistics)
    
    def get_by_user_and_period(
        self, db: Session, user_id: uuid.UUID, period_type: PeriodType, period_value: str
    ) -> Optional[UsageStatistics]:
        """
        Get usage statistics for a user and specific period
        
        Args:
            db: Database session
            user_id: ID of the user
            period_type: Type of period (DAY, WEEK, MONTH)
            period_value: Value for the period
            
        Returns:
            Usage statistics for the period or None if not found
        """
        query = (
            select(UsageStatistics)
            .where(and_(
                UsageStatistics.user_id == user_id,
                UsageStatistics.period_type == period_type,
                UsageStatistics.period_value == period_value
            ))
        )
        
        return db.execute(query).scalars().first()
    
    def get_or_create(
        self, db: Session, user_id: uuid.UUID, period_type: PeriodType, period_value: str
    ) -> UsageStatistics:
        """
        Get usage statistics for a period or create if not exists
        
        Args:
            db: Database session
            user_id: ID of the user
            period_type: Type of period (DAY, WEEK, MONTH)
            period_value: Value for the period
            
        Returns:
            Existing or newly created usage statistics
        """
        # Try to get existing statistics
        stats = self.get_by_user_and_period(db, user_id, period_type, period_value)
        
        # If not found, create new statistics
        if not stats:
            stats = UsageStatistics(
                user_id=user_id,
                period_type=period_type,
                period_value=period_value,
                total_journal_entries=0,
                total_journaling_minutes=0,
                total_checkins=0,
                total_tool_usage=0,
                tool_usage_by_category={},
                active_time_of_day=None,
                most_productive_day=None
            )
            
            db.add(stats)
            db.commit()
            db.refresh(stats)
            
            logger.info(
                f"Created new usage statistics for user {user_id}, period: {period_type.value} {period_value}",
                extra={
                    "user_id": str(user_id),
                    "period_type": period_type.value,
                    "period_value": period_value
                }
            )
        
        return stats
    
    def update_from_activities(
        self, 
        db: Session, 
        user_id: uuid.UUID, 
        period_type: PeriodType, 
        period_value: str,
        activities: List[UserActivity]
    ) -> UsageStatistics:
        """
        Update usage statistics based on user activities
        
        Args:
            db: Database session
            user_id: ID of the user
            period_type: Type of period (DAY, WEEK, MONTH)
            period_value: Value for the period
            activities: List of activities to process
            
        Returns:
            Updated usage statistics
        """
        # Get or create statistics
        stats = self.get_or_create(db, user_id, period_type, period_value)
        
        # Update statistics from activities
        stats.update_from_activities(activities)
        
        # Save changes
        db.add(stats)
        db.commit()
        db.refresh(stats)
        
        logger.info(
            f"Updated usage statistics for user {user_id}, period: {period_type.value} {period_value}",
            extra={
                "user_id": str(user_id),
                "period_type": period_type.value,
                "period_value": period_value,
                "activity_count": len(activities)
            }
        )
        
        return stats
    
    def get_most_active_period(
        self, db: Session, user_id: uuid.UUID, period_type: PeriodType
    ) -> Optional[UsageStatistics]:
        """
        Get the most active period for a user
        
        Args:
            db: Database session
            user_id: ID of the user
            period_type: Type of period (DAY, WEEK, MONTH)
            
        Returns:
            Statistics for the most active period or None
        """
        # Create a combined activity score expression
        activity_score = (
            UsageStatistics.total_journal_entries + 
            UsageStatistics.total_checkins + 
            UsageStatistics.total_tool_usage
        )
        
        query = (
            select(UsageStatistics)
            .where(and_(
                UsageStatistics.user_id == user_id,
                UsageStatistics.period_type == period_type
            ))
            .order_by(desc(activity_score))
            .limit(1)
        )
        
        return db.execute(query).scalars().first()


class CRUDProgressInsight(CRUDBase[ProgressInsight, Dict[str, Any], Dict[str, Any]]):
    """CRUD operations for ProgressInsight model"""
    
    def __init__(self):
        """Initialize with ProgressInsight model"""
        super().__init__(ProgressInsight)
    
    def get_by_user(
        self, db: Session, user_id: uuid.UUID, skip: int = 0, limit: int = 100
    ) -> List[ProgressInsight]:
        """
        Get insights for a specific user
        
        Args:
            db: Database session
            user_id: ID of the user
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of progress insights for the user
        """
        query = (
            select(ProgressInsight)
            .where(ProgressInsight.user_id == user_id)
            .order_by(desc(ProgressInsight.created_at))
            .offset(skip)
            .limit(limit)
        )
        
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_by_user_and_type(
        self, db: Session, user_id: uuid.UUID, insight_type: InsightType, skip: int = 0, limit: int = 100
    ) -> List[ProgressInsight]:
        """
        Get insights for a user filtered by insight type
        
        Args:
            db: Database session
            user_id: ID of the user
            insight_type: Type of insight to filter by
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of progress insights of the specified type
        """
        query = (
            select(ProgressInsight)
            .where(and_(
                ProgressInsight.user_id == user_id,
                ProgressInsight.type == insight_type.value
            ))
            .order_by(desc(ProgressInsight.created_at))
            .offset(skip)
            .limit(limit)
        )
        
        result = db.execute(query).scalars().all()
        return list(result)
    
    def create_insight(
        self,
        db: Session,
        user_id: uuid.UUID,
        insight_type: InsightType,
        title: str,
        description: str,
        supporting_data: str,
        actionable_steps: List[str],
        related_tools: List[str],
        confidence: float
    ) -> ProgressInsight:
        """
        Create a new progress insight
        
        Args:
            db: Database session
            user_id: ID of the user
            insight_type: Type of insight
            title: Short title describing the insight
            description: Detailed description of the insight
            supporting_data: Supporting data or evidence
            actionable_steps: Actionable steps the user can take
            related_tools: Related tools that might help
            confidence: Confidence level of the insight (0-1)
            
        Returns:
            The created insight
        """
        insight = ProgressInsight(
            user_id=user_id,
            type=insight_type.value,
            title=title,
            description=description,
            supporting_data=supporting_data,
            actionable_steps=actionable_steps,
            related_tools=related_tools,
            confidence=confidence
        )
        
        db.add(insight)
        db.commit()
        db.refresh(insight)
        
        logger.info(
            f"Created new progress insight for user {user_id}: {title}",
            extra={
                "user_id": str(user_id),
                "insight_type": insight_type.value,
                "confidence": confidence
            }
        )
        
        return insight
    
    def get_recent_insights(
        self, db: Session, user_id: uuid.UUID, limit: int = 5
    ) -> List[ProgressInsight]:
        """
        Get recent insights for a user
        
        Args:
            db: Database session
            user_id: ID of the user
            limit: Maximum number of insights to return
            
        Returns:
            List of recent progress insights
        """
        query = (
            select(ProgressInsight)
            .where(ProgressInsight.user_id == user_id)
            .order_by(desc(ProgressInsight.created_at))
            .limit(limit)
        )
        
        result = db.execute(query).scalars().all()
        return list(result)
    
    def get_high_confidence_insights(
        self, db: Session, user_id: uuid.UUID, min_confidence: float = 0.7, limit: int = 5
    ) -> List[ProgressInsight]:
        """
        Get high confidence insights for a user
        
        Args:
            db: Database session
            user_id: ID of the user
            min_confidence: Minimum confidence threshold (0-1)
            limit: Maximum number of insights to return
            
        Returns:
            List of high confidence insights
        """
        query = (
            select(ProgressInsight)
            .where(and_(
                ProgressInsight.user_id == user_id,
                ProgressInsight.confidence >= min_confidence
            ))
            .order_by(desc(ProgressInsight.confidence), desc(ProgressInsight.created_at))
            .limit(limit)
        )
        
        result = db.execute(query).scalars().all()
        return list(result)


# Create singleton instances
user_activity = CRUDUserActivity()
usage_statistics = CRUDUsageStatistics()
progress_insight = CRUDProgressInsight()