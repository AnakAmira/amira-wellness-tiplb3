"""
SQLAlchemy ORM models for emotional data in the Amira Wellness application. 
Defines database schemas for emotional check-ins, trends, and insights to support 
the core emotional tracking functionality of the application.
"""

from sqlalchemy import Column, String, Integer, Float, Text, ForeignKey, Enum
from sqlalchemy.orm import relationship, validates

from .base import BaseModel
from ..constants.emotions import (
    EmotionType, EmotionContext, TrendDirection, PeriodType,
    EMOTION_INTENSITY_MIN, EMOTION_INTENSITY_MAX
)


class EmotionalCheckin(BaseModel):
    """
    SQLAlchemy model representing an emotional check-in in the Amira Wellness application.
    
    Emotional check-ins track a user's emotional state at a specific point in time, 
    including the type of emotion, its intensity, and contextual information.
    """
    user_id = Column(ForeignKey('users.id'), nullable=False, index=True)
    emotion_type = Column(Enum(EmotionType), nullable=False)
    intensity = Column(Integer, nullable=False)
    context = Column(Enum(EmotionContext), nullable=False)
    notes = Column(Text, nullable=True)
    related_journal_id = Column(ForeignKey('journals.id'), nullable=True)
    related_tool_id = Column(ForeignKey('tools.id'), nullable=True)
    
    # Relationships will be uncommented when the referenced models are available
    # user = relationship("User", back_populates="emotional_checkins")
    # journal = relationship("Journal", back_populates="emotional_checkins")
    # tool = relationship("Tool", back_populates="emotional_checkins")
    
    @validates('intensity')
    def validate_intensity(self, key, intensity):
        """
        Validates that intensity is within allowed range.
        
        Args:
            key (str): The key being validated
            intensity (int): The intensity value to validate
            
        Returns:
            int: Validated intensity value
            
        Raises:
            ValueError: If intensity is outside allowed range
        """
        if not (EMOTION_INTENSITY_MIN <= intensity <= EMOTION_INTENSITY_MAX):
            raise ValueError(
                f"Intensity must be between {EMOTION_INTENSITY_MIN} and {EMOTION_INTENSITY_MAX}"
            )
        return intensity
    
    def get_emotion_metadata(self):
        """
        Gets metadata for the emotion type.
        
        Returns:
            dict: Emotion metadata including display name, description, and color
        """
        from ..constants.emotions import get_emotion_display_name, get_emotion_description, get_emotion_color
        
        return {
            'display_name': get_emotion_display_name(self.emotion_type),
            'description': get_emotion_description(self.emotion_type),
            'color': get_emotion_color(self.emotion_type)
        }
    
    def is_accessible_by_user(self, user_id):
        """
        Checks if an emotional check-in is accessible by a specific user.
        
        Args:
            user_id (UUID): The user ID to check access for
            
        Returns:
            bool: True if the check-in is accessible by the user, False otherwise
        """
        return self.user_id == user_id


class EmotionalTrend(BaseModel):
    """
    SQLAlchemy model representing an emotional trend for analysis and visualization.
    
    Emotional trends aggregate emotional data over time periods to identify patterns
    and changes in a user's emotional state.
    """
    user_id = Column(ForeignKey('users.id'), nullable=False, index=True)
    period_type = Column(Enum(PeriodType), nullable=False)
    period_value = Column(String(50), nullable=False)  # e.g., '2023-01', '2023-W01'
    emotion_type = Column(Enum(EmotionType), nullable=False)
    occurrence_count = Column(Integer, nullable=False, default=0)
    average_intensity = Column(Float, nullable=False, default=0.0)
    min_intensity = Column(Integer, nullable=False)
    max_intensity = Column(Integer, nullable=False)
    trend_direction = Column(Enum(TrendDirection), nullable=True)
    
    # Relationships will be uncommented when the referenced models are available
    # user = relationship("User", back_populates="emotional_trends")
    
    def calculate_trend_direction(self, historical_intensities):
        """
        Calculates the trend direction based on historical data.
        
        Args:
            historical_intensities (list): List of historical intensity values
            
        Returns:
            TrendDirection: Direction of the emotional trend
        """
        if len(historical_intensities) < 2:
            return None
            
        # Simple trend calculation - more sophisticated algorithms can be implemented
        first = historical_intensities[0]
        last = historical_intensities[-1]
        
        # Calculate the average change
        changes = [historical_intensities[i] - historical_intensities[i-1] 
                  for i in range(1, len(historical_intensities))]
        avg_change = sum(changes) / len(changes)
        
        # Calculate variance to determine stability
        variance = sum((c - avg_change) ** 2 for c in changes) / len(changes)
        
        if variance > 2.0:  # Threshold for fluctuation
            return TrendDirection.FLUCTUATING
        elif abs(last - first) < 1.0:  # Threshold for stability
            return TrendDirection.STABLE
        elif last > first:
            return TrendDirection.INCREASING
        else:
            return TrendDirection.DECREASING
    
    def is_accessible_by_user(self, user_id):
        """
        Checks if an emotional trend is accessible by a specific user.
        
        Args:
            user_id (UUID): The user ID to check access for
            
        Returns:
            bool: True if the trend is accessible by the user, False otherwise
        """
        return self.user_id == user_id


class EmotionalInsight(BaseModel):
    """
    SQLAlchemy model representing an insight derived from emotional data analysis.
    
    Emotional insights store patterns, correlations, and recommendations identified
    through analysis of a user's emotional data.
    """
    user_id = Column(ForeignKey('users.id'), nullable=False, index=True)
    type = Column(String(50), nullable=False)  # Pattern, Trigger, Improvement, etc.
    description = Column(Text, nullable=False)
    related_emotions = Column(String(255), nullable=True)  # Comma-separated emotion types
    confidence = Column(Float, nullable=False, default=0.0)  # 0.0 to 1.0
    recommended_actions = Column(Text, nullable=True)
    
    # Relationships will be uncommented when the referenced models are available
    # user = relationship("User", back_populates="emotional_insights")
    
    def is_accessible_by_user(self, user_id):
        """
        Checks if an emotional insight is accessible by a specific user.
        
        Args:
            user_id (UUID): The user ID to check access for
            
        Returns:
            bool: True if the insight is accessible by the user, False otherwise
        """
        return self.user_id == user_id