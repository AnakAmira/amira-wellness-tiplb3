"""
Models for the tool library in the Amira Wellness application.

This module defines SQLAlchemy ORM models for tools, tool favorites, 
and tool usage tracking to support the emotional regulation tool library feature.
"""

from sqlalchemy import Column, String, Integer, Boolean, Text, JSON, ForeignKey, Enum, ARRAY, DateTime
from sqlalchemy.orm import relationship, validates

from .base import BaseModel
from ..constants.tools import (
    ToolCategory,
    ToolContentType,
    ToolDifficulty,
    TOOL_DURATION_MIN,
    TOOL_DURATION_MAX,
    TOOL_DURATION_DEFAULT
)
from ..constants.emotions import EmotionType


class Tool(BaseModel):
    """
    SQLAlchemy model representing a tool in the emotional regulation tool library.
    """
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    category = Column(Enum(ToolCategory), nullable=False, index=True)
    content_type = Column(Enum(ToolContentType), nullable=False)
    content = Column(JSON, nullable=False)
    estimated_duration = Column(Integer, default=TOOL_DURATION_DEFAULT, nullable=False)
    difficulty = Column(Enum(ToolDifficulty), nullable=False, default=ToolDifficulty.BEGINNER)
    target_emotions = Column(ARRAY(Integer), nullable=True)
    icon_url = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    is_premium = Column(Boolean, default=False, nullable=False, index=True)
    
    # Relationships
    favorites = relationship("ToolFavorite", back_populates="tool", cascade="all, delete-orphan")
    usages = relationship("ToolUsage", back_populates="tool", cascade="all, delete-orphan")
    
    __table_args__ = (
        # Check constraint for valid duration range
        {"check": f"estimated_duration BETWEEN {TOOL_DURATION_MIN} AND {TOOL_DURATION_MAX}"},
    )
    
    @validates('estimated_duration')
    def validate_duration(self, key, duration):
        """
        Validates that the tool duration is within allowed range.
        
        Args:
            key (str): Field name being validated
            duration (int): Duration value to validate
            
        Returns:
            int: Validated duration value
        """
        if duration < TOOL_DURATION_MIN:
            return TOOL_DURATION_MIN
        elif duration > TOOL_DURATION_MAX:
            return TOOL_DURATION_MAX
        return duration
    
    def get_content_value(self, key, default=None):
        """
        Retrieves a specific value from the content JSON.
        
        Args:
            key (str): Key to retrieve from content
            default (any, optional): Default value if key not found
            
        Returns:
            any: Value from content or default if not found
        """
        if not self.content or not isinstance(self.content, dict):
            return default
        
        return self.content.get(key, default)
    
    def is_targeted_for_emotion(self, emotion):
        """
        Checks if this tool is targeted for a specific emotion.
        
        Args:
            emotion (EmotionType): Emotion to check
            
        Returns:
            bool: True if the tool targets the emotion, False otherwise
        """
        if not self.target_emotions:
            return False
        
        return emotion.value in self.target_emotions


class ToolFavorite(BaseModel):
    """
    SQLAlchemy model representing a user's favorite tool.
    """
    user_id = Column(ForeignKey('users.id'), nullable=False)
    tool_id = Column(ForeignKey('tools.id'), nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="tool_favorites")
    tool = relationship("Tool", back_populates="favorites")
    
    __table_args__ = (
        # Unique constraint to prevent duplicate favorites
        {"unique": ("user_id", "tool_id")},
    )


class ToolUsage(BaseModel):
    """
    SQLAlchemy model representing a record of a user using a tool.
    """
    user_id = Column(ForeignKey('users.id'), nullable=False, index=True)
    tool_id = Column(ForeignKey('tools.id'), nullable=False, index=True)
    duration_seconds = Column(Integer, nullable=False)
    completed_at = Column(DateTime, nullable=False, index=True)
    completion_status = Column(String(50), nullable=False)
    pre_checkin_id = Column(ForeignKey('emotional_checkins.id'), nullable=True)
    post_checkin_id = Column(ForeignKey('emotional_checkins.id'), nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="tool_usages")
    tool = relationship("Tool", back_populates="usages")
    pre_checkin = relationship("EmotionalCheckin", foreign_keys=[pre_checkin_id])
    post_checkin = relationship("EmotionalCheckin", foreign_keys=[post_checkin_id])
    
    __table_args__ = (
        # Check constraint for valid completion status
        {"check": "completion_status IN ('COMPLETED', 'PARTIAL', 'ABANDONED')"},
    )
    
    def get_emotional_shift(self):
        """
        Calculates the emotional shift from pre to post check-in if available.
        
        Returns:
            dict: Dictionary with emotional shift data or None if not available
        """
        if not self.pre_checkin or not self.post_checkin:
            return None
        
        # Calculate the change in emotion intensity
        intensity_change = self.post_checkin.intensity - self.pre_checkin.intensity
        
        # Determine if the shift is positive, negative, or neutral
        if intensity_change > 0:
            shift_direction = "positive"
        elif intensity_change < 0:
            shift_direction = "negative"
        else:
            shift_direction = "neutral"
        
        # Return the emotional shift data
        return {
            "pre_emotion": self.pre_checkin.emotion_type,
            "post_emotion": self.post_checkin.emotion_type,
            "pre_intensity": self.pre_checkin.intensity,
            "post_intensity": self.post_checkin.intensity,
            "intensity_change": intensity_change,
            "shift_direction": shift_direction,
            "emotion_changed": self.pre_checkin.emotion_type != self.post_checkin.emotion_type
        }