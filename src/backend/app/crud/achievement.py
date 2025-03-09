from typing import List, Dict, Optional, Union, Tuple
import uuid
import datetime

from sqlalchemy import select, and_, or_
from sqlalchemy.orm import Session

from .base import CRUDBase
from ..core.logging import get_logger
from ..models.achievement import Achievement
from ..constants.achievements import AchievementType, AchievementCategory, ACHIEVEMENT_METADATA
from ..core.exceptions import ResourceNotFoundException

# Initialize logger
logger = get_logger(__name__)

class CRUDAchievement(CRUDBase[Achievement, Dict, Dict]):
    """CRUD operations for Achievement model"""
    
    def __init__(self):
        """Initialize the CRUD operations for Achievement model"""
        super().__init__(Achievement)
        
    def get_by_type(self, db: Session, achievement_type: AchievementType) -> Optional[Achievement]:
        """
        Get an achievement by its type
        
        Args:
            db: SQLAlchemy database session
            achievement_type: The achievement type to look for
            
        Returns:
            The achievement if found, None otherwise
        """
        query = select(self.model).where(self.model.achievement_type == achievement_type)
        result = db.execute(query).scalars().first()
        return result
    
    def get_by_category(self, db: Session, category: AchievementCategory, skip: int = 0, limit: int = 100) -> List[Achievement]:
        """
        Get achievements by category
        
        Args:
            db: SQLAlchemy database session
            category: The achievement category to filter by
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of achievements in the specified category
        """
        query = select(self.model).where(self.model.category == category).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def get_or_create_by_type(self, db: Session, achievement_type: AchievementType) -> Tuple[Achievement, bool]:
        """
        Get an achievement by type or create it if it doesn't exist
        
        Args:
            db: SQLAlchemy database session
            achievement_type: The achievement type to get or create
            
        Returns:
            Tuple of (achievement, created) where created is True if a new achievement was created
        """
        # Try to get the achievement first
        achievement = self.get_by_type(db, achievement_type)
        
        # If it exists, return it with created=False
        if achievement:
            return achievement, False
        
        # If not, create it
        new_achievement = Achievement.from_achievement_type(achievement_type)
        db.add(new_achievement)
        db.commit()
        db.refresh(new_achievement)
        
        logger.info(f"Created new achievement: {achievement_type.value}")
        return new_achievement, True
    
    def get_visible_achievements(self, db: Session, skip: int = 0, limit: int = 100) -> List[Achievement]:
        """
        Get all non-hidden achievements
        
        Args:
            db: SQLAlchemy database session
            skip: Number of records to skip (for pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of visible achievements
        """
        query = select(self.model).where(self.model.is_hidden == False).offset(skip).limit(limit)
        results = db.execute(query).scalars().all()
        return list(results)
    
    def initialize_achievements(self, db: Session) -> List[Achievement]:
        """
        Initialize all achievements in the database from metadata
        
        Args:
            db: SQLAlchemy database session
            
        Returns:
            List of created or existing achievements
        """
        achievements = []
        
        # Get all achievement types from metadata
        for achievement_type in ACHIEVEMENT_METADATA.keys():
            achievement, _ = self.get_or_create_by_type(db, achievement_type)
            achievements.append(achievement)
        
        logger.info(f"Initialized {len(achievements)} achievements")
        return achievements

# Create a singleton instance to be imported and used throughout the application
achievement = CRUDAchievement()