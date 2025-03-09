from typing import List, Optional, Tuple
from datetime import datetime
import uuid

from sqlalchemy.orm import Session
from fastapi import HTTPException

from ..core.logging import get_logger
from ..crud import notification, notification_preference
from ..models.notification import NotificationType, Notification, NotificationPreference
from ..core.config import settings
from ..constants.error_codes import ErrorCategory, ERROR_CODES

# Initialize logger
logger = get_logger(__name__)

class NotificationService:
    """Service for managing notifications and notification preferences"""
    
    def __init__(self):
        """Initialize the notification service"""
        self.logger = logger
    
    def create_notification(
        self,
        db: Session,
        user_id: uuid.UUID,
        notification_type: NotificationType,
        title: str,
        content: str,
        scheduled_for: Optional[datetime] = None,
        related_entity_type: Optional[str] = None,
        related_entity_id: Optional[str] = None
    ) -> Optional[Notification]:
        """
        Create a new notification for a user
        
        Args:
            db: Database session
            user_id: User ID
            notification_type: Type of notification
            title: Notification title
            content: Notification content
            scheduled_for: When to send the notification (None for immediate)
            related_entity_type: Type of related entity (e.g., 'achievement')
            related_entity_id: ID of related entity
            
        Returns:
            The created notification or None if notifications of this type are disabled
        """
        # Check if user has enabled this notification type
        if not self.is_notification_type_enabled(db, user_id, notification_type):
            self.logger.debug(
                f"Notification type {notification_type} is disabled for user {user_id}, skipping creation"
            )
            return None
        
        # Create the notification
        created_notification = notification.create_for_user(
            db=db,
            user_id=user_id,
            notification_type=notification_type,
            title=title,
            content=content,
            scheduled_for=scheduled_for,
            related_entity_type=related_entity_type,
            related_entity_id=related_entity_id
        )
        
        self.logger.info(
            f"Created notification for user {user_id}, type {notification_type}: {title}"
        )
        
        return created_notification
    
    def get_user_notifications(
        self,
        db: Session,
        user_id: uuid.UUID,
        unread_only: bool = False,
        skip: int = 0,
        limit: int = 100
    ) -> Tuple[List[Notification], int]:
        """
        Get notifications for a specific user with optional filtering
        
        Args:
            db: Database session
            user_id: User ID
            unread_only: Only return unread notifications
            skip: Number of records to skip for pagination
            limit: Maximum number of records to return
            
        Returns:
            Tuple of (notifications, total_count)
        """
        notifications, total = notification.get_by_user(
            db=db,
            user_id=user_id,
            unread_only=unread_only,
            skip=skip,
            limit=limit
        )
        
        self.logger.debug(
            f"Retrieved {len(notifications)} notifications for user {user_id}"
            f" (unread_only={unread_only}, total={total})"
        )
        
        return notifications, total
    
    def get_notification(
        self,
        db: Session,
        notification_id: uuid.UUID
    ) -> Optional[Notification]:
        """
        Get a specific notification by ID
        
        Args:
            db: Database session
            notification_id: Notification ID
            
        Returns:
            The notification if found, None otherwise
        """
        notification_obj = notification.get(db=db, id=notification_id)
        
        self.logger.debug(f"Retrieved notification {notification_id}")
        
        return notification_obj
    
    def mark_notification_as_read(
        self,
        db: Session,
        notification_id: uuid.UUID
    ) -> Optional[Notification]:
        """
        Mark a notification as read
        
        Args:
            db: Database session
            notification_id: Notification ID
            
        Returns:
            The updated notification if found, None otherwise
        """
        updated_notification = notification.mark_as_read(db=db, notification_id=notification_id)
        
        self.logger.debug(f"Marked notification {notification_id} as read")
        
        return updated_notification
    
    def mark_all_as_read(
        self,
        db: Session,
        user_id: uuid.UUID
    ) -> int:
        """
        Mark all notifications for a user as read
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            Number of notifications marked as read
        """
        count = notification.mark_all_as_read(db=db, user_id=user_id)
        
        self.logger.info(f"Marked {count} notifications as read for user {user_id}")
        
        return count
    
    def count_unread_notifications(
        self,
        db: Session,
        user_id: uuid.UUID
    ) -> int:
        """
        Count unread notifications for a user
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            Count of unread notifications
        """
        count = notification.count_unread(db=db, user_id=user_id)
        
        return count
    
    def create_daily_reminder(
        self,
        db: Session,
        user_id: uuid.UUID,
        scheduled_for: Optional[datetime] = None
    ) -> Optional[Notification]:
        """
        Create a daily reminder notification for a user
        
        Args:
            db: Database session
            user_id: User ID
            scheduled_for: When to send the reminder (None for immediate)
            
        Returns:
            The created notification or None if daily reminders are disabled
        """
        title = "¡Momento de check-in!"
        content = "Es hora de tomarte un momento para tu bienestar emocional. ¿Cómo te sientes hoy?"
        
        return self.create_notification(
            db=db,
            user_id=user_id,
            notification_type=NotificationType.DAILY_REMINDER,
            title=title,
            content=content,
            scheduled_for=scheduled_for
        )
    
    def create_streak_reminder(
        self,
        db: Session,
        user_id: uuid.UUID,
        current_streak: int,
        scheduled_for: Optional[datetime] = None
    ) -> Optional[Notification]:
        """
        Create a streak reminder notification for a user
        
        Args:
            db: Database session
            user_id: User ID
            current_streak: Current streak count
            scheduled_for: When to send the reminder (None for immediate)
            
        Returns:
            The created notification or None if streak reminders are disabled
        """
        title = "¡No pierdas tu racha!"
        content = f"Llevas {current_streak} días consecutivos. Haz un check-in hoy para mantener tu racha."
        
        return self.create_notification(
            db=db,
            user_id=user_id,
            notification_type=NotificationType.STREAK_REMINDER,
            title=title,
            content=content,
            scheduled_for=scheduled_for
        )
    
    def create_achievement_notification(
        self,
        db: Session,
        user_id: uuid.UUID,
        achievement_name: str,
        achievement_description: str,
        achievement_id: Optional[str] = None
    ) -> Optional[Notification]:
        """
        Create an achievement notification for a user
        
        Args:
            db: Database session
            user_id: User ID
            achievement_name: Name of the achievement
            achievement_description: Description of the achievement
            achievement_id: Optional ID of the achievement for reference
            
        Returns:
            The created notification or None if achievement notifications are disabled
        """
        title = f"¡Logro desbloqueado: {achievement_name}!"
        content = achievement_description
        
        return self.create_notification(
            db=db,
            user_id=user_id,
            notification_type=NotificationType.ACHIEVEMENT,
            title=title,
            content=content,
            related_entity_type="achievement",
            related_entity_id=achievement_id
        )
    
    def create_affirmation_notification(
        self,
        db: Session,
        user_id: uuid.UUID,
        affirmation_text: str,
        scheduled_for: Optional[datetime] = None
    ) -> Optional[Notification]:
        """
        Create an affirmation notification for a user
        
        Args:
            db: Database session
            user_id: User ID
            affirmation_text: The affirmation text content
            scheduled_for: When to send the affirmation (None for immediate)
            
        Returns:
            The created notification or None if affirmation notifications are disabled
        """
        title = "Afirmación diaria"
        
        return self.create_notification(
            db=db,
            user_id=user_id,
            notification_type=NotificationType.AFFIRMATION,
            title=title,
            content=affirmation_text,
            scheduled_for=scheduled_for
        )
    
    def create_wellness_tip_notification(
        self,
        db: Session,
        user_id: uuid.UUID,
        tip_title: str,
        tip_content: str,
        scheduled_for: Optional[datetime] = None
    ) -> Optional[Notification]:
        """
        Create a wellness tip notification for a user
        
        Args:
            db: Database session
            user_id: User ID
            tip_title: Title of the wellness tip
            tip_content: Content of the wellness tip
            scheduled_for: When to send the tip (None for immediate)
            
        Returns:
            The created notification or None if wellness tip notifications are disabled
        """
        return self.create_notification(
            db=db,
            user_id=user_id,
            notification_type=NotificationType.WELLNESS_TIP,
            title=tip_title,
            content=tip_content,
            scheduled_for=scheduled_for
        )
    
    def get_notification_preferences(
        self,
        db: Session,
        user_id: uuid.UUID
    ) -> NotificationPreference:
        """
        Get notification preferences for a user
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            User's notification preferences
        """
        preferences = notification_preference.get_by_user(db=db, user_id=user_id)
        
        # If no preferences exist yet, create default preferences
        if not preferences:
            # Import here to avoid circular imports
            from ..schemas.notification import NotificationPreferencesCreate
            
            # Create default preferences (all enabled except wellness tips)
            preferences_data = NotificationPreferencesCreate(
                user_id=user_id,
                daily_reminders=True,
                streak_reminders=True,
                achievements=True,
                affirmations=True,
                wellness_tips=False,
                app_updates=False
            )
            
            preferences = notification_preference.create_for_user(
                db=db,
                user_id=user_id,
                preferences_data=preferences_data
            )
            
            self.logger.info(f"Created default notification preferences for user {user_id}")
        
        return preferences
    
    def update_notification_preferences(
        self,
        db: Session,
        user_id: uuid.UUID,
        preferences_data: dict
    ) -> NotificationPreference:
        """
        Update notification preferences for a user
        
        Args:
            db: Database session
            user_id: User ID
            preferences_data: Dictionary of preference settings to update
            
        Returns:
            Updated notification preferences
        """
        # Import here to avoid circular imports
        from ..schemas.notification import NotificationPreferencesUpdate
        
        # Convert dict to pydantic model
        update_data = NotificationPreferencesUpdate(**preferences_data)
        
        updated_preferences = notification_preference.update_for_user(
            db=db,
            user_id=user_id,
            preferences_data=update_data
        )
        
        self.logger.info(f"Updated notification preferences for user {user_id}")
        return updated_preferences
    
    def is_notification_type_enabled(
        self,
        db: Session,
        user_id: uuid.UUID,
        notification_type: NotificationType
    ) -> bool:
        """
        Check if a notification type is enabled for a user
        
        Args:
            db: Database session
            user_id: User ID
            notification_type: Type of notification to check
            
        Returns:
            True if the notification type is enabled, False otherwise
        """
        return notification_preference.is_enabled_for_user(
            db=db,
            user_id=user_id,
            notification_type=notification_type
        )
    
    def schedule_notification(
        self,
        db: Session,
        user_id: uuid.UUID,
        notification_type: NotificationType,
        title: str,
        content: str,
        scheduled_for: datetime,
        related_entity_type: Optional[str] = None,
        related_entity_id: Optional[str] = None
    ) -> Optional[Notification]:
        """
        Schedule a notification for future delivery
        
        Args:
            db: Database session
            user_id: User ID
            notification_type: Type of notification
            title: Notification title
            content: Notification content
            scheduled_for: When to send the notification
            related_entity_type: Type of related entity (e.g., 'achievement')
            related_entity_id: ID of related entity
            
        Returns:
            The scheduled notification or None if notifications of this type are disabled
        """
        # Validate that scheduled_for is in the future
        now = datetime.utcnow()
        if scheduled_for <= now:
            raise ValueError("Scheduled time must be in the future")
        
        # Create the notification with scheduled_for time
        notification_obj = self.create_notification(
            db=db,
            user_id=user_id,
            notification_type=notification_type,
            title=title,
            content=content,
            scheduled_for=scheduled_for,
            related_entity_type=related_entity_type,
            related_entity_id=related_entity_id
        )
        
        if notification_obj:
            self.logger.info(
                f"Scheduled notification for user {user_id}, type {notification_type} at {scheduled_for}"
            )
        
        return notification_obj


# Singleton instance
notification_service = NotificationService()