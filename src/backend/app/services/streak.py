from typing import List, Dict, Optional, Tuple, Any
from datetime import date, datetime, timedelta
import uuid

from sqlalchemy.orm import Session

from ..core.logging import get_logger
from ..models.streak import Streak
from ..crud.streak import streak
from ..schemas.progress import StreakUpdate
from ..utils.date_helpers import get_current_date, is_streak_at_risk
from ..services.notification import NotificationService
from ..constants.achievements import AchievementType, ACHIEVEMENT_METADATA

# Initialize logger
logger = get_logger(__name__)

# Initialize notification service
notification_service = NotificationService()

# Streak milestone values for achievements
STREAK_MILESTONES = [3, 7, 14, 30, 60, 90]

# Mapping of streak milestones to achievement types
STREAK_ACHIEVEMENT_MAPPING = {
    3: AchievementType.STREAK_3_DAYS,
    7: AchievementType.STREAK_7_DAYS,
    14: AchievementType.STREAK_14_DAYS,
    30: AchievementType.STREAK_30_DAYS,
    60: AchievementType.STREAK_60_DAYS,
    90: AchievementType.STREAK_90_DAYS
}


def update_user_streak(db: Session, user_id: uuid.UUID, activity_date: date, use_grace_period: bool = False) -> Tuple[Streak, bool]:
    """
    Updates a user's streak based on activity date.
    
    Args:
        db: SQLAlchemy database session
        user_id: User's UUID
        activity_date: Date of the activity
        use_grace_period: Whether to use a grace period if available
        
    Returns:
        A tuple containing the updated streak record and a boolean indicating if the streak increased
    """
    logger.info(f"Updating streak for user {user_id} with activity date {activity_date}")
    
    # Get user's streak or create a new one if it doesn't exist
    streak_record = streak.get_by_user_id_or_create(db, user_id)
    
    # Create the streak update data
    streak_update = StreakUpdate(
        activity_date=activity_date,
        use_grace_period=use_grace_period
    )
    
    # Update the streak record
    streak_before = streak_record.current_streak
    updated_streak, streak_changed = streak.update_streak(db, user_id, streak_update)
    
    # Check if a milestone achievement was reached
    if updated_streak.current_streak > streak_before and updated_streak.current_streak in STREAK_MILESTONES:
        check_streak_milestone_achievement(db, user_id, updated_streak.current_streak)
    
    logger.debug(
        f"Streak updated for user {user_id}: current={updated_streak.current_streak}, "
        f"longest={updated_streak.longest_streak}, streak_changed={streak_changed}"
    )
    
    return updated_streak, streak_changed


def check_streak_milestone_achievement(db: Session, user_id: uuid.UUID, current_streak: int) -> bool:
    """
    Checks if a user has reached a streak milestone and creates an achievement if needed.
    
    Args:
        db: SQLAlchemy database session
        user_id: User's UUID
        current_streak: Current streak value
        
    Returns:
        Boolean indicating whether an achievement was created
    """
    # Check if the current streak matches a milestone
    if current_streak not in STREAK_MILESTONES:
        return False
    
    # Get the corresponding achievement type for this milestone
    achievement_type = STREAK_ACHIEVEMENT_MAPPING.get(current_streak)
    if not achievement_type:
        logger.warning(f"No achievement type found for streak milestone {current_streak}")
        return False
    
    # Get achievement metadata
    achievement_data = ACHIEVEMENT_METADATA.get(achievement_type, {})
    if not achievement_data:
        logger.warning(f"No achievement metadata found for achievement type {achievement_type}")
        return False
    
    # Get achievement name and description based on metadata
    achievement_name = achievement_data.get("name_es", f"Racha de {current_streak} días")
    achievement_description = achievement_data.get("description_es", f"¡Has usado la aplicación durante {current_streak} días consecutivos!")
    
    # Create achievement notification
    notification_service.create_achievement_notification(
        db=db,
        user_id=user_id,
        achievement_name=achievement_name,
        achievement_description=achievement_description,
        achievement_id=str(achievement_type.value)
    )
    
    logger.info(f"Created streak milestone achievement for user {user_id}: {achievement_type.value} ({current_streak} days)")
    return True


def get_user_streak(db: Session, user_id: uuid.UUID) -> Streak:
    """
    Gets a user's current streak information.
    
    Args:
        db: SQLAlchemy database session
        user_id: User's UUID
        
    Returns:
        The user's streak record
    """
    return streak.get_by_user_id_or_create(db, user_id)


def reset_user_streak(db: Session, user_id: uuid.UUID) -> Streak:
    """
    Resets a user's streak to zero.
    
    Args:
        db: SQLAlchemy database session
        user_id: User's UUID
        
    Returns:
        The reset streak record
    """
    logger.info(f"Resetting streak for user {user_id}")
    streak_record = streak.reset_streak(db, user_id)
    return streak_record


def get_next_streak_milestone(db: Session, user_id: uuid.UUID) -> int:
    """
    Gets the next milestone for a user's streak.
    
    Args:
        db: SQLAlchemy database session
        user_id: User's UUID
        
    Returns:
        The next milestone value
    """
    streak_record = streak.get_by_user_id_or_create(db, user_id)
    return streak_record.get_next_milestone()


def send_streak_reminders(db: Session) -> int:
    """
    Sends reminders to users whose streaks are at risk of being broken.
    
    Args:
        db: SQLAlchemy database session
        
    Returns:
        Number of reminders sent
    """
    logger.info("Starting to send streak reminders to users with streaks at risk")
    
    # Get current date for reference
    current_date = get_current_date()
    
    # Get users with streaks at risk
    users_at_risk = streak.get_users_with_streak_at_risk(db)
    
    # Counter for reminders sent
    reminders_sent = 0
    
    # Send reminders to each user
    for streak_record in users_at_risk:
        user_id = streak_record.user_id
        current_streak = streak_record.current_streak
        
        # Create streak reminder notification
        notification = notification_service.create_streak_reminder(
            db=db,
            user_id=user_id,
            current_streak=current_streak
        )
        
        if notification:
            reminders_sent += 1
            logger.debug(f"Sent streak reminder to user {user_id} (current streak: {current_streak})")
    
    logger.info(f"Sent {reminders_sent} streak reminders to users with streaks at risk")
    return reminders_sent


def process_streak_milestones(db: Session) -> int:
    """
    Processes users who have reached streak milestones and creates achievements.
    
    Args:
        db: SQLAlchemy database session
        
    Returns:
        Number of achievements created
    """
    logger.info("Starting to process streak milestones")
    
    # Counter for achievements created
    achievements_created = 0
    
    # Process each milestone
    for milestone in STREAK_MILESTONES:
        # Get users who have exactly reached this milestone
        users_with_milestone = streak.get_users_with_milestone_reached(db, milestone)
        
        for streak_record in users_with_milestone:
            user_id = streak_record.user_id
            
            # Create achievement notification
            if check_streak_milestone_achievement(db, user_id, milestone):
                achievements_created += 1
                logger.debug(f"Created achievement for user {user_id} reaching {milestone} day streak milestone")
    
    logger.info(f"Created {achievements_created} streak milestone achievements")
    return achievements_created


def get_streak_statistics(db: Session) -> Dict:
    """
    Gets statistics about user streaks.
    
    Args:
        db: SQLAlchemy database session
        
    Returns:
        Dictionary with various streak statistics
    """
    stats = streak.get_streak_statistics(db)
    return stats


def use_grace_period(db: Session, user_id: uuid.UUID) -> bool:
    """
    Attempts to use a grace period for a user's streak.
    
    Args:
        db: SQLAlchemy database session
        user_id: User's UUID
        
    Returns:
        Whether grace period was successfully used
    """
    logger.info(f"Attempting to use grace period for user {user_id}")
    
    # Get user's streak or create a new one if it doesn't exist
    streak_record = streak.get_by_user_id_or_create(db, user_id)
    
    # Attempt to use grace period
    grace_period_used = streak_record.use_grace_period()
    
    if grace_period_used:
        logger.info(f"Grace period successfully used for user {user_id}")
    else:
        logger.info(f"Could not use grace period for user {user_id} (already used or not available)")
    
    return grace_period_used


class StreakService:
    """
    Service for managing user streaks and related functionality.
    
    This service provides methods for tracking user streaks, processing streak milestones,
    sending streak reminders, and other streak-related operations to support the 
    gamification features of the Amira Wellness application.
    """
    
    def __init__(self):
        """
        Initialize the streak service with required dependencies.
        """
        self.logger = logger
        self.notification_service = notification_service
    
    def update_streak(self, db: Session, user_id: uuid.UUID, activity_date: date, use_grace_period: bool = False) -> Tuple[Streak, bool]:
        """
        Updates a user's streak based on activity date.
        
        Args:
            db: SQLAlchemy database session
            user_id: User's UUID
            activity_date: Date of the activity
            use_grace_period: Whether to use a grace period if available
            
        Returns:
            A tuple containing the updated streak record and a boolean indicating if the streak increased
        """
        return update_user_streak(db, user_id, activity_date, use_grace_period)
    
    def get_streak(self, db: Session, user_id: uuid.UUID) -> Streak:
        """
        Gets a user's current streak information.
        
        Args:
            db: SQLAlchemy database session
            user_id: User's UUID
            
        Returns:
            The user's streak record
        """
        return get_user_streak(db, user_id)
    
    def reset_streak(self, db: Session, user_id: uuid.UUID) -> Streak:
        """
        Resets a user's streak to zero.
        
        Args:
            db: SQLAlchemy database session
            user_id: User's UUID
            
        Returns:
            The reset streak record
        """
        return reset_user_streak(db, user_id)
    
    def get_next_milestone(self, db: Session, user_id: uuid.UUID) -> int:
        """
        Gets the next milestone for a user's streak.
        
        Args:
            db: SQLAlchemy database session
            user_id: User's UUID
            
        Returns:
            The next milestone value
        """
        return get_next_streak_milestone(db, user_id)
    
    def send_reminders(self, db: Session) -> int:
        """
        Sends reminders to users whose streaks are at risk of being broken.
        
        Args:
            db: SQLAlchemy database session
            
        Returns:
            Number of reminders sent
        """
        return send_streak_reminders(db)
    
    def process_milestones(self, db: Session) -> int:
        """
        Processes users who have reached streak milestones and creates achievements.
        
        Args:
            db: SQLAlchemy database session
            
        Returns:
            Number of achievements created
        """
        return process_streak_milestones(db)
    
    def get_statistics(self, db: Session) -> Dict:
        """
        Gets statistics about user streaks.
        
        Args:
            db: SQLAlchemy database session
            
        Returns:
            Dictionary with various streak statistics
        """
        return get_streak_statistics(db)
    
    def use_grace_period(self, db: Session, user_id: uuid.UUID) -> bool:
        """
        Attempts to use a grace period for a user's streak.
        
        Args:
            db: SQLAlchemy database session
            user_id: User's UUID
            
        Returns:
            Whether grace period was successfully used
        """
        return use_grace_period(db, user_id)
    
    def check_milestone_achievement(self, db: Session, user_id: uuid.UUID, current_streak: int) -> bool:
        """
        Checks if a user has reached a streak milestone and creates an achievement if needed.
        
        Args:
            db: SQLAlchemy database session
            user_id: User's UUID
            current_streak: Current streak value
            
        Returns:
            Boolean indicating whether an achievement was created
        """
        return check_streak_milestone_achievement(db, user_id, current_streak)


# Create singleton instance for application-wide use
streak_service = StreakService()