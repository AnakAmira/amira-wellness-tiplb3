from typing import Dict, List, Optional, Tuple
from datetime import date, datetime, timedelta
import uuid

from sqlalchemy import select, func
from sqlalchemy.orm import Session

from .base import CRUDBase
from ..models.streak import Streak
from ..schemas.progress import StreakUpdate, StreakBase
from ..core.logging import get_logger
from ..core.exceptions import ResourceNotFoundException

# Initialize logger
logger = get_logger(__name__)

class CRUDStreak(CRUDBase[Streak, StreakBase, StreakUpdate]):
    """
    CRUD operations for the Streak model.
    
    This class provides database access methods for creating, retrieving, updating,
    and deleting streak records, as well as specialized queries for streak-related
    features like milestone tracking and streak risk detection.
    """
    
    def __init__(self):
        """
        Initialize the CRUD operations for the Streak model.
        """
        super().__init__(Streak)
    
    def get_by_user_id(self, db: Session, user_id: uuid.UUID) -> Optional[Streak]:
        """
        Get a user's streak record by user ID.
        
        Args:
            db: SQLAlchemy database session
            user_id: ID of the user
            
        Returns:
            The user's streak record if found, None otherwise
        """
        query = select(Streak).where(Streak.user_id == user_id)
        result = db.execute(query).scalars().first()
        return result
    
    def get_by_user_id_or_create(self, db: Session, user_id: uuid.UUID) -> Streak:
        """
        Get a user's streak record or create a new one if it doesn't exist.
        
        Args:
            db: SQLAlchemy database session
            user_id: ID of the user
            
        Returns:
            The existing or newly created streak record
        """
        streak = self.get_by_user_id(db, user_id)
        
        if not streak:
            # Create a new streak record with default values
            streak = Streak(
                user_id=user_id,
                current_streak=0,
                longest_streak=0,
                total_days_active=0,
                streak_history=[],
                grace_period_used_count=0,
                grace_period_active=False
            )
            db.add(streak)
            db.commit()
            db.refresh(streak)
            
        return streak
    
    def update_streak(self, db: Session, user_id: uuid.UUID, streak_update: StreakUpdate) -> Tuple[Streak, bool]:
        """
        Update a user's streak with a new activity date.
        
        Args:
            db: SQLAlchemy database session
            user_id: ID of the user
            streak_update: Update data containing activity date and grace period usage
            
        Returns:
            Tuple containing the updated streak record and a boolean indicating whether the streak increased
        """
        # Get or create the streak record
        streak = self.get_by_user_id_or_create(db, user_id)
        
        # Extract update data
        activity_date = streak_update.activity_date
        use_grace_period = streak_update.use_grace_period
        
        # Track if the streak was increased
        streak_before = streak.current_streak
        
        # Record the activity
        streak_changed = streak.record_activity(activity_date)
        
        # Apply grace period if requested and available
        if use_grace_period and streak.current_streak == 0:
            if streak.use_grace_period():
                streak_changed = True
        
        # Save changes
        db.add(streak)
        db.commit()
        db.refresh(streak)
        
        # Return the updated streak and whether it increased
        return streak, streak.current_streak > streak_before
    
    def reset_streak(self, db: Session, user_id: uuid.UUID) -> Streak:
        """
        Reset a user's streak to zero.
        
        Args:
            db: SQLAlchemy database session
            user_id: ID of the user
            
        Returns:
            The reset streak record
        """
        streak = self.get_by_user_id_or_create(db, user_id)
        
        # Reset streak
        streak.reset_streak()
        
        db.add(streak)
        db.commit()
        db.refresh(streak)
        
        return streak
    
    def get_next_milestone(self, db: Session, user_id: uuid.UUID) -> int:
        """
        Get the next milestone for a user's streak.
        
        Args:
            db: SQLAlchemy database session
            user_id: ID of the user
            
        Returns:
            The next milestone value
        """
        streak = self.get_by_user_id_or_create(db, user_id)
        return streak.get_next_milestone()
    
    def get_top_streaks(self, db: Session, limit: int = 10) -> List[Streak]:
        """
        Get users with the highest current streaks.
        
        Args:
            db: SQLAlchemy database session
            limit: Maximum number of records to return
            
        Returns:
            List of streak records sorted by current_streak descending
        """
        query = select(Streak).order_by(Streak.current_streak.desc()).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_users_with_milestone_reached(self, db: Session, milestone: int) -> List[Streak]:
        """
        Get users who have reached a specific streak milestone.
        
        Args:
            db: SQLAlchemy database session
            milestone: Streak milestone value to check for
            
        Returns:
            List of streak records that exactly match the milestone
        """
        query = select(Streak).where(Streak.current_streak == milestone)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_users_with_streak_at_risk(self, db: Session, reference_date: date = None) -> List[Streak]:
        """
        Get users whose streaks are at risk of being broken.
        
        This method identifies users who haven't recorded activity today but have
        an active streak from yesterday, meaning they need to take action today
        to maintain their streak.
        
        Args:
            db: SQLAlchemy database session
            reference_date: Date to check against (defaults to today)
            
        Returns:
            List of streak records with last_activity_date one day before reference_date
        """
        if reference_date is None:
            reference_date = date.today()
        
        # Calculate the date that would put streaks at risk
        risk_date = reference_date - timedelta(days=1)
        
        # Find users with active streaks (> 0) who last had activity on the risk date
        query = select(Streak).where(
            (Streak.current_streak > 0) & 
            (Streak.last_activity_date == risk_date)
        )
        
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_streak_statistics(self, db: Session) -> Dict:
        """
        Get statistics about user streaks.
        
        This method calculates various metrics including average streak,
        maximum streak, and distribution of streak values.
        
        Args:
            db: SQLAlchemy database session
            
        Returns:
            Dictionary with various streak statistics
        """
        # Average current streak
        avg_query = select(func.avg(Streak.current_streak))
        avg_streak = db.execute(avg_query).scalar_one() or 0
        
        # Maximum current streak
        max_query = select(func.max(Streak.current_streak))
        max_streak = db.execute(max_query).scalar_one() or 0
        
        # Average longest streak
        avg_longest_query = select(func.avg(Streak.longest_streak))
        avg_longest_streak = db.execute(avg_longest_query).scalar_one() or 0
        
        # Maximum longest streak
        max_longest_query = select(func.max(Streak.longest_streak))
        max_longest_streak = db.execute(max_longest_query).scalar_one() or 0
        
        # Count of active streaks (current_streak > 0)
        active_query = select(func.count()).select_from(Streak).where(Streak.current_streak > 0)
        active_streaks = db.execute(active_query).scalar_one() or 0
        
        # Count of total streak records
        total_query = select(func.count()).select_from(Streak)
        total_streaks = db.execute(total_query).scalar_one() or 0
        
        # Return compiled statistics
        return {
            "average_current_streak": round(avg_streak, 2),
            "max_current_streak": max_streak,
            "average_longest_streak": round(avg_longest_streak, 2),
            "max_longest_streak": max_longest_streak,
            "active_streaks_count": active_streaks,
            "total_users_count": total_streaks,
            "active_streak_percentage": round((active_streaks / total_streaks * 100) if total_streaks > 0 else 0, 2)
        }

# Create a singleton instance
streak = CRUDStreak()