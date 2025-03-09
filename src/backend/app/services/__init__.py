"""
This file serves as the entry point for all service-related functionality in the Amira Wellness application. It imports and re-exports all service classes to provide a clean, organized API for other modules to use. This approach follows the facade pattern, simplifying the interface to the services layer.
"""

# Import service classes from their respective modules
from .encryption import EncryptionService  # v41.0+ Service for handling end-to-end encryption of sensitive user data
from .storage import StorageService  # Service for managing secure storage of files and data
from .auth import AuthService  # Service for handling user authentication and authorization
from .user import UserService  # Service for managing user profiles and preferences
from .journal import JournalService  # Service for handling voice journal recordings and metadata
from .emotion import EmotionService  # Service for processing emotional check-ins and analysis
from .tool import ToolService  # Service for managing the tool library and user interactions
from .progress import ProgressService  # Service for tracking user progress and generating insights
from .notification import NotificationService  # Service for managing user notifications and reminders
from .recommendation import RecommendationService  # Service for generating personalized tool recommendations
from .streak import StreakService  # Service for calculating and managing user streaks
from .analytics import AnalyticsService  # Service for processing anonymized analytics data

# Expose the service classes for use in other modules
__all__ = [
    "EncryptionService",  # Expose encryption service for end-to-end encryption of sensitive data
    "StorageService",  # Expose storage service for secure file management
    "AuthService",  # Expose authentication service for user identity management
    "UserService",  # Expose user service for profile management
    "JournalService",  # Expose journal service for voice recording management
    "EmotionService",  # Expose emotion service for emotional check-in processing
    "ToolService",  # Expose tool service for tool library management
    "ProgressService",  # Expose progress service for tracking user progress
    "NotificationService",  # Expose notification service for user alerts and reminders
    "RecommendationService",  # Expose recommendation service for personalized tool suggestions
    "StreakService",  # Expose streak service for user streak calculations
    "AnalyticsService",  # Expose analytics service for data analysis
]