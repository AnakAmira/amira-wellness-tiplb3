from typing import Optional

from sqlalchemy import Column, String, Integer, Boolean, Enum
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from .base import BaseModel
from ..constants.achievements import (
    AchievementType,
    AchievementCategory,
    CriteriaType,
    ActionType,
    ACHIEVEMENT_METADATA,
    ACHIEVEMENT_POINTS_DEFAULT
)


class Achievement(BaseModel):
    """
    SQLAlchemy model representing an achievement template in the Amira Wellness application.
    
    Achievements are used to track user progress and reward users for meeting specific goals.
    Achievement templates define the criteria and metadata for different types of achievements.
    """
    
    # Define SQLAlchemy columns
    achievement_type = Column(Enum(AchievementType), unique=True, nullable=False, index=True)
    category = Column(Enum(AchievementCategory), nullable=False, index=True)
    name_es = Column(String(255), nullable=False)
    name_en = Column(String(255), nullable=False)
    description_es = Column(String(500), nullable=False)
    description_en = Column(String(500), nullable=False)
    icon_url = Column(String(255), nullable=False)
    points = Column(Integer, nullable=False, default=ACHIEVEMENT_POINTS_DEFAULT)
    is_hidden = Column(Boolean, nullable=False, default=False)
    criteria = Column(JSONB, nullable=False)
    metadata = Column(JSONB, nullable=True)
    
    # Relationships
    user_achievements = relationship("UserAchievement", back_populates="achievement")
    
    @classmethod
    def from_achievement_type(cls, achievement_type: AchievementType) -> "Achievement":
        """
        Creates an Achievement instance from an achievement type using the predefined metadata.
        
        Args:
            achievement_type: The AchievementType enum value to create an achievement for
            
        Returns:
            A new Achievement instance initialized with data from ACHIEVEMENT_METADATA
        """
        # Get metadata for the achievement type
        metadata = ACHIEVEMENT_METADATA.get(achievement_type, {})
        
        # Create a new achievement instance
        achievement = cls()
        achievement.achievement_type = achievement_type
        achievement.category = metadata.get("category")
        achievement.name_es = metadata.get("name_es", "")
        achievement.name_en = metadata.get("name_en", "")
        achievement.description_es = metadata.get("description_es", "")
        achievement.description_en = metadata.get("description_en", "")
        achievement.icon_url = metadata.get("icon_url", "")
        achievement.points = metadata.get("points", ACHIEVEMENT_POINTS_DEFAULT)
        achievement.is_hidden = metadata.get("is_hidden", False)
        achievement.criteria = metadata.get("criteria", {})
        achievement.metadata = metadata.get("metadata", {})
        
        return achievement
    
    def get_name(self, language_code: str) -> str:
        """
        Gets the achievement name in the specified language.
        
        Args:
            language_code: The language code (e.g., 'en' or 'es')
            
        Returns:
            The localized achievement name
        """
        if language_code == 'en':
            return self.name_en
        return self.name_es
    
    def get_description(self, language_code: str) -> str:
        """
        Gets the achievement description in the specified language.
        
        Args:
            language_code: The language code (e.g., 'en' or 'es')
            
        Returns:
            The localized achievement description
        """
        if language_code == 'en':
            return self.description_en
        return self.description_es
    
    def get_criteria_type(self) -> CriteriaType:
        """
        Gets the criteria type for this achievement.
        
        Returns:
            The criteria type enum value
        """
        criteria_type_str = self.criteria.get("type")
        if criteria_type_str:
            return CriteriaType(criteria_type_str)
        return None
    
    def get_criteria_target(self) -> int:
        """
        Gets the target value needed to earn this achievement.
        
        Returns:
            The target value as an integer
        """
        return self.criteria.get("target", 0)
    
    def get_criteria_action(self) -> ActionType:
        """
        Gets the action type that triggers progress for this achievement.
        
        Returns:
            The action type enum value
        """
        action_str = self.criteria.get("action")
        if action_str:
            return ActionType(action_str)
        return None
    
    def get_display_order(self) -> int:
        """
        Gets the display order for sorting achievements in the UI.
        
        Returns:
            The display order value (defaults to 999 if not specified)
        """
        if self.metadata and "display_order" in self.metadata:
            return self.metadata.get("display_order")
        return 999  # Default to a high number to put at the end
    
    def get_next_achievement(self) -> Optional[AchievementType]:
        """
        Gets the next achievement in a sequence if applicable.
        
        Returns:
            The next achievement type or None if there is no next achievement
        """
        if self.metadata and "next_achievement" in self.metadata:
            next_achievement = self.metadata.get("next_achievement")
            return AchievementType(next_achievement) if isinstance(next_achievement, str) else next_achievement
        return None
    
    def to_dict(self, language_code: str = 'es') -> dict:
        """
        Converts the achievement to a dictionary representation.
        
        Args:
            language_code: The language code for localizable fields (default: 'es')
            
        Returns:
            A dictionary representation of the achievement
        """
        # Start with base fields
        result = {
            "id": str(self.id),
            "achievement_type": self.achievement_type.value,
            "name": self.get_name(language_code),
            "description": self.get_description(language_code),
            "icon_url": self.icon_url,
            "points": self.points,
            "is_hidden": self.is_hidden,
            "category": self.category.value,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }
        
        # Add criteria information
        criteria_info = {
            "type": self.get_criteria_type().value if self.get_criteria_type() else None,
            "target": self.get_criteria_target(),
            "action": self.get_criteria_action().value if self.get_criteria_action() else None
        }
        
        # Add additional conditions if present
        if self.criteria.get("conditions"):
            criteria_info["conditions"] = self.criteria.get("conditions")
            
        result["criteria"] = criteria_info
        
        # Add relevant metadata
        if self.metadata:
            if "tags" in self.metadata:
                result["tags"] = self.metadata.get("tags")
            
            if "display_order" in self.metadata:
                result["display_order"] = self.metadata.get("display_order")
                
            if "next_achievement" in self.metadata:
                next_achievement = self.metadata.get("next_achievement")
                if isinstance(next_achievement, AchievementType):
                    result["next_achievement"] = next_achievement.value
                else:
                    result["next_achievement"] = next_achievement
        
        return result