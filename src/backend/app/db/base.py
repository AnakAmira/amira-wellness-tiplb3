"""
base.py

Central database module that imports and re-exports all SQLAlchemy models to avoid circular imports.
Provides helper functions to access model classes and ensures proper initialization of the database schema.
"""

# Import Base from session
from .session import Base

# Import all models that will be included in the SQLAlchemy metadata
from ..models.user import User
from ..models.journal import Journal
from ..models.emotion import EmotionalCheckin, EmotionalTrend, EmotionalInsight
from ..models.tool import Tool, ToolFavorite, ToolUsage
from ..models.achievement import Achievement
from ..models.progress import UserActivity, UsageStatistics, ProgressInsight, UserAchievement
from ..models.streak import Streak
from ..models.device import Device, DevicePlatform
from ..models.notification import Notification, NotificationPreference, NotificationType

# List of all models for reference
all_models = [
    User, 
    Journal, 
    EmotionalCheckin, 
    EmotionalTrend, 
    EmotionalInsight, 
    Tool, 
    ToolFavorite, 
    ToolUsage, 
    Achievement, 
    UserActivity, 
    UsageStatistics, 
    ProgressInsight, 
    UserAchievement, 
    Streak, 
    Device, 
    Notification, 
    NotificationPreference
]

def get_user_model():
    """
    Returns the User model class to avoid circular imports
    
    Returns:
        class: User model class
    """
    return User

def get_journal_models():
    """
    Returns Journal-related model classes to avoid circular imports
    
    Returns:
        dict: Dictionary containing Journal model classes
    """
    return {
        "Journal": Journal
    }

def get_emotion_models():
    """
    Returns Emotion-related model classes to avoid circular imports
    
    Returns:
        dict: Dictionary containing Emotion-related model classes
    """
    return {
        "EmotionalCheckin": EmotionalCheckin,
        "EmotionalTrend": EmotionalTrend,
        "EmotionalInsight": EmotionalInsight
    }

def get_tool_models():
    """
    Returns Tool-related model classes to avoid circular imports
    
    Returns:
        dict: Dictionary containing Tool-related model classes
    """
    return {
        "Tool": Tool,
        "ToolFavorite": ToolFavorite,
        "ToolUsage": ToolUsage
    }

def get_progress_models():
    """
    Returns Progress-related model classes to avoid circular imports
    
    Returns:
        dict: Dictionary containing Progress-related model classes
    """
    return {
        "UserActivity": UserActivity,
        "UsageStatistics": UsageStatistics,
        "ProgressInsight": ProgressInsight,
        "UserAchievement": UserAchievement
    }

def get_achievement_model():
    """
    Returns the Achievement model class to avoid circular imports
    
    Returns:
        class: Achievement model class
    """
    return Achievement

def get_streak_model():
    """
    Returns the Streak model class to avoid circular imports
    
    Returns:
        class: Streak model class
    """
    return Streak

def get_device_models():
    """
    Returns Device-related model classes to avoid circular imports
    
    Returns:
        dict: Dictionary containing Device-related model classes and enums
    """
    return {
        "Device": Device,
        "DevicePlatform": DevicePlatform
    }

def get_notification_models():
    """
    Returns Notification-related model classes to avoid circular imports
    
    Returns:
        dict: Dictionary containing Notification-related model classes and enums
    """
    return {
        "Notification": Notification,
        "NotificationPreference": NotificationPreference,
        "NotificationType": NotificationType
    }