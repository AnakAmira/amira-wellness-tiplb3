"""
CRUD operations for emotional data in the Amira Wellness application.
Implements database operations for emotional check-ins, trends, and insights,
supporting the core emotional tracking functionality of the application.
"""

from typing import List, Dict, Optional, Any, Tuple, Union
import uuid
import datetime

from sqlalchemy import select, func, and_, or_, desc
from sqlalchemy.orm import Session

from .base import CRUDBase
from ..models.emotion import EmotionalCheckin, EmotionalTrend, EmotionalInsight
from ..schemas.emotion import EmotionalStateCreate, EmotionalState, EmotionalStateFilter
from ..constants.emotions import EmotionType, EmotionContext, PeriodType
from ..core.logging import get_logger
from ..core.exceptions import ResourceNotFoundException

# Initialize logger
logger = get_logger(__name__)


class CRUDEmotionalCheckin(CRUDBase[EmotionalCheckin, EmotionalStateCreate, EmotionalState]):
    """CRUD operations for emotional check-ins"""
    
    def __init__(self):
        """Initialize the CRUD operations for emotional check-ins"""
        super().__init__(EmotionalCheckin)
    
    def get_by_user(self, db: Session, user_id: uuid.UUID, skip: int = 0, limit: int = 100) -> List[EmotionalCheckin]:
        """
        Get emotional check-ins for a specific user
        
        Args:
            db: Database session
            user_id: User ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional check-ins for the user
        """
        query = select(self.model).where(self.model.user_id == user_id).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_by_journal(self, db: Session, journal_id: uuid.UUID) -> List[EmotionalCheckin]:
        """
        Get emotional check-ins related to a specific journal
        
        Args:
            db: Database session
            journal_id: Journal ID to filter by
            
        Returns:
            List of emotional check-ins for the journal
        """
        query = select(self.model).where(self.model.related_journal_id == journal_id).order_by(self.model.context)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_by_tool(self, db: Session, tool_id: uuid.UUID, skip: int = 0, limit: int = 100) -> List[EmotionalCheckin]:
        """
        Get emotional check-ins related to a specific tool
        
        Args:
            db: Database session
            tool_id: Tool ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional check-ins for the tool
        """
        query = select(self.model).where(self.model.related_tool_id == tool_id).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_by_emotion_type(self, db: Session, emotion_type: EmotionType, user_id: Optional[uuid.UUID] = None, skip: int = 0, limit: int = 100) -> List[EmotionalCheckin]:
        """
        Get emotional check-ins for a specific emotion type
        
        Args:
            db: Database session
            emotion_type: Emotion type to filter by
            user_id: Optional user ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional check-ins for the emotion type
        """
        conditions = [self.model.emotion_type == emotion_type]
        if user_id:
            conditions.append(self.model.user_id == user_id)
        
        query = select(self.model).where(and_(*conditions)).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_by_context(self, db: Session, context: EmotionContext, user_id: Optional[uuid.UUID] = None, skip: int = 0, limit: int = 100) -> List[EmotionalCheckin]:
        """
        Get emotional check-ins for a specific context
        
        Args:
            db: Database session
            context: Context to filter by
            user_id: Optional user ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional check-ins for the context
        """
        conditions = [self.model.context == context]
        if user_id:
            conditions.append(self.model.user_id == user_id)
        
        query = select(self.model).where(and_(*conditions)).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_by_date_range(self, db: Session, start_date: datetime.datetime, end_date: datetime.datetime, user_id: Optional[uuid.UUID] = None, skip: int = 0, limit: int = 100) -> List[EmotionalCheckin]:
        """
        Get emotional check-ins within a date range
        
        Args:
            db: Database session
            start_date: Start date for the range
            end_date: End date for the range
            user_id: Optional user ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional check-ins within the date range
        """
        conditions = [
            self.model.created_at >= start_date,
            self.model.created_at <= end_date
        ]
        
        if user_id:
            conditions.append(self.model.user_id == user_id)
        
        query = select(self.model).where(and_(*conditions)).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_filtered(self, db: Session, filters: EmotionalStateFilter, user_id: uuid.UUID, skip: int = 0, limit: int = 100) -> Tuple[List[EmotionalCheckin], int]:
        """
        Get emotional check-ins with complex filtering
        
        Args:
            db: Database session
            filters: Filters to apply
            user_id: User ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            Tuple of (results, total_count)
        """
        conditions = [self.model.user_id == user_id]
        
        # Apply filters
        if filters.emotion_types:
            conditions.append(self.model.emotion_type.in_(filters.emotion_types))
        
        if filters.contexts:
            conditions.append(self.model.context.in_(filters.contexts))
        
        if filters.min_intensity is not None:
            conditions.append(self.model.intensity >= filters.min_intensity)
        
        if filters.max_intensity is not None:
            conditions.append(self.model.intensity <= filters.max_intensity)
        
        if filters.start_date:
            conditions.append(self.model.created_at >= filters.start_date)
        
        if filters.end_date:
            conditions.append(self.model.created_at <= filters.end_date)
        
        if filters.related_journal_id:
            conditions.append(self.model.related_journal_id == filters.related_journal_id)
        
        if filters.related_tool_id:
            conditions.append(self.model.related_tool_id == filters.related_tool_id)
        
        if filters.notes_contains:
            conditions.append(self.model.notes.ilike(f"%{filters.notes_contains}%"))
        
        # Get total count for pagination
        count_query = select(func.count()).select_from(self.model).where(and_(*conditions))
        total = db.execute(count_query).scalar_one()
        
        # Get paginated results
        query = select(self.model).where(and_(*conditions)).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        
        return list(results), total
    
    def get_emotion_distribution(self, db: Session, user_id: uuid.UUID, start_date: datetime.datetime, end_date: datetime.datetime) -> Dict[EmotionType, Dict[str, Any]]:
        """
        Get distribution of emotions for a user within a date range
        
        Args:
            db: Database session
            user_id: User ID to filter by
            start_date: Start date for the range
            end_date: End date for the range
            
        Returns:
            Dictionary mapping emotion types to their distribution data
        """
        conditions = [
            self.model.user_id == user_id,
            self.model.created_at >= start_date,
            self.model.created_at <= end_date
        ]
        
        # Query to get counts and stats for each emotion type
        query = select(
            self.model.emotion_type,
            func.count(self.model.id).label("count"),
            func.avg(self.model.intensity).label("avg_intensity"),
            func.min(self.model.intensity).label("min_intensity"),
            func.max(self.model.intensity).label("max_intensity")
        ).where(
            and_(*conditions)
        ).group_by(
            self.model.emotion_type
        )
        
        results = db.execute(query).all()
        
        # Calculate total count for percentages
        total_count = sum(row.count for row in results)
        
        # Format the results
        distribution = {}
        for row in results:
            distribution[row.emotion_type] = {
                "count": row.count,
                "percentage": (row.count / total_count * 100) if total_count > 0 else 0,
                "average_intensity": float(row.avg_intensity) if row.avg_intensity else 0,
                "min_intensity": row.min_intensity,
                "max_intensity": row.max_intensity
            }
        
        return distribution
    
    def get_latest_by_user(self, db: Session, user_id: uuid.UUID) -> Optional[EmotionalCheckin]:
        """
        Get the latest emotional check-in for a user
        
        Args:
            db: Database session
            user_id: User ID to filter by
            
        Returns:
            The latest emotional check-in or None if not found
        """
        query = select(self.model).where(self.model.user_id == user_id).order_by(desc(self.model.created_at)).limit(1)
        result = db.execute(query).scalars().first()
        return result
    
    def get_pre_post_journal(self, db: Session, journal_id: uuid.UUID) -> Tuple[Optional[EmotionalCheckin], Optional[EmotionalCheckin]]:
        """
        Get pre and post emotional check-ins for a journal
        
        Args:
            db: Database session
            journal_id: Journal ID to filter by
            
        Returns:
            Tuple of (pre_checkin, post_checkin)
        """
        check_ins = self.get_by_journal(db, journal_id)
        
        pre_checkin = None
        post_checkin = None
        
        for check_in in check_ins:
            if check_in.context == EmotionContext.PRE_JOURNALING:
                pre_checkin = check_in
            elif check_in.context == EmotionContext.POST_JOURNALING:
                post_checkin = check_in
        
        return pre_checkin, post_checkin


class CRUDEmotionalTrend(CRUDBase[EmotionalTrend, Any, Any]):
    """CRUD operations for emotional trends"""
    
    def __init__(self):
        """Initialize the CRUD operations for emotional trends"""
        super().__init__(EmotionalTrend)
    
    def get_by_user(self, db: Session, user_id: uuid.UUID, skip: int = 0, limit: int = 100) -> List[EmotionalTrend]:
        """
        Get emotional trends for a specific user
        
        Args:
            db: Database session
            user_id: User ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional trends for the user
        """
        query = select(self.model).where(self.model.user_id == user_id).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_by_period(self, db: Session, period_type: PeriodType, user_id: Optional[uuid.UUID] = None, skip: int = 0, limit: int = 100) -> List[EmotionalTrend]:
        """
        Get emotional trends for a specific period type
        
        Args:
            db: Database session
            period_type: Period type to filter by
            user_id: Optional user ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional trends for the period type
        """
        conditions = [self.model.period_type == period_type]
        if user_id:
            conditions.append(self.model.user_id == user_id)
        
        query = select(self.model).where(and_(*conditions)).order_by(desc(self.model.period_value)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_by_emotion_type(self, db: Session, emotion_type: EmotionType, user_id: Optional[uuid.UUID] = None, skip: int = 0, limit: int = 100) -> List[EmotionalTrend]:
        """
        Get emotional trends for a specific emotion type
        
        Args:
            db: Database session
            emotion_type: Emotion type to filter by
            user_id: Optional user ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional trends for the emotion type
        """
        conditions = [self.model.emotion_type == emotion_type]
        if user_id:
            conditions.append(self.model.user_id == user_id)
        
        query = select(self.model).where(and_(*conditions)).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_by_date_range(self, db: Session, start_date: datetime.datetime, end_date: datetime.datetime, user_id: Optional[uuid.UUID] = None, skip: int = 0, limit: int = 100) -> List[EmotionalTrend]:
        """
        Get emotional trends within a date range
        
        Args:
            db: Database session
            start_date: Start date for the range
            end_date: End date for the range
            user_id: Optional user ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional trends within the date range
        """
        conditions = [
            self.model.created_at >= start_date,
            self.model.created_at <= end_date
        ]
        
        if user_id:
            conditions.append(self.model.user_id == user_id)
        
        query = select(self.model).where(and_(*conditions)).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def calculate_trends(self, db: Session, user_id: uuid.UUID, start_date: datetime.datetime, end_date: datetime.datetime, period_type: PeriodType, emotion_types: Optional[List[EmotionType]] = None) -> List[EmotionalTrend]:
        """
        Calculate emotional trends from check-in data
        
        Args:
            db: Database session
            user_id: User ID to filter by
            start_date: Start date for the range
            end_date: End date for the range
            period_type: Period type for aggregation
            emotion_types: Optional list of emotion types to include
            
        Returns:
            Calculated emotional trends
        """
        # Determine the format string for the period based on period_type
        if period_type == PeriodType.DAY:
            period_format = 'YYYY-MM-DD'
        elif period_type == PeriodType.WEEK:
            period_format = 'YYYY-"W"IW'
        elif period_type == PeriodType.MONTH:
            period_format = 'YYYY-MM'
        else:
            raise ValueError(f"Unsupported period type: {period_type}")
        
        # Build the query conditions
        conditions = [
            EmotionalCheckin.user_id == user_id,
            EmotionalCheckin.created_at >= start_date,
            EmotionalCheckin.created_at <= end_date
        ]
        
        if emotion_types:
            conditions.append(EmotionalCheckin.emotion_type.in_(emotion_types))
        
        # Build the query to group check-ins by period and emotion type
        query = select(
            func.to_char(EmotionalCheckin.created_at, period_format).label("period"),
            EmotionalCheckin.emotion_type,
            func.count(EmotionalCheckin.id).label("count"),
            func.avg(EmotionalCheckin.intensity).label("avg_intensity"),
            func.min(EmotionalCheckin.intensity).label("min_intensity"),
            func.max(EmotionalCheckin.intensity).label("max_intensity")
        ).where(
            and_(*conditions)
        ).group_by(
            "period",
            EmotionalCheckin.emotion_type
        ).order_by(
            "period",
            EmotionalCheckin.emotion_type
        )
        
        results = db.execute(query).all()
        
        # Process the results into trend objects
        trends = []
        for row in results:
            # Create a new trend object
            trend = EmotionalTrend(
                user_id=user_id,
                period_type=period_type,
                period_value=row.period,
                emotion_type=row.emotion_type,
                occurrence_count=row.count,
                average_intensity=float(row.avg_intensity) if row.avg_intensity else 0,
                min_intensity=row.min_intensity,
                max_intensity=row.max_intensity
            )
            
            # Calculate trend direction (this would ideally use historical data)
            # In a real implementation, you would retrieve historical data for comparison
            
            # Save the trend to the database
            db.add(trend)
            trends.append(trend)
        
        db.commit()
        
        return trends


class CRUDEmotionalInsight(CRUDBase[EmotionalInsight, Any, Any]):
    """CRUD operations for emotional insights"""
    
    def __init__(self):
        """Initialize the CRUD operations for emotional insights"""
        super().__init__(EmotionalInsight)
    
    def get_by_user(self, db: Session, user_id: uuid.UUID, skip: int = 0, limit: int = 100) -> List[EmotionalInsight]:
        """
        Get emotional insights for a specific user
        
        Args:
            db: Database session
            user_id: User ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional insights for the user
        """
        query = select(self.model).where(self.model.user_id == user_id).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_by_type(self, db: Session, insight_type: str, user_id: Optional[uuid.UUID] = None, skip: int = 0, limit: int = 100) -> List[EmotionalInsight]:
        """
        Get emotional insights of a specific type
        
        Args:
            db: Database session
            insight_type: Insight type to filter by
            user_id: Optional user ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional insights of the specified type
        """
        conditions = [self.model.type == insight_type]
        if user_id:
            conditions.append(self.model.user_id == user_id)
        
        query = select(self.model).where(and_(*conditions)).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_by_confidence(self, db: Session, min_confidence: float, user_id: Optional[uuid.UUID] = None, skip: int = 0, limit: int = 100) -> List[EmotionalInsight]:
        """
        Get emotional insights with confidence above a threshold
        
        Args:
            db: Database session
            min_confidence: Minimum confidence threshold
            user_id: Optional user ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional insights with confidence above the threshold
        """
        conditions = [self.model.confidence >= min_confidence]
        if user_id:
            conditions.append(self.model.user_id == user_id)
        
        query = select(self.model).where(and_(*conditions)).order_by(desc(self.model.confidence)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_by_related_emotions(self, db: Session, emotion_types: List[EmotionType], user_id: Optional[uuid.UUID] = None, skip: int = 0, limit: int = 100) -> List[EmotionalInsight]:
        """
        Get emotional insights related to specific emotions
        
        Args:
            db: Database session
            emotion_types: List of emotion types to filter by
            user_id: Optional user ID to filter by
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of emotional insights related to the specified emotions
        """
        conditions = []
        
        # Convert emotion types to their string values for comparison
        emotion_values = [emotion_type.value for emotion_type in emotion_types]
        
        # Construct conditions that check if any of the emotion values are in the related_emotions field
        # This assumes related_emotions is stored as a comma-separated string
        for emotion_value in emotion_values:
            # Use a LIKE clause to check if the emotion is in the related_emotions field
            conditions.append(self.model.related_emotions.like(f"%{emotion_value}%"))
        
        # Use OR for emotion conditions (match any of the emotions)
        emotion_condition = or_(*conditions)
        
        # If there's a user_id condition, combine it with emotion condition using AND
        if user_id:
            final_condition = and_(emotion_condition, self.model.user_id == user_id)
        else:
            final_condition = emotion_condition
        
        query = select(self.model).where(final_condition).order_by(desc(self.model.created_at)).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def generate_insights(self, db: Session, user_id: uuid.UUID, start_date: datetime.datetime, end_date: datetime.datetime) -> List[EmotionalInsight]:
        """
        Generate emotional insights from check-in and trend data
        
        Args:
            db: Database session
            user_id: User ID to generate insights for
            start_date: Start date for the analysis period
            end_date: End date for the analysis period
            
        Returns:
            Generated emotional insights
        """
        # Get emotional check-ins for the period
        checkin_query = select(EmotionalCheckin).where(
            and_(
                EmotionalCheckin.user_id == user_id,
                EmotionalCheckin.created_at >= start_date,
                EmotionalCheckin.created_at <= end_date
            )
        ).order_by(EmotionalCheckin.created_at)
        
        checkins = db.execute(checkin_query).scalars().all()
        
        if not checkins:
            return []
        
        # Get existing trends for the period
        trend_query = select(EmotionalTrend).where(
            and_(
                EmotionalTrend.user_id == user_id,
                EmotionalTrend.created_at >= start_date,
                EmotionalTrend.created_at <= end_date
            )
        )
        
        trends = db.execute(trend_query).scalars().all()
        
        # Generate insights - this is a simplified implementation
        # In a real system, this would involve more sophisticated analysis
        insights = []
        
        # Example: Analyze patterns in emotional data
        # Count occurrences of each emotion type
        emotion_counts = {}
        for checkin in checkins:
            emotion_type = checkin.emotion_type
            if emotion_type not in emotion_counts:
                emotion_counts[emotion_type] = 0
            emotion_counts[emotion_type] += 1
        
        # Find the most common emotion
        most_common_emotion = max(emotion_counts.items(), key=lambda x: x[1])[0] if emotion_counts else None
        if most_common_emotion:
            # Create an insight for the most frequent emotion
            pattern_insight = EmotionalInsight(
                user_id=user_id,
                type="PATTERN",
                description=f"Your most frequently experienced emotion is {most_common_emotion.value}.",
                related_emotions=most_common_emotion.value,  # This is simplified - would store as a proper format in real implementation
                confidence=0.8,
                recommended_actions="Consider exploring tools specifically designed for managing this emotion."
            )
            db.add(pattern_insight)
            insights.append(pattern_insight)
        
        # Example: Detect improvements in emotional regulation
        # Check if negative emotions have decreased in intensity over time
        negative_emotions = [EmotionType.SADNESS, EmotionType.ANGER, EmotionType.FEAR, EmotionType.ANXIETY]
        negative_checkins = [c for c in checkins if c.emotion_type in negative_emotions]
        
        if len(negative_checkins) >= 5:  # Require a minimum number for analysis
            # Sort by date
            negative_checkins.sort(key=lambda x: x.created_at)
            
            # Calculate average intensity for first half and second half
            midpoint = len(negative_checkins) // 2
            first_half = negative_checkins[:midpoint]
            second_half = negative_checkins[midpoint:]
            
            first_half_avg = sum(c.intensity for c in first_half) / len(first_half)
            second_half_avg = sum(c.intensity for c in second_half) / len(second_half)
            
            # If intensity decreased, create an improvement insight
            if second_half_avg < first_half_avg:
                improvement_insight = EmotionalInsight(
                    user_id=user_id,
                    type="IMPROVEMENT",
                    description="Your negative emotions have been decreasing in intensity over time.",
                    related_emotions=",".join([e.value for e in negative_emotions]),  # Simplified
                    confidence=0.7,
                    recommended_actions="Continue with your current emotional regulation practices."
                )
                db.add(improvement_insight)
                insights.append(improvement_insight)
        
        # Commit the new insights to the database
        db.commit()
        
        return insights


# Create instances of the CRUD classes for export
emotion = CRUDEmotionalCheckin()
emotional_trend = CRUDEmotionalTrend()
emotional_insight = CRUDEmotionalInsight()